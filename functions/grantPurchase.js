const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { ensureUserDoc } = require("./helpers/credits");
const { GRANTS } = require("./helpers/purchaseGrants");

const PERIOD_MS = {
  "com.babycollages.weekly": 7 * 24 * 60 * 60 * 1000,
  "com.babycollages.monthly": 31 * 24 * 60 * 60 * 1000,
  "com.babycollages.yearly": 366 * 24 * 60 * 60 * 1000,
};

// Called right after RevenueCat's Purchases.purchase() resolves successfully on the client —
// StoreKit itself is what makes "purchase succeeded" trustworthy here (a client can't fabricate
// a completed transaction), so this function's job is just mapping product -> credits, not
// re-verifying the receipt. See playbook Phase 7.
exports.grantPurchase = onCall({}, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

  const { productId } = request.data || {};
  const grant = GRANTS[productId];
  if (!grant) throw new HttpsError("invalid-argument", `Unknown productId: ${productId}`);

  await ensureUserDoc(uid);
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);

  if (grant.kind === "subscription") {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      const data = snap.data() || {};
      const renewalDate = data.subscriptionRenewalDate;
      const now = Timestamp.now();
      // Period-guarded: an app-open re-check of the active entitlement must not re-grant
      // credits every launch — only once the previous period has actually elapsed.
      if (renewalDate && renewalDate.toMillis() > now.toMillis()) {
        return;
      }
      const periodMs = PERIOD_MS[productId] || PERIOD_MS["com.babycollages.monthly"];
      tx.update(userRef, {
        isPremium: true,
        subscriptionCredits: grant.credits,
        subscriptionRenewalDate: Timestamp.fromMillis(now.toMillis() + periodMs),
        activeProductId: productId,
      });
    });
  } else {
    await userRef.update({ purchasedCredits: FieldValue.increment(grant.credits) });
  }

  await db.collection("credit_transactions").add({
    uid,
    amount: grant.credits,
    reason: `purchase:${productId}`,
    createdAt: FieldValue.serverTimestamp(),
  });

  const updated = await userRef.get();
  const data = updated.data() || {};
  return {
    isPremium: !!data.isPremium,
    subscriptionCredits: data.subscriptionCredits || 0,
    purchasedCredits: data.purchasedCredits || 0,
  };
});
