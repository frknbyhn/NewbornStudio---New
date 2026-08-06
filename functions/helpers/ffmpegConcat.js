const ffmpegPath = require("ffmpeg-static");
const { spawn } = require("child_process");
const fs = require("fs");

// Concatenates a list of local mp4 files, in order, into one output file. Deliberately
// re-encodes (no `-c copy` stream-copy shortcut) — the clips all come from the same Wiro model
// call with the same settings so they SHOULD already share a codec/profile/timebase, but
// stream-copy concat is unforgiving of even a small mismatch (silently drops audio, corrupts the
// container, or fails outright) and there's no way to verify that guarantee holds for every
// Wiro response. A full re-encode is slower but always produces a valid file regardless.
function concatVideos(clipPaths, outputPath) {
  return new Promise((resolve, reject) => {
    const listPath = `${outputPath}.txt`;
    const listContent = clipPaths.map((p) => `file '${p.replace(/'/g, "'\\''")}'`).join("\n");
    fs.writeFileSync(listPath, listContent);

    const proc = spawn(ffmpegPath, [
      "-y",
      "-f", "concat",
      "-safe", "0",
      "-i", listPath,
      outputPath,
    ]);

    let stderr = "";
    proc.stderr.on("data", (d) => { stderr += d.toString(); });
    proc.on("close", (code) => {
      fs.unlinkSync(listPath);
      if (code === 0) resolve();
      else reject(new Error(`ffmpeg exited with code ${code}: ${stderr.slice(-2000)}`));
    });
    proc.on("error", reject);
  });
}

module.exports = { concatVideos };
