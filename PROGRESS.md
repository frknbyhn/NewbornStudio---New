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
- [x] Design pulled from Claude Design project "Newborn Studio App Design" (`9c003995-88f6-4dd1-bd8a-ac345052d187`) via `DesignSync get_file`, saved to `Design/Newborn Studio.dc.html`. Note: `list_projects` doesn't show this project because it's `PROJECT_TYPE_PROJECT`, not a design-system project — `get_project`/`list_files`/`get_file` by id work directly.
- [x] Tokens (colors, fonts, shape language) extracted into DECISIONS.md.
- [ ] Next: build `lib/app/theme` equivalent in Swift (colors, fonts, reusable button/card styles) from these tokens, then implement screens 1:1.

## Resolved
1. All subscription/credit-pack prices pulled live from ASC (see DECISIONS.md) using the `YC2YC44RMZ` API key. `com.newborn.monthly` needs to be created (Phase 7/9).
2. Photo Editor screen cut. Milestone Tracker confirmed private-only, no social layer anywhere in the app.
3. User approved moving forward — next: Swift/UIKit Xcode project scaffold + `Theme.swift` from the extracted design tokens.

## Phase 3 — Flutter Scaffold → adapted: Xcode Scaffold
- [ ] Not started yet.
