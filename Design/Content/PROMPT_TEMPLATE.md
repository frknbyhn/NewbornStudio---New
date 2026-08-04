# Wiro prompt formula for theme_catalog.json

Each style in `theme_catalog.json` stores a short **descriptor**, not a full prompt. The full
prompt sent to Wiro's `google/nano-banana` (image-to-image, `inputImage` = the user's uploaded
baby photo) is built at generation time from this formula:

```
Transform the uploaded baby photo into a professional AI-generated studio portrait.
Theme: {style.name} — {style.descriptor}.
Mood: {category.mood}.
Preserve the baby's exact face, expression, proportions and skin tone from the original
photo; only change styling, outfit, props and background to match the theme.
Soft, warm, professional studio-portrait lighting, photorealistic, high detail,
no text, no watermark, no logos, safe and wholesome, no adult content.
```

Why a formula instead of 300 hand-written paragraphs: every prompt needs the same non-negotiable
constraints (preserve the baby's actual face/likeness, no watermark, safe content) — writing
those by hand 300 times is how one of them quietly drifts and a bad prompt ships. The formula
guarantees every style carries them. The **only** creative content that has to be authored per
style is the one-line descriptor, which is what actually needs a human/AI's judgment.

`category.mood` and `style.descriptor` are the only two knobs. `aspectRatio` is fixed at `3:4`
(the app's portrait card ratio) unless a style benefits from otherwise.

## Worked examples

**Fantasy & Fairytale → Dragon Rider**
> Transform the uploaded baby photo into a professional AI-generated studio portrait.
> Theme: Dragon Rider — in tiny dragon-scale armor beside a toy dragon.
> Mood: dreamy, magical, enchanted fairytale atmosphere.
> Preserve the baby's exact face, expression, proportions and skin tone from the original
> photo; only change styling, outfit, props and background to match the theme.
> Soft, warm, professional studio-portrait lighting, photorealistic, high detail,
> no text, no watermark, no logos, safe and wholesome, no adult content.

**Seasonal — Winter & Christmas → Little Santa**
> Transform the uploaded baby photo into a professional AI-generated studio portrait.
> Theme: Little Santa — wearing a mini santa suit and hat.
> Mood: cozy, festive, warm holiday glow.
> Preserve the baby's exact face, expression, proportions and skin tone from the original
> photo; only change styling, outfit, props and background to match the theme.
> Soft, warm, professional studio-portrait lighting, photorealistic, high detail,
> no text, no watermark, no logos, safe and wholesome, no adult content.

**Professions → Tiny Doctor**
> Transform the uploaded baby photo into a professional AI-generated studio portrait.
> Theme: Tiny Doctor — in a white coat holding a toy stethoscope.
> Mood: cheerful, playful, pretend-career charm.
> Preserve the baby's exact face, expression, proportions and skin tone from the original
> photo; only change styling, outfit, props and background to match the theme.
> Soft, warm, professional studio-portrait lighting, photorealistic, high detail,
> no text, no watermark, no logos, safe and wholesome, no adult content.

## Where this goes next

- **Not wired into the app yet** — `ThemeCard.samples` in the Xcode project still has 6 hardcoded
  placeholder themes. This catalog is content planning only, per the user's instruction to hold
  off on generating style preview images.
- Phase 6 (backend): this JSON seeds the Firestore `ai_models` collection — one document per style,
  `category`, `name`, `descriptor`, computed `prompt` (or compute it server-side from the formula
  at generation time so a template tweak doesn't require re-seeding 300 documents).
- Phase 6.5 (admin panel), if ever needed: editing `category.mood` or a style's `descriptor` should
  be enough to retune an entire category's tone without touching code.
