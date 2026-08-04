# Progress

## Phase 0 — Setup
- [x] Machine scan: Xcode 26.2, git, ascelerate (logged in), Firebase CLI (logged in as frknbyhn@gmail.com) all ready.
- [x] Firebase project linked: `newborn-studio` (existing project, reused).
- [x] `functions/` + `public/` scaffolded, `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` created.
- [x] `.env` with Wiro credentials, `.gitignore` covering secrets/build artifacts.
- [ ] gcloud not logged in yet — needed later for Blaze billing check.
- [ ] `git init` + first commit — next step.

## Phase 1 — Idea & Scope
- [x] App idea, tech stack (Swift/UIKit, iOS 15+), AI provider (Wiro) confirmed.
- [x] Monetization structure confirmed (see DECISIONS.md) — prices for weekly/yearly subscription and all credit packs still open.
- [x] Name + bundle id confirmed (kept from existing ASC record).
- [ ] Main screens / social layer question still open.

## Phase 2 — Design
- [ ] Blocked: user referenced a Claude Design project ("Newborn Studio", id `9c003995-88f6-4dd1-bd8a-ac345052d187`) that does not appear in `DesignSync list_projects` (only "Modernist" is visible). Waiting on user to confirm/share the correct project.

## Open questions for the user
1. Which Claude Design project has the actual screens — "Modernist", or another one not yet shared with me?
2. Weekly and yearly subscription prices (only monthly $14.99 given so far).
3. Prices (not just credit amounts) for the small/medium/big/limited credit packs.
4. Main screens beyond the core upload→theme→generate→result flow — any gallery/history, social/discover layer, or is it fully personal/private?
