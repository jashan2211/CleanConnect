/**
 * CleanConnect 2.0 Cloud Functions.
 *
 * The app writes content (spots, drives, comments, reactions, attendees, flags).
 * These triggers own everything that must be trustworthy: Swachh Points, streaks,
 * counters, city/India stats, auto-hiding reported content, and account deletion.
 */

const { setGlobalOptions } = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getAuth } = require("firebase-admin/auth");

initializeApp();
const db = getFirestore();

setGlobalOptions({ region: "us-central1", maxInstances: 10, memory: "256MiB" });

// Keep in sync with Points in the iOS app (Core/Models/Profile.swift).
const POINTS = {
  report: 10,
  cleanup: 50,
  perBag: 5,
  maxBagsCounted: 20,
  reportGotCleaned: 10,
  verify: 5,
  joinDrive: 15,
  hostDrive: 20,
  completeDrive: 30,
};
const HIDE_AFTER_FLAGS = 3;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** "YYYY-MM-DD" in India Standard Time. */
function istDay(date) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kolkata",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

/** ISO-8601 week key ("2026-W43") of the IST calendar day. Matches WeekKey in the app. */
function isoWeek(date) {
  const [y, m, d] = istDay(date).split("-").map(Number);
  const t = new Date(Date.UTC(y, m - 1, d));
  const dow = t.getUTCDay() || 7;
  t.setUTCDate(t.getUTCDate() + 4 - dow);
  const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
  return `${t.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

function bagsCounted(bags) {
  return Math.min(Math.max(Number(bags) || 0, 0), POINTS.maxBagsCounted);
}

/**
 * Adds points (may be negative) and counter increments to a profile in a transaction,
 * maintaining weekly points and the daily streak.
 */
async function award(uid, points, inc = {}) {
  if (!uid || uid === "deleted") return;
  const ref = db.doc(`profiles/${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const p = snap.data();
    const now = new Date();
    const day = istDay(now);
    const yesterday = istDay(new Date(now.getTime() - 86400000));
    const week = isoWeek(now);

    const update = { updatedAt: FieldValue.serverTimestamp() };
    update.points = Math.max(0, (p.points || 0) + points);
    update.weekKey = week;
    update.weekPoints = Math.max(0, (p.weekKey === week ? p.weekPoints || 0 : 0) + points);
    for (const [key, value] of Object.entries(inc)) {
      update[key] = Math.max(0, (p[key] || 0) + value);
    }
    if (points > 0 && p.lastActiveDay !== day) {
      const streak = p.lastActiveDay === yesterday ? (p.streak || 0) + 1 : 1;
      update.streak = streak;
      update.bestStreak = Math.max(p.bestStreak || 0, streak);
      update.lastActiveDay = day;
    }
    tx.update(ref, update);
  });
}

/** Increments India-wide and per-city aggregate counters. */
async function bumpStats(source, inc) {
  const data = {};
  for (const [key, value] of Object.entries(inc)) data[key] = FieldValue.increment(value);
  data.updatedAt = FieldValue.serverTimestamp();
  const writes = [db.doc("stats/india").set(data, { merge: true })];
  const cityKey = source && typeof source.cityKey === "string" ? source.cityKey.trim() : "";
  if (cityKey && cityKey.length < 200 && !cityKey.includes("/")) {
    writes.push(
      db.doc(`cityStats/${cityKey}`).set({ ...data, city: source.city || "", state: source.state || "" }, { merge: true }),
    );
  }
  await Promise.all(writes);
}

async function bumpCounter(path, field, delta) {
  const ref = db.doc(path);
  try {
    await ref.update({ [field]: FieldValue.increment(delta) });
  } catch (err) {
    // Parent was deleted (e.g. cascading delete); nothing to count.
    if (err.code !== 5) logger.warn(`bumpCounter ${path}.${field}`, err.message);
  }
}

async function deleteStorageFolder(prefix) {
  try {
    await getStorage().bucket().deleteFiles({ prefix });
  } catch (err) {
    logger.warn(`deleteStorageFolder ${prefix}`, err.message);
  }
}

// ---------------------------------------------------------------------------
// Profiles
// ---------------------------------------------------------------------------

exports.onProfileCreated = onDocumentCreated("profiles/{uid}", async (event) => {
  if (!event.data) return;
  await event.data.ref.set(
    {
      points: 0, weekPoints: 0, weekKey: isoWeek(new Date()), reports: 0, cleanups: 0, bags: 0,
      drivesHosted: 0, drivesJoined: 0, verifications: 0, streak: 0, bestStreak: 0, lastActiveDay: "",
    },
    { merge: true },
  );
  await db.doc("stats/india").set({ volunteers: FieldValue.increment(1) }, { merge: true });
});

// ---------------------------------------------------------------------------
// Spots
// ---------------------------------------------------------------------------

exports.onSpotCreated = onDocumentCreated("spots/{spotId}", async (event) => {
  const spot = event.data && event.data.data();
  if (!spot) return;
  await Promise.all([
    award(spot.reporterId, POINTS.report, { reports: 1 }),
    bumpStats(spot, { reported: 1 }),
    event.data.ref.set({ respectCount: 0, stillThereCount: 0, verifiedCount: 0, commentCount: 0 }, { merge: true }),
  ]);
});

exports.onSpotUpdated = onDocumentUpdated("spots/{spotId}", async (event) => {
  const before = event.data && event.data.before.data();
  const after = event.data && event.data.after.data();
  if (!before || !after) return;
  if (before.status !== "cleaned" && after.status === "cleaned") {
    const bags = Math.min(Math.max(Number(after.bags) || 0, 0), 100);
    const jobs = [
      award(after.cleanedBy, POINTS.cleanup + POINTS.perBag * bagsCounted(bags), { cleanups: 1, bags }),
      bumpStats(after, { cleaned: 1, bags }),
    ];
    if (after.reporterId && after.reporterId !== after.cleanedBy) {
      jobs.push(award(after.reporterId, POINTS.reportGotCleaned));
    }
    await Promise.all(jobs);
  }
});

exports.onSpotDeleted = onDocumentDeleted("spots/{spotId}", async (event) => {
  const spot = event.data && event.data.data();
  if (!spot) return;
  const jobs = [
    db.recursiveDelete(event.data.ref),
    deleteStorageFolder(`spots/${event.params.spotId}/`),
  ];
  if (spot.status === "open") {
    jobs.push(award(spot.reporterId, -POINTS.report, { reports: -1 }));
    jobs.push(bumpStats(spot, { reported: -1 }));
  }
  await Promise.all(jobs);
});

const REACTION_FIELDS = { respect: "respectCount", stillThere: "stillThereCount", verified: "verifiedCount" };

exports.onReactionCreated = onDocumentCreated("spots/{spotId}/reactions/{reactionId}", async (event) => {
  const reaction = event.data && event.data.data();
  const field = reaction && REACTION_FIELDS[reaction.type];
  if (!field) return;
  await bumpCounter(`spots/${event.params.spotId}`, field, 1);
  if (reaction.type === "verified") await award(reaction.uid, POINTS.verify, { verifications: 1 });
});

exports.onReactionDeleted = onDocumentDeleted("spots/{spotId}/reactions/{reactionId}", async (event) => {
  const reaction = event.data && event.data.data();
  const field = reaction && REACTION_FIELDS[reaction.type];
  if (!field) return;
  await bumpCounter(`spots/${event.params.spotId}`, field, -1);
  if (reaction.type === "verified") await award(reaction.uid, -POINTS.verify, { verifications: -1 });
});

exports.onSpotCommentCreated = onDocumentCreated("spots/{spotId}/comments/{commentId}", (event) =>
  bumpCounter(`spots/${event.params.spotId}`, "commentCount", 1));

exports.onSpotCommentDeleted = onDocumentDeleted("spots/{spotId}/comments/{commentId}", (event) =>
  bumpCounter(`spots/${event.params.spotId}`, "commentCount", -1));

// ---------------------------------------------------------------------------
// Drives
// ---------------------------------------------------------------------------

exports.onDriveCreated = onDocumentCreated("drives/{driveId}", async (event) => {
  const drive = event.data && event.data.data();
  if (!drive) return;
  await Promise.all([
    award(drive.organizerId, POINTS.hostDrive, { drivesHosted: 1 }),
    bumpStats(drive, { drives: 1 }),
    event.data.ref.set({ attendeeCount: 0, commentCount: 0 }, { merge: true }),
  ]);
});

exports.onDriveUpdated = onDocumentUpdated("drives/{driveId}", async (event) => {
  const before = event.data && event.data.before.data();
  const after = event.data && event.data.after.data();
  if (!before || !after || before.status === after.status) return;
  if (after.status === "done" && before.status === "upcoming") {
    const bags = Math.min(Math.max(Number(after.resultBags) || 0, 0), 500);
    await Promise.all([
      award(after.organizerId, POINTS.completeDrive + POINTS.perBag * bagsCounted(bags), { bags }),
      bumpStats(after, { bags }),
    ]);
  } else if (after.status === "cancelled" && before.status === "upcoming") {
    await Promise.all([
      award(after.organizerId, -POINTS.hostDrive, { drivesHosted: -1 }),
      bumpStats(after, { drives: -1 }),
    ]);
  }
});

exports.onDriveDeleted = onDocumentDeleted("drives/{driveId}", async (event) => {
  const drive = event.data && event.data.data();
  if (!drive) return;
  const jobs = [db.recursiveDelete(event.data.ref), deleteStorageFolder(`drives/${event.params.driveId}/`)];
  if (drive.status === "upcoming") {
    jobs.push(award(drive.organizerId, -POINTS.hostDrive, { drivesHosted: -1 }));
    jobs.push(bumpStats(drive, { drives: -1 }));
  }
  await Promise.all(jobs);
});

exports.onAttendeeCreated = onDocumentCreated("drives/{driveId}/attendees/{uid}", async (event) => {
  const { driveId, uid } = event.params;
  await bumpCounter(`drives/${driveId}`, "attendeeCount", 1);
  const drive = (await db.doc(`drives/${driveId}`).get()).data();
  if (drive && drive.organizerId !== uid) await award(uid, POINTS.joinDrive, { drivesJoined: 1 });
});

exports.onAttendeeDeleted = onDocumentDeleted("drives/{driveId}/attendees/{uid}", async (event) => {
  const { driveId, uid } = event.params;
  const driveSnap = await db.doc(`drives/${driveId}`).get();
  if (!driveSnap.exists) return;
  await bumpCounter(`drives/${driveId}`, "attendeeCount", -1);
  if (driveSnap.data().organizerId !== uid) await award(uid, -POINTS.joinDrive, { drivesJoined: -1 });
});

exports.onDriveCommentCreated = onDocumentCreated("drives/{driveId}/comments/{commentId}", (event) =>
  bumpCounter(`drives/${event.params.driveId}`, "commentCount", 1));

exports.onDriveCommentDeleted = onDocumentDeleted("drives/{driveId}/comments/{commentId}", (event) =>
  bumpCounter(`drives/${event.params.driveId}`, "commentCount", -1));

// ---------------------------------------------------------------------------
// Moderation
// ---------------------------------------------------------------------------

const FLAGGABLE = /^(spots|drives)\/[A-Za-z0-9]+(\/comments\/[A-Za-z0-9]+)?$|^profiles\/[A-Za-z0-9]+$/;

exports.onFlagCreated = onDocumentCreated("flags/{flagId}", async (event) => {
  const flag = event.data && event.data.data();
  if (!flag) return;
  const path = flag.targetPath;
  logger.info("Content flagged", { path, reason: flag.reason, by: flag.reporterId });
  if (typeof path !== "string" || !FLAGGABLE.test(path)) return;

  const flags = await db.collection("flags").where("targetPath", "==", path).get();
  const reporters = new Set(flags.docs.map((d) => d.data().reporterId));
  const target = db.doc(path);
  const snap = await target.get();
  if (!snap.exists) return;
  const update = { flagCount: reporters.size };
  if (reporters.size >= HIDE_AFTER_FLAGS && !path.startsWith("profiles/")) update.hidden = true;
  if (path.includes("/comments/") && reporters.size >= HIDE_AFTER_FLAGS) {
    await target.delete();
    return;
  }
  await target.update(update);
});

// ---------------------------------------------------------------------------
// Account deletion (App Store guideline 5.1.1(v))
// ---------------------------------------------------------------------------

async function deleteQuery(query) {
  const snap = await query.get();
  await Promise.all(snap.docs.map((d) => d.ref.delete().catch((e) => logger.warn("delete", d.ref.path, e.message))));
}

exports.deleteAccount = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  const former = "Former member";
  logger.info("Deleting account", { uid });

  // Spots they reported: remove open ones, anonymise the rest (cleanups stay on the map).
  const reported = await db.collection("spots").where("reporterId", "==", uid).get();
  for (const doc of reported.docs) {
    const spot = doc.data();
    if (spot.status === "open") {
      await doc.ref.delete();
    } else {
      await doc.ref.update({ reporterId: "deleted", reporterName: former, reporterPhoto: FieldValue.delete() });
    }
  }

  const cleaned = await db.collection("spots").where("cleanedBy", "==", uid).get();
  await Promise.all(cleaned.docs.map((doc) => doc.ref.update({
    cleanedBy: "deleted", cleanedByName: former, cleanedByPhoto: FieldValue.delete(),
  })));

  const claimed = await db.collection("spots").where("claimedBy", "==", uid).get();
  await Promise.all(claimed.docs.filter((d) => d.data().status === "claimed").map((doc) => doc.ref.update({
    status: "open", claimedBy: FieldValue.delete(), claimedByName: FieldValue.delete(), claimedAt: FieldValue.delete(),
  })));

  await deleteQuery(db.collectionGroup("comments").where("authorId", "==", uid));
  await deleteQuery(db.collectionGroup("reactions").where("uid", "==", uid));
  await deleteQuery(db.collectionGroup("attendees").where("uid", "==", uid));

  const drives = await db.collection("drives").where("organizerId", "==", uid).get();
  for (const doc of drives.docs) {
    const drive = doc.data();
    if (drive.status === "upcoming") {
      await doc.ref.delete();
    } else {
      await doc.ref.update({
        organizerId: "deleted", organizerName: former, organizerPhoto: FieldValue.delete(),
        upiId: FieldValue.delete(), whatsappLink: FieldValue.delete(),
      });
    }
  }

  // Legacy 1.x data.
  await deleteQuery(db.collection("posts").where("userId", "==", uid));
  await db.doc(`users/${uid}`).delete().catch(() => {});

  await Promise.all([
    db.doc(`profiles/${uid}`).delete(),
    db.doc(`userPrivate/${uid}`).delete(),
    deleteStorageFolder(`avatars/${uid}/`),
    db.doc("stats/india").set({ volunteers: FieldValue.increment(-1) }, { merge: true }),
  ]);

  await getAuth().deleteUser(uid);
  return { ok: true };
});

