const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getFunctions } = require("firebase-admin/functions");
const { ensureUserDoc, spendCredits } = require("./helpers/credits");

const MUSIC_CREDIT_COST = 1;

// Kicks off a collage-music job and returns almost immediately — the actual work (one Wiro
// text-to-music call, which can run well past what's comfortable to hold a client callable open
// for, then an ffmpeg mux pass) happens in the background (renderCollageMusic), same reasoning
// as startCollageAnimation -> processCollageAnimationItem for the collage video itself. This
// function's only jobs are: validate, charge the credit, mark the collage as busy, and enqueue.
exports.startCollageMusic = onCall({ timeoutSeconds: 60, memory: "256MiB" }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

  const { collageId, prompt } = request.data || {};
  if (!collageId || typeof collageId !== "string") {
    throw new HttpsError("invalid-argument", "collageId is required.");
  }
  if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
    throw new HttpsError("invalid-argument", "prompt is required.");
  }
  const trimmedPrompt = prompt.trim();

  const db = getFirestore();
  const collageRef = db.collection("users").doc(uid).collection("collages").doc(collageId);
  const collageSnap = await collageRef.get();
  if (!collageSnap.exists) throw new HttpsError("not-found", "Collage not found.");
  const collage = collageSnap.data();
  if (collage.status !== "complete" || !collage.videoPath) {
    throw new HttpsError("failed-precondition", "This collage isn't ready yet.");
  }
  if (collage.musicStatus === "generating") {
    throw new HttpsError("failed-precondition", "Music is already being generated for this collage.");
  }

  await ensureUserDoc(uid);
  let remainingCredits;
  try {
    ({ remainingCredits } = await spendCredits(uid, MUSIC_CREDIT_COST, "startCollageMusic"));
  } catch (err) {
    if (err.message === "insufficient-credits") {
      throw new HttpsError("failed-precondition", "Not enough credits.");
    }
    throw err;
  }

  await collageRef.update({ musicStatus: "generating", musicPrompt: trimmedPrompt });

  await getFunctions().taskQueue("renderCollageMusic").enqueue(
    { uid, collageId, prompt: trimmedPrompt },
    { scheduleDelaySeconds: 0 }
  );

  return { remainingCredits };
});
