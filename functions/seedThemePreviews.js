// TEMPORARY admin task — deploy, call once per style from the local generation script,
// then `firebase functions:delete seedThemePreviews --force`. Same pattern as seedThemes.js.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { randomUUID } = require("crypto");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.seedThemePreviews = onRequest(
  { secrets: [SEED_TOKEN], timeoutSeconds: 60, memory: "256MiB" },
  async (req, res) => {
    if (req.query.token !== SEED_TOKEN.value()) {
      res.status(403).send("Forbidden");
      return;
    }
    const { styleId, imageBase64 } = req.body || {};
    if (!styleId || !imageBase64) {
      res.status(400).send("styleId and imageBase64 are required.");
      return;
    }

    const buffer = Buffer.from(imageBase64, "base64");
    const bucket = getStorage().bucket();
    const path = `ai_models/${styleId}/preview.jpg`;
    const file = bucket.file(path);
    await file.save(buffer, { metadata: { contentType: "image/jpeg" } });

    const token = randomUUID();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
    const previewImageUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;

    await getFirestore().collection("ai_models").doc(styleId).update({ previewImageUrl });

    res.status(200).json({ styleId, previewImageUrl });
  }
);
