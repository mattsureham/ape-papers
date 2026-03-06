# Initial Research Plan: How Many Generics Does It Take?

## Research Question

How much does each additional generic competitor reduce drug acquisition costs, and at what number of competitors does the marginal price effect effectively reach zero?

## Identification Strategy

**Stacked event study at the drug-market level.** Each "event" is an FDA ANDA approval date that adds a new generic manufacturer to a drug market (defined as ingredient × dosage form × strength). The same drug market serves as its own control (before vs. after the Nth entrant).

**Separate event studies by entry position N = 2, 3, ..., 10.** This traces the full marginal competition curve non-parametrically. Each position-specific event study uses only markets experiencing that specific entry event during the sample period.

**Estimating equation:**
For each entry position N:
Δln(NADAC_{i,t}) = Σ_{k=-24}^{52} β_k · 1[t - t*_{i,N} = k] + α_i + γ_t + ε_{i,t}

- i = drug market (ingredient × form × strength)
- t = calendar week
- t*_{i,N} = approval date of Nth generic entrant
- α_i = drug-market fixed effects
- γ_t = calendar-week fixed effects
- Pre-window: 24 weeks; Post-window: 52 weeks

**Stacked design:** For each entry position N, stack all drug markets experiencing that entry event. Require minimum 12-week gap between consecutive events for a given market (clean window). Exclude overlapping events.

## Expected Effects and Mechanisms

1. **First generic entrant (N=1):** Large price drop (30-50% based on existing cross-sectional evidence)
2. **Second entrant (N=2):** Substantial additional decline (10-20%)
3. **Third-fourth entrant (N=3-4):** Moderate additional decline (5-15%)
4. **Fifth+ entrant (N≥5):** Diminishing returns — marginal effect approaching zero

**Key mechanism:** Competition among generic manufacturers for pharmacy/PBM contracts. Initial entry breaks the brand monopoly; subsequent entry intensifies price competition until margins hit production costs.

**The policy-relevant threshold:** At what N does β_{52} (the 52-week post-entry effect) become statistically indistinguishable from zero? This is the "effectively competitive" market structure number — the information FDA/FTC need for policy.

## Primary Specification

1. **Main results table:** Estimated 52-week price effect (β_{52}) for each entry position N=1 through 10, with 95% CIs.
2. **Event-study figures:** One figure per entry position showing the full {β_{-24}, ..., β_{52}} coefficient path. Pre-trends visible.
3. **Marginal competition curve:** Plot β_{52} against entry position N. This is the paper's signature figure.

## Data Sources

| Data | Source | Unit | Coverage |
|------|--------|------|----------|
| Drug pricing | CMS NADAC | NDC × week | 2013-2025 |
| Entry events | FDA Orange Book | ANDA × approval date | All time (37,025 ANDAs) |
| NDC crosswalk | openFDA Drug Label API | NDC → ANDA | 36,096 labels |
| Drug shortages | FDA Drug Shortages DB | ingredient × date | Current + historical |
| Patent/exclusivity | Orange Book patent.txt, exclusivity.txt | ANDA × patent | 20,174 patents |

## Planned Robustness Checks

1. **Pre-trend tests:** Joint F-test, individual coefficient plots, Rambachan-Roth sensitivity
2. **Alternative event dates:** First NDC appearance in NADAC vs. ANDA approval date
3. **Clean-window thresholds:** 12, 24, 36-week minimum gap between events
4. **Shortage controls:** Exclude drug-weeks during FDA shortage events
5. **Exclusivity controls:** Separate first-filer 180-day exclusivity from open competition
6. **CS-DiD estimator:** Callaway-Sant'Anna for formal heterogeneity-robust estimates
7. **Donut specifications:** Exclude first 4 weeks post-entry (adjustment period)
8. **Market definition:** Robustness to broader (ingredient × form) and narrower (ingredient × form × strength × route) market definitions
9. **Therapeutic-class spillovers:** Does entry for Drug A reduce prices of therapeutic substitutes?

## Welfare / Policy Extension

1. **Annual Medicaid savings from the Nth entrant:** Combine price effect estimates with CMS Medicaid State Drug Utilization quantities to compute dollar savings from each additional competitor.
2. **Optimal FDA review capacity:** Back-of-envelope cost-benefit of faster GDUFA review (cost of extra reviewers vs. price savings from earlier entry).
3. **"Effectively competitive" threshold:** Report the N* at which marginal price effects are indistinguishable from zero — the key policy parameter for generic drug regulation.
