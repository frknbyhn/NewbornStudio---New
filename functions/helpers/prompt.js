// Mirrors Design/Content/PROMPT_TEMPLATE.md exactly. Keep both in sync if this changes.
//
// `allowPoseChange` (per-category flag in theme_catalog.json, e.g. "Firsts"/"Milestones") flips
// the preserve-clause: most categories (costumes, backgrounds, seasonal themes) genuinely want
// the baby's original expression/pose left alone — only styling should change. But a milestone
// like "First Laugh" or "Waves Bye-Bye" is BY DEFINITION asking for a different expression/pose
// than whatever the uploaded photo happens to show, and the default "preserve exact expression"
// instruction was directly fighting that: the model got two contradictory instructions in the
// same prompt (descriptor says "mid-laugh, eyes crinkled shut"; preserve-clause says keep the
// original expression) and either produced a muddled result or just ignored the descriptor.
// Scoped to a category flag rather than changed globally so the ~290 styles that already work
// well under strict preservation aren't put at risk of unwanted expression drift.
function buildPrompt({ styleName, descriptor, mood, allowPoseChange = false }) {
  const preserveClause = allowPoseChange
    ? `Keep the baby's facial identity recognizable — same face shape, eyes, and skin tone as ` +
      `the original photo — but adopt the exact expression and pose described in the theme ` +
      `below, even if that differs from the original photo. `
    : `Preserve the baby's exact face, expression, proportions and skin tone from the original ` +
      `photo; only change styling, outfit, props and background to match the theme. `;
  return (
    `Transform the uploaded baby photo into a professional AI-generated studio portrait. ` +
    `Theme: ${styleName} — ${descriptor}. ` +
    `Mood: ${mood}. ` +
    preserveClause +
    `Soft, warm, professional studio-portrait lighting, photorealistic, high detail, ` +
    `no text, no watermark, no logos, safe and wholesome, no adult content.`
  );
}

// A broader, category-level variant for cover images (not tied to one specific style).
function buildCategoryPrompt({ categoryName, mood }) {
  return (
    `Transform the uploaded baby photo into a professional AI-generated studio portrait ` +
    `representing the "${categoryName}" theme collection. ` +
    `Mood: ${mood}. ` +
    `Preserve the baby's exact face, expression, proportions and skin tone from the original ` +
    `photo; only change styling, outfit, props and background to fit the theme. ` +
    `Soft, warm, professional studio-portrait lighting, photorealistic, high detail, ` +
    `no text, no watermark, no logos, safe and wholesome, no adult content.`
  );
}

// Used for the Result screen's "edit this portrait" flow AND MilestoneCaptureViewController's
// own capture flow (a curated milestone's aiPrompt travels through here as `instruction`) — the
// source image is already the styled result/a plain uploaded photo, so this must ask for a
// targeted change rather than re-describing a whole theme from scratch.
//
// `allowPoseChange` — same reasoning as buildPrompt above: a free-text "edit this result" ask
// (e.g. "add a soft blue blanket") should leave the expression alone by default, but a standard
// milestone capture like First Laugh or Waves Bye-Bye IS the requested expression/pose change,
// so the default preserve-clause can't be allowed to override it. MilestoneCaptureViewController
// passes true only for its own curated-prompt milestones; every other caller keeps the old,
// stricter default.
function buildEditPrompt({ instruction, allowPoseChange = false }) {
  const preserveClause = allowPoseChange
    ? `Keep the baby's facial identity recognizable — same face shape, eyes, and skin tone — but ` +
      `apply the requested expression or pose change fully, even if it differs from the original photo. `
    : `Preserve the baby's exact face, expression, proportions and skin tone, and keep the ` +
      `overall studio-portrait style intact; only make the requested change. `;
  return (
    `Apply this specific edit to the uploaded studio portrait: ${instruction}. ` +
    preserveClause +
    `Photorealistic, high detail, no text, no watermark, no logos, safe and wholesome, no adult content.`
  );
}

// Used for the Result screen's "Animate Portrait" action (ResultViewController -> animateResult
// Cloud Function -> Wiro's bytedance/seedance-pro-v1-5, an image-to-video model). Per-style like
// buildPrompt (weaves in that style's own descriptor/mood), but a genuinely separate formula
// rather than a reused one: an image prompt describes a STATIC scene, a video prompt needs to
// describe MOTION within that already-fixed scene instead — reusing buildPrompt's wording would
// just re-describe the same still image, giving the video model nothing to animate.
//
// One formula for all 333 styles (not 333 hand-written motion descriptions) — same reasoning as
// the rest of this file: every prompt needs the same non-negotiable constraints (don't change
// what's already in the photo, keep motion subtle and safe), and the per-style descriptor/mood
// already carry everything scene-specific that a motion prompt needs to reference.
function buildAnimatePrompt({ styleName, descriptor, mood }) {
  return (
    `Bring this still studio portrait photo to life with subtle, natural motion — do not change ` +
    `the composition, styling, outfit, props or background from what's shown in the photo, only ` +
    `animate it. Scene: ${styleName} — ${descriptor}. Mood: ${mood}. ` +
    `Add gentle, realistic movement appropriate to the scene: soft breathing, slow relaxed ` +
    `blinking, small natural head or hand movement from the baby, and light ambient motion in ` +
    `the background or props if present (e.g. a slow drift, gentle sway, soft flicker of light). ` +
    `Camera stays mostly static, at most a very slow, gentle drift or push-in — no sudden or ` +
    `jarring movement. Keep the baby's exact face and identity unchanged throughout. ` +
    `Photorealistic, smooth, calm, safe and wholesome, no adult content.`
  );
}

module.exports = { buildPrompt, buildCategoryPrompt, buildEditPrompt, buildAnimatePrompt };
