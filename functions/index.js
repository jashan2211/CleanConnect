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
