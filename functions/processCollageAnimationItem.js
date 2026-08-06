const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getFunctions } = require("firebase-admin/functions");
const { getStorage } = require("firebase-admin/storage");
const { generateVideo } = require("./helpers/wiroVideo");
const { buildAnimatePrompt } = require("./helpers/prompt");

const WIRO_API_KEY = defineSecret("WIRO_API_KEY");
const WIRO_API_SECRET = defineSecret("WIRO_API_SECRET");

// Processes exactly ONE item of a collage-animation job, then enqueues the next item (or, once
// this was the last one, the finalize step) — this chain-of-tasks shape is what lets a
// 20-item collage finish without ever needing a single function invocation long enough to hold
// the whole job (Cloud Functions caps out at 60 minutes; 20 sequential video generations could
// easily exceed that in one run, but never will here since each task only does one).
//
// A failed item (Wiro error, timeout, etc.) is logged and skipped — per product decision, one
// bad item shouldn't sink the whole collage. Its credit is refunded once at finalize time (see
// that file), not here, so a single retry-free pass through the whole failedIndexes bookkeeping
// happens in one place.
exports.processCollageAnimationItem = onTaskDispatched(
  {
    secrets: [WIRO_API_KEY, WIRO_API_SECRET],
    // A retried attempt would re-spend the Wiro call for an item that may have already
    // succeeded (or already been marked failed) on a prior attempt — simpler and safer to treat
    // "this task failed" the same as "this item failed" and let the chain move on, rather than
    // risk double-processing.
    retryConfig: { maxAttempts: 1 },
    rateLimits: { maxConcurrentDispatches: 3 },
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request) => {
    const { uid, collageId, itemIndex } = request.data;
    const db = getFirestore();
    const collageRef = db.collection("users").doc(uid).collection("collages").doc(collageId);
    const snap = await collageRef.get();
    if (!snap.exists) return; // deleted mid-flight (e.g. user deleted it from My Collages) — nothing to do
    const collage = snap.data();
    if (collage.status !== "generating") return; // already finalized or otherwise no longer active

    const item = collage.items[itemIndex];
    // No styleId at all means this is a custom-list item — there's no ai_models descriptor to
    // look up (we genuinely don't know what's in the photo), but the user's OWN title for it
    // (e.g. "First Haircut", "Grandma's Visit") is real context that was otherwise going
    // completely unused here — better than the fully generic "Portrait" placeholder.
    let styleName = item.title || "Portrait";
    let descriptor = "a warm, gentle studio portrait";
    let mood = "warm, natural, gentle";
    if (item.styleId) {
      const styleSnap = await db.collection("ai_models").doc(item.styleId).get();
      if (styleSnap.exists) {
        const style = styleSnap.data();
        styleName = style.name || styleName;
        descriptor = style.descriptor || descriptor;
        mood = style.mood || mood;
      }
    }
    const prompt = buildAnimatePrompt({ styleName, descriptor, mood });

    try {
      const { buffer, contentType } = await generateVideo({
        apiKey: WIRO_API_KEY.value(),
        apiSecret: WIRO_API_SECRET.value(),
        prompt,
        inputImage: item.photoUrl,
        timeoutMs: 480000,
      });
      const clipPath = `users/${uid}/collages/${collageId}/clips/${itemIndex}.mp4`;
      await getStorage().bucket().file(clipPath).save(buffer, { metadata: { contentType } });
      await collageRef.update({ [`clipPaths.${itemIndex}`]: clipPath });
    } catch (err) {
      console.error(`Collage ${collageId} item ${itemIndex} failed:`, err);
      await collageRef.update({ failedIndexes: FieldValue.arrayUnion(itemIndex) });
    }

    const nextIndex = itemIndex + 1;
    if (nextIndex < collage.itemCount) {
      await getFunctions().taskQueue("processCollageAnimationItem").enqueue(
        { uid, collageId, itemIndex: nextIndex },
        { scheduleDelaySeconds: 0 }
      );
    } else {
      await getFunctions().taskQueue("finalizeCollageAnimation").enqueue(
        { uid, collageId },
        { scheduleDelaySeconds: 0 }
      );
    }
  }
);
