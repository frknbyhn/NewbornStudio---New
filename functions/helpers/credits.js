const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const WELCOME_CREDITS = 5;

async function ensureUserDoc(uid) {
  const db = getFirestore();
  const ref = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return;
    tx.set(ref, {
      createdAt: FieldValue.serverTimestamp(),
      subscriptionCredits: 0,
      purchasedCredits: WELCOME_CREDITS,
      isPremium: false,
    });
  });
}

/** Deducts from subscriptionCredits first, then purchasedCredits. Throws if insufficient. */
async function spendCredits(uid, amount) {
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const data = snap.data() || {};
    const subscriptionCredits = data.subscriptionCredits || 0;
    const purchasedCredits = data.purchasedCredits || 0;
    const total = subscriptionCredits + purchasedCredits;
    if (total < amount) {
      throw new Error("insufficient-credits");
    }
    const fromSubscription = Math.min(subscriptionCredits, amount);
    const fromPurchased = amount - fromSubscription;
    tx.update(userRef, {
      subscriptionCredits: subscriptionCredits - fromSubscription,
      purchasedCredits: purchasedCredits - fromPurchased,
    });
    const ledgerRef = db.collection("credit_transactions").doc();
    tx.set(ledgerRef, {
      uid,
      amount: -amount,
      reason: "generateContent",
      createdAt: FieldValue.serverTimestamp(),
    });
    return { remainingCredits: total - amount };
  });
}

module.exports = { ensureUserDoc, spendCredits, WELCOME_CREDITS };
