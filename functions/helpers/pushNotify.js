const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Generic FCM send to every token saved on a user's doc (users/{uid}.fcmTokens — written by
// PushNotificationService.swift once notification permission is granted). Requires an APNs Auth
// Key uploaded to the Firebase Console; silently sends 0 messages otherwise (no token will have
// ever registered successfully). Shared by every place in this backend that sends a push —
// currently sendCollageNotification and the scheduleTestNotification/sendTestNotification pair
// used to verify the whole pipeline end-to-end without waiting on a real collage to finish.
async function sendPushNotification(uid, title, body) {
  const db = getFirestore();
  const userSnap = await db.collection("users").doc(uid).get();
  const tokens = (userSnap.data() || {}).fcmTokens || [];
  if (tokens.length === 0) return { sent: 0 };

  const response = await getMessaging().sendEachForMulticast({ tokens, notification: { title, body } });

  // Prune tokens FCM reports as dead (uninstalled app, expired token) so this array doesn't
  // grow stale forever.
  const staleTokens = [];
  response.responses.forEach((r, i) => {
    const code = r.error && r.error.code;
    if (!r.success && (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token")) {
      staleTokens.push(tokens[i]);
    }
  });
  if (staleTokens.length > 0) {
    await db.collection("users").doc(uid).update({ fcmTokens: FieldValue.arrayRemove(...staleTokens) });
  }
  return { sent: tokens.length - staleTokens.length };
}

module.exports = { sendPushNotification };
