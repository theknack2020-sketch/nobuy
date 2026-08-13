# HANDOFF_MANIFEST — NoBuy v2.0.0 (round 2)
## Chosen direction
**ESCAPEMENT — waiting made mechanical.** Owner-chosen 2026-08-12 from round 1. Corrections 1-3 applied (calendar re-solved as the timing sheet; horological distance stated and drawn; density proof on Today). Graft carried as a measure: ended runs are permanent settled intervals (Stats).

## Files produced this run
### Tokens (first — M-12 gate ran before any screen)
- tokens/tokens.json — semantic colours light+dark, five theme finishes, type roles, spacing, radii, strokes, shadow doctrine, motion; _meta.accent_contract, _meta.legibility_law, _meta.contrastPairs. Gate: ALL pairs pass (worst graphic 3.91:1 vs 3; worst text 4.84:1 vs 4.5).
- tokens/panels.schema.json — store panel compose geometry, iPhone 6.9" + iPad 13" blocks.

### Screens (screen · 5 states, light drawn per state; dark = exemplar frames + declared token map)
- screens/today.dc.html — first-run / quiet / rollover(loading) / unanswered(error) / dense ×2 modes (10 phones). Corrections 2+3 carried here.
- screens/calendar.dc.html — first-run / empty(pre-record) / loading / error(the truthful July, 19-6-3-1-2) / dense; dark exemplars. Correction 1 carried here.
- screens/stats.dc.html — standard / first-run(empty) / dense(26 runs) / loading; error N/A + why. The M-09 measure drawn.
- screens/settings.dc.html — free default / LIFETIME OWNER (the 60, "Early supporter") / subscriber + permission-refused path / restore error + loading.
- screens/onboarding.dc.html — 4 first-run screens + the permission moment (after day one is kept) + refused path; ends inside the product.
- screens/paywall.dc.html — limit-reached / neutral(from Settings) / StoreKit loading / StoreKit error / already-subscribed. Standing slot fixed; trial sentence complete; no grid, no lock, no urgency. (Addendum reconciliation: the widgets row REMOVED from the Pro list — Pro is now full record · five dials · open waiting list.)
- screens/impulse-checklist.dc.html — fresh / in-progress / verdict / edit+dense (custom questions with remove+undo).
- screens/urge-surfing.dc.html — idle / running / done / interrupted(error).

### Components & system
- components/inventory.dc.html — component vocabulary with states (answer pair, day cell ×7 forms, complication rows, price capsules, notices, freeze chips, waiting-item edit sheet + undo toast, interval bars, toggle, swatches, dial anatomy), type scale + spacing, THE WIDGET FAMILY (Home small+medium, Lock circular+rectangular, light+dark, interactive mark-today), and the LEGIBILITY PROOF (object set at 80px and 44px on both grounds).
- components/widgets.dc.html — 🔴 ADDENDUM BOARD: all four families (.systemSmall, .systemMedium, .accessoryCircular ~76pt, .accessoryRectangular) in unanswered + answered states; pending render (the ~1 s between tap and reload); first-run (the question, not a zero); Lock families in FULL COLOUR and TINT MODE side by side with the meaning channel named (arc gap, seated hand, filled/block/hollow silhouettes); one-vs-two answers decided (Home: both; Lock: read-only deep link, with the reason); editability said in the widget's own words; StandBy night mode (red-on-black); VoiceOver order + labels + hints per family; platform rules (system containerBackground, no animation — the beat lives only in the app, budgeted refresh with rounded "~" remainders). Widgets ship FREE — no Pro wording anywhere in the family.

### Identity
- icon/concept-1.svg · concept-2.svg · concept-3.svg (flat vector, ~1-2 KB each)
- icon/board.dc.html — each at 1024/120/80/40 on light + dark home strips; recommendation: concept 2 (The Seated Hand); why 1 and 3 fail at 40px stated.
- assets/wordmark.svg · lockup-horizontal.svg · lockup-stacked.svg · lockup-single-ink.svg (~1 KB each)

### Store
- store/panels.dc.html — 6 panels @ 6.9" ratio, marked screenshot wells; P4 = free widget family working, P5 = Pro (finishes) shown unlocked; no paywall/price/lock anywhere.
- store/CAPTIONS.md — shipped captions + rejected lines.

### Docs
- docs/VISUAL-LANGUAGE.md (grammar, palette jobs + measured ratios, the one legibility law, category-vs-state, component formulas, draw order, accessibility substitution map, material as procedure, asset N+1 procedure)
- docs/OBJECT-MANIFEST.md (closed set of 12 + coverage table)
- docs/BRAND.md · docs/FREE-TIER.md · docs/FEEDBACK.md · docs/USER-CONTENT.md (N/A + why) · docs/DESIGN-RATIONALE.md (corrections, graft, arbitration, brave-choice table, deliberate absences) · docs/HANDOFF.md (build order, silent-break list, motion params, measured acceptance, guardrails)
- Round 2 — Escapement.dc.html — package index
- docs/HANDOFF_MANIFEST.md — this file

### Carried from round 1 (unchanged)
- docs/ROUND1_DIRECTIONS.md · Round 1 — Directions.dc.html · directions/* (three candidate boards)

## Not produced, because…
- **Per-state dark frames beyond exemplars** — dark differs by token substitution only (no layout deltas by design); each board declares the exact map on a dedicated card. Drawing 40 more identical frames would add risk, not information.
- **Full iPad screen set** — the regular-width law is stated in VISUAL-LANGUAGE (dial pinned left, well right, same slots) and the store schema carries the iPad panel geometry; a drawn iPad set is round-3 work if the owner wants it before build.
- **Per-component @dsCard files** — this environment renders component previews from a single live inventory board; the brief's intent (every piece, all states, one place) is met there. Split-out cards can be generated mechanically from the inventory if the owner's pipeline requires the marker format.
- **Live animation prototypes** — motion is specified numerically (spring 0.55/0.75 ×1 overshoot; 200ms functional; RM substitutes) per the technical frame: the HTML is never shipped, so parameters, not playback, are the deliverable.
- **Achievement surfaces** — round-1 scope listed plain-named achievements; v2 IA gives them no room (Stats holds three claims). Flagged as an open question rather than silently added.

## Open questions for round 3
1. Free-tier numbers to confirm: 90-day window and 3 waiting slots (both drawn everywhere; cheap to change now, expensive after build).
2. Icon: confirm concept 2, or run the 40px test on a real device grid.
3. Reminder default 21:30 — confirm, or make it the one question in the permission card.
4. Achievements ("Seven days", "A full month"): drop for v2, or give them a quiet home in Stats ▸ intervals?

## Round 2 addendum — accepted and closed
The widget family was raised to 🔴 and delivered as components/widgets.dc.html (acceptance items all drawn: four families × two states, tint + full colour, interaction end-to-end, first-run + free states, VoiceOver, StandBy). Consequence applied package-wide: widgets moved to the free tier — paywall Pro rows, store panel P4/P5 roles and docs/FREE-TIER.md updated in the same pass.

## READY FOR HANDOFF
All paths above exist as files. Build starts at tokens/tokens.json; docs/HANDOFF.md carries the order and the silent-break list.
