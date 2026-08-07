const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.generateContent = require("./generateContent").generateContent;
exports.animateResult = require("./animateResult").animateResult;
exports.startCollageAnimation = require("./startCollageAnimation").startCollageAnimation;
exports.processCollageAnimationItem = require("./processCollageAnimationItem").processCollageAnimationItem;
exports.finalizeCollageAnimation = require("./finalizeCollageAnimation").finalizeCollageAnimation;
exports.deleteAccount = require("./deleteAccount").deleteAccount;
exports.grantPurchase = require("./grantPurchase").grantPurchase;
// Debug aid — see scheduleTestNotification.js's doc comment. Safe to leave exported
// permanently: auth-gated, and a caller can only ever send a push to their own devices.
exports.scheduleTestNotification = require("./scheduleTestNotification").scheduleTestNotification;
exports.sendTestNotification = require("./sendTestNotification").sendTestNotification;

// seedThemes / seedThemePreviews / seedCategoryPreviews are one-off admin tasks — deployed,
// called from a local script to bulk-write, then deleted. Not exported here so
// `firebase deploy --only functions` never redeploys them by accident. To re-run any of them
// (e.g. after editing theme_catalog.json or regenerating preview images), temporarily add the
// export back:
//   firebase deploy --only functions:seedThemes && curl ".../seedThemes?token=$SEED_TOKEN"
//   firebase deploy --only functions:seedThemePreviews && Scripts/DesignAssets/venv/bin/python Scripts/DesignAssets/generate_theme_previews.py
//   firebase deploy --only functions:seedCategoryPreviews && Scripts/DesignAssets/venv/bin/python Scripts/DesignAssets/generate_category_covers.py
//   firebase functions:delete seedThemes seedThemePreviews seedCategoryPreviews --force

// grantPurchase (RevenueCat) is added in Phase 7.
