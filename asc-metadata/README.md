# App Store Connect metadata (local staging)

App Store Connect was under maintenance when this was prepared, so these are staged locally — **not yet entered into ASC**. One JSON file per locale, matching ASC's locale codes.

Each file has 5 fields, matching ASC's own field limits:

| Field | Limit | Notes |
|---|---|---|
| `name` | 30 chars | App Name |
| `subtitle` | 30 chars | Subtitle |
| `keywords` | 100 chars | Comma-separated, no spaces after commas (saves characters). Deliberately avoids repeating any word already used in `name` or `subtitle` — Apple indexes those fields for search too, so repeating a word there wastes keyword budget. |
| `promotionalText` | 170 chars | Can be updated anytime without an app review |
| `description` | 4000 chars | Ends with Privacy Policy / Terms of Use links pointing at the hosted pages |

All 33 locales are done: `en` (base) + the 32 requested (Chinese Simplified and Traditional count as two separate ASC locales). `zh-Hant` was derived from `zh-Hans` via OpenCC's `s2twp` conversion (Taiwan-standard phrasing, e.g. 视频→影片), then hand-corrected for a couple of vocabulary spots OpenCC doesn't know about (宇航員→太空人, 想象力→想像力).

ASC locale codes used here differ slightly from the iOS in-app locale codes used in `Localizable.xcstrings`: `fr` → `fr-FR`, `de` → `de-DE`, `es` → `es-ES`, `pt` → `pt-PT` (European Portuguese — flag if Brazilian Portuguese was actually wanted), `nb` → `no`.

Validated programmatically (`check_asc.py`, not committed — lived in the session's scratch dir) for: character limits per field, and no word repeated between `name`/`subtitle`/`keywords`. All 33 files pass with zero hard violations.

**Still needed before going live:**
- Enter each locale's fields into App Store Connect once it's back online.
- Confirm the Portuguese variant (European vs. Brazilian) is the right call.
- Set the ASC "Privacy Policy URL" field itself (separate from the in-description link) to `https://newborn-moments.web.app/privacy.html`.
