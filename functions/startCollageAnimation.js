const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getFunctions } = require("firebase-admin/functions");
const { ensureUserDoc, spendCredits } = require("./helpers/credits");

// Mirrors the client's own gate (MilestoneListDetailViewController) so a request can't bypass
// it by calling this directly.
const MIN_ITEMS = 5;
// Deliberately a different (lower) per-unit rate than animateResult's standalone
// ANIMATE_CREDIT_COST (4) — a collage of N items costs exactly N credits, per product decision,
// not N x the single-item rate.
const CREDIT_COST_PER_ITEM = 1;

// Kicks off a collage-animation job and returns almost immediately — the actual work (one Wiro
// video call per item, then concatenation) runs across a chain of background tasks
// (processCollageAnimationItem -> ... -> finalizeCollageAnimation) because it can easily run far
// longer than any single Cloud Function invocation's time budget. This function's only jobs are:
// validate, charge credits, write the tracking doc, and enqueue the first task.
exports.startCollageAnimation = onCall({ timeoutSeconds: 60, memory: "256MiB" }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

  const { listId, listName, items } = request.data || {};
  if (!listId || typeof listId !== "string") {
    throw new HttpsError("invalid-argument", "listId is required.");
  }
  if (!listName || typeof listName !== "string") {
    throw new HttpsError("invalid-argument", "listName is required.");
  }
  if (!Array.isArray(items) || items.length < MIN_ITEMS) {
    throw new HttpsError("invalid-argument", `At least ${MIN_ITEMS} items are required.`);
  }
  for (const item of items) {
    if (!item || typeof item.photoUrl !== "string" || !item.photoUrl || typeof item.title !== "string") {
      throw new HttpsError("invalid-argument", "Each item needs a title and a photoUrl.");
    }
  }

  await ensureUserDoc(uid);

  const creditCost = items.length * CREDIT_COST_PER_ITEM;
  let remainingCredits;
  try {
    ({ remainingCredits } = await spendCredits(uid, creditCost, "startCollageAnimation"));
  } catch (err) {
    if (err.message === "insufficient-credits") {
      throw new HttpsError("failed-precondition", "Not enough credits.");
    }
    throw err;
  }

  const db = getFirestore();
  const collageRef = db.collection("users").doc(uid).collection("collages").doc();
  await collageRef.set({
    listId,
    listName,
    status: "generating",
    itemCount: items.length,
    items: items.map((item) => ({
      milestoneId: typeof item.milestoneId === "string" ? item.milestoneId : null,
      title: item.title,
      photoUrl: item.photoUrl,
      styleId: typeof item.styleId === "string" ? item.styleId : null,
      // ISO 8601 string (client sends via ISO8601DateFormatter) — finalizeCollageAnimation
      // parses it back with `new Date(...)` for the per-clip date caption. Stored as the plain
      // string rather than a Firestore Timestamp since it's just carried through to a text
      // burn-in, never queried on.
      capturedAt: typeof item.capturedAt === "string" ? item.capturedAt : null,
    })),
    clipPaths: {},
    failedIndexes: [],
    createdAt: FieldValue.serverTimestamp(),
  });

  await getFunctions().taskQueue("processCollageAnimationItem").enqueue(
    { uid, collageId: collageRef.id, itemIndex: 0 },
    { scheduleDelaySeconds: 0 }
  );

  return { collageId: collageRef.id, remainingCredits };
});
