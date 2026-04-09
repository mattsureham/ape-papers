# Research Plan: Direct Democracy and the Minimum Wage

## Research Question
Do the world's highest minimum wages reduce employment? Five Swiss cantons adopted cantonal minimum wages of CHF 19–24/hr via popular referendum between 2017 and 2022 — the highest statutory floors globally. We estimate the causal effect on employment, establishments, and firm entry/exit using a staggered difference-in-differences design.

## Institutional Background
Switzerland has no federal minimum wage (rejected 76.3% in a 2014 national referendum). Five cantons subsequently adopted their own:
- Neuchâtel: CHF 20.08/hr (August 2017)
- Jura: CHF 20.00/hr (January 2018)
- Geneva: CHF 23.00/hr (November 2020)
- Ticino: CHF 19.00/hr (December 2021)
- Basel-Stadt: CHF 21.00/hr (July 2022)

All were adopted via popular referendum or parliamentary vote following cantonal initiative. Rates are indexed annually.

## Identification Strategy
**Callaway & Sant'Anna (2021) staggered DiD.** Five treated cantons adopt at five different times; 21 cantons never adopt (including those that explicitly rejected cantonal minimum wages). Key advantages:
1. Heterogeneity-robust: avoids negative weighting from staggered TWFE
2. Group-time ATTs allow dynamic treatment effects
3. Pre-trends directly testable with 6+ pre-treatment years

**Triple-difference:** High-bite sectors (hospitality NOGA 55-56, retail 47, cleaning 81) vs. low-bite sectors (finance 64-66, pharma 21, IT 62) within treated vs. never-treated cantons. This controls for canton-level shocks that affect all sectors equally.

## Expected Effects
- **Employment:** Small negative or null. Swiss labor markets are flexible with high union coverage — the bite may be lower than US/UK settings despite high nominal levels. Prior literature (Dube 2019) suggests employment effects are near zero for moderate minimum wages; these are extreme values but in a high-wage economy.
- **Firm dynamics:** Possible reduction in new firm entry in low-wage sectors, with exit effects for marginal establishments.
- **Mechanism:** If effects are null, the direct democracy channel matters — referendums may select for minimum wages calibrated to local labor markets (political endogeneity working in favor of identification).

## Data Sources
1. **BFS STATENT** (Statistik der Unternehmensstruktur): Annual employment, establishments, FTE by canton × NOGA 2-digit industry. 2011-2023. PXWeb API, no key needed.
2. **BFS UDEMO** (Unternehmensdemografie): Firm births and deaths by canton. 2013-2023. PXWeb API.
3. **SECO unemployment:** Monthly registered unemployment by canton. Public CSV.

## Primary Specification
```
Y_{c,s,t} = α + τ(g,t) + γ_c + δ_s + θ_t + ε_{c,s,t}
```
Where c = canton, s = sector, t = year. τ(g,t) = group-time ATT from CS estimator. Standard errors clustered at canton level (wild cluster bootstrap with 5 treated clusters).

## Robustness
1. Event study plots (dynamic ATTs from CS)
2. HonestDiD sensitivity analysis for parallel trends violations
3. Sun & Abraham (2021) as alternative staggered estimator
4. Placebo: high-wage sectors (finance, pharma) as outcomes
5. Dose-response: bite variation across cantons × sectors
6. Bacon decomposition to diagnose TWFE contamination
