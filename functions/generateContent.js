const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { randomUUID } = require("crypto");
const { generateImage } = require("./helpers/wiro");
const { ensureUserDoc, spendCredits } = require("./helpers/credits");

// Firebase's own download-token scheme (what client SDKs' getDownloadURL() produces) instead of
// a GCS signed URL — the runtime service account doesn't have iam.serviceAccounts.signBlob, and
// granting it needs a gcloud-authenticated session this environment doesn't have. This route
// needs no IAM change: any client with the token URL can GET the file over plain HTTPS (which is
// exactly what's needed here — Wiro's servers fetch the source image with no Firebase awareness).
async function downloadUrlFor(file) {
  const token = randomUUID();
  await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  return `https://firebasestorage.googleapis.com/v0/b/${file.bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}

const WIRO_API_KEY = defineSecret("WIRO_API_KEY");
const WIRO_API_SECRET = defineSecret("WIRO_API_SECRET");

const DEFAULT_CREDIT_COST = 1;

exports.generateContent = onCall(
  { secrets: [WIRO_API_KEY, WIRO_API_SECRET], timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

    const { styleId, sourceImagePath } = request.data || {};
    if (!styleId || !sourceImagePath) {
      throw new HttpsError("invalid-argument", "styleId and sourceImagePath are required.");
    }
    // Every generation writes under the caller's own Storage path — never let a client
    // point this at another user's upload.
    if (!sourceImagePath.startsWith(`users/${uid}/`)) {
      throw new HttpsError("permission-denied", "sourceImagePath must be under the caller's own users/{uid}/ path.");
    }

    const db = getFirestore();
    const styleSnap = await db.collection("ai_models").doc(styleId).get();
    if (!styleSnap.exists) throw new HttpsError("not-found", `Unknown styleId: ${styleId}`);
    const style = styleSnap.data();
    const creditCost = style.creditCost || DEFAULT_CREDIT_COST;

    await ensureUserDoc(uid);

    let remainingCredits;
    try {
      ({ remainingCredits } = await spendCredits(uid, creditCost));
    } catch (err) {
      if (err.message === "insufficient-credits") {
        throw new HttpsError("failed-precondition", "Not enough credits.");
      }
      throw err;
    }

    const bucket = getStorage().bucket();
    const generationRef = db.collection("users").doc(uid).collection("generations").doc();
    // Written before the try block so the catch's .update() always has a doc to land on,
    // even if the very first step inside try (building the source URL) is what fails.
    await generationRef.set({
      styleId,
      styleName: style.name,
      status: "generating",
      createdAt: FieldValue.serverTimestamp(),
    });

    // Everything from here on can fail (bad upload, Wiro outage, a bug) and every one of those
    // paths must refund the credit already spent above — so the try starts here, not just
    // around the Wiro call.
    try {
      const sourceFile = bucket.file(sourceImagePath);
      const sourceUrl = await downloadUrlFor(sourceFile);

      const { buffer, contentType } = await generateImage({
        apiKey: WIRO_API_KEY.value(),
        apiSecret: WIRO_API_SECRET.value(),
        prompt: style.prompt,
        inputImageUrl: sourceUrl,
        aspectRatio: style.aspectRatio || "3:4",
        timeoutMs: 90000,
      });

      const resultPath = `users/${uid}/generations/${generationRef.id}.png`;
      const resultFile = bucket.file(resultPath);
      await resultFile.save(buffer, { metadata: { contentType } });
      const resultUrl = await downloadUrlFor(resultFile);

      await generationRef.update({
        status: "complete",
        resultPath,
        resultUrl,
        completedAt: FieldValue.serverTimestamp(),
      });

      return { generationId: generationRef.id, resultUrl, remainingCredits };
    } catch (err) {
      await generationRef.update({ status: "failed", error: String(err.message || err) });
      // Refund the spent credits — the user didn't get a result.
      await db.collection("users").doc(uid).update({
        [creditFieldToRefund(style, creditCost)]: FieldValue.increment(creditCost),
      });
      throw new HttpsError("internal", "Generation failed. Your credits were refunded.");
    }
  }
);

// Refunds are simplest as purchasedCredits — subscriptionCredits resets on its own renewal
// cadence and mixing refund logic into that period-guard would risk a double-grant bug.
function creditFieldToRefund(_style, _creditCost) {
  return "purchasedCredits";
}
