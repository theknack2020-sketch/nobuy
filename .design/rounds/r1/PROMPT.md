> **OWNER: paste everything below this line into the Claude Design chat for this project and run it.** (Round 1 · 3 candidates)

---

## 1. ROLE & MISSION

You are a world-class product designer with the taste of a design director who has
shipped award-winning work. You do not produce "safe defaults" — you produce work with
a clear, defensible point of view. Your mission:

> Redesign a no-spend day tracker so that answering one honest question at the end of the day feels like closing a ledger you are glad to keep — steady, adult, and entirely free of the cheerful gamification that makes money apps embarrassing to open in public.

## 2. PRODUCT CONTEXT

- **Product:** NoBuy is a no-spend day tracker for iPhone and iPad. Every evening the user answers one question — did I buy something unnecessary today? — with a single tap, and the app keeps the resulting streak of no-spend days. Mandatory expenses (rent, bills, transport, groceries) are logged separately and never break the streak, and one streak freeze per month covers a slip. Beyond the tally it carries three in-the-moment intervention tools no ranked competitor ships: a 10-minute urge-surfing timer, an impulse checklist, and a 24-hour waiting list where a wanted purchase sits before it may be bought. All data is local — no account, no bank connection, no analytics. It is live on the App Store (1.2.0, ~976 downloads, 0 ratings) and this round redresses it for v2.0.0, which also moves it from a one-time unlock to a monthly + yearly subscription with a 7-day trial.
- **This deliverable:** The whole product. Eight screens (Today, Calendar, Stats, Settings, Onboarding, Paywall, Impulse Checklist, Urge Surfing), the component set behind them, five selectable themes reduced to one token contract, the widget family that does not exist yet (Home Screen small + medium, Lock Screen circular + rectangular, with an interactive mark-today action), the app icon, and the App Store panel set. The five current themes are a product feature and must survive as token variants, not as five separate designs.
- **Platform & medium:** A native iPhone and iPad app opened once a day at night, occasionally opened mid-craving in a shop, and glanced at from the Home and Lock Screen without being opened at all.
- **Technical frame:** SwiftUI, iOS 17 minimum, Swift 6. Semantic colour tokens only — no view may reference a hex. SF Pro with Dynamic Type to XXXL; SF Symbols for chrome, authored flat vector SVG where a symbol cannot carry the meaning. Standard SwiftUI layout, shapes and spring animation only: no shaders, no custom render loops, no raster texture. WidgetKit for the peripheral surfaces (widgets get a restricted palette and no animation — design for that constraint, do not discover it later). Prices always render from StoreKit, never typed into a view.

### 2-P. TECHNICAL FRAME — ios profile

The medium's non-negotiables. Written once per profile in `claude-design/profiles/`
and injected by the compiler, because six of six real briefs hand-wrote this block and
the ones that skipped a line paid for it downstream.

Written by hand in 6 of 6 real runs before it became part of this template — which is why it
is here.

- Built in **SwiftUI** with semantic colour tokens. Every colour comes from `tokens.json`;
  **no view may reference a hex.** Design in tokens, not in swatches.
- **System type** (SF Pro / New York) unless a licensed face is named in §4. Type must respond
  to **Dynamic Type** — never a fixed point size for body copy.
- **SF Symbols for UI chrome**; custom vector only where a symbol cannot carry the meaning.
  Say which is which. Custom art ships as **flat vector SVG** (Xcode *Preserve Vector Data*).
- **No raster texture, no painterly/photographic surfaces, no gradients-as-decoration.** Imply
  material through shape, value and procedure (M-14), never through a bitmap.
- Only standard SwiftUI layout, shapes and spring animation. No shaders, no custom render loops.
- **The HTML you produce is never shipped.** Only the direction, the tokens and the measures
  cross into Swift. Build the deliverables so that translation is mechanical.

## 3. AUDIENCE & EMOTION

- **Who looks at this:** Adults who already know they overspend and have quit at least one budgeting app for being too much work. They arrive from the no-buy / underconsumption conversation, not from personal finance: they do not want categories, forecasts or a linked bank account, they want to stop buying things they will not remember next month. Mostly using the app at night, tired, deciding whether today counted — and occasionally opening it mid-craving, standing in a shop or holding a full cart on a phone.
- **Primary emotion on first sight:** Relief. The quiet, unglamorous satisfaction of a day where nothing was bought and nothing was lost — the product must feel like exhaling, never like being graded.
- **What they must be able to do in 5 seconds:** Answer today's one question and watch the record respond — the user must see, without reading, whether today is still open, already answered, and how long the run behind it is.
- **What this must NOT feel like:** Not a budgeting spreadsheet — no categories, charts-first dashboards or bank-app chrome. Not a gamified habit app — no cartoon mascots, no confetti storms, no badge-shower dopamine, no streak-guilt. Not a wellness/meditation product — no soft gradients, no rounded pastel blobs, no affirmational voice. Not a fintech startup landing page — no glassmorphism, no glowing crown or lock icons, no 'premium' theatre. And not a punishment ledger: a spent day is a fact, never a failure. The current build fails three of these five and that is the reason for this round.
- **Structure before skin — information architecture:** Four rooms, decided before any skin. (1) TODAY — one question, one answer, and the run it feeds; single most important element is the unanswered day itself, which must be legible as unanswered from across the room. (2) CALENDAR — the record: every day carries one of five truthful states (no-spend, spent, mandatory-only, frozen, not-yet); most important element is the shape the month makes, not any single cell. (3) STATS — what the record means over time, at most three claims per screen; most important element is the current run versus the best run. (4) SETTINGS — the boring room, kept boring: what is mine, what is Pro, how to leave. Two intervention tools (urge-surfing timer, impulse checklist) and the 24-hour waiting list are entered FROM Today, never as a fifth tab — they belong to the moment, not to the navigation. The paywall is not a room: it is a door that opens where a limit was met and states which limit that was.

## 4. DESIGN DIRECTION

> **Authoring ban (2026-07-25).** The brief does NOT name, sketch or rank the candidates, and
> carries no "lead recommendation". Six of six runs selected the first-listed candidate —
> including the one run whose candidates were not pre-written — so ordering alone is a strong
> enough prior to make the spread rule theatre. You invent the directions; you present them in
> a non-preferential order; your honest recommendation goes in the closing section of §6.A,
> never encoded in the ordering. (Mechanism M-18.)

The brief supplies the raw material below; the NAMED directions are yours to invent.

- **Product truth to design from:** 1. The user's achievement is an ABSENCE — nothing was bought. The product's core visual problem is making an absence feel substantial, which is the opposite of every spending app's job. 2. The unit is a DAY and days accumulate into an unbroken run; the run is fragile in one direction only, and a single freeze per month is the mercy built into it. 3. There are exactly five truths a day can carry — no-spend, spent, mandatory-only, frozen, not-yet-answered — and the design must give all five a place, including the ugly one. 4. Money is never counted here: the app deliberately does not know what anything cost unless the user volunteers it. The number that matters is DAYS, not dollars. 5. The interventions happen before the purchase, not after: a timer that runs for ten minutes while a craving passes, a list where a wanted thing waits twenty-four hours. Waiting IS the product's mechanism.
- **Type personality brief:** The day count is the product's one heroic number and must read instantly, at a glance, from a Lock Screen widget and from a hand's length away — instrument-grade, tabular, never decorative. Around it the type must carry an adult, unembarrassed voice for the narrative moments (the broken-streak message, the trial terms, the empty state) without turning literary. Dates and calendar cells need a compact numeral that stays unambiguous at cell size in Dynamic Type XXXL. One family may do all of it if the weights and widths earn it; if a second face enters, it must justify itself by a job the first cannot do.
- **Colour world brief:** Describe a world, not swatches. The field carries the product's calm and must work as its own composition in both light and dark — dark is not an inversion. The palette needs one accent doing ONE job (the answered/no-spend truth), a second that names a spent day WITHOUT shaming it, and a third, quieter, for mandatory and frozen days which are neither good nor bad — three distinguishable states plus a resting neutral, all measured to WCAG AA at their real sizes. Note the trap: the current build's mint-green reads as generic wellness and its spend-red reads as an error. Green-means-good and red-means-bad is the cheapest available mapping and probably the wrong one for a product whose whole point is that a spent day is a fact, not a fault. Five user themes must be expressible as variants of one token contract, so whatever world is chosen has to survive re-tinting without losing its identity.
- **Spatial feel:** One decision per screen with real air around it; the day's answer is the only thing at full weight and everything else recedes. Fixed slots — an element that appears only in some states reads as disorder and must hold its place instead. Grid discipline over decoration; corner language stated once and obeyed everywhere.
- **Texture & depth:** Material implied through shape, value and procedure — never a bitmap, never a gradient used as decoration, never glassmorphism as a substitute for hierarchy (the current build leans on all three and it is what makes it read as generic). Hairline borders and value steps do the separating; shadow gets a written doctrine and is used where elevation is real.
- **Motion appetite:** Functional-only, plus exactly one expressive beat: the moment today is answered. Motion lives ON the object that changed — no free-floating particles, no confetti storms, nothing decorative crossing the screen. The current build fires confetti and a pulsing glow; both are on the table for removal. Every motion must have a Reduce Motion answer that is not simply 'nothing happens'.
- **Signature move:** every direction MUST have one, and it must satisfy M-04 in §5.
- **Recently-used styles to AVOID (divergence clause — MANDATORY, compiler-filled):**
    - **Ethiopian Bible: Lost Books — Folio (2026-08-08, type A, iOS)**
    · palette: ** warm **folio cream** with a two-accent job split — LIGHT
    · type: ** a SINGLE serif carrying scripture, display and UI labels alike
    · topology: ** five tabs and one reader; the reader is a measured text column with a
    · motif: ** the vocabulary of a printed scholarly edition — the hairline
    · signature: ** **THE PROVENANCE DIAMOND** — a small gold lozenge that terminates every
    · TAKEN — ** the **folio/rubric scholarly-edition register is TAKEN for Ethiopian
  - **Coneglow — Fired True (2026-08-07, type A, iOS)**
    · palette: **porcelain & cobalt** — a COOL craft world, deliberately the opposite temperature to the portfolio's warm-craft lane. LIGHT field `#EBEAE6` / porcel…
    · type: SF Pro names + chrome over SF Mono for codes, counts, cones and schedules — mono never sets a name, SF Pro ne…
    · topology: three fixed tabs (Studio / Glazes / Kiln), home = the five-stage board; fixed slots and empty as a DRAWN stat…
    · motif: **gloss vs matte as the truth channel** — fired evidence carries a specular highlight poured from the upper l…
    · signature: **THE GLOST WEDGE** — a right-isosceles specular triangle over the bottom-right corner of any fired datum (le…
    · TAKEN — the **porcelain-and-cobalt truth-test register is TAKEN for Coneglow** — gloss-vs-matte as an evidence channel, the corner wedge with a count, square-cut evidence, and cobalt-as-brushed-pigment must not be reprised by a…
  - **Saponora — Settle (2026-08-07, type A, iOS)**
    · palette: scrubbed-concrete workshop wall `#E3E1DB` light / night `#17181A` dark, with bar ivory `#F5F1E7` (light) and night slabs `#2A2B2F` + lit top edge `#D…
    · type: SF Pro Display 800 spaced-caps verdicts · SF Mono every measured number · SF Pro Text names. No serif, no ita…
    · topology: one held object, no tab bar — the rack is home, BENCH ↑ and BOOK → always-present handles. **No cards exist i…
    · motif: **gravity is the cure** — water leaves, mass settles, the bar sits. Exactly ONE shadow exists in the whole pr…
    · signature: **THE SETTLE** — the air gap beneath a curing bar encodes distance to plateau (8→6→4→2→0 pt, quantized to fiv…
    · TAKEN — the settle-gap/one-shadow register is TAKEN for Saponora — gap-as-progress, slats-instead-of-cards, the single contact shadow, and neutral-grey concrete inside a warm-craft neighbourhood must not be reprised. Deliberate…
  - **Citora — Waterline (2026-08-06, type A, iOS)**
    · palette: petrol/sage sea + limestone dry land — LIGHT field `#C2CFCC` / sheet `#F4F2EC` / visited `#EFE8D8`; DARK field `#0D181B` / sheet `#17252A` / visited…
    · type: SF Pro Display **Ultralight (200)** oversized counts — the lightness of things afloat — over SF Pro Text chro…
    · topology: one held object — map root with counts above and search dock below, everything else sheets/pushes; no tab bar…
    · motif: **the world surfacing** — visited land is DRY, one full read above the submerged world via three non-hue chan…
    · signature: **THE WATERLINE** — every completeness metric is a water level; marking beat = the country rises 4pt and brea…
    · TAKEN — the elemental-water register is TAKEN for Citora — water-level-as-progress, the surfacing beat, petrol/sage + limestone, and the single-shadow doctrine must not be reprised by future map/progress/travel products. Delibe…
  - **Ovenspring — Open Crumb (2026-08-06, type A, iOS)**
    · palette: semolina/crumb warm neutrals with a DARK HERO IN LIGHT MODE — LIGHT field `#E8DFC9` / card `#F3ECDA` / hero (the living starter) `#33261A`; DARK `#19…
    · type: New York ITALIC for starter names (pets, warmth) over SF Pro 600–800 chrome/verdict chips and SF Mono for eve…
    · topology: one held object, no tab bar — starter breathes at top, LOG and BAKE as two always-present sheet handles; fixe…
    · motif: **the alveoli field** — fermentation drawn as a deterministic circle pack whose density/size/coverage track R…
    · signature: **the % rise result pushed up by the field inflating beneath it** (spring 0.55/0.75, one overshoot; RM: final…
    · TAKEN — the living-culture/crumb register is TAKEN for Ovenspring — alveoli-as-data, dark-organic-hero-on-warm-light-field, gold+mahogany job split, and New York italic pet-names must not be reprised by future food/tracker prod…
  - **KoalaHood — Cold Enamel (2026-08-04, type B, static / fully on-chain SVG NFT)**
    · palette: **cold enamel on nickel** — navy backing `#12293D`, five enamel ways (deep-water `#157481`, ash-nickel `#5D6B79`, oxide `#9F5535`, sea-green `#2A755E…
    · type: Familjen Grotesk 700 display + Martian Mono 400 data — and type lives OUTSIDE the artwork; there is not one l…
    · topology: square 1200 grid, 96px safe margin, four named anchors (HEAD/PERCH/HOLD/EDGE BAND) with a 12px overlap allowa…
    · motif: **the struck pin** — flat vitreous cells poured into one cell plan, each walled in nickel; enamel may never c…
    · signature: **the keyline** — the wall between two cells, whose gauge IS the rarity ladder (6→9→13→18), second channel st…
    · TAKEN — cold industrial enamel, deliberately outside the warm-paper family (TERSE vellum, FAIZ foxed rag, Pulse daybook), outside the dark instrument cockpits (RangePilot, COS), outside ROTORFALL's silver-gelatin photo register…

## 5. HARD CONSTRAINTS (non-negotiable)

### 5.1 Accessibility and platform
- WCAG AA minimum — text contrast ≥ 4.5:1 (≥ 3:1 for large text); hairlines ≥ 1.2:1 against
  their surface (subtle is a decision, invisible is a defect).
- **Every contrast claim ships as a measured number**, and rejected pairings are recorded as
  evidence. **Recompute independently** every pair within 0.3 of its threshold or carrying
  interactive text — that is exactly where the one wrong number hides. (M-03.)
- **Colour is never the only channel.** Every state, category and signal carries a second
  channel — glyph, label, band, hatch, shape or position — so it survives dark mode, colour
  blindness and the narrowest supported width. (M-15.)
- **Dark mode is REQUIRED and first-class**, designed as its own composition, never an
  inversion. Name both worlds ("the kitchen table at 10pm, the day closed and the receipts not opened" (light) / "the same table with only the phone lit" (dark)).

### 5.1b Medium constraints — ios profile

- **Sizes in points, not CSS pixels:** iPhone **393pt** (standard) and **430pt** (Max) portrait;
  iPad **834pt** portrait and **1194pt** landscape when the product supports iPad. Show or
  imply each supported class. Respect safe areas, the Dynamic Island and the home indicator.
- **Dynamic Type** to XXXL without clipping; hero art scales with `@ScaledMetric`.
- **Touch targets ≥ 44pt** (larger where the audience needs it — state the number).
- **VoiceOver plan** is a design deliverable, not a coding afterthought: for each screen, what
  is exposed, in what order, with what label and trait, and what is hidden as decorative.
- Surfaces beyond the app when the product has them (widget / Lock Screen / Live Activity /
  Dynamic Island / App Clip) are designed, not assumed — or marked "N/A + why".

### 5.2 Structure and behaviour (owner law — evidence in `_learning/OWNER_TASTE.md`)
- **Fixed slots: nothing appears or disappears.** Every slot renders always; only its state
  changes. An empty state is a state, not an absence. Conditional chrome reads as disorder.
- **Motion only on the object, and ONE expressive beat in the whole product.** No free-floating
  particles, confetti or sparkles. The beat needs a physical cause and written spring
  parameters, plus its Reduce Motion substitute. Everything else is functional.
- **Distinctiveness outranks genre convention.** "This is what apps in this category look like"
  is a reason to go elsewhere, not a justification.
- **Material is specified as procedure, not as an adjective** — how the pattern is generated,
  where it accumulates, how it fails. "Warm paper" is rejected; "procedural fibre tile,
  page-sized foxing, torn along the gutter when a debt matures" is accepted. (M-14.)

### 5.3 Design system contracts
- **One job per accent, no overlap.** Write the contract into `tokens.json` under
  `_meta.accent_contract`. Seeing that colour must mean one thing. (M-01.)
- **One legibility law** that keeps the whole set above threshold when obeyed — one sentence,
  documented. (M-02.)
- **Type roles never swap.** Assign each family a role and keep it. (M-16.)
- **Corner and depth language are decisions**, not global defaults — never one radius and one
  shadow on everything.
- All interactive components need visible states: default / pressed / focus / disabled /
  loading / empty / error. Design the unhappy paths.

### 5.4 Content and voice
- **Real content only** — a plausible content world, not samples: Real content, never samples. A 23-day current run against a best of 41. A calendar month with 19 no-spend days, 6 spent, 3 mandatory-only, 1 frozen. Mandatory categories named Rent, Utilities, Transport, Groceries. Waiting-list entries a real person would write: 'wireless earbuds — 89' added 14 hours ago with 10 hours left; 'second coffee grinder — 220' expiring tonight; 'linen shirt — 45' already resolved as skipped. A spent day whose note says 'takeaway, tired after work'. Achievements with plain names, not titles: 'Seven days', 'A full month', 'Thirty days without a slip'. Prices shown only where StoreKit supplies them — $4.99 monthly, $39.99 yearly, 7 days free. Never lorem ipsum, never round fake numbers, never 'John Doe'.. Never lorem ipsum, never
  "John Doe", never round fake numbers like "1,000,000".
- Voice & microcopy: buttons, empty states and error messages carry the product's voice —
  Calm, factual, adult. Never congratulatory about money, never scolding about a slip. No exclamation marks, no streak-guilt, no gamified cheer — the compassionate copy on a broken streak is the voice's hardest test and its best example.. Words are design;
  generic robotic copy fails review even if the visuals pass.
- **No emoji anywhere in the product** — headings, labels, empty states, error text.
- The App Store Name 'NoBuy: No Spend Day Tracker' is measured #1 for two search phrases and its WORDING is fixed; the identity around it is not. Copyright reads © 2026 TheKnack. The paid structure is locked at one monthly + one yearly with a 7-day trial and every price renders from StoreKit — a hardcoded price is a defect. Paywall bans, non-negotiable: no fake urgency or countdown, no strikethrough against a price that never existed, no lock or crown imagery, no delayed or disguised dismiss control, and NO two-column ✓/✗ comparison grid (the current build ships a 16-row one; it is the single most templated pattern in the store and it is being removed). The paywall must instead state where the user stands, in their own numbers, when a limit sent them there. 60 existing customers own a retired lifetime unlock and their status must have a dignified, permanent place in the interface — they are not lapsed, they are early. No emoji anywhere in the product. Nothing may imply an account, a cloud sync, a bank connection or analytics: none of them exist and the store listing promises they never will. App Store panels may never show a paywall, a price or lock imagery.

## 6. DELIVERABLES & HANDOFF FORMAT

> **PERSIST, don't preview (LAW):** every deliverable MUST be written to the project as an
> actual FILE at the stated path, never left as an in-chat preview/canvas only. A design chat
> defaults to inline previews; unless you are told to write files, nothing is saved. The run is
> complete only when `docs/HANDOFF_MANIFEST.md` exists AND every path it lists is present as a
> file. (If the environment will not let you write files, say so explicitly at the top of your
> reply so the operator can export instead of discovering it later.)

### 6.0 File-path contract (binding — the only tree that ever came back clean)

```
directions/<slug>/*.html      screens/<screen>-<state>.html      components/*.html
tokens/tokens.json            store/                              icon/
docs/                         assets/
```
Every component preview carries `<!-- @dsCard group="…" -->` as its FIRST line.
File names use the exact strings you write in the docs — a doc that points at a name the file
does not have costs a whole revision round.

---

### 6.A ROUND 1 — DIRECTION (this round only, when the brief says Round 1)

1. **Produce 3+2 candidate directions, then ELIMINATE the weakest 2 yourself.** Judge them
   against §7 and §5; write one line per eliminated candidate saying what failed. Present the
   surviving 3. (Candidate-count policy: **5** for a new product's first dressing · **3**
   for a redesign/refresh of an existing product · **2** for a small one-off job — the brief's
   own number wins when the owner asks for a different count.)
2. Each surviving candidate is a **full-fidelity key screen set** (not wireframes):
   Today (the single daily decision and the streak it feeds) · Calendar (the accumulated record, month by month) · Paywall (the money moment — held to a higher bar than the hero, per the world-class law), light AND dark.
3. Open with the decisions ALL candidates share — "this is structure, not skin" — then give
   every candidate the same seven fields: **point of view · signature move · brave choice ·
   type · palette · depth doctrine + radius family · accent-swap test**. (M-08.)
4. The candidates must form a deliberate SPREAD, not variations of one idea: they diverge on
   ≥2 of {palette family, typography personality, layout topology, motif strategy}, AND the set
   includes at least one **thematic / subject-motif** direction (imagery or material metaphor
   drawn from what the product IS) and at least one **neutral-premium instrument** direction
   (restraint, type, material; no literal motif).
5. **Signature move test** — for each candidate state: which VARIABLE the move encodes and in
   which direction it moves · how its salience rises with that variable · its second channel
   besides colour · the ≥3 surfaces it recurs on. A signature that fails this is decoration
   and does not count. (M-04.)
6. **Close with an honest verdict section:** name each candidate's WEAKNESS, then give your
   recommendation with its argument, and propose at most ONE graft from a losing candidate —
   and only as a token or a measure, never as an appearance. (M-09.) Do not flatter; the
   operator will pick, and a defended recommendation is more useful than a safe one.
7. `docs/HANDOFF_MANIFEST.md` last: chosen-direction slot (left open for round 1), a flat list
   of every file produced, and a "ready for handoff" marker.

---

## 7. ANTI-SLOP DIRECTIVES (immune system — never trim this section)

The following are BANNED. Producing them means the work is rejected regardless of polish:

1. **The default AI palette:** purple-to-blue or violet-to-indigo gradients on dark
   backgrounds; the #7C3AED / #8B5CF6 family as accent "because tech".
2. **Template anatomy:** centered hero + three feature cards + testimonial strip +
   gradient CTA. If the layout could be any product's landing page, it is wrong.
3. **Emoji as design:** emoji in headings, emoji as icons, 🚀✨🎉 anywhere.
4. **Generic type:** a single default sans (Inter/Roboto/system) doing every job with
   no scale contrast. Type must have a personality decision, taken deliberately.
5. **Glassmorphism-by-default:** blurred translucent cards everywhere; use backdrop
   effects only if the direction in §4 explicitly calls for them, and sparingly.
6. **Uniform border-radius + uniform shadow on everything** — depth and corner language
   must be a decision, not a global default.
7. **Placeholder energy:** lorem ipsum, stock-photo people shaking hands, fake 5-star
   review blocks, meaningless big numbers ("10M+ users") — real content per §5.
8. **Adjective-soup minimalism:** "clean, modern, minimal" is not a direction. The work
   must express the named direction in §4, and the signature move must be visible.
9. **Decoration without information:** every visual element must either carry meaning,
   aid hierarchy, or express the direction. If removing it changes nothing, remove it.
10. **Trend cosplay:** do not imitate whatever style is currently everywhere (this
    season's fads included). Distinctiveness outranks fashion.
11. **Current-season slop (2025-26 edition, kept fresh):** bento-grid as the default
    layout answer; neon-glow cards/borders on dark; scroll-reveal animation on every
    element; AI copy-voice in microtext ("it's not just X, it's Y", em-dash chains,
    empty superlatives).
12. **Invisible hairlines:** borders so faint they vanish (below ~1.2:1 against
    their surface) — subtle is a decision, invisible is a defect.

Positive duty: make at least one brave choice per screen — an asymmetry, an unusual
crop, an oversized number, a restrained monochrome — that a template would never make.
State it in your rationale.

## 8. QUALITY BAR

Judge your own output before presenting: would this survive review next to
Things 3, Halide, Flighty? If any screen would look like the weakest item in
that lineup, redo it before showing.

(Note: this self-check is a floor, not the verdict — the binding quality authority
is an independent adversarial review downstream. Do not grade your own homework
generously; it gets re-graded.)

## 9. ITERATION PROTOCOL

- **Self-elimination is part of round 1** (§6.A.1), not an optional courtesy: produce 3+2,
  cut 2, show your reasoning. The operator should spend attention on strong options only.
- Present candidates with rationales in a non-preferential order; put your recommendation in
  the closing verdict section. Defend it honestly — do not flatter.
- Revisions come as structured notes against specific screens/components. Apply them
  without regressing approved parts.
- **Revision-round mode:** when the brief is a revision, it opens with a `LOCKED — do not
  revisit` table and a corrections list. A revision is not a re-exploration; converge.
- Max 3 revision rounds are expected; converge decisively.


---

## 10. MECHANISMS THIS BRIEF INHERITS

Distilled from every previous round in this portfolio. They are contracts, not advice —
each one exists because skipping it cost something measurable.

**M-01 · One job per accent, no overlap**
Every accent colour gets EXACTLY ONE job, and no two accents share a job. Write the contract into `tokens.json` under `_meta.accent_contract`. Seeing that colour on screen must mean one thing and only one thing — so the user learns a rule instead of a mood.

**M-02 · One legibility law instead of a contrast spreadsheet**
Write a single placement law that, when obeyed, keeps the whole asset set above its contrast threshold — e.g. "only X and Y may sit on the field; everything else touches Z". One sentence, documented, binding.

**M-03 · Measured numbers, never adjectives — and recompute the tight ones**
Every contrast claim ships as a measured number, and rejected pairings are recorded as evidence of real work. Independently recompute every pair that (a) sits within 0.3 of its threshold or (b) carries interactive text.

**M-04 · The signature move carries information and recurs on ≥3 surfaces**
The signature move may not be decoration. It must encode a named variable (state the variable and the direction it moves), its salience must rise monotonically with that variable, it must carry a **second channel** besides colour, and it must appear as the same object on at least three surfaces. Count the jobs it does.

**M-05 · Fixed slots: nothing appears or disappears**
No element is conditionally present. Every slot renders always; only its state changes. "Timer off" is a state, not an absence.

**M-06 · Motion only on the object, and ONE expressive beat per product**
No free-floating particles, confetti or sparkles. The whole product gets a single expressive moment; it must have a physical cause and written spring parameters. Every other motion is functional. State the Reduce Motion substitute for the expressive beat.

**M-07 · Closed asset set, with a coverage manifest that proves it**
Close the object/icon set with a NUMBER, then read the product's entire content back against that set in a manifest table (one row per content item × the primitives it uses). A content item with no match in the set means the SET grows — before production starts, never during it.

**M-08 · Direction round anatomy: shared structure, diverging skin, honest weakness**
Open the candidate round with the decisions ALL candidates share ("this is structure, not skin"). Then every candidate fills the same fields: point of view · signature move · brave choice · type · palette · depth doctrine + radius family · accent-swap test. Close by naming each candidate's WEAKNESS honestly and proposing at most one graft onto the winner.

**M-09 · From a rejected candidate, only a TOKEN may cross**
When a losing candidate contributes something, it crosses as a token or a measure — never as an appearance. Name what crossed and why it is functional.

**M-10 · One brave choice per screen, written down — plus the deliberate absences**
Every screen makes at least one choice a template would never make, and the rationale document lists them in a table. Also list what the design deliberately does NOT have, so a later round does not "fix" an intentional absence.

**M-11 · Portfolio arbitration: name the taken lanes, then say why you are elsewhere**
Read `STYLE_REGISTRY.md`, name the colliding lanes by project, and state which register this work occupies instead. If the brief's own direction risks a collision, say so in the brief and make it a rejection condition.

**M-12 · Token seam first, paint second**
`tokens.json` is the single source. Run the contrast gate on the token file BEFORE a single view or draw call is written.

**M-13 · A blend needs its seam described concretely**
"Combine 1a and 1c" is forbidden. Name which layer is the glance, which is the act, and what grammar they share.

**M-14 · Material is specified as procedure, not as an adjective**
"Warm paper" is an adjective and is rejected. Specify the material as something buildable: the pattern, how it is generated, where it accumulates, how it fails.

**M-15 · Colour is never the only channel**
Every state, category and signal carries a second channel — glyph, label, band, hatch, shape or position. It must survive dark mode, colour blindness and a 375pt width.

**M-16 · Type roles never swap**
Assign each family a role and keep it. The serif that labels never becomes the face that tabulates.

**M-17 · The three delivery conditions that actually decide package richness**
(i) PERSIST law — every deliverable is written to the project as a FILE at a stated path, never left as an in-chat preview; (ii) a file-path contract naming the directory for every artefact type; (iii) **count targets** on every asset deliverable.

**M-18 · Present candidates without a preferred position**
The dispatcher may not name or sketch the candidates, and may not mark a lead recommendation. Candidates are presented in a non-preferential order; the model's honest recommendation goes in a separate closing section, never encoded in the ordering.
