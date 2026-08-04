const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getAuth } = require("firebase-admin/auth");

async function deleteCollection(db, collectionRef, batchSize = 200) {
  const snap = await collectionRef.limit(batchSize).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  if (snap.size === batchSize) await deleteCollection(db, collectionRef, batchSize);
}

exports.deleteAccount = onCall({}, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);

  await deleteCollection(db, userRef.collection("generations"));
  await deleteCollection(db, userRef.collection("milestones"));
  await userRef.delete();

  const bucket = getStorage().bucket();
  await bucket.deleteFiles({ prefix: `users/${uid}/` }).catch(() => {
    // No files uploaded yet is not an error.
  });

  await getAuth().deleteUser(uid);

  return { deleted: true };
});
