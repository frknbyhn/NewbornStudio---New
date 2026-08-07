const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFunctions } = require("firebase-admin/functions");

// Debug aid only — lets the "Test Notification" button on Home (wrapped in #if DEBUG client-side)
// verify the whole push pipeline (device token -> APNs -> FCM -> this backend -> back down to
// the device) end-to-end without waiting on a real collage to finish generating. Same
// enqueue-a-task shape as startCollageAnimation, just for a single delayed send instead of a
// whole processing chain.
exports.scheduleTestNotification = onCall({ timeoutSeconds: 30 }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign-in required.");

  await getFunctions().taskQueue("sendTestNotification").enqueue(
    { uid },
    { scheduleDelaySeconds: 60 }
  );

  return { scheduled: true };
});
