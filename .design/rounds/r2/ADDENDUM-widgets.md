# ROUND 2 — ADDENDUM: THE WIDGET FAMILY IS A 🔴 DELIVERABLE, NOT A 🟡

> Paste this into the same round-2 session. It does not replace anything in the brief; it
> raises one deliverable's bar and hands you the platform constraints that decide whether the
> chosen direction survives outside the app. Everything below is verified against WidgetKit's
> documented behaviour, not assumed.

## Why this is not optional for this release

NoBuy v2.0.0 ships a widget family as one of its three signature surfaces. The iOS profile
marks widgets 🟡 ("designed or marked N/A + why") because most products do not ship one. This
product does, so for this round the widget family is **🔴** and a package without it is a
revision, not a preference.

It also matters more here than in most apps: the product is opened once a day, at night, to
answer one question. A surface that lets the person answer it **without opening the app** is
not a convenience — it is the product's shortest possible path, and the Lock Screen is where a
no-spend day is actually decided.

## The constraint that decides ESCAPEMENT's fate outside the app

**Lock Screen and StandBy widgets render in tint mode: flat, single-colour silhouettes in the
user's chosen tint.** `.widgetRenderingMode(.fullColor)` exists, Apple actively discourages it,
and we are not using it.

Read what that costs this direction. Escapement's identity is currently carried by material and
hue: silvered face, blued steel hands by day, lume by night, copper for the spent fact. **On the
Lock Screen, every one of those becomes the same single colour.** The accent contract — blued =
kept, copper = spent — does not survive the trip.

So the round must answer, explicitly and with drawings:

1. **What carries meaning when hue is gone?** Tick pitch, hand angle, arc length, bezel, index,
   filled versus hollow, printed numerals — the second channel (M-15) stops being a courtesy
   here and becomes the only channel. Show the same widget in full colour and in tint, side by
   side, and prove both read.
2. **Which of the five day-truths survive at 76×76pt in one colour?** If all five cannot be
   distinguished, say which the widget carries and which it deliberately drops — a widget that
   silently conflates "frozen" with "kept" is worse than one that shows less on purpose.
3. **Does the dial still beat a number here?** `.accessoryCircular` is roughly 76×76pt rendered.
   If the honest answer is that the circular slot should show the count and not a face, say so
   — matching the house geometry is not worth costing the user the read.

## The families to design (all four, both states)

| Family | Size | What it must carry |
|---|---|---|
| `.systemSmall` | Home Screen | The run, today's state, and the answer action |
| `.systemMedium` | Home Screen | The above plus the week's shape or the nearest wait |
| `.accessoryCircular` | ~76×76pt, **tint mode** | One reading, glanceable, no hue |
| `.accessoryRectangular` | Lock Screen, **tint mode** | The run plus today's state, text-first |

For each: the **unanswered** state (today still open — the whole reason the widget exists) and
the **answered** state. Plus the two the round must not skip: **before any data exists** (a
fresh install pinned to the Home Screen shows something, and "0" is not a design), and the
**Pro-less** state — the widget is free, and nothing in it may advertise or tease the paywall.

## Interactivity — the rule and its trap

Interactive widgets (iOS 17+) run an `AppIntent` from a `Button` or `Toggle` **without opening
the app**. That is what NoBuy wants: answer today from the Home or Lock Screen.

The trap is that **there is no confirmation step and no undo affordance inside a widget.** A
mistaken tap writes a real day into the record. Design the answer:

- What does the widget look like in the ~1 second between the tap and the reload?
- After answering, what does it show — and how does the person learn the entry is editable in
  the app? (Silence here is how a wrong tap becomes a permanent wrong record, which the
  finished-product law forbids.)
- Does the widget offer both answers ("No" and "Yes"), or only the no-spend one? Offering only
  the flattering answer is a small dishonesty that compounds into a false record; offering both
  in a 76pt circle may be impossible. Decide, and say why.
- Reduce Motion and VoiceOver for the widget too: what is spoken, in what order, and what the
  button's label and hint are.

## Platform rules the drawings must respect

- **Background:** `.containerBackground(.fill.tertiary, for: .widget)` — the system chooses the
  material per context (Home, Lock, StandBy, iOS 26 Liquid Glass). A hardcoded fill is wrong and
  breaks the moment the context changes. Design against a background you do not control.
- **No animation.** Widgets do not animate on a timeline; the state changes between renders.
  Escapement's expressive beat (the hand seating with one overshoot) **exists only in the app**.
  Say what the widget does instead at the moment of the answer.
- **Refresh is budgeted.** The widget cannot tick a live countdown. A wait with "10 h left" is a
  rendered value that goes stale between reloads — draw the honest version (a rounded remainder
  that cannot lie), never a running clock.
- **StandBy** shows the accessory families on a bedside charger, at a distance, at night. If the
  design leans on lume, this is where it either pays off or disappears. Show it.

## Acceptance for this addendum

- 🔴 Four families drawn, each in unanswered and answered state
- 🔴 Every Lock Screen family shown **in tint mode as well as full colour**, with the
  meaning-carrying channel named for each
- 🔴 The interactive answer designed end to end: pending render, post-answer state, how
  editability is communicated, one-answer-versus-two decided with a reason
- 🔴 First-run (no data) and free-tier states drawn; zero paywall/price/lock imagery anywhere
- 🔴 VoiceOver order and button labels per family
- 🟡 StandBy shown, or "N/A + why"
