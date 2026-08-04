const crypto = require("crypto");

const API_BASE = "https://api.wiro.ai/v1";
const RUN_URL = `${API_BASE}/Run/google/nano-banana`;
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

async function submitTask({ apiKey, apiSecret, prompt, inputImageUrl, aspectRatio = "3:4" }) {
  const form = new FormData();
  form.append("prompt", prompt);
  form.append("aspectRatio", aspectRatio);
  form.append("temperature", "1.0");
  form.append("safetySetting", "BLOCK_ONLY_HIGH");
  if (inputImageUrl) form.append("inputImage", inputImageUrl);

  const resp = await fetch(RUN_URL, { method: "POST", headers: authHeaders(apiKey, apiSecret), body: form });
  if (!resp.ok) throw new Error(`Wiro submit failed: HTTP ${resp.status}`);
  const payload = await resp.json();
  if (!payload.taskid) throw new Error(`Wiro submit returned no taskid: ${JSON.stringify(payload)}`);
  return payload.taskid;
}

// Task/Detail's real payload shape is {tasklist: [{status, outputs, ...}]}, not top-level
// {status, task}. Verified the hard way — see the project's Wiro memory notes.
async function pollTask({ apiKey, apiSecret, taskId, timeoutMs = 90000, intervalMs = 2000 }) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const resp = await fetch(DETAIL_URL, {
      method: "POST",
      headers: authHeaders(apiKey, apiSecret),
      body: (() => { const f = new FormData(); f.append("taskid", taskId); return f; })(),
    });
    if (!resp.ok) throw new Error(`Wiro poll failed: HTTP ${resp.status}`);
    const payload = await resp.json();
    const task = payload.tasklist && payload.tasklist[0];
    if (!task) throw new Error(`Wiro poll returned no tasklist: ${JSON.stringify(payload)}`);
    if (task.status === TERMINAL_SUCCESS) return task;
    if (task.status === TERMINAL_FAILURE) throw new Error(`Wiro task ${taskId} was cancelled`);
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error(`Wiro task ${taskId} timed out after ${timeoutMs}ms`);
}

// Outputs are private (ispublic: 0) — the URL 403s without ?accesskey=.
async function downloadOutput(task) {
  const output = task.outputs && task.outputs[0];
  if (!output) throw new Error(`Wiro task has no outputs: ${JSON.stringify(task)}`);
  const url = output.accesskey ? `${output.url}?accesskey=${output.accesskey}` : output.url;
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`Wiro output download failed: HTTP ${resp.status}`);
  const arrayBuffer = await resp.arrayBuffer();
  return { buffer: Buffer.from(arrayBuffer), contentType: output.contenttype || "image/png" };
}

async function generateImage({ apiKey, apiSecret, prompt, inputImageUrl, aspectRatio, timeoutMs }) {
  const taskId = await submitTask({ apiKey, apiSecret, prompt, inputImageUrl, aspectRatio });
  const task = await pollTask({ apiKey, apiSecret, taskId, timeoutMs });
  return downloadOutput(task);
}

module.exports = { generateImage };
