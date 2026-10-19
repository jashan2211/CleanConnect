// Trigger tests: points, streaks, counters and stats computed by functions-v2.
const { test, before } = require("node:test");
const assert = require("node:assert/strict");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const PROJECT = process.env.GCLOUD_PROJECT || "demo-cleanconnect";
initializeApp({ projectId: PROJECT });
const db = getFirestore();

/** Polls until `check(data)` passes or times out. */
async function waitFor(pathStr, check, timeoutMs = 15000) {
  const start = Date.now();
  let last;
  while (Date.now() - start < timeoutMs) {
    const snap = await db.doc(pathStr).get();
    last = snap.data();
    try {
      if (snap.exists && check(last)) return last;
    } catch { /* keep polling */ }
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error(`Timed out waiting on ${pathStr}: ${JSON.stringify(last)}`);
}

const uid = (name) => `${name}_${Math.random().toString(36).slice(2, 8)}`;

async function makeProfile(id) {
  await db.doc(`profiles/${id}`).set({ name: id, bio: "", city: "Bengaluru", state: "Karnataka", cityKey: "karnataka|bengaluru", createdAt: FieldValue.serverTimestamp() });
  return waitFor(`profiles/${id}`, (p) => p.points === 0 && p.streak === 0);
}

before(async () => {
  // Warm up the functions emulator.
  await makeProfile(uid("warmup"));
});

test("profile creation initialises counters and volunteer count", async () => {
  const before = (await db.doc("stats/india").get()).data()?.volunteers || 0;
  const p = await makeProfile(uid("vol"));
  assert.equal(p.reports, 0);
  await waitFor("stats/india", (s) => s.volunteers >= before + 1);
});

test("reporting, cleaning and verifying award the right points", async () => {
  const reporter = uid("rep");
  const cleaner = uid("cln");
  const verifier = uid("ver");
  await Promise.all([makeProfile(reporter), makeProfile(cleaner), makeProfile(verifier)]);

  const spot = db.collection("spots").doc();
  await spot.set({ reporterId: reporter, reporterName: "R", status: "open", beforePhotos: ["x"], cityKey: "karnataka|bengaluru", city: "Bengaluru", state: "Karnataka", createdAt: FieldValue.serverTimestamp() });
  let r = await waitFor(`profiles/${reporter}`, (p) => p.points === 10);
  assert.equal(r.reports, 1);
  assert.equal(r.streak, 1);
  await waitFor(spot.path, (s) => s.respectCount === 0 && s.commentCount === 0);
  await waitFor("cityStats/karnataka|bengaluru", (s) => s.reported >= 1);

  await spot.update({ status: "cleaned", cleanedBy: cleaner, cleanedByName: "C", afterPhotos: ["y"], bags: 30, crew: 3 });
  const c = await waitFor(`profiles/${cleaner}`, (p) => p.points === 50 + 5 * 20);
  assert.equal(c.cleanups, 1);
  assert.equal(c.bags, 30);
  assert.equal(c.weekPoints, 150);
  r = await waitFor(`profiles/${reporter}`, (p) => p.points === 20);

  await spot.collection("reactions").doc(`${verifier}_verified`).set({ uid: verifier, type: "verified" });
  await waitFor(spot.path, (s) => s.verifiedCount === 1);
  const v = await waitFor(`profiles/${verifier}`, (p) => p.points === 5);
  assert.equal(v.verifications, 1);

  await spot.collection("reactions").doc(`${verifier}_verified`).delete();
  await waitFor(spot.path, (s) => s.verifiedCount === 0);
  await waitFor(`profiles/${verifier}`, (p) => p.points === 0 && p.verifications === 0);
});

test("deleting an open report takes its points back", async () => {
  const reporter = uid("del");
  await makeProfile(reporter);
  const spot = db.collection("spots").doc();
  await spot.set({ reporterId: reporter, status: "open", beforePhotos: ["x"], cityKey: "" });
  await waitFor(`profiles/${reporter}`, (p) => p.points === 10);
  await spot.collection("comments").add({ authorId: reporter, text: "hi" });
  await waitFor(spot.path, (s) => s.commentCount === 1);
  await spot.delete();
  await waitFor(`profiles/${reporter}`, (p) => p.points === 0 && p.reports === 0);
});

test("drives: hosting, joining, leaving and completing", async () => {
  const host = uid("host");
  const vol = uid("join");
  await Promise.all([makeProfile(host), makeProfile(vol)]);
  const drive = db.collection("drives").doc();
  await drive.set({ organizerId: host, status: "upcoming", title: "T", cityKey: "karnataka|bengaluru" });
  await waitFor(`profiles/${host}`, (p) => p.points === 20 && p.drivesHosted === 1);

  await drive.collection("attendees").doc(host).set({ uid: host, name: "H" });
  await drive.collection("attendees").doc(vol).set({ uid: vol, name: "V" });
  await waitFor(drive.path, (d) => d.attendeeCount === 2);
  await waitFor(`profiles/${vol}`, (p) => p.points === 15 && p.drivesJoined === 1);
  const h = (await db.doc(`profiles/${host}`).get()).data();
  assert.equal(h.points, 20, "organiser joining their own drive earns nothing extra");

  await drive.collection("attendees").doc(vol).delete();
  await waitFor(drive.path, (d) => d.attendeeCount === 1);
  await waitFor(`profiles/${vol}`, (p) => p.points === 0);

  await drive.update({ status: "done", resultBags: 8 });
  await waitFor(`profiles/${host}`, (p) => p.points === 20 + 30 + 40);
});

test("three distinct flags hide a spot", async () => {
  const spot = db.collection("spots").doc();
  await spot.set({ reporterId: "x", status: "open", beforePhotos: ["x"] });
  for (const who of ["f1", "f2", "f2", "f3"]) {
    await db.collection("flags").add({ reporterId: who, targetPath: spot.path, targetType: "spot", reason: "Spam" });
  }
  await waitFor(spot.path, (s) => s.hidden === true && s.flagCount === 3);
});
