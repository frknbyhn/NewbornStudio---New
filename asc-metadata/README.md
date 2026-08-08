# App Store Connect metadata

**Status: live in App Store Connect.** These were originally staged locally while ASC was under maintenance, then pushed via the App Store Connect API once it came back (app `com.BabyCollages` / id `6799130521`, "Baby Collages" in ASC — user-facing name now "Newborn Moments: Baby Photo AI" per locale). One JSON file per locale here, matching ASC's locale codes, kept as the source of truth for future edits — re-run the same sync approach (appInfoLocalizations + appStoreVersionLocalizations via the ASC API) if these files change.

Note: ASC's locale codes differ slightly from these filenames in three cases — `en` → `en-GB` (this app's primaryLocale), `ar` → `ar-SA`, `nl` → `nl-NL`. Verified via the API's own validation error when the plain codes were rejected.

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

**Still open:**
- Confirm the Portuguese variant (European `pt-PT` vs. Brazilian `pt-BR`) is the right call — `pt-PT` is what's live.
- Everything else (name/subtitle/keywords/promotional text/description/Privacy Policy URL) is live for all 33 locales as of this pass — verified with a follow-up GET against the API showing zero locales with a missing field.
