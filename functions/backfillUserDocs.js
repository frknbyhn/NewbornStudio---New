// TEMPORARY, one-off — same pattern as seedThemes.js: deploy, curl once, then
// `firebase functions:delete backfillUserDocs --force`. onUserCreated.js only catches auth users
// created FROM NOW ON; this catches everyone who already opened the app before that trigger
// existed (an Auth user with no users/{uid} Firestore doc yet, because they never generated or
// purchased anything — the only two things that used to call ensureUserDoc).
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { ensureUserDoc } = require("./helpers/credits");

const SEED_TOKEN = defineSecret("SEED_TOKEN");

exports.backfillUserDocs = onRequest({ secrets: [SEED_TOKEN], timeoutSeconds: 300 }, async (req, res) => {
  if (req.query.token !== SEED_TOKEN.value()) {
    res.status(403).send("Forbidden");
    return;
  }

  const db = getFirestore();
  let created = 0;
  let checked = 0;
  let skippedPassword = 0;
  let nextPageToken;

  do {
    const page = await getAuth().listUsers(1000, nextPageToken);
    for (const user of page.users) {
      checked += 1;
      const isPasswordAccount = (user.providerData || []).some((p) => p.providerId === "password");
      if (isPasswordAccount) {
        skippedPassword += 1;
        continue; // admin panel logins, not real app users — same rule as onUserCreated.js
      }
      const snap = await db.collection("users").doc(user.uid).get();
      if (!snap.exists) {
        await ensureUserDoc(user.uid);
        created += 1;
      }
    }
    nextPageToken = page.pageToken;
  } while (nextPageToken);

  res.status(200).send(`Checked ${checked} auth users, skipped ${skippedPassword} admin login(s), created ${created} missing users/{uid} docs.`);
});
