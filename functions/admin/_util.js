const { HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

/// Every admin-panel callable starts with this — throws unless the caller is signed in AND has
/// a doc in the `admins` collection (see firestore.rules' isAdmin() and adminBootstrap.js, the
/// only thing that ever creates one). Returns the caller's uid for ledger/audit fields.
async function requireAdmin(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");
  const doc = await getFirestore().collection("admins").doc(uid).get();
  if (!doc.exists) throw new HttpsError("permission-denied", "Admin access required.");
  return uid;
}

module.exports = { requireAdmin };
