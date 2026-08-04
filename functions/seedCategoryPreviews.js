// TEMPORARY admin task — deploy, call once per category from the local generation script,
// then `firebase functions:delete seedCategoryPreviews --force`. Same pattern as seedThemePreviews.js.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { randomUUID } = require("crypto");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.seedCategoryPreviews = onRequest(
  { secrets: [SEED_TOKEN], timeoutSeconds: 60, memory: "256MiB" },
  async (req, res) => {
    if (req.query.token !== SEED_TOKEN.value()) {
      res.status(403).send("Forbidden");
      return;
    }
    const { categoryId, imageBase64 } = req.body || {};
    if (!categoryId || !imageBase64) {
      res.status(400).send("categoryId and imageBase64 are required.");
      return;
    }

    const buffer = Buffer.from(imageBase64, "base64");
    const bucket = getStorage().bucket();
    const path = `categories/${categoryId}/cover.jpg`;
    const file = bucket.file(path);
    await file.save(buffer, { metadata: { contentType: "image/jpeg" } });

    const token = randomUUID();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
    const coverImageUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;

    await getFirestore().collection("categories").doc(categoryId).set({ coverImageUrl }, { merge: true });

    res.status(200).json({ categoryId, coverImageUrl });
  }
);
