# Initial Research Plan: apep_0544

## Research Question

How did the 2022 Russian gas supply cutoff to Europe differentially affect manufacturing production across countries and sectors? Specifically: did countries with higher pre-war Russian gas dependence experience larger production declines in more gas-intensive manufacturing sectors, and through what mechanism?

## Identification Strategy

**Design:** Continuous-treatment difference-in-differences exploiting the interaction of country-level Russian gas exposure and sector-level gas intensity.

**Estimating equation:**

Y_{c,s,t} = alpha_{cs} + gamma_{ct} + delta_{st} + beta * (RussianGasShare_c * GasIntensity_s * Post_t) + epsilon_{c,s,t}

Where:
- Y_{c,s,t} = log industrial production index (country c, NACE sector s, month t)
- alpha_{cs} = country x sector FE (absorb time-invariant differences)
- gamma_{ct} = country x month FE (absorb all aggregate country-level shocks: sanctions, fiscal stimulus, confidence)
- delta_{st} = sector x month FE (absorb global sector trends, supply chain disruptions)
- RussianGasShare_c = country c's 2021 share of gas imports from Russia (continuous, 0-0.75)
- GasIntensity_s = sector s's 2019 gas consumption share (continuous)
- Post_t = indicator for t >= March 2022

**Key coefficient:** beta captures whether countries MORE exposed to Russian gas experienced LARGER production declines in MORE gas-intensive sectors, relative to the prediction from country-level and sector-level shocks alone.

**Why this is NOT staggered DiD:** Treatment is a single shock (Feb 2022 invasion) with continuous intensity, not staggered adoption across units. Standard TWFE with triple FE is appropriate. No heterogeneity-robust estimators needed — the treatment timing is common.

## Expected Effects and Mechanisms

**Primary hypothesis:** beta < 0. Gas-dependent countries saw larger production declines in gas-intensive sectors.

**Mechanism chain:**
1. Gas cutoff → energy cost spike (producer prices rise for gas-intensive sectors in gas-dependent countries)
2. Energy cost spike → production decline (firms reduce output or shut down)
3. Production decline → import substitution (gas-dependent countries import more gas-intensive manufactured goods)
4. Net welfare effect: deadweight loss = production decline - import substitution offset

**Expected magnitudes (from smoke test):**
- Germany (66% Russian gas): chemicals production -18% (2021-H1 to 2022-H2)
- Spain (8.7% Russian gas): chemicals production -8%
- Poland (diversified by 2022): chemicals production +12%
- The gradient across gas dependence is ~30 percentage points in the most gas-intensive sector.

## Primary Specification

**Panel:** ~25 EU countries x ~15-20 NACE 2-digit manufacturing sectors x 84 months (Jan 2018 - Dec 2024)
**Treatment variables:** Pre-determined (2021 gas import shares, 2019 sector gas consumption)
**Fixed effects:** Country x sector, country x month, sector x month
**Clustering:** Two-way at country and sector level
**Standard errors:** Multi-way clustered (country, sector) using fixest::feols()

## Event Study Specification

Y_{c,s,t} = alpha_{cs} + gamma_{ct} + delta_{st} + sum_k [beta_k * RussianGasShare_c * GasIntensity_s * 1(t = k)] + epsilon

Where k runs from Jan 2018 to Dec 2024, with Feb 2022 as the omitted reference month. Pre-trend test: joint F-test on beta_k for k < March 2022.

## Planned Robustness Checks

### Pre-trends and Identification
1. **Event study** with monthly leads (24+ pre-treatment months)
2. **Placebo treatment dates:** Run the same DiD at fake dates (Jan 2019, Jan 2020)
3. **Placebo treatment variable:** Replace GasIntensity with non-gas-energy intensity (oil, electricity) — gas-specific channel should dominate
4. **Leave-one-country-out:** Verify results not driven by Germany alone

### Confound Separation
5. **Control for Russian non-energy trade exposure:** Sector-level imports from Russia/Ukraine (Comext) to separate gas channel from broader trade disruption
6. **Control for energy subsidy intensity:** Country-level fiscal response (energy price caps, subsidies) as attenuation check
7. **Exclude sectors with high intra-EU supply chain linkages** (motor vehicles, machinery) to bound SUTVA violation

### Inference
8. **Wild cluster bootstrap** at country level (~25 clusters)
9. **Permutation inference:** Randomly reassign RussianGasShare across countries (1000 draws)

### Mechanism Tests
10. **Producer prices:** Same DiD specification on producer price indices — should show positive beta (prices rise)
11. **Import substitution:** Comext bilateral trade data — imports of gas-intensive goods should rise in gas-dependent countries
12. **Temporal structure:** Lag analysis showing price spike precedes production decline by 1-3 months

### Extensions
13. **Recovery dynamics:** Does the production decline persist through 2024, or do gas-dependent countries recover?
14. **Comparison to CGE predictions:** Benchmark our estimates against Bachmann et al. (2022) simulation

## Built-in Placebos

1. **Non-gas-intensive sectors in gas-dependent countries:** Transport equipment (C29) in Germany should show near-zero effect
2. **Gas-intensive sectors in non-gas-dependent countries:** Chemicals (C20) in Spain/Portugal should show small effect
3. **Non-energy-trade placebo:** If the effect is gas-specific, sector-level non-energy Russian trade exposure should not predict production declines

## Power Assessment

- **Countries:** ~25 EU members (continuous treatment from 0% to 75%)
- **Sectors:** ~15-20 NACE 2-digit manufacturing (continuous gas intensity)
- **Monthly observations:** 84 months (Jan 2018 - Dec 2024)
- **Total observations:** ~25 x 17 x 84 ≈ 35,700 country-sector-month
- **Effective variation:** Continuous treatment on both dimensions — no binary threshold
- **Pre-treatment periods:** 50 months (Jan 2018 - Feb 2022) — very long pre-period
- **Post-treatment periods:** 34 months (Mar 2022 - Dec 2024)
- **MDE:** With 25 clusters and the observed gradient (30 pp across the distribution), power is strong. The smoke test shows effect sizes of 15-20% in the most exposed cells.

## Data Sources

| Dataset | Source | Coverage | Access |
|---------|--------|----------|--------|
| Industrial production | Eurostat STS_INPR_M | ~25 countries, ~20 sectors, monthly | Public API |
| Russian gas imports | Eurostat NRG_TI_GAS | ~31 countries, annual | Public API |
| Sector gas consumption | Eurostat NRG_BAL_C | ~25 countries, by sector | Public API |
| Producer prices | Eurostat STS_INPR_M (PRC_PRR) | ~25 countries, ~20 sectors, monthly | Public API |
| Bilateral trade | Eurostat Comext (DS-045409) | ~25 countries, HS2-HS6, monthly | Public API |
| Energy balances | Eurostat NRG_BAL_C | Complete energy consumption | Public API |

## Literature Positioning

This paper bridges three literatures:
1. **Energy and growth:** Allcott, Collard-Wexler, and O'Connell (2016, JPE); Abeberese (2017); Costa (2021)
2. **Trade disruption propagation:** Barrot and Sauvagnat (2016, QJE); Boehm, Flaaen, and Pandalai-Nayar (2019)
3. **Economic costs of conflict:** Abadie and Gardeazabal (2003, AER); Costinot, Donaldson, and Smith (2015)

**Direct predecessor:** Bachmann, Baqaee, Bayer, Kuhn, Löschel, Moll, Peichl, Pittel, and Schularick (2022, Econometrica) — "What if? The economic effects for Germany of a stop of energy imports from Russia." We provide the ex-post causal test of their ex-ante simulation.

## Key Risks

1. **COVID contamination:** 2020-2021 creates noisy pre-period. Mitigated by using Jan 2018 start date and sector x time FE.
2. **Government energy subsidies:** Price caps attenuate the effect. This makes our estimate conservative (lower bound).
3. **Supply chain spillovers:** Violate SUTVA between countries. Attenuating — makes estimates conservative.
4. **Germany dominance:** Large economy may drive results. Leave-one-out check essential.
