# DESIGN ACCEPTANCE — NoBuy v2.0.0

**Direction:** ESCAPEMENT — waiting made mechanical
**Rounds:** 1 (directions, 3 candidates) + 2 (full package) + widget addendum
**Design project:** NoBuy · `7cb929ac-3aff-4109-8da1-eeed6f3b9d04`
**Accepted:** 2026-08-12
**Package:** `.design/rounds/r2/` (46 files, manifest cross-check 30/30 resolve)

## Verdict: ACCEPTED — build may start

`checklists/HANDOFF_ACCEPTANCE.md` + `profiles/ios.md` ACCEPTANCE run in full. No 🔴 open.

| Check | Result |
|---|---|
| Manifest ↔ files cross-check | ✅ 30/30 paths resolve |
| All briefed screens present | ✅ 8 screens × 5 states |
| Direction named + reasoned | ✅ chosen by owner from 3, corrections applied |
| Onboarding (3–5 + permission moment, both modes) | ✅ 4 screens + priming after day one is kept + refused path |
| Onboarding & paywall at the HIGHER bar | ✅ paywall in 5 states incl. StoreKit loading + error + already-subscribed |
| Paywall states WHERE THE USER STANDS | ✅ "you turned the record back past 90 days; yours holds 143" — no ✓/✗ grid, no lock, no countdown, dismiss is the first element |
| Product-completeness surfaces | ✅ edit + delete + undo (waiting item sheet), permission card + refused path, one mechanism per capability |
| Token extractability | ✅ `tokens/tokens.json` with `_meta.accent_contract`, `legibility_law`, `contrastPairs` |
| Measured contrast | ✅ **26 pairs, 0 fail** (`contrast_check.py`) |
| Every screen: first-run · empty · loading · error · dense | ✅ (Stats declares error N/A + why) |
| Dark mode as its own composition | ✅ "nightfall, not inversion" — exemplar frames + declared token map |
| Widget family (raised to 🔴 by addendum) | ✅ 4 families × 2 states, tint + full colour, interaction end-to-end, StandBy, VoiceOver |
| 3 icon concepts at real sizes | ✅ concepts 1–3 at 1024/120/80/40 on both grounds; recommends concept 2 |
| Brand marks | ✅ wordmark + 3 lockups |
| App Store panels | ✅ 6 @ 6.9" with marked wells; zero paywall/price/lock |
| Feedback spec names the SILENT moments | ✅ `docs/FEEDBACK.md` |
| Realistic content throughout | ✅ the 143-day record, the truthful July, real waiting items |

### Two things carried into build rather than back into a revision round

1. **iPad screens not drawn.** The package states the regular-width law in
   `docs/VISUAL-LANGUAGE.md` (dial pinned left, well right, same slots) and `tokens/panels.schema.json`
   carries the iPad 13" block. `HANDOFF_ACCEPTANCE` accepts "a design OR a clear adaptation rule",
   so this passes — but the rule is UNPROVEN until it runs. **Build obligation:** verify both form
   factors in the simulator (`snapshot_ui` + `screenshot`, iPhone and iPad) before the ship review.
   If the rule does not hold, that is a revision, not a build improvisation.
2. **A field mismatch was fixed on intake, not by the round.** `tokens.json` declared each
   contrast pair's threshold as `"need"`; `contrast_check.py`'s documented schema reads `"min"`.
   Unnormalised, the gate applied the 4.5 text threshold to hairlines and reported 5 FALSE reds —
   a gate that is red for the wrong reason gets ignored, which is worse than one that is silent.
   Normalised on intake (13 pairs), re-run: 26 pass / 0 fail. The round's contrast claim was
   correct all along.

## Owner rulings applied after the round

- **Free tier / Pro split.** The round drew Pro as three rows; the owner widened it (analysis
  layer, challenges, unlimited categories, unlimited freezes) because three rows is a thin offer
  at $4.99/month. The FREE tier is unchanged from the round — the 90-day window and three waiting
  slots stay, because the paywall's standing moment is built on them and free CSV export keeps
  the data honestly un-hostage. Recorded in `docs/FREE-TIER.md`.
- Direction pick: **1b Escapement**, listed second of three with the dispatcher's argued
  alternative listed LAST — no M-18 ordering caveat applies.

## FINGERPRINT

Direction: NoBuy — Escapement (2026-08-12, type A, iOS)

- Palette family + hue anchors: silvered greys, LIGHT-primary (field `#E8EAE7` / dial `#F4F5F1`);
  dark is nightfall not inversion (field `#0F1113`). One kept-accent that changes WORLD rather
  than job: blued steel `#33567E` by day, lume `#D3D8A4` by night. Spent = copper (`#A65B41`
  mark / `#8F4A33` text). Deliberately NOT green-means-good — mint-on-white was measured at
  1.68:1 and rejected as the generic-wellness trap the brief named.
- Type pairing (personality): SF Pro only. Display Semibold tabular = counts; Display Medium =
  dial numerals; Text = chrome. No mono, no serif, no count below weight 600.
- Layout topology: four rooms (Today / Calendar / Stats / Settings); the interventions and the
  waiting list enter FROM Today, never a fifth tab; the paywall is a door, not a room. Fixed
  slots everywhere — nothing appears or disappears, an unused freeze is a rendered slot.
- Motif / material metaphor: the escapement — waiting made mechanical. Ten minutes of urge,
  twenty-four hours of a wanted thing and the day closing at midnight are one sweep on one
  silvered geometry.
- Signature move: THE SWEEP — the arc of elapsed waiting, closing clockwise against ticks, with
  the numeric remainder always printed; the hand SEATS into its index on answer (one overshoot,
  spring 0.55/0.75) and that is the product's only expressive beat. On the Lock Screen the hues
  die by system rendering, so the accessories are drawn hue-blind: arc length, terminal gap,
  seated-hand glyph, filled/block/hollow silhouettes.
- Divergence note: the silvered-horology register — bezel + index + seated hand, blued-by-day /
  lume-by-night accent swap, copper as the spent fact — is TAKEN for NoBuy. Future products must
  not reprise dial-as-progress with a seating hand, nor the day/night accent swap on one token.
  Deliberately outside: warm-paper/folio, porcelain-cobalt, settle-gap concrete, water-level
  petrol/sage, crumb/warm-food, cold navy enamel, dark instrument cockpits, silver-gelatin photo.

## Open questions deferred to build (not blockers)

- Icon: the round recommends concept 2 (The Seated Hand); owner confirmation at production.
- Reminder default 21:30 — confirm or make it the permission card's one question.
- Achievements: the v2 IA gives them no room; the round flagged this rather than silently
  dropping them. Current code ships 12 and they are FREE — decide at build whether they keep a
  quiet home in Stats ▸ intervals or leave v2.
