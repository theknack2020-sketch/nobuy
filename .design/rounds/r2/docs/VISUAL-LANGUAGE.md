# NoBuy v2 — Visual language grammar (Escapement)
The product renders a repeating domain object (the day, in five truths) — so this grammar is REQUIRED and binding. tokens/tokens.json is the single source; the gate ran before any screen was drawn (M-12).

## Fixed grammar
- **Canvas:** iPhone 393pt / 430pt portrait; iPad 834pt portrait, 1194pt landscape (regular-width layouts pin the dial left, the well right; same slots).
- **Field:** surface.field carries the room; surface.dial is the one raised value (the face); surface.well is the one recessed value (complications). Three surfaces, no more.
- **Ground element:** the bezel hairline ring — every time object sits inside one.
- **Subject box:** the day dial owns the upper half of Today; the question sheet is the only element on surface.dial white; nothing else may sit on dial-white on that screen.
- **Subject scale:** countXL 78pt on Today; dials 266pt (Today), 290pt (urge), 118pt (stats), 104pt (paywall gauge), 24pt (bezel minis).
- **Stroke doctrine:** hairline 1 / minor 1.5 / major 2 / hand 3 / arc 4 — never other weights.
- **Corner language:** circle = time · capsule = action · 12 = sheet · 6 = day cell · 0 = ruled list.
- **FORBIDDEN:** drop shadows, blur/glass, gradients-as-decoration, raster texture, red-means-bad, green-means-good, confetti/particles, a fifth tab, conditional chrome, emoji, exclamation marks, hardcoded prices, lock/crown imagery, checkmark/cross comparison grids.

## Palette — one job per token (measured, light / dark)
- ink.primary — all reading text: 12.39 / 14.17 on field; 11.59 / 13.47 on well.
- ink.secondary — captions, remainders: 5.18 / 7.19 on field; 4.84 / 6.84 on well.
- accent.kept (blued steel / lume) — the answered-kept truth + the one primary action: 6.26 / 12.73 on field; 6.92 / 11.76 on dial; 5.85 / 12.10 on well (mark use).
- accent.spentText — spent-day text: 5.43 / 6.95. accent.spentMark — spent block (>=3:1 graphic): 4.57 / 6.42 on dial.
- state.wait — mandatory, frozen, any wait in progress (>=3:1 graphic): 3.91 / 5.02 on dial.
- ink.onAccent on accent.kept — 6.92 / 12.73.
- ink.hairline — 1.55 / 1.37 on dial; 1.40 / 1.48 on field (threshold 1.2; subtle is the decision, invisible is banned).
- Themes: five finishes swap surface.* only — worst measured pair across all finishes: ink 11.72, kept-on-dial 6.71, lume 12.67. All pass.

## The single legibility law (M-02)
**Ink and accents sit only on field, dial or well; nothing textual ever sits on an accent except ink.onAccent, and no accent ever touches another accent.** Obey it and every pair above holds.

## Category vs state
Day-truths are STATES: mark geometry + colour, always both (M-15). Themes are FINISHES: surface swap only. Accents never encode category; the waiting list, mandatory logs and freezes all borrow state.wait + their own glyph.

## Component vocabulary — formulas
- Day tick (kept): 3.5×14 r2 kept. Mandatory: 3.5×10 tick + 4×4 dot, gap 1. Spent block: 9×12 r1.5 spentMark. Frozen: 8×14 hollow, 2pt wait wall, r4. Not-yet: 3×9 r2 hairline-colour. Cell: 46pt h, r6, 1pt hairline, numeral 12 top-centre; today adds the 8×5 index triangle notched over the top edge and a 1.5pt ink border.
- Dial: bezel r = size/2 − 7; majors at 30° (24h) or 36° (10min), y 10→20; minors at half-pitch, y 10→16; numerals dialNumeral at r−26; arc r = bezel−22, arc 4pt round; rim hand from r−80 to r−108 + 3.5pt counterweight dot; index triangle 12×10 at 0°.
- Complication row: 44-47pt, 22pt bezel mini (r10, 2.5pt arc), label row 13.5, detail remainder 12.5.
- Interval bar: h 10 (7 in dense), r5; settled = wait-colour; open = kept + open end; length = days/best × rail width.
- Week rate rail: 24pt column, cellNumeral, counts no-spend days only.

## Combination rules — draw order
field → well slabs → dial faces (bezel, ticks, numerals) → arcs → hands/index → marks → text → notice line. Marks never overlap text; arcs never cross the bezel; the index triangle is always topmost on its dial.

## Accessibility variant — substitution map
- Reduce Motion: beat → crossfade 200ms (hand pre-seated); sheet rise → fade; skeleton shimmer → static.
- Increase Contrast: hairline → ink.secondary at 1pt; state.wait marks → ink.primary outlines; scrim +15%.
- Differentiate Without Colour: already true (geometry channel); spent block additionally gains a 1pt ink outline.
- Dynamic Type XXXL: cells grow to 56pt, numeral floor 12; countXL floor 56 via @ScaledMetric; rows wrap to two lines before truncating; the well scrolls before the question sheet ever shrinks.
- VoiceOver order (per screen) is drawn in each screens/*.dc.html caption block; decorative marks are hidden, every state is spoken text ("kept", "spent — takeaway, tired after work", "frozen", "not yet answered").

## Material specification (M-14)
The silver is procedure, not texture: value steps only — dial +1 step above field, well −1 below, separated by 1pt hairlines; "silvering" is the discipline of tick pitch and numeral placement, never a gradient or grain. Lume is a colour swap at nightfall, not a glow: no shadows, no blur; its "glow" is contrast arithmetic (12.73:1 on the night field). Accumulation: marks accumulate in cells and rails; nothing ever stacks or overlaps. Failure mode: below 160pt (widgets) minors drop first, then numerals; bezel, index, hand, arc and count never drop.

## How asset N+1 is made
1. Name the variable it encodes and its direction. 2. Pick the object from the closed set (docs/OBJECT-MANIFEST.md) — if none fits, the SET grows first, with a new manifest row. 3. Draw with the stroke doctrine and corner language above. 4. Add the non-colour channel. 5. Measure its pairs against the gate; append to _meta.contrastPairs. 6. Show it at 80 and 44px on both grounds before it ships.
