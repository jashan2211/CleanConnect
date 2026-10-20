// End-to-end test of the deleteAccount callable against the Auth, Firestore and Functions emulators.
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const PROJECT = process.env.GCLOUD_PROJECT || "demo-cleanconnect";
initializeApp({ projectId: PROJECT }, "delete-test");
const app = require("firebase-admin/app").getApp("delete-test");
const db = getFirestore(app);
const auth = getAuth(app);

const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";

async function signUp() {
  const res = await fetch(`http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ returnSecureToken: true }),
  });
  const json = await res.json();
  return { uid: json.localId, idToken: json.idToken };
}

async function callDelete(idToken) {
  const res = await fetch(`http://127.0.0.1:5005/${PROJECT}/us-central1/deleteAccount`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data: {} }),
  });
  return { status: res.status, body: await res.json() };
}

test("deleteAccount removes the user's data, anonymises cleanups and deletes the auth user", async () => {
  const { uid, idToken } = await signUp();
  const other = "someone_else";

  await db.doc(`profiles/${uid}`).set({ name: "Leaving User" });
  await db.doc(`userPrivate/${uid}`).set({ blocked: [] });
  const open = db.collection("spots").doc();
  await open.set({ reporterId: uid, status: "open", beforePhotos: ["x"] });
  const cleanedByOther = db.collection("spots").doc();
  await cleanedByOther.set({ reporterId: uid, status: "cleaned", cleanedBy: other, beforePhotos: ["x"], afterPhotos: ["y"] });
  const cleanedByMe = db.collection("spots").doc();
  await cleanedByMe.set({ reporterId: other, status: "cleaned", cleanedBy: uid, cleanedByName: "Leaving User", beforePhotos: ["x"], afterPhotos: ["y"] });
  const claimed = db.collection("spots").doc();
  await claimed.set({ reporterId: other, status: "claimed", claimedBy: uid, claimedByName: "Leaving User", beforePhotos: ["x"] });
  const comment = await cleanedByMe.collection("comments").add({ authorId: uid, text: "hi" });
  await cleanedByMe.collection("reactions").doc(`${uid}_respect`).set({ uid, type: "respect" });
  const drive = db.collection("drives").doc();
  await drive.set({ organizerId: other, status: "upcoming", title: "T" });
  await drive.collection("attendees").doc(uid).set({ uid, name: "Leaving User" });
  const myDrive = db.collection("drives").doc();
  await myDrive.set({ organizerId: uid, status: "upcoming", title: "Mine" });

  const res = await callDelete(idToken);
  assert.equal(res.status, 200, JSON.stringify(res.body));

  assert.equal((await db.doc(`profiles/${uid}`).get()).exists, false);
  assert.equal((await db.doc(`userPrivate/${uid}`).get()).exists, false);
  assert.equal((await open.get()).exists, false, "open report deleted");
  assert.equal((await cleanedByOther.get()).data().reporterId, "deleted");
  const mine = (await cleanedByMe.get()).data();
  assert.equal(mine.cleanedBy, "deleted");
  assert.equal(mine.cleanedByName, "Former member");
  const c = (await claimed.get()).data();
  assert.equal(c.status, "open");
  assert.equal(c.claimedBy, undefined);
  assert.equal((await cleanedByMe.collection("comments").doc(comment.id).get()).exists, false);
  assert.equal((await cleanedByMe.collection("reactions").doc(`${uid}_respect`).get()).exists, false);
  assert.equal((await drive.collection("attendees").doc(uid).get()).exists, false);
  assert.equal((await myDrive.get()).exists, false, "upcoming drive deleted");
  await assert.rejects(auth.getUser(uid), "auth user deleted");
});

test("deleteAccount rejects unauthenticated calls", async () => {
  const res = await fetch(`http://127.0.0.1:5005/${PROJECT}/us-central1/deleteAccount`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ data: {} }),
  });
  assert.equal(res.status, 401);
});
