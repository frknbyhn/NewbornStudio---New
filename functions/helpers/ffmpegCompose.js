const { spawn, execFile } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const sharp = require("sharp");

// Neither obvious npm ffmpeg package actually worked for what this file needs (both confirmed
// against real production failures, not guessed):
//   - ffmpeg-static's Linux (Cloud Functions) build is missing libfreetype/fontconfig entirely,
//     so drawtext (the title/date captions below) doesn't exist: every real collage's finalize
//     step failed with "No such filter: 'drawtext'".
//   - @ffmpeg-installer/ffmpeg's Linux binary DOES have drawtext, but it's pinned to ffmpeg
//     4.1.0 — too old to have xfade at all (added in ffmpeg 4.3), so finalize just failed
//     differently: "No such filter: 'xfade'".
// bin/ffmpeg-linux-x64 (committed to this repo, not a dependency) is John Van Sickle's own
// current "release-amd64-static" build (ffmpeg 7.0.2, https://johnvansickle.com/ffmpeg/) —
// verified directly against the downloaded binary (not just trusted from a README) to have both
// --enable-fontconfig --enable-libfreetype AND xfade/acrossfade before committing it. Used only
// on Linux (i.e. always, in the real deployed function); macOS keeps using
// @ffmpeg-installer/ffmpeg for local dev/testing, since a modern-enough full build isn't needed
// there — local runs are just filter-graph/command sanity checks, never a stand-in for the exact
// deployed binary (Cloud Build always reinstalls node_modules on Linux regardless).
const ffmpegPath = os.platform() === "linux"
  ? path.join(__dirname, "..", "bin", "ffmpeg-linux-x64")
  : require("@ffmpeg-installer/ffmpeg").path;
const ffprobePath = require("ffprobe-static").path;

const FONT_PATH = path.join(__dirname, "..", "assets", "Quicksand-Variable.ttf");

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { maxBuffer: 10 * 1024 * 1024 }, (err, stdout, stderr) => {
      if (err) {
        reject(new Error(`${path.basename(cmd)} failed: ${stderr || err.message}`));
        return;
      }
      resolve(stdout);
    });
  });
}

async function probeDuration(filePath) {
  const out = await run(ffprobePath, ["-v", "error", "-show_entries", "format=duration", "-of", "json", filePath]);
  const seconds = parseFloat(JSON.parse(out).format.duration);
  if (!Number.isFinite(seconds) || seconds <= 0) throw new Error(`Could not read a valid duration for ${filePath}`);
  return seconds;
}

async function probeHasAudio(filePath) {
  const out = await run(ffprobePath, [
    "-v", "error", "-select_streams", "a", "-show_entries", "stream=codec_type", "-of", "json", filePath,
  ]);
  const streams = JSON.parse(out).streams;
  return Array.isArray(streams) && streams.length > 0;
}

async function probeVideoSize(filePath) {
  const out = await run(ffprobePath, [
    "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "json", filePath,
  ]);
  const stream = JSON.parse(out).streams && JSON.parse(out).streams[0];
  if (!stream || !stream.width || !stream.height) throw new Error(`Could not read video dimensions for ${filePath}`);
  return { width: stream.width, height: stream.height };
}

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    const proc = spawn(ffmpegPath, args);
    let stderr = "";
    proc.stderr.on("data", (d) => { stderr += d.toString(); });
    proc.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`ffmpeg exited with code ${code}: ${stderr.slice(-3000)}`));
    });
    proc.on("error", reject);
  });
}

// NOT ffmpeg's drawtext filter — see this file's own top-of-file note: no static ffmpeg build we
// could find (or bundle) has both drawtext AND xfade/acrossfade at once. Captions are rendered as
// standalone transparent PNGs via sharp's text feature instead (using our own bundled font file
// directly, sidestepping any system-fontconfig dependency) and composited onto each clip with
// ffmpeg's `overlay` filter — a universally-available core filter, unlike drawtext.
//
// `rgba: true` makes sharp treat `text` as Pango markup (allowing the `<span>` color) rather than
// plain text, so a raw title (user-typed, could contain `<`/`&`/etc.) has to be XML-escaped first.
function escapeMarkup(text) {
  return String(text || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Renders `text` to an in-memory transparent-background PNG buffer, white, left-aligned, using
 * our own bundled Quicksand font. Returns null for empty text. */
async function renderTextPng({ text, fontSizePx, maxWidth }) {
  if (!text) return null;
  const buffer = await sharp({
    text: {
      text: `<span foreground="white">${escapeMarkup(text)}</span>`,
      fontfile: FONT_PATH,
      font: `Quicksand Bold ${fontSizePx}`,
      width: maxWidth,
      rgba: true,
      align: "left",
    },
  }).png().toBuffer();
  const { width, height } = await sharp(buffer).metadata();
  return { buffer, width, height };
}

/**
 * Renders a single compact "chip" PNG — title (+ optional date below it) left-aligned over a
 * small rounded semi-transparent backdrop sized to hug just the text, not a full-width banner.
 * Meant to sit in a corner of the frame (see composeCollage/composeSingleClip's positioning) —
 * the rounded pill + drop-shadow-free flat backdrop keeps it legible over any footage without
 * dominating the frame the way a full-width bar across a quarter of the video did before.
 * Returns null (nothing to overlay) if there's no title and no date.
 */
async function renderCaptionChip({ title, dateText, fontSizeTitlePx, fontSizeDatePx, maxTextWidth, outputPath }) {
  const [titleImg, dateImg] = await Promise.all([
    renderTextPng({ text: title, fontSizePx: fontSizeTitlePx, maxWidth: maxTextWidth }),
    renderTextPng({ text: dateText, fontSizePx: fontSizeDatePx, maxWidth: maxTextWidth }),
  ]);
  if (!titleImg && !dateImg) return null;

  const padding = Math.round(fontSizeTitlePx * 0.55);
  const gap = Math.round(fontSizeTitlePx * 0.2);
  const contentWidth = Math.max(titleImg ? titleImg.width : 0, dateImg ? dateImg.width : 0);
  const contentHeight = (titleImg ? titleImg.height : 0) + (titleImg && dateImg ? gap : 0) + (dateImg ? dateImg.height : 0);
  const chipWidth = contentWidth + padding * 2;
  const chipHeight = contentHeight + padding * 2;
  const cornerRadius = Math.round(padding * 0.7);

  const backdropSvg = Buffer.from(
    `<svg width="${chipWidth}" height="${chipHeight}" xmlns="http://www.w3.org/2000/svg">` +
    `<rect width="${chipWidth}" height="${chipHeight}" rx="${cornerRadius}" ry="${cornerRadius}" fill="black" fill-opacity="0.45"/>` +
    `</svg>`
  );

  const composites = [];
  let y = padding;
  if (titleImg) {
    composites.push({ input: titleImg.buffer, left: padding, top: y });
    y += titleImg.height + gap;
  }
  if (dateImg) {
    composites.push({ input: dateImg.buffer, left: padding, top: y });
  }

  await sharp(backdropSvg).composite(composites).png().toFile(outputPath);
  return outputPath;
}

/**
 * Concatenates `clips` (in order) into one video at `outputPath`, with:
 *   - a crossfade transition between each consecutive pair (video via xfade, audio via
 *     acrossfade — but only if EVERY clip actually has an audio stream; if even one doesn't,
 *     the whole output is rendered silent rather than risk a broken filter graph referencing a
 *     stream that isn't there),
 *   - each clip's own title + date shown as a compact rounded caption chip in the bottom-left
 *     corner (see renderCaptionChip) rather than a full-width bar across the frame.
 *
 * `clips`: [{ path, title, dateText }], already in final display order.
 */
async function composeCollage({ clips, transitionDuration = 0.5, outputPath }) {
  if (clips.length < 2) throw new Error("composeCollage needs at least 2 clips");
  const tmpDir = path.dirname(outputPath);

  const durations = await Promise.all(clips.map((c) => probeDuration(c.path)));
  const audioFlags = await Promise.all(clips.map((c) => probeHasAudio(c.path)));
  const allHaveAudio = audioFlags.every(Boolean);
  const sizes = await Promise.all(clips.map((c) => probeVideoSize(c.path)));

  const inputArgs = [];
  clips.forEach((c) => inputArgs.push("-i", c.path));

  // One caption "chip" per clip (title + optional date, see renderCaptionChip), sized relative
  // to that clip's own dimensions — each becomes its own extra ffmpeg input, appended after all
  // the clip inputs so clip-input indices stay 0..clips.length-1 as everything below (the
  // xfade/acrossfade chain) already assumes.
  const chipInputIndex = []; // chipInputIndex[i] = input index, or undefined if clip i has no caption
  let nextInputIndex = clips.length;
  for (let i = 0; i < clips.length; i++) {
    const { width, height } = sizes[i];
    const chipPath = await renderCaptionChip({
      title: clips[i].title,
      dateText: clips[i].dateText,
      fontSizeTitlePx: Math.round(height * 0.042),
      fontSizeDatePx: Math.round(height * 0.026),
      maxTextWidth: Math.round(width * 0.6),
      outputPath: path.join(tmpDir, `chip_${i}.png`),
    });
    if (chipPath) {
      inputArgs.push("-i", chipPath);
      chipInputIndex[i] = nextInputIndex++;
    }
  }

  const filterParts = [];

  // Bottom-left corner placement, margin scaled to the clip's own size — no full-width scrim.
  clips.forEach((clip, i) => {
    const chipIdx = chipInputIndex[i];
    if (chipIdx === undefined) {
      filterParts.push(`[${i}:v]null[v${i}]`);
      return;
    }
    const marginX = "main_w*0.05";
    const marginY = "main_h*0.05";
    filterParts.push(`[${i}:v][${chipIdx}:v]overlay=x=${marginX}:y=main_h-overlay_h-${marginY}[v${i}]`);
  });

  // Video crossfade chain — xfade's `offset` is where in the RUNNING OUTPUT timeline (not the
  // individual clip) the transition starts, so it has to accumulate: each step's output runs
  // for (previous output duration - transitionDuration + this clip's own duration), and that
  // becomes the base for the next offset.
  let cumulative = durations[0];
  let lastVideoLabel = "v0";
  for (let i = 1; i < clips.length; i++) {
    const offset = Math.max(0, cumulative - transitionDuration);
    const outLabel = i === clips.length - 1 ? "vout" : `vx${i}`;
    filterParts.push(`[${lastVideoLabel}][v${i}]xfade=transition=fade:duration=${transitionDuration}:offset=${offset.toFixed(3)}[${outLabel}]`);
    cumulative = offset + durations[i];
    lastVideoLabel = outLabel;
  }

  const mapArgs = ["-map", "[vout]"];
  if (allHaveAudio) {
    // acrossfade needs no offset math of its own — it always crossfades the tail of its first
    // input with the head of its second over `d` seconds, so chaining it is just "feed the
    // previous merged result in as input A again," same shape as the video chain but simpler.
    let lastAudioLabel = "0:a";
    for (let i = 1; i < clips.length; i++) {
      const outLabel = i === clips.length - 1 ? "aout" : `ax${i}`;
      filterParts.push(`[${lastAudioLabel}][${i}:a]acrossfade=d=${transitionDuration}[${outLabel}]`);
      lastAudioLabel = outLabel;
    }
    mapArgs.push("-map", "[aout]");
  }

  const args = [
    "-y",
    ...inputArgs,
    "-filter_complex", filterParts.join(";"),
    ...mapArgs,
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    ...(allHaveAudio ? ["-c:a", "aac"] : []),
    outputPath,
  ];
  await runFfmpeg(args);
}

/**
 * Same caption burn-in as composeCollage, but for exactly one clip — nothing to crossfade with,
 * used only as finalizeCollageAnimation's fallback when every item but one failed.
 */
async function composeSingleClip(clip, outputPath) {
  const tmpDir = path.dirname(outputPath);
  const { width, height } = await probeVideoSize(clip.path);
  const chipPath = await renderCaptionChip({
    title: clip.title,
    dateText: clip.dateText,
    fontSizeTitlePx: Math.round(height * 0.042),
    fontSizeDatePx: Math.round(height * 0.026),
    maxTextWidth: Math.round(width * 0.6),
    outputPath: path.join(tmpDir, "chip_0.png"),
  });

  const inputArgs = ["-i", clip.path];
  const filterParts = chipPath
    ? [`[0:v][1:v]overlay=x=main_w*0.05:y=main_h-overlay_h-main_h*0.05[vout]`]
    : ["[0:v]null[vout]"];
  if (chipPath) inputArgs.push("-i", chipPath);

  const hasAudio = await probeHasAudio(clip.path);
  await runFfmpeg([
    "-y",
    ...inputArgs,
    "-filter_complex", filterParts.join(";"),
    "-map", "[vout]",
    ...(hasAudio ? ["-map", "0:a"] : []),
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    ...(hasAudio ? ["-c:a", "copy"] : []),
    outputPath,
  ]);
}

/**
 * Adds `musicPath` (a generated audio track, already requested at the video's own duration — see
 * renderCollageMusic.js) onto `videoPath` as background music, writing the result to
 * `outputPath`. If the video already has its own audio (per-item Wiro clips can — see
 * composeCollage's allHaveAudio), the two are mixed (music turned down to sit behind it) rather
 * than one replacing the other; otherwise the music becomes the video's only audio track. Video
 * stream is copied untouched (`-c:v copy`) — only audio is (re-)encoded, so this is fast
 * regardless of how long composeCollage's own re-encode took.
 *
 * Wiro's own returned track can come back a little short or long of the `duration` it was asked
 * for. `-stream_loop -1` on the music input (before ITS `-i`, so only that input loops — the
 * video input is untouched) restarts the track from the beginning as many times as needed to
 * outlast the video, rather than leaving the tail of the video silent; the output-level `-t`
 * then hard-caps the result at the video's real length either way, so a track that came back
 * long just gets cut off at the end like before, and one that came back short loops seamlessly
 * instead.
 */
async function addBackgroundMusic({ videoPath, musicPath, outputPath }) {
  const [duration, hasExistingAudio] = await Promise.all([probeDuration(videoPath), probeHasAudio(videoPath)]);
  const args = hasExistingAudio
    ? [
        "-y", "-i", videoPath, "-stream_loop", "-1", "-i", musicPath,
        "-filter_complex", "[1:a]volume=0.5[bg];[0:a][bg]amix=inputs=2:duration=first:dropout_transition=2[aout]",
        "-map", "0:v", "-map", "[aout]",
        "-t", duration.toFixed(3),
        "-c:v", "copy", "-c:a", "aac",
        outputPath,
      ]
    : [
        "-y", "-i", videoPath, "-stream_loop", "-1", "-i", musicPath,
        "-map", "0:v", "-map", "1:a",
        "-t", duration.toFixed(3),
        "-c:v", "copy", "-c:a", "aac",
        outputPath,
      ];
  await runFfmpeg(args);
}

module.exports = { composeCollage, composeSingleClip, probeDuration, probeHasAudio, addBackgroundMusic };
