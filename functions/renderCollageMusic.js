const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const os = require("os");
const path = require("path");
const fs = require("fs");
const { generateMusic } = require("./helpers/wiroMusic");
const { probeDuration, addBackgroundMusic } = require("./helpers/ffmpegCompose");
const { downloadUrlFor } = require("./helpers/storage");

const WIRO_API_KEY = defineSecret("WIRO_API_KEY");
const WIRO_API_SECRET = defineSecret("WIRO_API_SECRET");

// Runs after startCollageMusic enqueues it: asks Wiro for a track matching the collage video's
// own already-rendered length (never trusted from the client — read straight off the collage
// doc, or probed from the video file directly for the rare case that's missing), then muxes it
// onto the existing video as background audio (helpers/ffmpegCompose.js's addBackgroundMusic —
// mixes with the video's own audio if it has one, otherwise becomes the sole track) and
// overwrites the collage's videoPath with the result, so MilestoneCollageViewController/
// MilestoneCollageGalleryViewController need no changes to start playing it — they only ever
// cared about the Firestore doc's videoUrl, not how it got there (same reasoning as
// finalizeCollageAnimation's own doc comment).
exports.renderCollageMusic = onTaskDispatched(
  { secrets: [WIRO_API_KEY, WIRO_API_SECRET], timeoutSeconds: 400, memory: "1GiB", retryConfig: { maxAttempts: 1 } },
  async (request) => {
    const { uid, collageId, prompt } = request.data;
    const db = getFirestore();
    const collageRef = db.collection("users").doc(uid).collection("collages").doc(collageId);
    const snap = await collageRef.get();
    if (!snap.exists) return; // deleted mid-flight
    const collage = snap.data();
    if (collage.musicStatus !== "generating") return; // already finalized or cancelled — idempotent

    const bucket = getStorage().bucket();
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "collage-music-"));
    try {
      const videoLocalPath = path.join(tmpDir, "video.mp4");
      await bucket.file(collage.videoPath).download({ destination: videoLocalPath });

      // finalizeCollageAnimation stores this for every collage created after that change
      // landed; older collages fall back to probing the video directly.
      const duration = collage.duration || (await probeDuration(videoLocalPath));
      // Wiro's duration input is documented as a whole-number seconds value (default 60) —
      // round rather than pass a fractional video length, never send 0 for a very short collage.
      const musicDurationSeconds = Math.max(1, Math.round(duration));

      const { buffer: musicBuffer, contentType: musicContentType } = await generateMusic({
        apiKey: WIRO_API_KEY.value(),
        apiSecret: WIRO_API_SECRET.value(),
        prompt,
        duration: musicDurationSeconds,
        timeoutMs: 280000,
      });

      const musicExtension = musicContentType === "audio/wav" ? "wav" : "mp3";
      const musicLocalPath = path.join(tmpDir, `music.${musicExtension}`);
      fs.writeFileSync(musicLocalPath, musicBuffer);

      // Kept as its own Storage object too (not just muxed into the video) in case a future
      // screen wants to offer the track on its own — cheap to keep, and it's already generated.
      const musicStoragePath = `users/${uid}/collages/${collageId}-music.${musicExtension}`;
      await bucket.file(musicStoragePath).save(musicBuffer, { metadata: { contentType: musicContentType } });

      const mixedLocalPath = path.join(tmpDir, "final.mp4");
      await addBackgroundMusic({ videoPath: videoLocalPath, musicPath: musicLocalPath, outputPath: mixedLocalPath });

      const videoFile = bucket.file(collage.videoPath);
      await videoFile.save(fs.readFileSync(mixedLocalPath), { metadata: { contentType: "video/mp4" } });
      const videoUrl = await downloadUrlFor(videoFile);

      await collageRef.update({
        musicStatus: "complete",
        musicPath: musicStoragePath,
        videoUrl,
        musicCompletedAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error(`renderCollageMusic failed for ${collageId}:`, err);
      await db.collection("users").doc(uid).update({ purchasedCredits: FieldValue.increment(1) });
      await collageRef.update({ musicStatus: "failed" });
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  }
);
