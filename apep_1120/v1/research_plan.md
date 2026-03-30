# Research Plan: apep_1120

## Research Question
Does emigration to newly opened labor markets raise wages for workers who remain in sending regions, or does it accelerate economic decline through capital flight, fiscal drain, and adverse selection?

## Setting
Romania's January 1, 2014 lifting of transitional labor market restrictions by Germany, France, and Austria. Romania joined the EU in 2007, but nine EU-15 countries retained work permit requirements for Romanian workers until the maximum allowable date. On January 1, 2014, Germany, France, the Netherlands, Belgium, and Austria simultaneously opened their labor markets (Austria for some sectors until April 30, 2014). Romania→Germany immigration jumped from ~24K/year (2008-2013 average) to 97K in 2014 — a 4x shock.

## Identification Strategy

### Main Design: Continuous-Treatment DiD
**Specification:**
```
log(Y_{c,t}) = α_c + λ_t + β · (θ_c × Post2014_t) + X_{c,t}′γ + ε_{c,t}
```

Where:
- Y_{c,t}: outcome (wages, employment, population) for county c in year t
- α_c: county fixed effects
- λ_t: year fixed effects
- θ_c: pre-2014 county emigration propensity to Germany/France/Austria (exposure variable)
- Post2014_t: indicator for t ≥ 2014
- X_{c,t}: time-varying controls interacted with Post (if needed)

### Exposure Variable (θ_c)
**LOCKED:** Average annual emigration rate to Germany from INSSE POP309D, window 1990-2006. This pre-dates EU accession (2007) and the euro crisis. Window is frozen ex ante — not to be reopened.

### Why Not Fuzzy RD
The restriction lifting was a clean national policy date (January 1, 2014), not a threshold. All counties were treated simultaneously with differential intensity based on historical migration networks.

### Outcomes (Triple-Outcome Design)
1. **Wages** (headline): INSSE FOM106E — county-level average net monthly wages by CAEN sector, 42 counties, 2008-2024
2. **Employment** (headline): INSSE FOM105G — county-level employment
3. **Population** (validation/accounting): INSSE POP309A — county-level emigration; working-age population

All three reported side-by-side. If wages rise + employment falls + population drops = honest composition story, not pure incumbent gains.

### Controls (Absorbing Structural Divergence)
Interact baseline county characteristics with Post2014:
- Initial wage level (2008-2013 average)
- Manufacturing employment share
- Urbanization rate
- West-region indicator
- Pre-trend wage slope (2008-2013)

### First Stage
Show destination-specific, dynamic first stage:
- High-θ counties show discrete post-2014 jump in Germany-directed emigration
- No differential pre-trend in Germany emigration by θ
- No comparable 2014 jump in Italy/Spain-directed emigration for the same counties

### Placebos and Falsification
1. **Fake break years**: Estimate specification with placebo breaks at 2011, 2012 — should be null
2. **Italy/Spain-exposed counties**: Counties with high historical emigration to Italy/Spain (which opened in 2007, not 2014) should show no 2014 break. Use as placebo treatment group.
3. **Event study**: Full dynamic specification with year-by-year θ × YearDummy interactions, 2008-2023
4. **Predetermined outcomes**: Verify no pre-trend in wages, employment by θ in 2008-2013

### Inference
- Cluster SEs at county level (42 clusters — borderline but standard)
- Wild cluster bootstrap (via `fixest` + manual implementation or `boottest` in R)
- Randomization inference: permute θ across counties
- Leave-one-county-out jackknife: show no single NW county drives the result
- Remove Bucharest sensitivity check

### Kill-Switch Conditions (Pre-Committed)
If the first stage lacks a clean 2014 break (no discrete jump in Germany emigration by θ), or the Italy/Spain placebo shows a 2014 break, we downshift the claim rather than argue around it. If both fail, we resolve the idea as failed.

## Data Sources
| Source | Variable | Coverage | Access |
|--------|----------|----------|--------|
| INSSE FOM106E | County wages by sector | 42 counties, 2008-2024 | REST API |
| INSSE FOM105G | County employment | 42 counties, 2008-2024 | REST API |
| INSSE POP309A | County emigration (total) | 42 counties, 1990-2024 | REST API |
| INSSE POP309D | Emigration by destination | 16 destinations, 1990-2024 | REST API |
| Eurostat migr_imm1ctz | Immigration to Germany by origin | Annual, 2000-2023 | REST API |

INSSE API: https://statistici.insse.ro:8077/tempo-ins/

## DDD Extension (Secondary)
Germany-exposed vs Italy/Spain-exposed counties × pre-2014 vs post-2014:
```
log(Y_{c,t}) = α_c + λ_t + β₁(θ_DE_c × Post) + β₂(θ_IT/ES_c × Post) + ...
```
If β₁ > 0 and β₂ ≈ 0, the effect is specific to the 2014 restriction-lifting shock, not general western-exposure divergence.

## Sector Heterogeneity
INSSE FOM106E has 12 CAEN sectors × 42 counties. Test whether wage effects concentrate in construction and agriculture (sectors where Romanian workers in Germany concentrate) vs. services (where they don't).

## Named Mechanism
Working title: "The Exodus Dividend" — whether emigration to newly open markets raises wages for stayers through labor-supply reduction, or "The Hollowing-Out Trap" — if it accelerates decline. Final framing depends on results.

## Expected Sample Size
- County-year: 42 × 17 = 714 observations
- County-sector-year: 42 × 12 × 17 = 8,568 observations
- High-θ counties (NW/West): ~12-15 counties
- Low-θ counties (NE/Moldova/South): ~20-25 counties

## Code Structure
```
code/00_packages.R       — Libraries (fixest, did, dplyr, arrow, ggplot2)
code/01_fetch_data.R     — INSSE API + Eurostat API data fetching
code/02_clean_data.R     — Construct θ, merge panels, create treatment variables
code/03_main_analysis.R  — Main regressions + first stage + diagnostics.json
code/04_robustness.R     — Placebos, RI, jackknife, event study
code/05_tables.R         — Generate LaTeX tables + SDE appendix
```

## Timeline Commitment
- Phase gate: research_plan.md committed before any data fetch
- Smoke test: verify INSSE API returns data before committing to full fetch
