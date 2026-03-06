# Initial Research Plan — apep_0543

## Research Question

Does rent control capitalize into property sale prices? We exploit France's staggered adoption of the *encadrement des loyers* across 10+ cities (2019–2025) to estimate the causal effect of rent ceilings on property transaction values using the universe of French property sales (DVF).

## Identification Strategy

**Triple-Difference (DDD):**
1. **City margin:** Controlled vs. uncontrolled cities (staggered DiD using Callaway-Sant'Anna)
2. **Time margin:** Pre vs. post rent-control adoption
3. **Property-type margin:** Investment-type properties (studios, 1-2 room apartments — high rental probability) vs. owner-occupier-type properties (houses, 3+ room apartments — low rental probability)

The third difference nets out any city-level common shock. The identifying assumption: absent rent control, the price gap between investment-type and owner-occupier-type properties would have evolved similarly in treated and control cities.

**Why DDD is credible:**
- Rent control directly reduces expected rental income for investment properties
- Owner-occupiers are unaffected by rental ceilings (they live in the property)
- City-specific shocks (COVID, infrastructure, demand shifts) affect both property types equally within a city

## Treatment Details

| City/Agglomeration | Adoption Date | Pre-Period | Post-Period |
|---|---|---|---|
| Paris | July 1, 2019 | 2014-2019H1 | 2019H2-2025 |
| Lille (+Hellemmes, Lomme) | March 1, 2020 | 2014-2020Q1 | 2020Q2-2025 |
| Plaine Commune (9 communes) | June 1, 2021 | 2014-2021Q1 | 2021Q2-2025 |
| Est Ensemble (9 communes) | December 1, 2021 | 2014-2021Q3 | 2022-2025 |
| Lyon + Villeurbanne | November 1, 2021 | 2014-2021Q3 | 2022-2025 |
| Montpellier | July 1, 2022 | 2014-2022H1 | 2022H2-2025 |
| Bordeaux | July 15, 2022 | 2014-2022H1 | 2022H2-2025 |
| Pays Basque (24 communes) | 2023 | 2014-2022 | 2023-2025 |
| Grenoble-Alpes Métropole | 2024 | 2014-2023 | 2024-2025 |

Control cities: French cities with 100k+ population that have not adopted rent control (e.g., Toulouse, Nantes, Strasbourg, Nice, Rennes, Rouen, Toulon, Saint-Étienne, etc.)

## Expected Effects and Mechanisms

**Primary hypothesis:** Rent control reduces property prices for investment-type properties by 3-8%, reflecting the capitalized loss of expected rental income.

**Mechanism decomposition:**
1. **Capitalization channel:** Rent ceilings reduce NPV of future rental income → lower willingness to pay by investors → lower sale prices
2. **Supply reallocation:** Landlords convert rental units to owner-occupied (condo conversion) → increased supply of for-sale units → downward price pressure
3. **Quality channel:** Rent control reduces maintenance incentives → property quality declines → lower prices

**Heterogeneity predictions:**
- Effect concentrated in small apartments (highest rental probability)
- Larger in neighborhoods where rent control is binding (market rent > ceiling)
- Stronger for older buildings (more likely to be rental stock)
- Weaker for new construction (often exempt or with higher ceilings)

## Primary Specification

```
log(price_it) = α + β₁(Treated_c × Post_t) + β₂(Treated_c × Post_t × Investment_i)
                + γ(Investment_i × Post_t) + δ(Treated_c × Investment_i)
                + X_i'θ + μ_c + λ_t + ε_it
```

Where:
- `price_it` = transaction price for property i at time t
- `Treated_c` = 1 if commune c has adopted rent control
- `Post_t` = 1 if transaction occurs after adoption date in commune c
- `Investment_i` = 1 if property is investment-type (studio/1-2 rooms, apartment)
- `X_i` = property controls (surface, rooms, construction period)
- `μ_c` = commune fixed effects
- `λ_t` = year-quarter fixed effects
- `β₂` = DDD coefficient of interest (differential effect on investment properties)

**Modern staggered estimator:** Callaway-Sant'Anna (2021) for the city-level staggered DiD component, with property-type interaction.

## Planned Robustness Checks

1. **Pre-trend validation:** Event-study with leads and lags; Rambachan-Roth sensitivity
2. **Commercial property placebo:** No effect expected on commercial real estate
3. **Boundary design:** Compare properties within 2km of the regulatory border (inside vs. outside)
4. **Leave-one-out:** Drop each city; results should hold
5. **Continuous rental-exposure score:** Replace binary investment indicator with continuous score
6. **COVID controls:** Exclude 2020Q2-Q4; include lockdown period dummies
7. **Anticipation test:** Check for effects during Paris's first rent-control episode (2015-2017)
8. **Wild cluster bootstrap:** Cluster at city level (few clusters → WCB)
9. **Randomization inference:** Permute treatment timing across cities

## Data Sources

| Source | Content | Access |
|---|---|---|
| DVF (data.gouv.fr) | Universe of property transactions, 2014-2025 | Open, bulk CSV |
| Arrêtés préfectoraux | Exact commune lists and adoption dates | Official Journal |
| FILOCOM/RPLS | Rental share by property type and commune | INSEE/data.gouv.fr |
| OLAP | Reference rents (bindingness measure) | olap.fr |

## Power Assessment

- **Treated communes:** 50+ communes across 10+ agglomerations
- **Pre-treatment periods:** 5-10 years depending on city
- **Post-treatment periods:** 1-6 years depending on city
- **N transactions:** ~25-30 million over 2014-2025
- **Within treated communes:** ~5 million transactions
- **MDE estimate:** With N > 5 million and commune FE, MDE < 1% for the DDD coefficient
