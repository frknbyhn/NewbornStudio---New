// Fires the instant a new Firebase Auth user is created — including the app's silent anonymous
// sign-in on first launch (AuthService.ensureSignedIn), so a user shows up in the admin panel
// just from opening the app, not only once they generate/purchase something (which is when
// ensureUserDoc used to first run, via generateContent/grantPurchase/etc — see helpers/credits.js).
//
// v1 API deliberately — auth.user().onCreate() has no v2 equivalent yet (v2's `identity` module
// only covers blocking triggers, not this kind of after-the-fact one); mixing v1 and v2 functions
// in one codebase is fine.
const functions = require("firebase-functions/v1");
const { ensureUserDoc } = require("./helpers/credits");

exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // Skip email/password accounts — that's the admin panel's own login mechanism
  // (adminBootstrap.js), not a real app user. Anonymous, Apple, and Google sign-ins all fall
  // through and get a users/{uid} doc, same as any real end-user.
  const isPasswordAccount = (user.providerData || []).some((p) => p.providerId === "password");
  if (isPasswordAccount) return;

  await ensureUserDoc(user.uid);
});
