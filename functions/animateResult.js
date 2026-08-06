const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { randomUUID } = require("crypto");
const { generateVideo } = require("./helpers/wiroVideo");
const { buildAnimatePrompt } = require("./helpers/prompt");
const { ensureUserDoc, spendCredits } = require("./helpers/credits");

// Same download-token scheme as generateContent.js — see that file's comment for why (no
// iam.serviceAccounts.signBlob available to this runtime service account).
async function downloadUrlFor(file) {
  const token = randomUUID();
  await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  return `https://firebasestorage.googleapis.com/v0/b/${file.bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}

const WIRO_API_KEY = defineSecret("WIRO_API_KEY");
const WIRO_API_SECRET = defineSecret("WIRO_API_SECRET");

// Video generation costs Wiro considerably more than a still-image edit — placeholder pricing,
// tune to actual Wiro cost/margin once known.
const ANIMATE_CREDIT_COST = 4;

exports.animateResult = onCall(
  // Video generation runs far longer than an image edit — 540s here, and the client
  // (AnimationService.swift) sets a matching httpsCallable timeoutInterval, since the Functions
  // SDK's own default (70s) would otherwise time out the CLIENT long before this finishes even
  // if the server call is still healthy.
  { secrets: [WIRO_API_KEY, WIRO_API_SECRET], timeoutSeconds: 540, memory: "512MiB" },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

    const { resultUrl, styleId } = request.data || {};
    if (!resultUrl || typeof resultUrl !== "string") {
      throw new HttpsError("invalid-argument", "resultUrl is required.");
    }

    const db = getFirestore();

    // The style's own descriptor/mood feed the animate prompt (see buildAnimatePrompt) — falls
    // back to a generic scene description for "custom-style" results, which have neither.
    let styleName = "Portrait";
    let descriptor = "a warm, gentle studio portrait";
    let mood = "warm, natural, gentle";
    if (styleId && styleId !== "custom-style") {
      const styleSnap = await db.collection("ai_models").doc(styleId).get();
      if (styleSnap.exists) {
        const style = styleSnap.data();
        styleName = style.name || styleName;
        descriptor = style.descriptor || descriptor;
        mood = style.mood || mood;
      }
    }
    const prompt = buildAnimatePrompt({ styleName, descriptor, mood });

    await ensureUserDoc(uid);

    let remainingCredits;
    try {
      ({ remainingCredits } = await spendCredits(uid, ANIMATE_CREDIT_COST, "animateResult"));
    } catch (err) {
      if (err.message === "insufficient-credits") {
        throw new HttpsError("failed-precondition", "Not enough credits.");
      }
      throw err;
    }

    const bucket = getStorage().bucket();
    const animationRef = db.collection("users").doc(uid).collection("animations").doc();
    await animationRef.set({
      styleId: styleId || "custom-style",
      sourceResultUrl: resultUrl,
      status: "generating",
      createdAt: FieldValue.serverTimestamp(),
    });

    // From here on, any failure must refund the spent credit — same reasoning/shape as
    // generateContent.js.
    try {
      // Every parameter below (beyond prompt/inputImage) is the model's own documented default —
      // see wiroVideo.js's header comment.
      const { buffer, contentType } = await generateVideo({
        apiKey: WIRO_API_KEY.value(),
        apiSecret: WIRO_API_SECRET.value(),
        prompt,
        inputImage: resultUrl,
        timeoutMs: 480000,
      });

      const videoPath = `users/${uid}/animations/${animationRef.id}.mp4`;
      const videoFile = bucket.file(videoPath);
      await videoFile.save(buffer, { metadata: { contentType } });
      const videoUrl = await downloadUrlFor(videoFile);

      await animationRef.update({
        status: "complete",
        videoPath,
        videoUrl,
        completedAt: FieldValue.serverTimestamp(),
      });

      return { animationId: animationRef.id, videoUrl, remainingCredits };
    } catch (err) {
      await animationRef.update({ status: "failed", error: String(err.message || err) });
      await db.collection("users").doc(uid).update({
        purchasedCredits: FieldValue.increment(ANIMATE_CREDIT_COST),
      });
      throw new HttpsError("internal", "Animation failed. Your credits were refunded.");
    }
  }
);
