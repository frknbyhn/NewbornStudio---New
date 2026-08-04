// TEMPORARY recovery task — deploy, curl once with the recovery payload, then
// `firebase functions:delete restorePreviewUrls --force`.
// Restores ai_models/{styleId}.previewImageUrl after seedThemes' non-merge .set() wiped it.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore } = require("firebase-admin/firestore");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.restorePreviewUrls = onRequest({ secrets: [SEED_TOKEN], timeoutSeconds: 120 }, async (req, res) => {
  if (req.query.token !== SEED_TOKEN.value()) {
    res.status(403).send("Forbidden");
    return;
  }
  const mapping = (req.body && req.body.urls) || {};
  const entries = Object.entries(mapping);

  const db = getFirestore();
  let written = 0;
  let batch = db.batch();
  let inBatch = 0;
  for (const [styleId, previewImageUrl] of entries) {
    batch.set(db.collection("ai_models").doc(styleId), { previewImageUrl }, { merge: true });
    inBatch += 1;
    written += 1;
    if (inBatch === 200) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }
  if (inBatch > 0) await batch.commit();

  res.status(200).send(`Restored previewImageUrl on ${written} docs.`);
});
