# NoBuy — Screenshot Plan (v1.2.0)

patterns_read: 2026-07-21

Conversion funnel: P1 hook (brand promise) → P2 moat (in-the-moment anti-impulse
toolkit — no rival has it) → P3 depth (calendar outcome state). P5 pre-sells Pro
value (unlocked charts, never the price wall). Captions reuse metadata vocabulary
(impulse, no-spend, savings, streaks, underconsumption audience).

| # | Panel | uiState | Caption | Sub | bg |
|---|---|---|---|---|---|
| 1 | Home hero (23-day streak, $575 saved, challenge 23/30) | today | Break impulse buying | One tap a day. No budgets, no bank logins. | mint-light + halo |
| 2 | Urge Surfing timer sheet | urge | Beat the urge in minutes | 10-minute urge-surfing timer for impulse moments | forest-dark |
| 3 | Calendar month (green outcome state) | calendar | Your month at a glance | Color-coded no-spend calendar with streaks and freezes | ocean |
| 4 | Stats top (savings + achievements) | stats | Watch real savings grow | Savings estimate, achievements, monthly progress | sunset |
| 5 | Stats Pro charts (scrolled) | statsCharts | Pro insights keep you going | Trends, weekday patterns, streak history — pay once | forest-dark |
| 6 | Impulse checklist sheet | checklist | Think before you buy | Honest checklist and a 24-hour waiting list | mint-light |

## A/B variants (post-launch PPO)

- P1 alt: "Stop impulse buying today" / "Join the no-buy challenge"
- P2 alt: "Outsmart the impulse" / "Urge surfing + waiting list beat regret"
- P5 alt: "Own Pro forever — $4.99" (price-forward test; only if conversion dips)

## Capture notes

- Demo data: `-demoData` (DemoSeeder — 23-day streak, ~$575 saved, challenge 23/30,
  Pro unlocked). Fresh container before the run (`simctl uninstall`) + one warm-up
  launch (cold-start blank rule).
- Devices: iPhone 17 Pro Max (1320×2868) + iPad Pro 13-inch M5 (2064×2752), en_US
  locale, status bar 9:41 / discharging / full bars.
- 6.7" (1290×2796) set derived from the composed 6.9" PNGs (0.2% aspect resize,
  imperceptible) so the stale live APP_IPHONE_67 set gets replaced too.
