const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.generateContent = require("./generateContent").generateContent;
exports.deleteAccount = require("./deleteAccount").deleteAccount;
exports.grantPurchase = require("./grantPurchase").grantPurchase;
exports.seedThemePreviews = require("./seedThemePreviews").seedThemePreviews;

// seedThemes / seedThemePreviews are one-off admin tasks — deployed, called from a local
// script to bulk-write, then deleted. Not normally exported so `firebase deploy --only
// functions` never redeploys them by accident; seedThemePreviews stays exported only while
// the theme preview generation batch (see Scripts/DesignAssets/generate_theme_previews.py)
// is actively running, then gets removed and the deployed function deleted.
//   firebase deploy --only functions:seedThemes && curl ".../seedThemes?token=$SEED_TOKEN"
//   firebase functions:delete seedThemes --force

// grantPurchase (RevenueCat) is added in Phase 7.
