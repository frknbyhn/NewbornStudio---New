// TEMPORARY admin task — deploy, call once, then `firebase functions:delete seedCustomStyle --force`.
// Writes the single reserved ai_models doc the "Create Your Own Style" flow points at — its
// `prompt` is never actually used since that flow always sends editInstruction (which
// generateContent.js prefers over style.prompt); it only exists so styleId lookup/creditCost
// have somewhere real to resolve to, same as every other style.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore } = require("firebase-admin/firestore");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.seedCustomStyle = onRequest({ secrets: [SEED_TOKEN], timeoutSeconds: 30 }, async (req, res) => {
  if (req.query.token !== SEED_TOKEN.value()) {
    res.status(403).send("Forbidden");
    return;
  }
  await getFirestore().collection("ai_models").doc("custom-style").set({
    name: "Custom Style",
    prompt: "Transform the uploaded baby photo into a professional AI-generated studio portrait.",
    creditCost: 1,
    aspectRatio: "3:4",
  }, { merge: true });
  res.json({ ok: true });
});
