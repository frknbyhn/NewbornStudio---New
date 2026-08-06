const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Sends the "your collage is ready" (or failed) push once finalizeCollageAnimation finishes.
// Requires an APNs Auth Key uploaded to the Firebase Console — see PushNotificationService.swift
// on the client side for the registration half of this. Silently no-ops if the user has no
// saved token yet (declined the permission prompt, or hasn't launched a build with push wired
// up) — this is a nice-to-have on top of the in-app "Preparing…" status in My Collages, not the
// only way to find out.
async function sendCollageNotification(uid, listName, success) {
  const db = getFirestore();
  const userSnap = await db.collection("users").doc(uid).get();
  const tokens = (userSnap.data() || {}).fcmTokens || [];
  if (tokens.length === 0) return;

  const message = success
    ? { notification: { title: "Your collage is ready!", body: `"${listName}" is ready to watch.` } }
    : { notification: { title: "Collage couldn't be created", body: `We couldn't create the "${listName}" collage. Your credits were refunded.` } };

  try {
    const response = await getMessaging().sendEachForMulticast({ tokens, ...message });
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
  } catch (err) {
    console.error("sendCollageNotification failed:", err);
  }
}

module.exports = { sendCollageNotification };
