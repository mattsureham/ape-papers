# Research Plan: The Compression Shock — Cross-Baltic Evidence on Extreme Minimum Wage Binding

## Research Question
Does the largest minimum wage increase in EU history — Lithuania's 2019 +46% hike (400→555 EUR) — cause differential employment losses in sectors where the minimum wage binds most intensely? We test whether the consensus of "small disemployment effects" holds at the extreme, using a cross-Baltic sector-level DiD that exploits variation in pre-reform Kaitz binding intensity.

## Identification Strategy
**Continuous-treatment DiD** with cross-national controls.

- **Unit:** (country, ISIC4 sector, year)
- **Treatment:** Lithuania × Post-2019 × Kaitz_s,2018 (pre-reform sector-level MW/mean_wage ratio)
- **Controls:** Latvia (0% MW increase in 2019) and Estonia (+8% increase — moderate dose)
- **Fixed effects:** Country × sector (absorb level differences), Country × year (absorb macro shocks)

Core specification:
```
ln(emp_cst) = α_cs + γ_ct + β·(LT_c × Post2019_t × Kaitz_s,2018,LT) + ε_cst
```

β identifies the differential employment response per unit of Kaitz binding intensity in Lithuania relative to Baltic peers.

## Expected Effects and Mechanisms
- **Main prediction:** β < 0 — high-binding sectors (accommodation, agriculture, retail) lose employment relative to low-binding sectors (ICT, finance) after Lithuania's extreme hike.
- **Magnitude prior:** At +46%, effects may be larger than the consensus elasticity (-0.1 to -0.3). A null would be equally interesting — suggesting monopsony even at extreme shock sizes.
- **Mechanisms:** (1) Substitution toward capital/automation in high-binding sectors, (2) Informality/shadow economy absorption, (3) Hours reduction rather than headcount.

## Primary Specification
- **Outcome:** ln(sector employment in thousands), ILO STAT
- **Treatment intensity:** 2018 Kaitz index = MW / sector mean wage (Lithuania), pre-determined
- **Robustness:**
  - Placebo tests: Lithuania's 2013 (+18%) and 2016 (+24%) MW hikes as earlier events
  - Triple-difference with Estonia as partial treatment (+8%)
  - Leave-one-sector-out stability
  - Wild cluster bootstrap (3 countries = few clusters)

## Data Sources and Fetch Strategy
1. **ILO STAT API** (no credentials needed):
   - `EMP_TEMP_SEX_ECO_NB_A` — sector employment by ISIC4, LTU/LVA/EST, 2013–2023
   - `EAR_4MTH_SEX_ECO_CUR_NB_A` — sector average monthly wages, LTU/LVA/EST, 2013–2023
2. **Eurostat SDMX API** (no credentials needed):
   - `earn_mw_cur` — semi-annual minimum wages, LT/LV/EE, 2010–2023
3. All confirmed live in idea smoke tests.

## Key Risk
**Few clusters (3 countries).** Standard clustered SEs are unreliable. Mitigation: wild cluster bootstrap, randomization inference over sectors, and the placebo events (2013, 2016) serve as falsification.
