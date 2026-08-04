const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.generateContent = require("./generateContent").generateContent;
exports.deleteAccount = require("./deleteAccount").deleteAccount;

// seedThemes is a one-off admin task (see seedThemes.js) — deployed, curled once to seed
// ai_models, then deleted. Not exported here so a normal `firebase deploy --only functions`
// never redeploys it. To re-seed after editing theme_catalog.json:
//   firebase deploy --only functions:seedThemes && curl ".../seedThemes?token=$SEED_TOKEN"
//   firebase functions:delete seedThemes --force

// grantPurchase (RevenueCat) is added in Phase 7.
