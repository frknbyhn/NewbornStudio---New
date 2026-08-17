const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.generateContent = require("./generateContent").generateContent;
exports.animateResult = require("./animateResult").animateResult;
exports.startCollageAnimation = require("./startCollageAnimation").startCollageAnimation;
exports.processCollageAnimationItem = require("./processCollageAnimationItem").processCollageAnimationItem;
exports.finalizeCollageAnimation = require("./finalizeCollageAnimation").finalizeCollageAnimation;
exports.deleteAccount = require("./deleteAccount").deleteAccount;
// Creates users/{uid} the instant a new Firebase Auth user exists (anonymous sign-in on first
// launch included) — so a user shows up in the admin panel just from opening the app, not only
// once they generate/purchase something. See onUserCreated.js.
exports.onUserCreated = require("./onUserCreated").onUserCreated;
// backfillUserDocs was a one-off (like seedThemes) — deployed, curled once on 2026-08-10 to
// catch users who opened the app before onUserCreated existed (18 of 19 auth users backfilled,
// 1 admin login correctly skipped), then removed. Re-add + redeploy only if ever needed again:
// exports.backfillUserDocs = require("./backfillUserDocs").backfillUserDocs;
exports.grantPurchase = require("./grantPurchase").grantPurchase;
exports.startCollageMusic = require("./startCollageMusic").startCollageMusic;
exports.renderCollageMusic = require("./renderCollageMusic").renderCollageMusic;

// TEMPORARY — self-service test-credit top-up for the #if DEBUG button on HomeViewController.
// Remove this export, debugAddCredits.js, and that button together once done testing (see
// debugAddCredits.js's own doc comment for why this shouldn't stay exported long-term).
exports.debugAddCredits = require("./debugAddCredits").debugAddCredits;

// Admin panel (public/admin/) — every write it needs to make (credits/premium, catalog,
// categories, Remote Config) is blocked for a plain client by firestore.rules, so it goes
// through these. Reads (users list, credit_transactions, ai_models, categories) the panel does
// directly via the client SDK, gated by firestore.rules' isAdmin().
exports.adminUpdateUser = require("./admin/adminUpdateUser").adminUpdateUser;
exports.adminDeleteUser = require("./admin/adminUpdateUser").adminDeleteUser;
exports.adminUpsertStyle = require("./admin/adminCatalog").adminUpsertStyle;
exports.adminDeleteStyle = require("./admin/adminCatalog").adminDeleteStyle;
exports.adminUpsertCategory = require("./admin/adminCatalog").adminUpsertCategory;
exports.adminDeleteCategory = require("./admin/adminCatalog").adminDeleteCategory;
exports.adminGetRemoteConfig = require("./admin/adminRemoteConfig").adminGetRemoteConfig;
exports.adminSetRemoteConfig = require("./admin/adminRemoteConfig").adminSetRemoteConfig;

// adminBootstrap is a one-off like seedThemes — deployed only while creating a new admin login,
// then removed (done: frknbyhn@gmail.com is admin as of 2026-08-10). To add another admin:
// uncomment the export below, deploy, POST to it, remove again:
//   firebase deploy --only functions:adminBootstrap
//   curl -X POST https://us-central1-newborn-moments.cloudfunctions.net/adminBootstrap \
//     -H "Content-Type: application/json" -d '{"token":"$ADMIN_BOOTSTRAP_TOKEN","email":"...","password":"..."}'
//   firebase functions:delete adminBootstrap --force
// exports.adminBootstrap = require("./admin/adminBootstrap").adminBootstrap;

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
