const crypto = require("crypto");

// bytedance/seedance-pro-v1-5 (image-to-video) — a separate Wiro model from google/nano-banana
// (wiro.js), different endpoint and a completely different parameter set, so this is its own
// module rather than a variant of wiro.js. Every parameter name/value/default here is taken
// verbatim from https://wiro.ai/models/bytedance/seedance-pro-v1-5/llms-full.txt — nothing
// guessed. Only `prompt` and `inputImage` are actually set by callers; every other field is
// passed through at its documented default so behavior matches the model's own baseline.
const API_BASE = "https://api.wiro.ai/v1";
const RUN_URL = `${API_BASE}/Run/bytedance/seedance-pro-v1-5`;
const DETAIL_URL = `${API_BASE}/Task/Detail`;

const TERMINAL_SUCCESS = "task_postprocess_end";
const TERMINAL_FAILURE = "task_cancel";

function authHeaders(apiKey, apiSecret) {
  const nonce = String(Math.floor(Date.now() / 1000));
  const signature = crypto
    .createHmac("sha256", apiKey)
    .update(apiSecret + nonce)
    .digest("hex");
  return { "x-api-key": apiKey, "x-nonce": nonce, "x-signature": signature };
}

// inputImage accepts either a URL string OR { buffer, filename, contentType } for a real
// multipart file attachment — same dual support as wiro.js's submitTask, and for the same
// reason: a result image already has a durable Storage URL, no need to re-fetch and re-attach
// it as bytes when Wiro will just fetch the URL itself.
async function submitVideoTask({
  apiKey,
  apiSecret,
  prompt,
  inputImage,
  inputImageLast,
  resolution = "480p",
  ratio = "adaptive",
  duration = 5,
  generateAudio = "false", // default off — callers (collage + animate) don't pass it, so this wins

  watermark = "false",
  seed = 1,
  camerafixed = "false",
  callbackUrl,
}) {
  const form = new FormData();
  form.append("prompt", prompt);
  form.append("resolution", resolution);
  form.append("ratio", ratio);
  form.append("duration", String(duration));
  form.append("generateAudio", generateAudio);
  form.append("watermark", watermark);
  form.append("seed", String(seed));
  form.append("camerafixed", camerafixed);
  if (callbackUrl) form.append("callbackUrl", callbackUrl);

  const appendImage = (field, image) => {
    if (typeof image === "string") {
      form.append(field, image);
    } else if (image && image.buffer) {
      const blob = new Blob([image.buffer], { type: image.contentType || "image/jpeg" });
      form.append(field, blob, image.filename || "input.jpg");
    }
  };
  if (inputImage) appendImage("inputImage", inputImage);
  if (inputImageLast) appendImage("inputImageLast", inputImageLast);

  const resp = await fetch(RUN_URL, { method: "POST", headers: authHeaders(apiKey, apiSecret), body: form });
  if (!resp.ok) throw new Error(`Wiro video submit failed: HTTP ${resp.status}`);
  const payload = await resp.json();
  if (!payload.taskid) throw new Error(`Wiro video submit returned no taskid: ${JSON.stringify(payload)}`);
  return payload.taskid;
}

// Same tasklist[0] response shape as wiro.js's pollTask (this is a Task/Detail-wide API
// contract, not specific to one model) — but video generation runs far longer than an image
// edit, so the default timeout/interval here are both much larger.
async function pollVideoTask({ apiKey, apiSecret, taskId, timeoutMs = 480000, intervalMs = 4000 }) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const resp = await fetch(DETAIL_URL, {
      method: "POST",
      headers: authHeaders(apiKey, apiSecret),
      body: (() => { const f = new FormData(); f.append("taskid", taskId); return f; })(),
    });
    if (!resp.ok) throw new Error(`Wiro video poll failed: HTTP ${resp.status}`);
    const payload = await resp.json();
    const task = payload.tasklist && payload.tasklist[0];
    if (!task) throw new Error(`Wiro video poll returned no tasklist: ${JSON.stringify(payload)}`);
    if (task.status === TERMINAL_SUCCESS) return task;
    if (task.status === TERMINAL_FAILURE) throw new Error(`Wiro video task ${taskId} was cancelled`);
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error(`Wiro video task ${taskId} timed out after ${timeoutMs}ms`);
}

async function downloadVideoOutput(task) {
  const output = task.outputs && task.outputs[0];
  if (!output) throw new Error(`Wiro video task has no outputs: ${JSON.stringify(task)}`);
  const url = output.accesskey ? `${output.url}?accesskey=${output.accesskey}` : output.url;
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`Wiro video output download failed: HTTP ${resp.status}`);
  const arrayBuffer = await resp.arrayBuffer();
  return { buffer: Buffer.from(arrayBuffer), contentType: output.contenttype || "video/mp4" };
}

async function generateVideo(opts) {
  const taskId = await submitVideoTask(opts);
  const task = await pollVideoTask({ apiKey: opts.apiKey, apiSecret: opts.apiSecret, taskId, timeoutMs: opts.timeoutMs });
  return downloadVideoOutput(task);
}

module.exports = { generateVideo };
