const ffmpegPath = require("ffmpeg-static");
const ffprobePath = require("ffprobe-static").path;
const { spawn, execFile } = require("child_process");
const fs = require("fs");
const path = require("path");

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

// ffmpeg drawtext's `text=`/`textfile=` values are filter-graph syntax, where a raw title (user
// typed, could contain anything) would need careful escaping of `:`, `'`, `\`, `%`, newlines,
// etc. — a real source of bugs. Writing each caption to its own tiny textfile and pointing
// drawtext's `textfile=` at that sidesteps all of it: the ONLY thing that still needs escaping
// is the file PATH itself inside the filter string, and since these are our own auto-generated
// tmp paths (UUID-based, forward slashes only, no quotes/colons), that's a non-issue in practice.
function writeCaptionFile(dir, name, text) {
  const filePath = path.join(dir, name);
  fs.writeFileSync(filePath, text || "", "utf8");
  return filePath;
}

/**
 * Concatenates `clips` (in order) into one video at `outputPath`, with:
 *   - a crossfade transition between each consecutive pair (video via xfade, audio via
 *     acrossfade — but only if EVERY clip actually has an audio stream; if even one doesn't,
 *     the whole output is rendered silent rather than risk a broken filter graph referencing a
 *     stream that isn't there),
 *   - each clip's own title + date burned in over a bottom scrim, matching what the old
 *     on-device MilestoneVideoRenderer used to show per item before this feature moved server-side.
 *
 * `clips`: [{ path, title, dateText }], already in final display order.
 */
async function composeCollage({ clips, transitionDuration = 0.5, outputPath }) {
  if (clips.length < 2) throw new Error("composeCollage needs at least 2 clips");
  const tmpDir = path.dirname(outputPath);

  const durations = await Promise.all(clips.map((c) => probeDuration(c.path)));
  const audioFlags = await Promise.all(clips.map((c) => probeHasAudio(c.path)));
  const allHaveAudio = audioFlags.every(Boolean);

  const inputArgs = [];
  clips.forEach((c) => inputArgs.push("-i", c.path));

  const filterParts = [];

  // Per-clip caption: a dark scrim across the bottom ~24% of the frame, title + date drawn over
  // it — same idea as the old renderer's gradient scrim + two-line caption, just a flat
  // semi-transparent band here since ffmpeg doesn't have an easy true-gradient primitive.
  clips.forEach((clip, i) => {
    const titleFile = writeCaptionFile(tmpDir, `title_${i}.txt`, clip.title);
    const dateFile = writeCaptionFile(tmpDir, `date_${i}.txt`, clip.dateText);
    const captionFilter =
      `[${i}:v]drawbox=x=0:y=ih-0.24*ih:w=iw:h=0.24*ih:color=black@0.45:t=fill,` +
      `drawtext=textfile='${titleFile}':fontfile='${FONT_PATH}':fontsize=h*0.058:fontcolor=white:x=(w-text_w)/2:y=h-0.165*h` +
      (clip.dateText
        ? `,drawtext=textfile='${dateFile}':fontfile='${FONT_PATH}':fontsize=h*0.036:fontcolor=white@0.85:x=(w-text_w)/2:y=h-0.09*h`
        : "") +
      `[v${i}]`;
    filterParts.push(captionFilter);
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
  const titleFile = writeCaptionFile(tmpDir, "title_0.txt", clip.title);
  const dateFile = writeCaptionFile(tmpDir, "date_0.txt", clip.dateText);
  const filter =
    `drawbox=x=0:y=ih-0.24*ih:w=iw:h=0.24*ih:color=black@0.45:t=fill,` +
    `drawtext=textfile='${titleFile}':fontfile='${FONT_PATH}':fontsize=h*0.058:fontcolor=white:x=(w-text_w)/2:y=h-0.165*h` +
    (clip.dateText
      ? `,drawtext=textfile='${dateFile}':fontfile='${FONT_PATH}':fontsize=h*0.036:fontcolor=white@0.85:x=(w-text_w)/2:y=h-0.09*h`
      : "");
  const hasAudio = await probeHasAudio(clip.path);
  await runFfmpeg(["-y", "-i", clip.path, "-vf", filter, "-c:v", "libx264", "-pix_fmt", "yuv420p", ...(hasAudio ? ["-c:a", "copy"] : []), outputPath]);
}

module.exports = { composeCollage, composeSingleClip, probeDuration };
