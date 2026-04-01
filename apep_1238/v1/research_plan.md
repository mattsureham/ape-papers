# Research Plan: apep_1238

## Idea
idea_2051 — The Price of a 1946 Decision: Hill-Burton Hospital Placement, Market Concentration, and Medicare Spending

## Research Question
Does historical hospital infrastructure — shaped by the Hill-Burton Act's formula-driven funding (1946-1971) — create persistent market concentration that still determines Medicare spending today?

## Identification Strategy
**Instrumental Variables (2SLS):**
- **Endogenous variable:** Hospital market HHI (Herfindahl-Hirschman Index) at county level
- **Instrument:** Hill-Burton-era hospital infrastructure legacy, proxied by hospital beds per capita in the 1970s-1980s (post-Hill-Burton)
- **Exclusion restriction:** 1946 bed deficiency formula drove funding allocation; bed capacity created in the 1950s-60s affects 2020s spending only through persistent hospital infrastructure and market structure
- **Within-state variation:** Include state fixed effects to exploit county-level variation in Hill-Burton exposure within states

## Expected Effects and Mechanisms
- **First stage (expected strong):** More Hill-Burton-era hospital capacity → more hospitals survived → lower current HHI
- **Second stage (expected negative):** Lower HHI → lower Medicare per-beneficiary spending
- **Mechanism: "persistence of competition"** — federal investment in hospital capacity 75 years ago created competitive market structures that persist and continue to constrain prices
- **Magnitude:** Cooper et al. (QJE 2019) find 1 SD increase in HHI → ~5% higher prices. Expect similar or smaller effects on Medicare spending (administered prices dampen concentration effects)

## Primary Specification
```
Spending_c = α + β·HHI_c + X_c'γ + δ_s + ε_c    (OLS)
HHI_c = π + ρ·HB_Beds_c + X_c'λ + δ_s + ν_c     (First stage)
```
Where:
- c = county, s = state
- Spending_c = standardized Medicare per-beneficiary spending (2019-2022 average)
- HHI_c = hospital discharge HHI
- HB_Beds_c = historical beds per capita (1970s-1980s, post-Hill-Burton)
- X_c = controls: current population, income, poverty rate, age distribution, health status
- δ_s = state fixed effects

## Data Sources

### Outcomes (confirmed accessible)
1. **CMS Geographic Variation PUF** — County-level standardized Medicare per-beneficiary spending, 2007-2022. Free at data.cms.gov.

### Market Structure
2. **CMS Provider of Services (POS)** — Universe of Medicare-certified hospitals with county, bed count, discharges. Construct HHI.
3. **AHRQ Hospital Market Structure files** — Pre-computed HHI (backup).

### Instrument
4. **HRSA Area Health Resources Files (AHRF)** — County-level hospital beds, physicians, demographics. Historical series. Free download.
5. **Fallback:** Construct from CMS POS hospital founding dates (hospitals founded 1946-1971 as Hill-Burton proxy).

### Controls
6. **Census/ACS** — County demographics (population, age, income, poverty)
7. **CMS** — County-level Medicare enrollment, risk adjustment scores

## Robustness Checks
1. **Placebo outcomes:** Non-hospital spending (Part B physician, Part D drugs) — should show weaker/no concentration effect
2. **First-stage diagnostics:** F-statistic, instrument relevance
3. **Overidentification:** Use multiple instruments (beds/capita at different historical years)
4. **Functional form:** Linear HHI, log HHI, HHI quartiles
5. **Controls sensitivity:** Progressively add controls, Oster (2019) bounds
6. **Exclude outliers:** Drop counties with extreme HHI (monopoly/monopsony)
7. **Subsample:** Rural vs. urban markets

## Fallback Plan
If Hill-Burton-era instrument proves infeasible (data quality or relevance):
- **Plan B:** Use 1990s hospital counts/beds as longer-lagged instrument (still pre-ACA, pre-major consolidation)
- **Plan C:** Exploit hospital merger/closure events (2000-2015) for within-county variation in HHI over time → panel DiD
