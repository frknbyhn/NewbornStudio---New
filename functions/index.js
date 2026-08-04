const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.generateContent = require("./generateContent").generateContent;
exports.deleteAccount = require("./deleteAccount").deleteAccount;
exports.grantPurchase = require("./grantPurchase").grantPurchase;

// seedThemes / seedThemePreviews are one-off admin tasks — deployed, called from a local
// script to bulk-write, then deleted. Not exported here so `firebase deploy --only functions`
// never redeploys them by accident. To re-run either (e.g. after editing theme_catalog.json
// or regenerating preview images), temporarily add the export back:
//   firebase deploy --only functions:seedThemes && curl ".../seedThemes?token=$SEED_TOKEN"
//   firebase deploy --only functions:seedThemePreviews && Scripts/DesignAssets/venv/bin/python Scripts/DesignAssets/generate_theme_previews.py
//   firebase functions:delete seedThemes seedThemePreviews --force

// grantPurchase (RevenueCat) is added in Phase 7.
