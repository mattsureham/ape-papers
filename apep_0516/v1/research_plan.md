# Initial Research Plan: Does Geographic Targeting of Housing Subsidies Matter?

## Research Question

Does the geographic withdrawal of housing subsidies (PTZ and Pinel) from low-demand French communes affect housing prices, construction activity, and buyer sorting? Specifically, what share of subsidy incidence falls on prices versus real activity, and does spatial reallocation of subsidies redirect demand to still-eligible areas?

## Policy Background

France's Prêt à Taux Zéro (PTZ) is a zero-interest government-backed loan for first-time homebuyers, worth up to €138,000 depending on zone and income. The ABC zoning system classifies communes by housing market tightness:

- **Zone A bis/A:** Paris region and major tight markets
- **Zone B1:** Large cities (>250k), coastal/tourist areas
- **Zone B2:** Medium cities (50k-250k)
- **Zone C:** Rural and small towns

The 2018 Finance Law (Loi de Finances 2018) enacted two simultaneous reforms:
1. **PTZ for new construction:** Quotité reduced from 40% to 20% in zones B2/C (halving the subsidy)
2. **Pinel rental investment tax incentive:** Restricted to zones A/Abis/B1 only

This represents a deliberate spatial reallocation of ~€3.5 billion/year in housing subsidies away from ~70% of French territory (B2/C zones) toward tight urban markets (A/B1 zones).

Timeline of shocks:
- **2018:** PTZ halved in B2/C (40% → 20%); Pinel eliminated in B2/C
- **2020:** PTZ fully eliminated in B2/C for new construction
- **2024:** PTZ partially restored in B2/C (new eligibility rules)

## Identification Strategy

### Primary Design: Zone-Boundary Difference-in-Differences

- **Treatment:** ~21,000 communes in zones B2/C (lost PTZ/Pinel)
- **Control:** ~5,000 communes in zone B1 (retained subsidies)
- **Time:** 2014-2025 (4 pre-periods, 7+ post-periods relative to 2018)
- **Unit:** Commune × semester

**Why B1 as control (not A/Abis):** B1 communes are the closest comparator to B2 — both are medium-to-large cities, both had PTZ/Pinel pre-reform, and many B1/B2 communes are adjacent within the same département. A/Abis communes (Paris, major metros) have fundamentally different housing market dynamics.

### Event Study Specification

$$Y_{ct} = \alpha_c + \gamma_t + \sum_{k=-4}^{+7} \beta_k \cdot \mathbb{1}[\text{B2/C}_c] \times \mathbb{1}[t = 2018+k] + X_{ct}'\delta + \varepsilon_{ct}$$

where $Y_{ct}$ is the outcome in commune $c$ and semester $t$, $\alpha_c$ are commune fixed effects, $\gamma_t$ are semester fixed effects, and $X_{ct}$ are time-varying controls (population, income).

### Supplementary Design: Border Discontinuity

Compare communes within the same département on opposite sides of the B1/B2 boundary. This exploits the fact that adjacent communes may be classified differently due to population thresholds, providing a sharp comparison.

## Expected Effects and Mechanisms

1. **Price capitalization:** If PTZ subsidies were capitalized by sellers, removing the subsidy should reduce new-build prices in B2/C relative to B1. Expected sign: negative. Magnitude: PTZ worth ~€30,000-50,000 on average → expect 5-15% price decline on new builds if fully capitalized.

2. **Construction supply response:** Reduced demand should lower construction starts. Expected: negative effect on Sitadel housing starts in B2/C.

3. **Buyer sorting:** First-time buyers may relocate to B1 zones that still offer subsidies. Expected: decline in young/first-time buyer share in B2/C, increase in B1 border communes.

4. **Existing housing spillovers:** New-build and existing housing are substitutes. If new construction falls, existing housing demand may rise, partially offsetting the price decline. Expected: smaller (or positive) effect on existing housing prices.

## Primary Specification

Outcome: Log median price per m² of residential transactions (commune × semester)

$$\log(P_{ct}) = \alpha_c + \gamma_t + \beta \cdot \mathbb{1}[\text{B2/C}_c] \times \mathbb{1}[\text{Post}_{t}] + X_{ct}'\delta + \varepsilon_{ct}$$

Clustering: Département level (~96 clusters)

## Planned Robustness Checks

1. **Pre-trend verification:** Event study coefficients 2014-2017 should be zero
2. **HonestDiD/Rambachan-Roth sensitivity:** Bound effects under relaxed parallel trends
3. **COVID exclusion:** Re-estimate excluding 2020-2021
4. **Commercial property placebo:** Non-residential transactions should be unaffected
5. **Existing vs. new-build decomposition:** Separate effects by property age
6. **Border sample:** Restrict to communes within 20km of B1/B2 boundary
7. **Continuous treatment intensity:** Use pre-reform PTZ take-up rate as continuous treatment
8. **Bacon decomposition:** Verify no negative weights in two-way FE
9. **Callaway-Sant'Anna estimator:** For the 2020 full-elimination shock (staggered intensity)

## Exposure Alignment (DiD Requirements)

- **Who is treated:** Communes in zones B2/C that lost PTZ/Pinel eligibility
- **Primary estimand:** ATT on housing prices in subsidy-losing communes
- **Placebo population:** Commercial/industrial properties; existing housing (partial placebo)
- **Design:** Standard 2×2 DiD with event study for 2018 shock; staggered intensity for 2018+2020 combined

## Power Assessment

- **Pre-treatment periods:** 4 years (8 semesters), 2014H1–2017H2
- **Treated clusters:** ~96 départements contain B2/C communes; effective clusters ~80+
- **Post-treatment periods:** 7+ years (14+ semesters)
- **Total transactions:** ~35M over 2014-2025 in DVF
- **MDE estimate:** With ~80 clusters, power ≥ 80% to detect 2-3% price change (well below the expected 5-15% effect from full capitalization)

## Data Sources

| Source | Variables | Granularity | Period |
|--------|-----------|-------------|--------|
| DVF (data.gouv.fr) | Transaction prices, dates, property type, surface, commune | Transaction-level | 2014-2025 |
| ABC Zonage (data.gouv.fr) | Zone classification per commune | Commune | Current + historical |
| Sitadel (SDES) | Housing starts, permits by type | Commune × year | 2013-2024 |
| INSEE BDM/SDMX | Population, income, demographics | Commune × year | 2014-2024 |
| SGFGAS reports | PTZ loan volumes by zone | Zone × year | 2015-2024 |

## Welfare Analysis

Following Hilber & Turner (2014), I will decompose the welfare effect:
- **Buyer welfare:** Change in effective housing cost = price change + subsidy loss
- **Seller welfare:** Price change = seller's share of subsidy incidence
- **Deadweight loss:** If subsidy was fully capitalized, its removal causes no efficiency loss (just a transfer). If construction falls, there is a real activity loss.
- **Spatial misallocation:** Compute counterfactual housing construction under uniform vs. targeted subsidies

## Paper Structure

1. Introduction (3 pages): Hook, context, what we do, what we find
2. Institutional Background (3 pages): PTZ/Pinel system, ABC zoning, 2018 reform
3. Data (3 pages): DVF, Sitadel, zone classification
4. Empirical Strategy (3 pages): DiD, event study, border design
5. Results (5 pages): First stage, price effects, mechanisms
6. Robustness (3 pages): COVID, placebos, sensitivity
7. Welfare Discussion (2 pages): Incidence decomposition
8. Conclusion (2 pages)
+ Appendix with additional tables/figures
