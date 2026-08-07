const { onTaskDispatched } = require("firebase-functions/v2/tasks");
const { sendPushNotification } = require("./helpers/pushNotify");

// Fired ~60s after scheduleTestNotification enqueues it — see that file's doc comment.
exports.sendTestNotification = onTaskDispatched(
  { timeoutSeconds: 30, retryConfig: { maxAttempts: 1 } },
  async (request) => {
    const { uid } = request.data;
    const result = await sendPushNotification(
      uid,
      "Test Notification",
      "This confirms your device can receive push notifications from Newborn Studio."
    );
    console.log(`sendTestNotification: sent to ${result.sent} device(s) for uid ${uid}`);
  }
);
