/**
 * CleanConnect Firebase Cloud Functions
 * Handles Stripe payments for tipping creators
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe");

admin.initializeApp();

// Initialize Stripe with secret key from Firebase config
const getStripe = () => {
  const secretKey = functions.config().stripe?.secret_key;
  if (!secretKey) {
    throw new Error("Stripe secret key not configured. Run: firebase functions:config:set stripe.secret_key=sk_live_xxx");
  }
  return stripe(secretKey);
};

// ============================================
// CONNECT ONBOARDING - Let creators receive tips
// ============================================

/**
 * Create a Stripe Connect account for a creator
 * Call this when a user wants to start receiving tips
 */
exports.createConnectAccount = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const userId = context.auth.uid;
  const stripeClient = getStripe();

  try {
    // Check if user already has a Connect account
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (userData?.stripeAccountId) {
      // Already has account, create new onboarding link
      const accountLink = await stripeClient.accountLinks.create({
        account: userData.stripeAccountId,
        refresh_url: `https://thebighead.ca/CleanConnect/stripe-refresh?userId=${userId}`,
        return_url: `https://thebighead.ca/CleanConnect/stripe-return?userId=${userId}`,
        type: "account_onboarding",
      });
      return { url: accountLink.url, accountId: userData.stripeAccountId };
    }

    // Create new Connect Express account
    const account = await stripeClient.accounts.create({
      type: "express",
      country: "IN", // India
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      business_type: "individual",
      metadata: {
        firebaseUserId: userId,
      },
    });

    // Save account ID to Firestore
    await admin.firestore().collection("users").doc(userId).set({
      stripeAccountId: account.id,
      stripeOnboardingComplete: false,
    }, { merge: true });

    // Create onboarding link
    const accountLink = await stripeClient.accountLinks.create({
      account: account.id,
      refresh_url: `https://thebighead.ca/CleanConnect/stripe-refresh?userId=${userId}`,
      return_url: `https://thebighead.ca/CleanConnect/stripe-return?userId=${userId}`,
      type: "account_onboarding",
    });

    return { url: accountLink.url, accountId: account.id };
  } catch (error) {
    console.error("Error creating Connect account:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Check if a creator's Stripe account is ready to receive payments
 */
exports.checkConnectStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const userId = context.auth.uid;
  const stripeClient = getStripe();

  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (!userData?.stripeAccountId) {
      return { hasAccount: false, canReceivePayments: false };
    }

    const account = await stripeClient.accounts.retrieve(userData.stripeAccountId);

    const canReceivePayments = account.charges_enabled && account.payouts_enabled;

    // Update Firestore
    await admin.firestore().collection("users").doc(userId).set({
      stripeOnboardingComplete: canReceivePayments,
    }, { merge: true });

    return {
      hasAccount: true,
      canReceivePayments,
      accountId: userData.stripeAccountId,
    };
  } catch (error) {
    console.error("Error checking Connect status:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ============================================
// PAYMENTS - Send tips to creators
// ============================================

/**
 * Create a payment intent for tipping a creator
 * Platform takes 7% fee, creator gets 93%
 */
exports.createTipPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const { amount, creatorId, postId } = data;

  // Validate amount (minimum ₹10, maximum ₹10,000)
  if (!amount || amount < 1000 || amount > 1000000) { // Amount in paise
    throw new functions.https.HttpsError("invalid-argument", "Amount must be between ₹10 and ₹10,000");
  }

  if (!creatorId) {
    throw new functions.https.HttpsError("invalid-argument", "Creator ID required");
  }

  const stripeClient = getStripe();
  const senderId = context.auth.uid;

  try {
    // Get creator's Stripe account
    const creatorDoc = await admin.firestore().collection("users").doc(creatorId).get();
    const creatorData = creatorDoc.data();

    if (!creatorData?.stripeAccountId) {
      throw new functions.https.HttpsError("failed-precondition", "Creator cannot receive tips yet");
    }

    // Check creator account is active
    const account = await stripeClient.accounts.retrieve(creatorData.stripeAccountId);
    if (!account.charges_enabled) {
      throw new functions.https.HttpsError("failed-precondition", "Creator's payment account is not active");
    }

    // Calculate fees: Platform takes 7%
    const platformFee = Math.round(amount * 0.07);

    // Create payment intent with automatic transfer to creator
    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: amount, // in paise
      currency: "inr",
      automatic_payment_methods: {
        enabled: true,
      },
      application_fee_amount: platformFee,
      transfer_data: {
        destination: creatorData.stripeAccountId,
      },
      metadata: {
        senderId,
        creatorId,
        postId: postId || "",
        type: "tip",
      },
    });

    // Save tip record to Firestore
    await admin.firestore().collection("tips").add({
      senderId,
      creatorId,
      postId: postId || null,
      amount,
      platformFee,
      creatorReceives: amount - platformFee,
      paymentIntentId: paymentIntent.id,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    console.error("Error creating payment intent:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ============================================
// WEBHOOKS - Handle Stripe events
// ============================================

/**
 * Stripe webhook handler
 * Processes payment success/failure events
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const stripeClient = getStripe();
  const webhookSecret = functions.config().stripe?.webhook_secret;

  let event;

  try {
    if (webhookSecret) {
      const signature = req.headers["stripe-signature"];
      event = stripeClient.webhooks.constructEvent(req.rawBody, signature, webhookSecret);
    } else {
      event = req.body;
    }
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case "payment_intent.succeeded": {
      const paymentIntent = event.data.object;
      console.log("Payment succeeded:", paymentIntent.id);

      // Update tip status in Firestore
      const tipsSnapshot = await admin.firestore()
        .collection("tips")
        .where("paymentIntentId", "==", paymentIntent.id)
        .get();

      for (const doc of tipsSnapshot.docs) {
        await doc.ref.update({
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const tipData = doc.data();

        // Update creator's total tips received
        await admin.firestore().collection("users").doc(tipData.creatorId).update({
          tipsReceived: admin.firestore.FieldValue.increment(tipData.creatorReceives),
        });

        // Update sender's tips given
        await admin.firestore().collection("users").doc(tipData.senderId).update({
          tipsGiven: admin.firestore.FieldValue.increment(tipData.amount),
        });

        // Update post tips if applicable
        if (tipData.postId) {
          await admin.firestore().collection("posts").doc(tipData.postId).update({
            tipsReceived: admin.firestore.FieldValue.increment(tipData.creatorReceives),
          });
        }
      }
      break;
    }

    case "payment_intent.payment_failed": {
      const paymentIntent = event.data.object;
      console.log("Payment failed:", paymentIntent.id);

      const tipsSnapshot = await admin.firestore()
        .collection("tips")
        .where("paymentIntentId", "==", paymentIntent.id)
        .get();

      for (const doc of tipsSnapshot.docs) {
        await doc.ref.update({
          status: "failed",
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          failureMessage: paymentIntent.last_payment_error?.message || "Payment failed",
        });
      }
      break;
    }

    case "account.updated": {
      // Connect account was updated
      const account = event.data.object;
      const userId = account.metadata?.firebaseUserId;

      if (userId) {
        await admin.firestore().collection("users").doc(userId).update({
          stripeOnboardingComplete: account.charges_enabled && account.payouts_enabled,
        });
      }
      break;
    }

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
});

// ============================================
// DASHBOARD LINK - Let creators access Stripe dashboard
// ============================================

/**
 * Create a login link for creators to access their Stripe dashboard
 */
exports.createDashboardLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const userId = context.auth.uid;
  const stripeClient = getStripe();

  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (!userData?.stripeAccountId) {
      throw new functions.https.HttpsError("failed-precondition", "No Stripe account found");
    }

    const loginLink = await stripeClient.accounts.createLoginLink(userData.stripeAccountId);

    return { url: loginLink.url };
  } catch (error) {
    console.error("Error creating dashboard link:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ============================================
// POST MANAGEMENT - Vote, Delete, Update
// ============================================

/**
 * Vote on a post (upvote or downvote)
 * Each user can only vote once per post
 */
exports.voteOnPost = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const { postId, voteType } = data; // voteType: "up", "down", or "none" (to remove vote)
  const userId = context.auth.uid;

  if (!postId) {
    throw new functions.https.HttpsError("invalid-argument", "Post ID required");
  }

  if (!["up", "down", "none"].includes(voteType)) {
    throw new functions.https.HttpsError("invalid-argument", "Vote type must be 'up', 'down', or 'none'");
  }

  const db = admin.firestore();
  const postRef = db.collection("posts").doc(postId);
  const voteRef = db.collection("votes").doc(`${userId}_${postId}`);

  try {
    return await db.runTransaction(async (transaction) => {
      const postDoc = await transaction.get(postRef);
      const voteDoc = await transaction.get(voteRef);

      if (!postDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Post not found");
      }

      const postData = postDoc.data();
      let upvotes = postData.communityVotes || 0;
      let downvotes = postData.communityDownvotes || 0;

      const previousVote = voteDoc.exists ? voteDoc.data().voteType : null;

      // Remove previous vote effect
      if (previousVote === "up") upvotes--;
      if (previousVote === "down") downvotes--;

      // Apply new vote
      if (voteType === "up") upvotes++;
      if (voteType === "down") downvotes++;

      // Update post
      transaction.update(postRef, {
        communityVotes: upvotes,
        communityDownvotes: downvotes,
        voteScore: upvotes - downvotes, // For sorting
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Save or delete vote record
      if (voteType === "none") {
        transaction.delete(voteRef);
      } else {
        transaction.set(voteRef, {
          userId,
          postId,
          voteType,
          votedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        success: true,
        communityVotes: upvotes,
        communityDownvotes: downvotes,
        voteScore: upvotes - downvotes,
      };
    });
  } catch (error) {
    console.error("Error voting on post:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Get user's vote for a post
 */
exports.getUserVote = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return { voteType: null };
  }

  const { postId } = data;
  const userId = context.auth.uid;

  if (!postId) {
    throw new functions.https.HttpsError("invalid-argument", "Post ID required");
  }

  try {
    const voteDoc = await admin.firestore()
      .collection("votes")
      .doc(`${userId}_${postId}`)
      .get();

    return {
      voteType: voteDoc.exists ? voteDoc.data().voteType : null,
    };
  } catch (error) {
    console.error("Error getting user vote:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Delete a post (owner only)
 * Also deletes associated comments and images
 */
exports.deletePost = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const { postId } = data;
  const userId = context.auth.uid;

  if (!postId) {
    throw new functions.https.HttpsError("invalid-argument", "Post ID required");
  }

  const db = admin.firestore();
  const storage = admin.storage().bucket();

  try {
    // Get the post
    const postDoc = await db.collection("posts").doc(postId).get();

    if (!postDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Post not found");
    }

    const postData = postDoc.data();

    // Check ownership
    if (postData.userId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "You can only delete your own posts");
    }

    // Delete associated comments
    const commentsSnapshot = await db.collection("comments")
      .where("postId", "==", postId)
      .get();

    const batch = db.batch();

    commentsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Delete associated votes
    const votesSnapshot = await db.collection("votes")
      .where("postId", "==", postId)
      .get();

    votesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Delete the post
    batch.delete(db.collection("posts").doc(postId));

    // Update user stats (subtract points)
    batch.update(db.collection("users").doc(userId), {
      totalPosts: admin.firestore.FieldValue.increment(-1),
      totalPoints: admin.firestore.FieldValue.increment(-postData.pointsEarned || 0),
      totalWasteKg: admin.firestore.FieldValue.increment(-postData.wasteCollectedKg || 0),
    });

    await batch.commit();

    // Delete images from storage (async, don't wait)
    try {
      await storage.deleteFiles({ prefix: `posts/${postId}/` });
    } catch (storageError) {
      console.log("Storage cleanup error (non-fatal):", storageError.message);
    }

    return { success: true, message: "Post deleted successfully" };
  } catch (error) {
    console.error("Error deleting post:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Delete a comment (owner only)
 */
exports.deleteComment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const { commentId } = data;
  const userId = context.auth.uid;

  if (!commentId) {
    throw new functions.https.HttpsError("invalid-argument", "Comment ID required");
  }

  const db = admin.firestore();

  try {
    const commentDoc = await db.collection("comments").doc(commentId).get();

    if (!commentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Comment not found");
    }

    const commentData = commentDoc.data();

    // Check ownership
    if (commentData.userId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "You can only delete your own comments");
    }

    // Update post comment count
    if (commentData.postId) {
      await db.collection("posts").doc(commentData.postId).update({
        comments: admin.firestore.FieldValue.increment(-1),
      });
    }

    // Delete the comment
    await db.collection("comments").doc(commentId).delete();

    return { success: true, message: "Comment deleted successfully" };
  } catch (error) {
    console.error("Error deleting comment:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Recalculate and update user stats
 * Call this if stats get out of sync
 */
exports.recalculateUserStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const userId = context.auth.uid;
  const db = admin.firestore();

  try {
    // Get all user's posts
    const postsSnapshot = await db.collection("posts")
      .where("userId", "==", userId)
      .get();

    let totalPosts = 0;
    let totalWasteKg = 0;
    let totalPoints = 0;

    postsSnapshot.docs.forEach((doc) => {
      const post = doc.data();
      totalPosts++;
      totalWasteKg += post.wasteCollectedKg || 0;
      totalPoints += post.pointsEarned || 0;
    });

    // Get tips received
    const tipsSnapshot = await db.collection("tips")
      .where("creatorId", "==", userId)
      .where("status", "==", "completed")
      .get();

    let tipsReceived = 0;
    tipsSnapshot.docs.forEach((doc) => {
      tipsReceived += doc.data().creatorReceives || 0;
    });

    // Update user document
    await db.collection("users").doc(userId).update({
      totalPosts,
      totalWasteKg,
      totalPoints,
      tipsReceived,
      statsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      stats: { totalPosts, totalWasteKg, totalPoints, tipsReceived },
    };
  } catch (error) {
    console.error("Error recalculating stats:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ============================================
// FEED QUERIES - Get posts with sorting
// ============================================

/**
 * Get posts with advanced sorting and filtering
 * Supports: hot, new, top (day/week/month/year/all)
 */
exports.getFeedPosts = functions.https.onCall(async (data, context) => {
  const {
    sortBy = "hot",      // hot, new, top
    timeRange = "all",   // day, week, month, year, all
    state = null,
    district = null,
    verifiedOnly = false,
    limit = 20,
    startAfter = null,
  } = data;

  const db = admin.firestore();

  try {
    let query = db.collection("posts");

    // Location filters
    if (state) {
      query = query.where("state", "==", state);
    }
    if (district) {
      query = query.where("district", "==", district);
    }

    // Verified filter
    if (verifiedOnly) {
      query = query.where("hasVideoProof", "==", true);
    }

    // Time range filter
    if (timeRange !== "all") {
      const now = new Date();
      let startDate;

      switch (timeRange) {
        case "day":
          startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
          break;
        case "week":
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case "month":
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case "year":
          startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
          break;
      }

      if (startDate) {
        query = query.where("createdAt", ">=", startDate);
      }
    }

    // Sorting
    switch (sortBy) {
      case "new":
        query = query.orderBy("createdAt", "desc");
        break;
      case "top":
        query = query.orderBy("voteScore", "desc").orderBy("createdAt", "desc");
        break;
      case "tipped":
        query = query.orderBy("tipsReceived", "desc").orderBy("createdAt", "desc");
        break;
      case "hot":
      default:
        // Hot = combination of recency and votes (simplified)
        query = query.orderBy("createdAt", "desc");
        break;
    }

    // Pagination
    if (startAfter) {
      const startDoc = await db.collection("posts").doc(startAfter).get();
      if (startDoc.exists) {
        query = query.startAfter(startDoc);
      }
    }

    query = query.limit(limit);

    const snapshot = await query.get();
    const posts = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {
      posts,
      hasMore: posts.length === limit,
      lastPostId: posts.length > 0 ? posts[posts.length - 1].id : null,
    };
  } catch (error) {
    console.error("Error getting feed posts:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
