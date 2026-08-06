const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const os = require("os");
const path = require("path");
const fs = require("fs");
const { concatVideos } = require("./helpers/ffmpegConcat");
const { downloadUrlFor } = require("./helpers/storage");
const { sendCollageNotification } = require("./helpers/collageNotify");

// Runs once, after processCollageAnimationItem's chain has worked through every item — downloads
// whatever clips actually succeeded (in order), concatenates them into the final collage video,
// uploads it to the same users/{uid}/collages/{collageId}.mp4 path the old on-device renderer
// used to write to (so MilestoneCollageGalleryViewController/MilestoneCollageViewController need
// no changes — they only ever cared about the Firestore doc's videoUrl, not how it got there),
// refunds credits for any item that never produced a clip, and sends the "ready" push.
exports.finalizeCollageAnimation = onTaskDispatched(
  { timeoutSeconds: 540, memory: "1GiB", retryConfig: { maxAttempts: 1 } },
  async (request) => {
    const { uid, collageId } = request.data;
    const db = getFirestore();
    const collageRef = db.collection("users").doc(uid).collection("collages").doc(collageId);
    const snap = await collageRef.get();
    if (!snap.exists) return; // deleted mid-flight
    const collage = snap.data();
    if (collage.status !== "generating") return; // already finalized (shouldn't happen, but idempotent)

    const bucket = getStorage().bucket();
    const clipPaths = collage.clipPaths || {};
    const orderedIndexes = Object.keys(clipPaths).map(Number).sort((a, b) => a - b);
    const failedCount = collage.itemCount - orderedIndexes.length;

    // Refund one credit per item that never produced a usable clip — whether it failed outright
    // or (defensively) is just missing for some other reason.
    if (failedCount > 0) {
      await db.collection("users").doc(uid).update({ purchasedCredits: FieldValue.increment(failedCount) });
    }

    if (orderedIndexes.length === 0) {
      await collageRef.update({ status: "failed", completedAt: FieldValue.serverTimestamp() });
      await sendCollageNotification(uid, collage.listName, false);
      return;
    }

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "collage-"));
    try {
      const localClipPaths = [];
      for (const index of orderedIndexes) {
        const localPath = path.join(tmpDir, `${index}.mp4`);
        await bucket.file(clipPaths[index]).download({ destination: localPath });
        localClipPaths.push(localPath);
      }

      const outputPath = path.join(tmpDir, "final.mp4");
      await concatVideos(localClipPaths, outputPath);

      const finalStoragePath = `users/${uid}/collages/${collageId}.mp4`;
      const finalFile = bucket.file(finalStoragePath);
      await finalFile.save(fs.readFileSync(outputPath), { metadata: { contentType: "video/mp4" } });
      const videoUrl = await downloadUrlFor(finalFile);

      // Clean up the per-item clips now that they're merged into the final file — no reason to
      // keep paying to store them.
      await Promise.all(orderedIndexes.map((index) => bucket.file(clipPaths[index]).delete().catch(() => {})));

      await collageRef.update({
        status: "complete",
        videoPath: finalStoragePath,
        videoUrl,
        completedAt: FieldValue.serverTimestamp(),
      });
      await sendCollageNotification(uid, collage.listName, true);
    } catch (err) {
      console.error(`finalizeCollageAnimation failed for ${collageId}:`, err);
      // The per-item credits were already refunded above for genuinely failed items; a
      // concat/upload failure here means the SUCCEEDED items' credits should come back too,
      // since the user ends up with nothing playable either way.
      const succeededCount = orderedIndexes.length;
      if (succeededCount > 0) {
        await db.collection("users").doc(uid).update({ purchasedCredits: FieldValue.increment(succeededCount) });
      }
      await collageRef.update({ status: "failed", error: String(err.message || err), completedAt: FieldValue.serverTimestamp() });
      await sendCollageNotification(uid, collage.listName, false);
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  }
);
