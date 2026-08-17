const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { requireAdmin } = require("./_util");

// The only client-facing way to change a user's credits/premium flag — firestore.rules blocks
// the user themselves from writing these fields directly (see users/{userId}'s update rule), and
// this keeps every change in the credit_transactions ledger, same as a real purchase.
exports.adminUpdateUser = onCall({}, async (request) => {
  const adminUid = await requireAdmin(request);
  const { targetUid, purchasedCreditsDelta, subscriptionCreditsDelta, isPremium, note } = request.data || {};
  if (!targetUid) throw new HttpsError("invalid-argument", "targetUid is required.");

  const db = getFirestore();
  const userRef = db.collection("users").doc(targetUid);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) throw new HttpsError("not-found", "User not found.");
    const data = snap.data();
    const updates = {};

    if (typeof isPremium === "boolean") updates.isPremium = isPremium;
    if (purchasedCreditsDelta) {
      updates.purchasedCredits = Math.max(0, (data.purchasedCredits || 0) + purchasedCreditsDelta);
    }
    if (subscriptionCreditsDelta) {
      updates.subscriptionCredits = Math.max(0, (data.subscriptionCredits || 0) + subscriptionCreditsDelta);
    }
    if (Object.keys(updates).length) tx.update(userRef, updates);

    if (purchasedCreditsDelta || subscriptionCreditsDelta) {
      tx.set(db.collection("credit_transactions").doc(), {
        uid: targetUid,
        amount: (purchasedCreditsDelta || 0) + (subscriptionCreditsDelta || 0),
        reason: note ? `admin:${note}` : "admin:adjustment",
        adminUid,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    return { ...data, ...updates };
  });

  return result;
});

// Admin-only: hard-delete a user's account + all their data. Mirrors deleteAccount.js (the
// user-initiated version) but callable by an admin against any uid, for support requests /
// abuse cleanup. Never exposed to the app itself.
exports.adminDeleteUser = onCall({}, async (request) => {
  await requireAdmin(request);
  const { targetUid } = request.data || {};
  if (!targetUid) throw new HttpsError("invalid-argument", "targetUid is required.");

  const { getAuth } = require("firebase-admin/auth");
  const db = getFirestore();

  const subcollections = ["generations", "animations", "milestones", "favorites", "collages"];
  for (const name of subcollections) {
    const snap = await db.collection("users").doc(targetUid).collection(name).get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    if (!snap.empty) await batch.commit();
  }
  await db.collection("users").doc(targetUid).delete();
  try {
    await getAuth().deleteUser(targetUid);
  } catch (e) {
    // Auth user may already be gone — the Firestore cleanup above is the part that matters.
  }
  return { success: true };
});
