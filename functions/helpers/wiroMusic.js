const crypto = require("crypto");

// stabilityai/stable-audio-3-small-music (text-to-music) — a separate Wiro model from
// bytedance/seedance-pro-v1-5 (wiroVideo.js) and google/nano-banana (wiro.js), different
// endpoint and parameter set, so this is its own module. Every parameter name/value/default
// here is taken verbatim from
// https://wiro.ai/models/stabilityai/stable-audio-3-small-music/llms-full.txt — nothing guessed.
const API_BASE = "https://api.wiro.ai/v1";
const RUN_URL = `${API_BASE}/Run/stabilityai/stable-audio-3-small-music`;
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

// duration/promptExpansion/steps/scale default to the model's own documented defaults (60,
// "False", 8, 1.0) so behavior matches the model's baseline unless a caller overrides one.
async function submitMusicTask({
  apiKey,
  apiSecret,
  prompt,
  duration = 60,
  promptExpansion = "False",
  steps = 8,
  scale = 1.0,
  callbackUrl,
}) {
  const form = new FormData();
  form.append("prompt", prompt);
  form.append("duration", String(duration));
  form.append("promptExpansion", promptExpansion);
  form.append("steps", String(steps));
  form.append("scale", String(scale));
  if (callbackUrl) form.append("callbackUrl", callbackUrl);

  const resp = await fetch(RUN_URL, { method: "POST", headers: authHeaders(apiKey, apiSecret), body: form });
  if (!resp.ok) throw new Error(`Wiro music submit failed: HTTP ${resp.status}`);
  const payload = await resp.json();
  if (!payload.taskid) throw new Error(`Wiro music submit returned no taskid: ${JSON.stringify(payload)}`);
  return payload.taskid;
}

// Same tasklist[0] response shape as wiro.js/wiroVideo.js's pollTask (this is a Task/Detail-wide
// API contract, not specific to one model). Only task_postprocess_end (success) and task_cancel
// (failure) are terminal per the doc's "Task Status Information" section — every other status
// (task_queue/task_accept/task_assign/task_preprocess_start/task_preprocess_end/task_start/
// task_output) means keep polling.
async function pollMusicTask({ apiKey, apiSecret, taskId, timeoutMs = 300000, intervalMs = 4000 }) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const resp = await fetch(DETAIL_URL, {
      method: "POST",
      headers: authHeaders(apiKey, apiSecret),
      body: (() => { const f = new FormData(); f.append("taskid", taskId); return f; })(),
    });
    if (!resp.ok) throw new Error(`Wiro music poll failed: HTTP ${resp.status}`);
    const payload = await resp.json();
    const task = payload.tasklist && payload.tasklist[0];
    if (!task) throw new Error(`Wiro music poll returned no tasklist: ${JSON.stringify(payload)}`);
    if (task.status === TERMINAL_SUCCESS) return task;
    if (task.status === TERMINAL_FAILURE) throw new Error(`Wiro music task ${taskId} was cancelled`);
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error(`Wiro music task ${taskId} timed out after ${timeoutMs}ms`);
}

async function downloadMusicOutput(task) {
  const output = task.outputs && task.outputs[0];
  if (!output) throw new Error(`Wiro music task has no outputs: ${JSON.stringify(task)}`);
  const url = output.accesskey ? `${output.url}?accesskey=${output.accesskey}` : output.url;
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`Wiro music output download failed: HTTP ${resp.status}`);
  const arrayBuffer = await resp.arrayBuffer();
  return { buffer: Buffer.from(arrayBuffer), contentType: output.contenttype || "audio/mpeg" };
}

async function generateMusic(opts) {
  const taskId = await submitMusicTask(opts);
  const task = await pollMusicTask({ apiKey: opts.apiKey, apiSecret: opts.apiSecret, taskId, timeoutMs: opts.timeoutMs });
  return downloadMusicOutput(task);
}

module.exports = { generateMusic, submitMusicTask, pollMusicTask, downloadMusicOutput };
