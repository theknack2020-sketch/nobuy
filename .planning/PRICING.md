# NoBuy — Pricing Decision

> Created 2026-07-21 (v1.2.0 refresh session). Owner pricing autonomy per
> `monetization-pricing-autonomy`. Valid ≤90 days; re-check before next price move.

## Product

Single non-consumable: **NoBuy Pro** (`com.ufukozdemir.nobuy.pro`).
"One-time purchase · No subscription · No ads" is the paywall's trust pitch and the
app's market wedge — subscriptions are ruled out by positioning law.

## Evidence (2026-07-20/21, live data)

**Own funnel (Apr 1 – Jul 14):** ~976 downloads, 60 net Pro sales (~6% paid
conversion — strong for a $2.99 utility), ~$124 proceeds (~$2.10/unit), and all of
this with **0 ratings** on the store listing. Demand is not price-sensitive at
$2.99: buyers convert with zero social proof.

**Competitor scan (`asc apps public search`, US, 2026-07-21):**

| App | Monetization | Ratings | Signal |
|---|---|---|---|
| Stop Impulse Buying (Shawstad) | Sub $9.99/mo · $49.99/yr | 4.25 (72) | expensive; "predatory" complaints |
| BuyBye | Sub $2.49/mo · $29.99/yr | (250K+ installs, old data) | biggest rival, sub backlash |
| mallow – no buy tracker (Weekend Lab) | Freemium | 4.87 (39) | design-first, small |
| mora: no buy & spend challenge | Free(mium) | 4.00 (1) | new entrant |
| Wallet Diet: No Spend Tracker | Free | 0 | new entrant, Utilities |
| NoBuy: No Spend Challenge Game (TOKSARI) | Free | 0 | name-collision entrant |
| No-Buy Day Counter / NoSpend | Free | 0 | basic counters |

NoBuy ranks **#1 for "no spend tracker"** and is the only credible one-time-purchase
offering; the serious rivals all run subscriptions. Sub annual prices ($29.99–49.99/yr)
anchor the category's perceived value far above a $2.99 lifetime unlock.

## Decision

**Raise NoBuy Pro US base price $2.99 → $4.99** (one-time). Applied via ASC web UI
(Claude Browser, owner rule) with Apple's automatic per-territory equalization.

Rationale:
- 6% conversion at 0 ratings = value perception exceeds price; $2.99 leaves margin
  on the table (~+67% proceeds/unit at $4.99, ≈$3.50/unit).
- Against $29.99–49.99/yr subscription anchors, $4.99-lifetime still reads as a
  steal and *strengthens* the anti-subscription trust wedge.
- Paywall anchor copy ("Less than one impulse buy") remains truthful at $4.99.
- Non-consumable: existing 60 owners unaffected.
- $5.99–6.99 rejected **for now**: with 0 ratings the listing has no social proof;
  the honest review prompt ships in 1.2.0 — revisit the band at ≥25 ratings.

## Follow-up triggers

- ≥25 ratings ≥4.5 → evaluate $5.99.
- Conversion falls below ~3% for 4+ weeks after the change → consider reverting
  to $3.99 (not $2.99; keep some of the gain).
- Any credible one-time-purchase rival at $2.99 with traction → reassess wedge.
