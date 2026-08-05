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

  // Small standalone collection so Home can list categories cheaply (Firestore has no
  // distinct-query support, so deriving this from 300 ai_models docs client-side would mean
  // fetching all 300 just to build a 20-item filter chip list).
  // merge: true — same reasoning as the ai_models write below: a plain .set() here silently
  // wipes coverImageUrl (added later by seedCategoryPreviews), which is exactly what happened
  // re-running this to add the "Milestones" category — recovered from
  // Scripts/DesignAssets/category_cover_progress.json, but the underlying bug is fixed here.
  const categoriesBatch = db.batch();
  catalog.categories.forEach((category, index) => {
    categoriesBatch.set(db.collection("categories").doc(category.id), {
      name: category.name,
      mood: category.mood,
      position: index,
    }, { merge: true });
  });
  await categoriesBatch.commit();

  for (const category of catalog.categories) {
    let batch = db.batch();
    let inBatch = 0;
    for (const style of category.styles) {
      const ref = db.collection("ai_models").doc(style.id);
      // merge: true — a plain .set() here would silently wipe fields this doc has picked up
      // since the catalog was first seeded (previewImageUrl, most notably) since fixed the
      // hard way after re-running this to add the categories collection.
      batch.set(ref, {
        categoryId: category.id,
        categoryName: category.name,
        mood: category.mood,
        name: style.name,
        descriptor: style.descriptor,
        prompt: buildPrompt({ styleName: style.name, descriptor: style.descriptor, mood: category.mood }),
        creditCost: 1,
        aspectRatio: "3:4",
      }, { merge: true });
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

  res.status(200).send(`Seeded ${written} styles and ${catalog.categories.length} categories.`);
});
