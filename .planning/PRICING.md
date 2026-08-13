# PRICING — NoBuy

**Date:** 2026-08-12 · **Method:** live Apple-surface scan, archived under `.market/evidence/pricing/us`
(6 terms, 29 competitor pages) + this app's own funnel · **Valid until:** 2026-11-10 (≤90d)
**Authority note:** pricing decisions are delegated (global rule 3). Structure is NOT a market
question — owner law 2026-08-06 fixes it at one monthly + one yearly portfolio-wide. Only LEVELS
are derived here. This file supersedes the 2026-07-21 one-time-unlock decision, which the owner
retired on 2026-08-12.

## Job classification

**Daily-behaviour instrument with a growing personal record.** The user answers one question every
evening ("did I spend on something unnecessary?"), the streak renews continuously, the freeze
budget resets monthly, challenges run on rolling windows, and the ledger of days accumulates for
as long as the app is used. This is neither a one-shot instrument (a measurement you take once)
nor static content — which is what App Review 3.1.2 requires an auto-renewable subscription to be.

Recorded honestly: the portfolio's own evidence file
(`IOS Apps Portfolio/reports/lifetime-vs-subscription-2026-07.md`) shows 92.8% of all revenue this
portfolio ever earned came from one-time purchases. The move to subscription is an **owner policy
decision** (2026-08-06 structure law, reaffirmed for this app 2026-08-12), not a reading of that
evidence. Writing it down is the point: if the monitoring thresholds below trip, this paragraph is
where the review starts.

## Live competitor evidence

Ranked impulse-control / no-spend niche, US storefront, pulled 2026-08-12
(`ev:us/stop-impulse-buying`, `ev:us/no-spend-challenge`):

| App | Ratings | Indie/Funded | Structure | Prices |
|---|---|---|---|---|
| **Stop Impulse Buying \| Budget** (Shawstad) | 76 | indie | monthly + yearly | $9.99/mo · $49.99/yr |
| **MoodWallet: Mind Your Money** (Jomo Labs) | 145 | indie | monthly + yearly | $6.99–12.99/mo · $49.99–89.99/yr |
| **ThinkTwice – Save Money** (Lit Apps) | 192 | indie | weekly + yearly + lifetime | $5.99/wk · $29.99–34.99/yr · $19.99 lifetime |
| **bless. minimal shopping habits** (Stoic) | 204 | indie | yearly only | $14.99/yr |
| **Track Spending: Wise Budget** | 2 958 | indie | monthly + quarterly + 6mo + yearly + lifetime | $4.99/mo · $29.99/yr · $149 lifetime |
| **Dollarwise: Budget & Tracking** | 3 809 | funded | monthly + quarterly + yearly + one-time | $14.99/mo · $39.99/qtr · $89.99/yr |
| **Money+ Cute Expense Tracker** | 3 820 | funded | monthly + yearly + lifetime | $1.49/mo · $9.99/yr · $12.99 lifetime |
| **Fleur – Budget Planner** | 12 550 | indie | monthly + yearly + lifetime | $6.99/mo · $29.99–39.99/yr · $9.99–25.99 lifetime |
| **Spending Tracker** (MH Riley) | 19 342 | indie | one-time only | $2.99 |
| **Monefy: Money Tracker** | 6 615 | funded | one-time | $59.99 |
| **YNAB** | 61 164 | funded | monthly + yearly | $14.99/mo · $109/yr |

**IAP not readable** (archived as such, per §3 — never silently skipped):
Boycott Detective (151★) · Spendback (411★) · Crew Finance (1 300★) · Budget app – spending tracker
(15 425★) · Surveys On The Go · Coupa Mobile · ChallengeRunner · Challenges – Compete Get Fit ·
Apple Store · YearsHK. Product pages carried no "In-App Purchases" block, or the page did not fetch.

**Gate-computed medians** (`market-preflight.mjs`, 2026-08-12): yearly median **$34.99** (n=7,
floor $17.50) · monthly median **$6.99** (n=4, floor $3.50).

## Structure decision

**One monthly + one yearly auto-renewable, 7-day free trial. Nothing else.**

### Considered and rejected tiers

Every excluded tier, one sentence each, all cited — why these tiers and not the others:
- **Weekly rejected:** only ThinkTwice sells one ($5.99/wk), a burst pattern that contradicts a
  daily-habit product (`ev:us/stop-impulse-buying#appId=6757983716.iap`).
- **Lifetime rejected:** retired portfolio-wide by owner law 2026-08-06. In-niche it stays common
  (ThinkTwice $19.99, Fleur $9.99–25.99, Track Spending $149), so this is a house decision and is
  recorded as such rather than dressed up as a market reading.
- **Quarterly rejected:** present in one archived app only (Dollarwise $39.99/qtr) and in none of
  the ranked impulse-control rivals; a mid-rung splits an already thin funnel.
- **Trial 7 days:** house default, no citation owed. RevenueCat 2026 (115k apps): sub-4-day trials
  convert at 25.5% and 55% of 3-day cancellations happen on day 0 — three days cannot show what a
  streak app does, because a streak does not exist yet on day 3.

### The retired product

`com.ufukozdemir.nobuy.pro` ($4.99 non-consumable, **60 owners**) is **removed from sale but never
deleted**. It stays in `Sources/NoBuy.storekit` so the inherited-entitlement path stays testable in
the simulator, and it is declared in `.market/preflight.json` as `pricing.retiredSkus` — the gate
prints it on every run and excludes it from tier counting. Existing owners keep every Pro feature
permanently; the paywall never opens for them.

## Level decision

| Tier | Price | Position |
|---|---|---|
| Monthly | **$4.99** | Matches the cheapest credible rival exactly (Track Spending $4.99); half of Stop Impulse Buying's $9.99. Median $6.99, floor $3.50 → clears it with room. |
| Yearly | **$39.99** | **Under** the two closest rivals ($49.99 at both Stop Impulse Buying and MoodWallet), **over** the $34.99 median. Mid-premium. |

**Rationale.** The app carries **0 ratings**, so it cannot charge on reputation — the monthly rung
is set at the floor of the credible band to keep the entry decision small, and it happens to equal
the $4.99 the funnel has already proved people will pay. The yearly rung carries the margin, priced
below the direct rivals so the comparison always favours us. Yearly is **33% cheaper** than twelve
monthly renewals ($59.88 → $39.99) — a real discount, stated truthfully on the paywall, with no
strikethrough theatre against a price that never existed.

What justifies sitting above the median at all: no ranked rival ships the in-the-moment
intervention layer (urge-surfing timer, impulse checklist, 24h waiting list). They track spending;
NoBuy intervenes before it happens.

## Monitoring thresholds

Derived from **this app's own baseline**, not from a house anchor. Baseline: ~976 downloads and 60
one-time purchases over 105 days = **~280 downloads/month, ~6% paid conversion, ~$35/month proceeds**.

| Signal | Threshold | Action |
|---|---|---|
| Trial start rate | < 6% of new downloads for 4 consecutive weeks | The paywall converts worse than the old one-time wall did with the same traffic — treat as a paywall defect first, a price question second. |
| Trial → paid | < 25% for 4 consecutive weeks | Below RevenueCat's worst observed band. Step the yearly down one rung ($39.99 → $29.99, the niche median) before touching monthly. |
| Net proceeds | < $35/month for 8 consecutive weeks | The migration is losing to the model it replaced. **Report to owner** with the numbers — reverting the structure is an owner decision, not mine. |
| Ratings | ≥ 25 ratings at ≥ 4.5★ | Social proof now exists; evaluate $5.99/$49.99 (still under both direct rivals). |
| Rival move | Any ranked rival ships a credible one-time unlock under $10 with traction | Reassess — that was our wedge and someone would have taken it. |

## Apply checklist

- [ ] Subscription group created; both plans created with **territory availability set at creation
      time** (the #1 MISSING_METADATA root cause), then equalized
- [ ] 7-day introductory offer attached to both plans
- [ ] `Sources/NoBuy.storekit` carries both new plans **and** the retired non-consumable
- [ ] No hardcoded price anywhere: `grep -rn '\$[0-9]' Sources/` returns nothing user-facing —
      every price renders from StoreKit `displayPrice`
- [ ] Store description, paywall copy, onboarding and Settings no longer claim "no subscription"
- [ ] Review screenshot captured from the FINAL paywall, once; **no promo image on any product**
      (the 2.3.2 trap)
- [ ] Submit completeness: both plans READY_TO_SUBMIT **and attached** to the review submission
