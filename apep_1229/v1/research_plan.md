# Research Plan: apep_1229

## Research Question

Did the FCA's General Insurance Pricing Practices (GIPP) loyalty penalty ban — which required that renewal premiums not exceed equivalent new business prices from January 1, 2022 — reduce competitive pressure in the UK motor insurance market? Specifically, did the dramatic collapse in quote price dispersion (inter-quartile range from 37.7% to 11.4%) reflect genuine competition driving prices toward cost, or tacit coordination enabled by regulatory uniformity?

## The Mechanism: The Convergence Trap

Price discrimination bans can paradoxically facilitate tacit collusion. When firms can no longer charge heterogeneous prices across customer segments, the price distribution compresses. This compression makes it easier for firms to monitor each other's pricing and detect deviations — a classic ingredient for tacit coordination. The prediction: if dispersion collapse reflects coordination rather than competition, firm-level loss ratios should *fall* (firms retain more premium per pound of claims), industry profitability should *rise*, and market concentration should increase or remain stable (no new entry driven by competitive pressure).

## Identification Strategy

**Event study around January 1, 2022** — the GIPP implementation date.

**Primary test:** Firm-level loss ratios (claims paid / premiums earned) from FCA General Insurance Value Measures data. If GIPP enhanced competition: loss ratios should rise or stay stable (competition drives prices toward cost). If GIPP enabled coordination: loss ratios should fall (firms extract larger margins).

**Cross-product difference-in-differences:** Motor and home insurance (directly subject to GIPP loyalty penalty ban) vs. other insurance lines (pet, travel, commercial — less directly affected) as controls. This nets out aggregate industry trends (interest rates, claims inflation, regulatory burden).

**Secondary outcomes:**
- Combined operating ratio (BoE aggregates) — profitability metric
- Net premium written (BoE) — market size/entry dynamics
- Market concentration (HHI from firm-level data)

## Expected Effects

Under the "convergence trap" hypothesis:
1. Loss ratios fall post-GIPP in motor/home relative to other lines
2. Combined ratios fall (higher profitability)
3. No increase in market entry (new firms) despite higher margins
4. Price dispersion collapse is accompanied by level increases (average premium rises)

Under the "genuine competition" hypothesis:
1. Loss ratios stable or rise
2. Margins compress
3. Consumer switching increases
4. Average premiums fall relative to claims costs

## Primary Specification

```
LossRatio_{f,l,t} = α_f + γ_t + β₁(Post_t × Motor_l) + X'_{f,t}δ + ε_{f,l,t}
```

Where f indexes firms, l indexes insurance lines (motor vs. other), t indexes years, Post_t = 1 for 2022+. β₁ is the DiD estimate — negative β₁ = falling loss ratios in motor relative to other lines post-GIPP.

Cluster standard errors at the firm level.

## Data Sources

1. **FCA GI Value Measures (2015–2024)** — Firm-level annual data on premiums written, claims paid, loss ratios, by insurance line. Excel download from FCA website.

2. **Bank of England Insurance Aggregate Data** — Quarterly industry-level data on premiums, claims, combined ratios, investment income, by line of business. CSV download.

3. **ABI Premium Tracker / Confused.com WTW Index** — Quarterly average premium and dispersion statistics. Compiled from published reports.

## Feasibility Assessment

- **Sharp treatment:** GIPP effective date is January 1, 2022 — no ambiguity
- **Pre-periods:** GI VM data from at least 2015 (~7 pre-treatment years)
- **Post-periods:** Through 2024 (~3 years post-treatment)
- **Cross-product variation:** Motor/home (treated) vs. pet/travel/commercial (control)
- **Sample size:** ~195 firms in GI VM × multiple years × multiple lines
- **Risk:** GI VM data may be annual only (limits event-study dynamics); BoE data quarterly but aggregated (no firm variation)
