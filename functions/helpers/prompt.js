// Mirrors Design/Content/PROMPT_TEMPLATE.md exactly. Keep both in sync if this changes.
function buildPrompt({ styleName, descriptor, mood }) {
  return (
    `Transform the uploaded baby photo into a professional AI-generated studio portrait. ` +
    `Theme: ${styleName} — ${descriptor}. ` +
    `Mood: ${mood}. ` +
    `Preserve the baby's exact face, expression, proportions and skin tone from the original ` +
    `photo; only change styling, outfit, props and background to match the theme. ` +
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

module.exports = { buildPrompt, buildCategoryPrompt };
