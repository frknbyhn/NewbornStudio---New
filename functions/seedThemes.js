// TEMPORARY admin task — deploy, curl once, then `firebase functions:delete seedThemes --force`.
// Per playbook: local firebase-admin often can't get Firestore permission; this route is safer.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore } = require("firebase-admin/firestore");
const { buildPrompt } = require("./helpers/prompt");
const catalog = require("./data/theme_catalog.json");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.seedThemes = onRequest({ secrets: [SEED_TOKEN], timeoutSeconds: 120 }, async (req, res) => {
  if (req.query.token !== SEED_TOKEN.value()) {
    res.status(403).send("Forbidden");
    return;
  }

  const db = getFirestore();
  let written = 0;
  for (const category of catalog.categories) {
    let batch = db.batch();
    let inBatch = 0;
    for (const style of category.styles) {
      const ref = db.collection("ai_models").doc(style.id);
      batch.set(ref, {
        categoryId: category.id,
        categoryName: category.name,
        mood: category.mood,
        name: style.name,
        descriptor: style.descriptor,
        prompt: buildPrompt({ styleName: style.name, descriptor: style.descriptor, mood: category.mood }),
        creditCost: 1,
        aspectRatio: "3:4",
      });
      inBatch += 1;
      written += 1;
      if (inBatch === 200) {
        await batch.commit();
        batch = db.batch();
        inBatch = 0;
      }
    }
    if (inBatch > 0) await batch.commit();
  }

  res.status(200).send(`Seeded ${written} styles across ${catalog.categories.length} categories.`);
});
