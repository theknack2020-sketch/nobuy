# Build handoff — NoBuy v2.0.0 (Escapement)
## Build order
1. tokens/tokens.json → asset catalog + semantic Color extensions. **No view references a hex — CI greps for '#' in view code and fails the build.**
2. Primitives (the 12 objects) as SwiftUI shapes: DayMark, BezelDial, RimHand, SweepArc, IntervalBar, WellRow, IndexTriangle.
3. Rooms: Today → Calendar → Stats → Settings; doors: paywall sheet, urge, checklist; then widgets (WidgetKit, restricted palette, App Intent "MarkToday"); onboarding last (it reuses everything).

## Non-negotiables a build can silently break
- The five day-truths always carry geometry + colour, never colour alone (M-15).
- Fixed slots: the notice line, freeze chip, timer/waiting/mandatory rows, verdict slot and standing slot render in EVERY state (M-05) — no 'if' that removes a view.
- One expressive beat only: the hand seats on answer — spring(response 0.55, dampingFraction 0.75), one overshoot; RM: 200ms crossfade, remainder updates instantly. Everything else is 200ms easeOut.
- The run pauses at unanswered days; it never silently zeroes. Ended runs are never deleted from Stats.
- Prices render from StoreKit Products only; the paywall has real loading and error states — never a hardcoded string, never a blocked dismiss.
- Lifetime owners (legacy unlock receipt) never see the paywall; Settings shows "Early supporter".
- Mandatory categories are exactly: Rent, Utilities, Transport, Groceries.
- The day closes at local midnight; "amend today" dies at 00:00; late answers mark the day answered-late but kept/spent truthfully.
- Widgets: no animation, one accent, monochrome on Lock Screen by system rendering.
- Notifications: exactly one, 21:30, opt-in at onboarding step 4b; one re-offer surface in Settings; never re-prompted by the app itself.

## Motion parameters
Beat: spring(0.55, 0.75) ×1 overshoot. Functional: 200ms easeOut. Sheet present: 320ms easeOut + scrim fade. Gauge draw (paywall/onboarding): 240ms once. Skeletons: opacity pulse 1.2s, no translation.

## Accessibility acceptance (measured)
All token pairs from tokens/tokens.json _meta.contrastPairs pass (worst: wait-on-dial 3.91 at 3:1 graphic; secondary-on-well 4.84 at 4.5). Dynamic Type XXXL: cell numerals floor 12 with growing cells; countXL floor 56. Targets: answer buttons 52pt, rows 44pt min, toggle knob 22pt in a 44pt row. VoiceOver: orders drawn per screen; marks decorative; states spoken as words. Increase Contrast + Differentiate Without Colour maps in docs/VISUAL-LANGUAGE.md.

## Legal / positioning guardrails
App Store Name wording fixed: "NoBuy: No Spend Day Tracker". © 2026 TheKnack. Panels never show paywall/price/locks. Nothing may imply an account, cloud, bank connection, or analytics — the listing promises they never exist. Trial sentence verbatim pattern: "7 days free, then {StoreKit price} a {period}. Cancel any time in Settings ▸ Subscriptions before the trial ends and nothing is charged."
