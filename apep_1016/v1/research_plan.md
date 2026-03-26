# Research Plan: The Fresh Start Dividend — Bankruptcy Judge Leniency and Post-Discharge Business Formation

## Research Question

Does consumer debt relief causally increase entrepreneurship? We exploit random assignment of Chapter 13 bankruptcy cases to federal bankruptcy judges with varying confirmation propensities to estimate the causal effect of debt discharge on post-bankruptcy business formation.

## Motivation

Over 300,000 Americans file Chapter 13 bankruptcy annually, proposing 3–5 year repayment plans. Judges vary substantially in confirmation rates (40–70% within districts). The "fresh start" doctrine aims to free debtors from debt overhang, but whether this release translates into productive economic activity—specifically entrepreneurship—is unknown. If debt relief causally increases business formation, bankruptcy policy has benefits beyond financial relief.

## Identification Strategy

**Judge-leniency IV** (Kling 2006; Dobbie & Song 2015):
- Cases are randomly assigned to judges within each federal bankruptcy court
- Leave-one-out mean confirmation rate for each judge (excluding the focal case) instruments for Chapter 13 plan confirmation
- Court-by-year fixed effects absorb district-level trends
- 2SLS: Judge leniency → Plan confirmation → Business formation

**Key assumptions:**
1. Random assignment (verified by balance tests on debtor characteristics)
2. Exclusion restriction: Judge leniency affects business formation only through plan confirmation (standard in literature)
3. Monotonicity: More lenient judges weakly increase confirmation probability for all case types

## Data Sources

1. **CourtListener RECAP Archive** — Federal bankruptcy case dockets with judge identifiers, case outcomes, filing dates, court/division. ~220,000 Chapter 13 cases (2010–2020). Free, no authentication required.

2. **Census Business Formation Statistics (BFS)** — Monthly county-level business applications (BA), high-propensity business applications (HBA), and business applications with planned wages (WBA). Available via Census API. 2004–present.

3. **Census Business Dynamics Statistics (BDS)** — Annual county-level firm births, deaths, establishment counts. Available via Census API.

## Empirical Approach

### Level of Analysis
Court-division × year panel. Each federal bankruptcy court division maps to a set of counties. We aggregate:
- **Treatment side:** Mean judge leniency (leave-one-out) of judges handling cases filed in division d, year t
- **First stage:** Division-year confirmation rate
- **Outcome:** Business applications in division d's counties, years t+1 to t+3

### Specifications

1. **Reduced form:** Business formation = f(average judge leniency, court×year FEs)
2. **First stage:** Confirmation rate = f(judge leniency, court×year FEs)
3. **2SLS:** Business formation = f(predicted confirmation rate, court×year FEs)

### Robustness
- Placebo outcomes: Non-entrepreneurship county outcomes (e.g., employment, population)
- Heterogeneity by district size, pre-filing business activity levels
- Different lag structures (t+1, t+2, t+3, cumulative)
- Alternative leniency measures (residualized, time-varying)

## Expected Effects

**Prior:** Moderate positive. Debt overhang theory (Myers 1977) predicts that relieving excessive debt frees resources and reduces risk aversion, enabling entrepreneurship. The SDE is likely in the small-to-moderate positive range (0.01–0.10), as bankruptcy affects a subset of the population and business formation is a relatively rare outcome.

**Null result interpretation:** If null, this suggests that debt overhang is not the binding constraint for entrepreneurship among bankruptcy filers—perhaps credit access, human capital, or risk tolerance matter more.

## Primary Specification

```
BizFormation_{d,t+k} = β · ConfirmRate_{d,t} + γ_{c,t} + ε_{d,t}
```

Where ConfirmRate_{d,t} is instrumented by AvgLeniency_{d,t} (leave-one-out), γ_{c,t} are court-by-year FEs, and k ∈ {1,2,3}.

## Timeline and Risks

**Main risk:** CourtListener data may not cleanly map cases to geographic divisions needed for county-level matching. Mitigation: use court-level aggregation (90 districts × 10 years = 900 obs) if division-level mapping fails.

**Secondary risk:** Judge leniency variation may be absorbed by court-by-year FEs if there are few judges per court-year. Mitigation: use court FEs + year FEs separately, or restrict to large districts.
