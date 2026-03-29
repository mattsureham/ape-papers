# Research Plan: The Pollinator Dividend

## Research Question

Did EU member states' emergency derogations from the 2018 neonicotinoid ban reduce pollinator populations in sugar beet regions? We exploit staggered Article 53 emergency authorizations granted by 11 member states (2019–2022) and GBIF citizen-science bee observation data to estimate the causal effect of continued neonicotinoid exposure on field pollinator abundance.

## Policy Background

The EU banned outdoor use of three neonicotinoids (clothianidin, imidacloprid, thiamethoxam) effective December 2018 via Regulations 2018/783–785. However, Article 53 of Regulation 1107/2009 allows member states to grant 120-day "emergency authorizations" for specific crops when no alternatives exist. Between 2019 and 2022, 11 member states (Belgium, Croatia, Denmark, Finland, France, Germany, Lithuania, Poland, Romania, Slovakia, Spain) granted 17+ derogations primarily for sugar beet seed treatment against aphid-vectored Yellows virus. The EU Court of Justice ruled all such derogations illegal in January 2023 (Case C-162/21).

## Identification Strategy

**Design:** Staggered difference-in-differences at the NUTS-2 region × year level.

**Treatment:** A NUTS-2 region is "treated" in year $t$ if it is located in a country that granted a neonicotinoid derogation for sugar beet in year $t$ AND the region has substantial sugar beet cultivation (above-median Eurostat sugar beet area).

**Control groups:**
1. NUTS-2 regions in non-derogation EU countries (never-treated)
2. Non-sugar-beet regions within derogation countries (within-country placebo)

**Triple-difference:** Derogation country × sugar beet region × post-derogation year

**Placebo taxa:** Beetles (Coleoptera) and spiders (Araneae) — taxonomically related arthropods not directly sensitive to neonicotinoids applied to sugar beet seeds.

**Estimator:** Callaway-Sant'Anna (2021) for heterogeneous treatment timing, with event study for pre-trend visualization.

**Parallel trends assumption:** Pre-2019 bee observation trends in derogation vs non-derogation sugar beet regions evolved similarly, conditional on observation effort controls.

## Key Concerns and Mitigations

1. **Observation effort bias:** GBIF citizen science data reflects both true abundance and observer effort. Mitigation: (a) normalize bee counts by total arthropod observations in the same region-year, (b) control for number of unique recording events, (c) use region and year FE.

2. **Pre-periods:** Extend sample back to 2013 to obtain ≥5 pre-periods (2013–2018 = 6 years pre-ban).

3. **SUTVA:** Pollinators can fly across borders. Mitigation: use larger NUTS-2 regions (not NUTS-3), acknowledge this limitation explicitly.

4. **Selection into derogation:** Countries with worse pest pressure may be more likely to seek derogations. This is a threat if pest pressure also independently affects pollinator populations. Mitigation: the triple-diff with sugar beet vs non-sugar-beet regions within derogation countries absorbs country-level confounders.

## Expected Effects

Derogations allowed continued neonicotinoid seed treatment in sugar beet regions. If neonicotinoids harm pollinators, we expect:
- **Negative** effect on bee observation rates in derogation × sugar beet regions relative to controls
- **Null** effect on placebo taxa (beetles, spiders)
- **Heterogeneity:** Larger effects in regions with more intensive sugar beet cultivation

A null result would suggest that seed-treatment neonicotinoids (as opposed to foliar spraying) have limited field-level pollinator effects — itself an important finding for the "seed treatment exception" debate.

## Data Sources

1. **GBIF API** (api.gbif.org): Geolocated bee (order Hymenoptera, family Apidae + related), beetle (Coleoptera), and spider (Araneae) observations, 2013–2022, EU member states. ~2M+ records.

2. **Eurostat** (`eurostat` R package): Sugar beet harvested area by NUTS-2 region (table `apro_cpshr`), for identifying sugar beet vs non-sugar beet regions.

3. **EU derogation records:** Commission DG SANTE emergency authorization database + published regulatory summaries for Article 53 neonicotinoid derogations by country and year.

## Primary Specification

$$Y_{r,t} = \alpha_r + \gamma_t + \beta \cdot \text{Derog}_{c(r),t} \times \text{SugarBeet}_r + \delta \cdot X_{r,t} + \varepsilon_{r,t}$$

Where:
- $Y_{r,t}$: log(bee observations / total arthropod observations) in NUTS-2 region $r$, year $t$
- $\alpha_r$: region fixed effects
- $\gamma_t$: year fixed effects
- $\text{Derog}_{c(r),t}$: indicator for country $c$ granting derogation in year $t$
- $\text{SugarBeet}_r$: indicator for above-median sugar beet area
- $X_{r,t}$: observation effort controls (log total recording events)
- Standard errors clustered at country level (with wild cluster bootstrap for small N)

## Analysis Plan

1. `01_fetch_data.R` — Download GBIF records via API, Eurostat sugar beet area, compile derogation timeline
2. `02_clean_data.R` — Aggregate to NUTS-2 × year, construct treatment variables, observation effort controls
3. `03_main_analysis.R` — Callaway-Sant'Anna DiD, event study, triple-diff
4. `04_robustness.R` — Placebo taxa, alternative observation effort normalization, leave-one-country-out, HonestDiD bounds
5. `05_tables.R` — All tables including SDE appendix
