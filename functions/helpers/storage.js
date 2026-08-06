const { randomUUID } = require("crypto");

// Firebase's own download-token scheme (what client SDKs' getDownloadURL() produces) instead of
// a GCS signed URL — the runtime service account doesn't have iam.serviceAccounts.signBlob, and
// granting it needs a gcloud-authenticated session this environment doesn't have. Shared by
// every function that hands a Storage file's URL back to the client (generateContent,
// animateResult, finalizeCollageAnimation) — was duplicated three times before this.
async function downloadUrlFor(file) {
  const token = randomUUID();
  await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  return `https://firebasestorage.googleapis.com/v0/b/${file.bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}

module.exports = { downloadUrlFor };
