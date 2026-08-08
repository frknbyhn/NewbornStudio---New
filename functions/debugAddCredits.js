// TEMPORARY debug aid — an in-app button (HomeViewController, #if DEBUG only) calls this to
// self-grant a fixed top-up of test credits, so purchase/generation flows can be exercised on a
// device without going through a real StoreKit purchase every time. Self-targeting only (grants
// to request.auth.uid, never an arbitrary uid) — same safety shape as the old
// scheduleTestNotification/sendTestNotification debug aids. Still: this hands out free credits
// to whoever calls it, which is a real abuse vector if this ever ships, unlike those — remove
// this file, its index.js export, and HomeViewController's debug button together once done
// testing (see that button's own doc comment).
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { ensureUserDoc } = require("./helpers/credits");

const DEBUG_GRANT_AMOUNT = 50;

exports.debugAddCredits = onCall({ timeoutSeconds: 30, memory: "256MiB" }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

  await ensureUserDoc(uid);
  await getFirestore().collection("users").doc(uid).update({
    purchasedCredits: FieldValue.increment(DEBUG_GRANT_AMOUNT),
  });

  return { granted: DEBUG_GRANT_AMOUNT };
});
