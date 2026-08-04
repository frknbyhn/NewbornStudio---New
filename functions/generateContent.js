const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { randomUUID } = require("crypto");
const { generateImage } = require("./helpers/wiro");
const { ensureUserDoc, spendCredits } = require("./helpers/credits");
const { buildEditPrompt } = require("./helpers/prompt");

// Firebase's own download-token scheme (what client SDKs' getDownloadURL() produces) instead of
// a GCS signed URL — the runtime service account doesn't have iam.serviceAccounts.signBlob, and
// granting it needs a gcloud-authenticated session this environment doesn't have. Still used for
// the RESULT image, which does need to live somewhere the client can fetch it back from.
async function downloadUrlFor(file) {
  const token = randomUUID();
  await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  return `https://firebasestorage.googleapis.com/v0/b/${file.bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}

const WIRO_API_KEY = defineSecret("WIRO_API_KEY");
const WIRO_API_SECRET = defineSecret("WIRO_API_SECRET");

const DEFAULT_CREDIT_COST = 1;
const MAX_IMAGE_BYTES = 8 * 1024 * 1024; // 8MB — generous for a compressed JPEG, keeps the callable payload sane

exports.generateContent = onCall(
  { secrets: [WIRO_API_KEY, WIRO_API_SECRET], timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

    const { styleId, imageBase64, editInstruction } = request.data || {};
    if (!styleId || !imageBase64) {
      throw new HttpsError("invalid-argument", "styleId and imageBase64 are required.");
    }
    if (editInstruction !== undefined && (typeof editInstruction !== "string" || !editInstruction.trim())) {
      throw new HttpsError("invalid-argument", "editInstruction must be a non-empty string.");
    }

    const imageBuffer = Buffer.from(imageBase64, "base64");
    if (imageBuffer.length === 0) throw new HttpsError("invalid-argument", "imageBase64 decoded to an empty buffer.");
    if (imageBuffer.length > MAX_IMAGE_BYTES) throw new HttpsError("invalid-argument", "Image too large.");

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
    // even if the very first step inside try is what fails.
    await generationRef.set({
      styleId,
      styleName: style.name,
      status: "generating",
      createdAt: FieldValue.serverTimestamp(),
      ...(editInstruction ? { editInstruction } : {}),
    });

    // Everything from here on can fail (Wiro outage, a bug) and every one of those paths must
    // refund the credit already spent above — so the try starts here.
    try {
      const { buffer, contentType } = await generateImage({
        apiKey: WIRO_API_KEY.value(),
        apiSecret: WIRO_API_SECRET.value(),
        prompt: editInstruction ? buildEditPrompt({ instruction: editInstruction }) : style.prompt,
        // Sent directly to Wiro as a multipart file attachment — no Storage round-trip for the
        // user's source photo. Verified empirically that Wiro actually uses the attached file
        // (undocumented in Wiro's own docs, which only show URL-string examples).
        inputImage: { buffer: imageBuffer, filename: "input.jpg", contentType: "image/jpeg" },
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
