// TEMPORARY admin task — same pattern as seedThemes.js: deploy, curl once per new admin login,
// then remove the export + `firebase functions:delete adminBootstrap --force`. Creates (or
// reuses) a Firebase Auth email/password user and marks them admin by adding an `admins/{uid}`
// Firestore doc — the only thing firestore.rules' isAdmin() checks for.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const ADMIN_BOOTSTRAP_TOKEN = defineSecret("ADMIN_BOOTSTRAP_TOKEN");

exports.adminBootstrap = onRequest({ secrets: [ADMIN_BOOTSTRAP_TOKEN], timeoutSeconds: 30 }, async (req, res) => {
  // Prefer POST body — a query-string password ends up in HTTP access logs.
  const body = req.body || {};
  const email = body.email || req.query.email;
  const password = body.password || req.query.password;
  const token = body.token || req.query.token;
  if (token !== ADMIN_BOOTSTRAP_TOKEN.value()) {
    res.status(403).send("Forbidden");
    return;
  }
  if (!email || !password) {
    res.status(400).send("email and password are required (POST JSON body preferred)");
    return;
  }

  const auth = getAuth();
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (e) {
    user = await auth.createUser({ email, password });
  }

  await getFirestore().collection("admins").doc(user.uid).set({
    email,
    createdAt: FieldValue.serverTimestamp(),
  });

  res.status(200).send(`Admin ready: ${email} (${user.uid})`);
});
