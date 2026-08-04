// TEMPORARY admin task — deploy, call once to top up a specific test uid's credits for
// simulator E2E verification, then `firebase functions:delete debugGrantCredits --force`.
// Same pattern as seedCategoryPreviews.js.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore } = require("firebase-admin/firestore");
const { ensureUserDoc } = require("./helpers/credits");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.debugGrantCredits = onRequest(
  { secrets: [SEED_TOKEN], timeoutSeconds: 30, memory: "256MiB" },
  async (req, res) => {
    if (req.query.token !== SEED_TOKEN.value()) {
      res.status(403).send("Forbidden");
      return;
    }
    const uid = req.query.uid;
    const credits = parseInt(req.query.credits || "5", 10);
    if (!uid) {
      res.status(400).send("uid is required.");
      return;
    }
    await ensureUserDoc(uid);
    await getFirestore().collection("users").doc(uid).update({ purchasedCredits: credits });
    res.json({ ok: true, uid, purchasedCredits: credits });
  }
);
