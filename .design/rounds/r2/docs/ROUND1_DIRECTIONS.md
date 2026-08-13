# NoBuy v2.0 — Round 1: Direction candidates
Date: 2026-08-12 · Round: 1 (direction) · Status: awaiting owner pick — chosen-direction slot in HANDOFF_MANIFEST.md is open.

Presentation: **Round 1 — Directions.dc.html** (all three, side by side, with verdict).
Candidates are ordered alphabetically; no preference is encoded in position (M-18).

## Structure, not skin (shared by all candidates)
- Four rooms: Today / Calendar / Stats / Settings. Urge timer, impulse checklist and the 24-hour waiting list are entered from Today, never a fifth tab. The paywall is a door, not a room.
- Paywall law: states the limit that was met in the user's own numbers; visible dismiss ("Not now", first element under the status bar); prices render from StoreKit ($4.99 monthly, $39.99 yearly, 7 days free); no comparison grid, no lock/crown, no countdown, no strikethrough.
- Five day-truths, fixed slots everywhere: no-spend, spent, mandatory-only, frozen, not-yet. Every state carries a non-colour channel (M-15). Nothing appears or disappears (M-05); an unused freeze is a rendered slot.
- The count is DAYS, never dollars. Waiting-list amounts (89, 220, 45) are user-volunteered notes, not app accounting.
- One expressive beat: the moment today is answered, on the object that changed, with a written Reduce Motion substitute (M-06).
- SF Pro + Dynamic Type to XXXL; touch targets >= 44pt (answer buttons 52-54pt); WCAG AA with measured numbers (M-03; method below).
- Shared content world: run 23 (kept 20 Jul - 11 Aug, last spent 19 Jul "takeaway, tired after work"), best 41, keeping since 22 March (143 days on record); July 2026 = 19 no-spend / 6 spent (2,6,9,13,16,19) / 3 mandatory-only (22,27,30) / 1 frozen (8) / 2 unanswered (5,11); waiting list: wireless earbuds — 89 (10 h left), second coffee grinder — 220 (tonight), linen shirt — 45 (resolved: skipped); paywall trigger: opening the record past the free 90-day window.

## Candidate policy: 3 + 2, self-eliminated (6.A.1)
Produced five, eliminated two:
1. **Mended Cloth** (woven record; a spent day visibly darned) — failed M-11: fourth craft register in a portfolio already holding three (Coneglow, Saponora, Ovenspring); its one great idea is an appearance and may not cross to a winner (M-09).
2. **Strata** (days deposited as sediment bands) — gravity-as-progress collides with Saponora's settle register (M-11), and compressing days into bands erases the calendar's first job: the shape the month makes.

Portfolio arbitration (M-11): taken lanes avoided — warm-paper/folio (Ethiopian Bible; TERSE, FAIZ, Pulse), porcelain-cobalt gloss/matte (Coneglow), settle-gap/one-shadow concrete (Saponora), water-level petrol/sage (Citora), crumb/warm-food with dark organic hero (Ovenspring), cold navy/nickel enamel (KoalaHood), dark instrument cockpits (RangePilot, COS), silver-gelatin photo (ROTORFALL). Registers occupied instead: household slate tally (1a), silvered horology (1b), banker's-paper ruled instrument (1c). Citora's Ultralight-200 oversized counts also avoided: no count below weight 600 in any candidate.

---

## 1a — DOORFRAME (thematic · dark-primary)
- **Point of view:** the household tally. Kept days are chalk strokes on the slate of a home you are keeping; the wall keeps every mark ever made — a run that ends is history, never erasure.
- **Signature — THE GATE STROKE (M-04):** variable = run length in completed bundles of five; direction = gates accumulate left-to-right as the run grows, salience rises monotonically with run length; second channel = geometry (diagonal gate vs standing stroke vs lying stroke); surfaces (>=3): Today (active bundle + gates), Calendar (wall of marks), Stats (runs as walls), paywall (record band), Home + Lock widgets. Jobs: shows run length, shows distance into current bundle, marks today's absence (dashed slot).
- **Brave choices:** Today — the good mark is chalk, not green; today is a dashed absence legible across a room. Calendar — the month is a wall, not a grid of chips; a spent day lies flat: still a mark, never a hole. Paywall — the limit stated as marks on the wall; dismiss first.
- **Type roles (M-16):** SF Pro only. Display Bold tabular = counts; Text 600 = questions/actions; letterspaced caps 10-11 = chrome. Marks, not type, carry the character.
- **Material as procedure (M-14):** a mark is a 4x28pt rounded bar rotated by hash(dayIndex) in [-2deg, +2deg] — deterministic hand-variance, no texture, no raster. The gate is a 44x4pt bar at -26deg spanning its four strokes. Failure mode: at Dynamic Type XXXL the wall keeps stroke size and wraps rows; strokes never shrink below 4pt.
- **States:** kept = standing chalk stroke · mandatory-only = standing stroke + base tick · spent = lying ochre stroke at baseline · frozen = hollow outlined stroke · not-yet = baseline notch.
- **Expressive beat:** answering draws today's stroke downward; it settles with one 2-degree overshoot. spring(response 0.38, dampingFraction 0.72). Reduce Motion: the stroke fades in at final position, 200 ms.
- **Themes (one token contract):** theme rotates `surface.wall` (green/blue/plum/umber/grey slates; matching plasters in light); `mark.chalk` and `mark.spent` never move.
- **Accent contract:** chalk = a kept day and the primary action; ochre/clay = the spent fact; everything else is geometry + neutrals.
- **Measured contrast (dark / light):** chalk on wall 13.45 · dim on wall 6.38 · ochre on wall 5.88 · hairline on wall 1.35 | graphite on plaster 10.35 · dim on plaster 5.34 · clay on plaster 5.09 · hairline on plaster 1.28. All pass (text 4.5, hairline 1.2).
- **VoiceOver (Today):** date → freeze status ("Freeze unused, August") → run summary ("23 days kept, best 41") → question → No (button) → Yes (button) → mandatory note → waiting summary → timer → tab bar. Marks decorative-hidden; the count is the accessible element.
- **Weakness (honest):** reads penal if the voice ever slips; stroke calendar trades instant date lookup for month-shape; chalk without texture risks flattening to a generic dark theme in screenshots.

## 1b — ESCAPEMENT (thematic-instrument · light-primary)
- **Point of view:** waiting made mechanical. Ten minutes, twenty-four hours, and the day closing at midnight are one sweep on one silvered geometry. Dark is nightfall, not inversion: the silver goes out and the marks glow lume.
- **Signature — THE SWEEP (M-04):** variable = elapsed fraction of a named wait; direction = arc closes clockwise toward completion, salience rises monotonically with elapsed time; second channel = angular position against ticks + the numeric remainder always printed; surfaces (>=3): day dial (Today), urge-surfing timer, waiting-list mini bezels, calendar ring, circular Lock Screen widget. Jobs: time left on every hold, day progress, month shape.
- **Brave choices:** Today — the day is a 24-hour dial; waits are complications with their own sweeps. Calendar — the month is a dial of 31 ticks; July's shape is a ring. Paywall — the free window is drawn on the same face as the record; the limit is a place, not a threat.
- **Type roles (M-16):** SF Pro only. Display Semibold tabular = counts; Display Medium = dial numerals; Text = chrome. No mono, no serif.
- **Material as procedure (M-14):** faces are flat fills separated by 1pt tick hairlines; the only depth is the dial's single bezel line. Ticks: 12 majors at 30-degree pitch (2pt), day ring at 360/31-degree pitch. Failure mode: below 160pt of width (widgets) minors drop, majors and arc remain.
- **States:** kept = long blued tick · mandatory-only = long tick + inner dot · spent = copper block · frozen = hollow capsule tick · not-yet = short hairline tick.
- **Expressive beat:** on answering, the day hand seats into its index with a single overshoot and the arc closes its final gap. spring(response 0.55, dampingFraction 0.75). Reduce Motion: crossfade open → seated, 200 ms.
- **Themes:** theme rotates `surface.dial` (silver, sector cream, slate, salmon, anthracite); hands (`accent.kept`: blued by day, lume by night) and `accent.spent` copper never move.
- **Accent contract:** blued/lume = the answered-kept truth and the one primary action; copper = the spent fact; grey-green neutral = mandatory, frozen, and any wait in progress.
- **Measured contrast (light / dark):** gunmetal on silver 12.39 · secondary 5.18 · blued on silver 6.26, on dial 6.92 · copper text 5.43 (mark 4.14 at 3:1 graphic) · tick on dial 1.55 | marker on night 14.17 · secondary 7.19 · lume 12.73 · copper 6.95 · tick 1.37. All pass at their real sizes.
- **VoiceOver (Today):** date → freeze → run summary → day-progress ("2 hours 18 minutes to midnight") → question → No → Yes → waiting items (name, remainder) → timer → mandatory → tabs. Arcs decorative-hidden; remainders are text.
- **Weakness (honest):** nearest to genre convention — rings are the habit-app's native gesture, and Apple's; the dial calendar is the weakest calendar of the three; complication density pulls against one-decision-per-screen.

## 1c — RULED OFF (neutral-premium instrument · light-primary)
- **Point of view:** the account book as instrument. Answering at night rules off the day's entry — the double rule a bookkeeper draws under a settled total. Absence is the heaviest ink on the page; the good colour is ink itself.
- **Signature — THE RULING (M-04):** variable = closure of the record (day, month, run); direction = single hairline (open) becomes double ink rule (settled), and as the run grows more of the record stands double-ruled — salience rises with what is settled; second channel = line count and geometry, never colour; surfaces (>=3): Today (under the count), Calendar (month foot), Stats (every ended run), paywall (under the standing figure vs the free window's single open hairline), both widgets. Jobs: open-vs-settled state, run accumulation, month closure.
- **Brave choices:** Today — the hero is a blank ruled line, the absence itself; text-only tab bar. Calendar — a ruled table, not chips; spent days are underlined entries, not warnings. Paywall — typeset like a statement of account; standing double-ruled, free window still open on a single hairline.
- **Type roles (M-16):** SF Pro only. 100pt Display Bold tabular figures = the record; Text 600 = question/actions; letterspaced small-caps = chrome. No serif, no mono.
- **Material as procedure (M-14):** the page is two values of paper (field + one sheet step); all separation is 1pt hairline rule; the double rule is 2pt + 4pt gap + 2pt, width = the figure it settles. Zero shadows anywhere. Failure mode: at XXXL the ruled entry grows with the line-height; rules stay 2pt, never scale.
- **States:** kept = solid ink square · mandatory-only = outlined square + inner point · spent = oxblood underlined entry (numeral + 2pt rule) · frozen = slate outlined square + top bar · not-yet = short hairline dash.
- **Expressive beat:** on answering, the second rule draws itself left-to-right under the day (320 ms, spring(response 0.42, dampingFraction 0.92)), then the count increments once, no bounce. Reduce Motion: the rule appears at full length, opacity 0 → 1, 180 ms.
- **Themes:** theme rotates `ink` — black, iron-gall blue #2B3A55, sepia #5C4632, drafting green #37503F, violet-grey #4A4256 (all >= 10:1 on paper); `surface.paper` and `accent.spent` oxblood never move.
- **Accent contract:** ink = the kept truth and the primary action (weight is the accent, not hue); oxblood = the spent fact; slate = mandatory, frozen, unanswered.
- **Measured contrast (light / dark):** ink on paper 14.94 · secondary 6.75 · oxblood on sheet 8.96, on field 8.27 · slate 4.77 · hairline on sheet 1.61 | night ink 15.02 · secondary 7.26 · oxblood 6.43 (6.91 on sheet: 5.91) · slate 5.49 · hairline 1.45. All pass.
- **VoiceOver (Today):** date → freeze held → "Today's entry, open" → question → No → Yes → run summary ("23 days kept, ruled off through 11 August, best 41") → waiting → timer → mandatory → tabs. Rules decorative-hidden; "open/settled" is spoken state.
- **Weakness (honest):** the coldest — relief must come entirely from voice and paper warmth; ink-as-the-good-colour can read on first open as no colour system at all. Demands flawless copywriting forever.

---

## Rejected pairings (recorded as evidence, M-03)
- mint #9BD4B8 on #FFFFFF — 1.68, fails text; also reads generic wellness (named trap in brief). Rejected.
- alarm red #E5484D on #FAF9F5 — 3.71, fails small text; reads as error, wrong semantics for a fact. Rejected.
- ochre #C98B4B on plaster #ECE9E1 — 2.38, fails; darkened to clay #8F5222 (5.09). Ochre kept for dark wall only (5.88).
- copper #A65B41 on silver #E8EAE7 as small text — 4.14, fails 4.5; kept as >= 3:1 graphic mark only; text uses #8F4A33 (5.43).
- 1b-L dim #6C6E66 on plaster — 4.26, fails; darkened to #5D5F57 (5.34).

Method: WCAG 2.1 relative luminance, computed programmatically for every claimed pair; pairs within 0.3 of threshold and all interactive-text pairs recomputed in a second pass (clay 5.09, slate 4.77, copper-text 5.43 confirmed).

## Deliberate absences (M-10) — do not "fix" later
No confetti, glow, or particles. No green-means-good anywhere. No charts on Today. No checkmark/cross comparison grid. No lock or crown imagery. No countdown or urgency on the paywall. No fifth tab. No account, cloud, bank or analytics UI. No emoji. No exclamation marks. Prices never typed into a view.

## Verdict
Weaknesses above, per candidate. **Recommendation: 1c Ruled Off** — the mission sentence made literal; the strongest answer to absence-made-substantial (the blank ruled line); the cleanest theme contract (five inks); the most mechanical SwiftUI translation; the furthest from every taken register. **One graft (M-09), a measure:** from Doorframe — "the wall keeps every mark": ended runs are never visually truncated or reset; they remain in Stats as settled, double-ruled totals. No appearance crosses.
