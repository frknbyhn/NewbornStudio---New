const { sendPushNotification } = require("./pushNotify");

// Sends the "your collage is ready" (or failed) push once finalizeCollageAnimation finishes —
// see sendPushNotification's doc comment for the shared token-lookup/pruning behavior. Failures
// (e.g. no APNs key configured yet) are swallowed here since this is a nice-to-have on top of
// the in-app "Preparing…" status in My Collages, not the only way to find out.
async function sendCollageNotification(uid, listName, success) {
  const title = success ? "Your collage is ready!" : "Collage couldn't be created";
  const body = success
    ? `"${listName}" is ready to watch.`
    : `We couldn't create the "${listName}" collage. Your credits were refunded.`;
  try {
    await sendPushNotification(uid, title, body);
  } catch (err) {
    console.error("sendCollageNotification failed:", err);
  }
}

module.exports = { sendCollageNotification };
