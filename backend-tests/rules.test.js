// Security rules tests for CleanConnect 2.0. Run with `npm test` (needs Java for the emulator).
const { test, before, after, beforeEach } = require("node:test");
const fs = require("node:fs");
const path = require("node:path");
const {
  initializeTestEnvironment, assertSucceeds, assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc, setDoc, updateDoc, deleteDoc, getDoc, addDoc, collection, serverTimestamp, Timestamp, deleteField,
} = require("firebase/firestore");

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-cleanconnect-rules",
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, "../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8085,
    },
  });
});

after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

const alice = () => env.authenticatedContext("alice").firestore();
const bob = () => env.authenticatedContext("bob").firestore();
const guest = () => env.unauthenticatedContext().firestore();

async function seed(pathStr, data) {
  await env.withSecurityRulesDisabled(async (ctx) => { await setDoc(doc(ctx.firestore(), pathStr), data); });
}

function newSpot(uid, extra = {}) {
  return {
    reporterId: uid, reporterName: "Alice", status: "open", category: "mixed", size: "bag", note: "pile",
    lat: 12.97, lng: 77.64, geohash: "tdr1y", gh3: "tdr", gh4: "tdr1", locality: "Indiranagar",
    city: "Bengaluru", state: "Karnataka", cityKey: "karnataka|bengaluru",
    beforePhotos: ["https://example.com/a.jpg"], createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    ...extra,
  };
}

const openSpot = { reporterId: "alice", status: "open", beforePhotos: ["x"], note: "", category: "mixed", size: "bag" };

// ---------------- Profiles ----------------

test("profile: owner can create with basic fields, not counters", async () => {
  await assertSucceeds(setDoc(doc(alice(), "profiles/alice"), { name: "Alice", bio: "", city: "B", state: "K", cityKey: "k|b", createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(bob(), "profiles/bob"), { name: "Bob", points: 9999 }));
  await assertFails(setDoc(doc(bob(), "profiles/alice"), { name: "Bob" }));
});

test("profile: owner edits editable fields only; anyone can read", async () => {
  await seed("profiles/alice", { name: "Alice", points: 10 });
  await assertSucceeds(updateDoc(doc(alice(), "profiles/alice"), { name: "Alice K", upiId: "alice@okaxis", updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(alice(), "profiles/alice"), { points: 100000 }));
  await assertFails(updateDoc(doc(bob(), "profiles/alice"), { name: "hacked" }));
  await assertSucceeds(getDoc(doc(guest(), "profiles/alice")));
});

// ---------------- Spots ----------------

test("spot: signed-in user can report; guests and impostors cannot", async () => {
  await assertSucceeds(setDoc(doc(alice(), "spots/s1"), newSpot("alice")));
  await assertFails(setDoc(doc(alice(), "spots/s2"), newSpot("bob")));
  await assertFails(setDoc(doc(guest(), "spots/s3"), newSpot("alice")));
  await assertFails(setDoc(doc(alice(), "spots/s4"), newSpot("alice", { status: "cleaned" })));
  await assertFails(setDoc(doc(alice(), "spots/s5"), newSpot("alice", { respectCount: 500 })));
  await assertFails(setDoc(doc(alice(), "spots/s6"), newSpot("alice", { beforePhotos: [] })));
  await assertSucceeds(getDoc(doc(guest(), "spots/s1")));
});

test("spot: claim, unclaim and clean transitions", async () => {
  await seed("spots/s1", openSpot);
  await assertFails(updateDoc(doc(bob(), "spots/s1"), { status: "claimed", claimedBy: "alice", claimedByName: "x", claimedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(bob(), "spots/s1"), { status: "claimed", claimedBy: "bob", claimedByName: "Bob", claimedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(alice(), "spots/s1"), { status: "open", claimedBy: deleteField(), claimedByName: deleteField(), claimedAt: deleteField(), updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(doc(bob(), "spots/s1"), { status: "open", claimedBy: deleteField(), claimedByName: deleteField(), claimedAt: deleteField(), updatedAt: serverTimestamp() }));

  const clean = { status: "cleaned", cleanedBy: "bob", cleanedByName: "Bob", cleanedAt: serverTimestamp(), afterPhotos: ["y"], bags: 5, crew: 2, cleanupNote: "", updatedAt: serverTimestamp() };
  await assertFails(updateDoc(doc(bob(), "spots/s1"), { ...clean, afterPhotos: [] }));
  await assertFails(updateDoc(doc(bob(), "spots/s1"), { ...clean, bags: 5000 }));
  await assertFails(updateDoc(doc(bob(), "spots/s1"), { ...clean, reporterId: "bob" }));
  await assertFails(updateDoc(doc(bob(), "spots/s1"), { ...clean, cleanedBy: "alice" }));
  await assertSucceeds(updateDoc(doc(bob(), "spots/s1"), clean));
  // Can't re-clean or reopen a cleaned spot.
  await assertFails(updateDoc(doc(alice(), "spots/s1"), { ...clean, cleanedBy: "alice", cleanedByName: "A" }));
  await assertFails(updateDoc(doc(alice(), "spots/s1"), { status: "open" }));
});

test("spot: reporter edits and deletes only while open", async () => {
  await seed("spots/s1", openSpot);
  await assertSucceeds(updateDoc(doc(alice(), "spots/s1"), { note: "bigger now", updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(bob(), "spots/s1"), { note: "spam" }));
  await assertFails(deleteDoc(doc(bob(), "spots/s1")));
  await assertSucceeds(deleteDoc(doc(alice(), "spots/s1")));
  await seed("spots/s2", { ...openSpot, status: "cleaned", cleanedBy: "bob" });
  await assertFails(deleteDoc(doc(alice(), "spots/s2")));
});

// ---------------- Reactions ----------------

test("reactions: one per user per type, with state checks", async () => {
  await seed("spots/open1", openSpot);
  await seed("spots/clean1", { ...openSpot, status: "cleaned", cleanedBy: "bob" });
  const r = (db, spot, id, data) => setDoc(doc(db, `spots/${spot}/reactions/${id}`), { createdAt: serverTimestamp(), ...data });

  await assertSucceeds(r(bob(), "open1", "bob_respect", { uid: "bob", type: "respect" }));
  await assertFails(r(bob(), "open1", "alice_respect", { uid: "alice", type: "respect" }));
  await assertFails(r(bob(), "open1", "bob_respect2", { uid: "bob", type: "respect" }));
  await assertSucceeds(r(bob(), "open1", "bob_stillThere", { uid: "bob", type: "stillThere" }));
  await assertFails(r(bob(), "open1", "bob_verified", { uid: "bob", type: "verified" }));
  await assertFails(r(bob(), "clean1", "bob_verified", { uid: "bob", type: "verified" })); // cleaner can't self-verify
  await assertSucceeds(r(alice(), "clean1", "alice_verified", { uid: "alice", type: "verified" }));
  await assertFails(r(alice(), "clean1", "alice_stillThere", { uid: "alice", type: "stillThere" }));
  await assertFails(r(alice(), "clean1", "alice_boost", { uid: "alice", type: "boost" }));

  await assertSucceeds(getDoc(doc(bob(), "spots/open1/reactions/bob_respect")));
  await assertSucceeds(getDoc(doc(bob(), "spots/open1/reactions/bob_verified"))); // missing doc, still readable
  await assertFails(getDoc(doc(alice(), "spots/open1/reactions/bob_respect")));
  await assertFails(deleteDoc(doc(alice(), "spots/open1/reactions/bob_respect")));
  await assertSucceeds(deleteDoc(doc(bob(), "spots/open1/reactions/bob_respect")));
});

// ---------------- Comments ----------------

test("comments: author-only create/delete, length limit", async () => {
  await seed("spots/s1", openSpot);
  const c = { authorId: "bob", authorName: "Bob", text: "Great!", createdAt: serverTimestamp() };
  const ref = await assertSucceeds(addDoc(collection(bob(), "spots/s1/comments"), c));
  await assertFails(addDoc(collection(bob(), "spots/s1/comments"), { ...c, authorId: "alice" }));
  await assertFails(addDoc(collection(bob(), "spots/s1/comments"), { ...c, text: "x".repeat(501) }));
  await assertFails(addDoc(collection(guest(), "spots/s1/comments"), c));
  await assertFails(deleteDoc(doc(alice(), `spots/s1/comments/${ref.id}`)));
  await assertSucceeds(deleteDoc(doc(bob(), `spots/s1/comments/${ref.id}`)));
});

// ---------------- Drives ----------------

function newDrive(uid, extra = {}) {
  return {
    organizerId: uid, organizerName: "Alice", title: "Lake clean-up", about: "Bring water",
    startsAt: Timestamp.fromDate(new Date(Date.now() + 86400000)), durationMinutes: 120,
    lat: 12.98, lng: 77.62, geohash: "tdr1v", gh3: "tdr", gh4: "tdr1", address: "Main gate",
    city: "Bengaluru", state: "Karnataka", cityKey: "karnataka|bengaluru", bring: ["water"], providing: ["gloves"],
    status: "upcoming", createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
  };
}

test("drives: create, organiser-only updates", async () => {
  await assertSucceeds(setDoc(doc(alice(), "drives/d1"), newDrive("alice", { upiId: "alice@okaxis", capacity: 30 })));
  await assertFails(setDoc(doc(alice(), "drives/d2"), newDrive("bob")));
  await assertFails(setDoc(doc(alice(), "drives/d3"), newDrive("alice", { attendeeCount: 99 })));
  await assertFails(setDoc(doc(alice(), "drives/d4"), newDrive("alice", { title: "x" })));
  await assertFails(updateDoc(doc(bob(), "drives/d1"), { title: "mine now" }));
  await assertFails(updateDoc(doc(alice(), "drives/d1"), { attendeeCount: 500 }));
  await assertSucceeds(updateDoc(doc(alice(), "drives/d1"), { status: "done", resultBags: 12, resultPhotos: ["z"], resultNote: "", completedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
});

test("attendees: join/leave yourself; organiser can remove", async () => {
  await seed("drives/d1", { organizerId: "alice", status: "upcoming" });
  await seed("drives/dx", { organizerId: "alice", status: "cancelled" });
  const a = (db, drive, uid) => setDoc(doc(db, `drives/${drive}/attendees/${uid}`), { uid, name: "Bob", joinedAt: serverTimestamp() });
  await assertSucceeds(a(bob(), "d1", "bob"));
  await assertFails(a(bob(), "d1", "carol"));
  await assertFails(a(bob(), "dx", "bob"));
  await assertSucceeds(getDoc(doc(guest(), "drives/d1/attendees/bob")));
  await assertSucceeds(deleteDoc(doc(alice(), "drives/d1/attendees/bob")));
  await assertSucceeds(a(bob(), "d1", "bob"));
  await assertSucceeds(deleteDoc(doc(bob(), "drives/d1/attendees/bob")));
});

// ---------------- Moderation, stats, private ----------------

test("flags are write-only; stats are read-only; private data is owner-only", async () => {
  await assertSucceeds(addDoc(collection(bob(), "flags"), { reporterId: "bob", targetPath: "spots/s1", targetType: "spot", reason: "Spam", createdAt: serverTimestamp() }));
  await assertFails(addDoc(collection(bob(), "flags"), { reporterId: "alice", targetPath: "spots/s1", targetType: "spot", reason: "Spam", createdAt: serverTimestamp() }));
  await seed("flags/f1", { reporterId: "bob" });
  await assertFails(getDoc(doc(bob(), "flags/f1")));

  await seed("stats/india", { cleaned: 1 });
  await assertSucceeds(getDoc(doc(guest(), "stats/india")));
  await assertFails(setDoc(doc(alice(), "stats/india"), { cleaned: 1000000 }));

  await assertSucceeds(setDoc(doc(alice(), "userPrivate/alice"), { blocked: ["bob"] }));
  await assertFails(getDoc(doc(bob(), "userPrivate/alice")));
});

test("legacy 1.x collections still require auth to read", async () => {
  await seed("users/alice", { displayName: "Alice" });
  await assertFails(getDoc(doc(guest(), "users/alice")));
  await assertSucceeds(getDoc(doc(bob(), "users/alice")));
});
