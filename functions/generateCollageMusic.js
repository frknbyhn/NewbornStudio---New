const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { generateMusic } = require("./helpers/wiroMusic");
const { probeDuration } = require("./helpers/ffmpegCompose");
const { ensureUserDoc, spendCredits } = require("./helpers/credits");
const { downloadUrlFor } = require("./helpers/storage");
const os = require("os");
const path = require("path");
const fs = require("fs");

const WIRO_API_KEY = defineSecret("WIRO_API_KEY");
const WIRO_API_SECRET = defineSecret("WIRO_API_SECRET");

const MUSIC_CREDIT_COST = 1;

const CONTENT_TYPE_EXTENSION = {
  "audio/mpeg": "mp3",
  "audio/wav": "wav",
  "audio/x-wav": "wav",
  "audio/flac": "flac",
};

// Generates a music track sized to match an already-rendered collage video's own length —
// duration is read from the collage doc (set by finalizeCollageAnimation) rather than accepted
// from the client, so the track always lines up with the actual video regardless of what the
// client happens to think its duration is.
exports.generateCollageMusic = onCall(
  { secrets: [WIRO_API_KEY, WIRO_API_SECRET], timeoutSeconds: 300, memory: "512MiB" },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

    const { collageId, prompt } = request.data || {};
    if (!collageId || typeof collageId !== "string") {
      throw new HttpsError("invalid-argument", "collageId is required.");
    }
    if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
      throw new HttpsError("invalid-argument", "prompt is required.");
    }

    const db = getFirestore();
    const collageRef = db.collection("users").doc(uid).collection("collages").doc(collageId);
    const collageSnap = await collageRef.get();
    if (!collageSnap.exists) throw new HttpsError("not-found", "Collage not found.");
    const collage = collageSnap.data();
    if (collage.status !== "complete" || !collage.videoPath) {
      throw new HttpsError("failed-precondition", "This collage isn't ready yet.");
    }

    // finalizeCollageAnimation stores this for every collage created after that change landed;
    // older collages fall back to probing the already-rendered video directly.
    let duration = collage.duration;
    const bucket = getStorage().bucket();
    if (!duration) {
      const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "collage-music-probe-"));
      try {
        const localPath = path.join(tmpDir, "video.mp4");
        await bucket.file(collage.videoPath).download({ destination: localPath });
        duration = await probeDuration(localPath);
      } finally {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
    }
    // Wiro's duration input is documented as a whole-number seconds value (default 60) — round
    // rather than pass a fractional video length, and never send 0 for a very short collage.
    const musicDurationSeconds = Math.max(1, Math.round(duration));

    await ensureUserDoc(uid);
    let remainingCredits;
    try {
      ({ remainingCredits } = await spendCredits(uid, MUSIC_CREDIT_COST, "generateCollageMusic"));
    } catch (err) {
      if (err.message === "insufficient-credits") {
        throw new HttpsError("failed-precondition", "Not enough credits.");
      }
      throw err;
    }

    try {
      // promptExpansion/steps/scale left at the model's own documented defaults (see
      // wiroMusic.js's header comment) — only prompt and duration are ours to set here.
      const { buffer, contentType } = await generateMusic({
        apiKey: WIRO_API_KEY.value(),
        apiSecret: WIRO_API_SECRET.value(),
        prompt: prompt.trim(),
        duration: musicDurationSeconds,
        timeoutMs: 280000,
      });

      const extension = CONTENT_TYPE_EXTENSION[contentType] || "mp3";
      const musicPath = `users/${uid}/collages/${collageId}-music.${extension}`;
      const musicFile = bucket.file(musicPath);
      await musicFile.save(buffer, { metadata: { contentType } });
      const musicUrl = await downloadUrlFor(musicFile);

      await collageRef.update({
        musicStatus: "complete",
        musicPath,
        musicUrl,
        musicPrompt: prompt.trim(),
        musicCompletedAt: FieldValue.serverTimestamp(),
      });

      return { musicUrl, remainingCredits };
    } catch (err) {
      await collageRef.update({ musicStatus: "failed" });
      await db.collection("users").doc(uid).update({
        purchasedCredits: FieldValue.increment(MUSIC_CREDIT_COST),
      });
      throw new HttpsError("internal", "Music generation failed. Your credit was refunded.");
    }
  }
);
