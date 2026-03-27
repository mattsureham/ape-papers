# Research Plan: The Border Escape Valve — Abortion Restrictions and the Geography of Fertility in Poland

## Research Question

Does the effective cost of an abortion restriction — determined by distance to foreign clinics — shape its demographic impact? Poland's 2020 Constitutional Tribunal ruling banning fetal-anomaly abortion (97% of legal procedures) created a nationally uniform policy shock with spatially heterogeneous access costs.

## Identification Strategy

**Design:** Continuous-treatment DiD with a single national shock and border-distance gradient.

**Estimating equation:**
TFR_{r,t} = α_r + γ_t + β(Post_t × DistanceKm_r) + X_{r,t}Γ + ε_{r,t}

- Post_t = 1 for 2021 onward (effective date: January 27, 2021)
- DistanceKm_r = road distance from region centroid to nearest Czech/German abortion clinic
- β > 0: distant regions see relatively larger TFR increases (can't substitute to foreign clinics)
- β < 0: distant regions see larger TFR *declines* (chilling effect on family formation)

**Key assumptions:**
1. Parallel pre-trends in TFR across distance quintiles (testable, 6 pre-periods 2015-2020)
2. Distance to border clinics uncorrelated with other voivodship-level shocks (distance is predetermined)
3. No anticipation effects before October 2020

**Unit of analysis:** NUTS2 voivodships (N=17) or NUTS3 subregions (N=73 if available)

## Expected Effects and Mechanisms

1. **Substitution channel:** Women in border regions travel abroad for procedures → TFR unchanged near border, increased far from border → β > 0
2. **Chilling effect:** Restriction deters family formation broadly → TFR declines everywhere, possibly more in distant regions (fewer options → more uncertainty) → β ambiguous
3. **Political backlash:** Ruling provoked massive protests → delayed childbearing → β < 0 if protests concentrated in urban/distant areas

## Primary Specification

- Panel: 17 NUTS2 × 9 years (2015-2023) = 153 observations
- FE: Voivodship + Year
- Clustering: Voivodship level (17 clusters → wild cluster bootstrap)
- Robustness: NUTS3 panel, HonestDiD sensitivity, distance quintile event study

## Data Sources

1. **Fertility:** Eurostat `demo_r_find2` (NUTS2 TFR) and `demo_r_find3` (NUTS3 live births)
2. **Distance:** Computed from voivodship capitals to nearest Czech/German clinic (Brno, Ostrava, Prenzlau, Berlin)
3. **Cross-border procedures:** Czech ÚZIS abortion statistics by patient nationality
4. **Protests:** ACLED Poland events 2018-2023
5. **Elections:** PiS vote share change 2019→2023
6. **Controls:** GDP per capita, unemployment rate, urbanization (Eurostat regional statistics)
