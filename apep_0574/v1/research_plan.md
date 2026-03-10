# Initial Research Plan: Importing What You Used to Make

## Research Question

Did the 2022 Russian gas cutoff cause EU member states to permanently substitute collapsed domestic energy-intensive manufacturing with extra-EU imports? Specifically: (1) Did extra-EU imports of energy-intensive products rise differentially in gas-dependent countries? (2) Did this import substitution persist after gas prices normalized in 2023? (3) What mechanisms drove persistence — firm exit, capacity destruction, or hysteretic trade relationships?

## Identification Strategy

**Triple-Difference Design:**

Y_{c,p,t} = α + β · (GasDep_c × EnergyInt_p × Post_t) + γ_{c,t} + δ_{p,t} + μ_{c,p} + ε_{c,p,t}

- **Country variation (c):** Pre-war Russian gas share (continuous, 0–75%). Source: Eurostat/IEA.
- **Product variation (p):** Energy intensity of HS2 sector (binary: energy-intensive vs. non-energy-intensive).
- **Time variation (t):** Monthly, Jan 2019 – Dec 2024. Shock: Feb 2022.
- **Fixed effects:** Country × month (γ_{c,t}), product × month (δ_{p,t}), country × product (μ_{c,p}).

The triple-diff absorbs all country-level confounds (sanctions, fiscal policy, inflation) and all product-level confounds (global supply chains), isolating the interaction of gas dependence × energy intensity × post-shock.

**Treated products (energy-intensive):** HS 28 (inorganic chemicals), 29 (organic chemicals), 31 (fertilizers), 39 (plastics), 69 (ceramics), 72 (iron/steel), 76 (aluminium).

**Placebo products (non-energy-intensive):** HS 62 (apparel), 84 (machinery), 85 (electrical equipment).

## Expected Effects and Mechanisms

**Main prediction:** β > 0 — extra-EU imports of energy-intensive products increased more in gas-dependent countries after Feb 2022.

**Mechanism chain:** Gas prices spike → domestic energy-intensive production becomes uncompetitive → firms curtail/close → importers fill the gap → new trade relationships form → imports persist even after prices normalize.

**Persistence prediction:** If comparative advantage permanently shifted, import levels should remain elevated through 2024 even as TTF prices returned to ~30 EUR/MWh. If temporary smoothing, imports should revert.

**Quantity vs. price decomposition:** The quantity margin (kg) is the primary object. An increase in import values but not quantities would indicate price effects, not substitution.

## Primary Specification

1. **Main result:** Triple-diff on log import quantities (kg), monthly panel, 2019–2024.
2. **Event study:** Month-by-month triple-interaction coefficients to visualize dynamics.
3. **First stage:** Show domestic production (STS_INPR_M) fell differentially in treated cells.
4. **Partner decomposition:** Separate extra-EU imports by origin (China, Middle East, India, Turkey, other) excluding Russia/Belarus/Ukraine.
5. **Persistence test:** Formal test of whether post-normalization (Jul 2023–Dec 2024) import levels exceed pre-shock baselines.

## Planned Robustness Checks

1. **HS4 disaggregation** for largest HS2 groups (28, 72) to rule out composition.
2. **Leave-one-out by country** (especially Finland at 75% gas share) and by product.
3. **Intra-EU imports** as additional outcome (did within-EU reallocation also occur?).
4. **Quantity-only specification** (log kg) vs. value specification (log EUR) vs. unit values.
5. **Alternative gas dependence measures:** binary high/low, gas imports/GDP ratio.
6. **Controlling for national energy subsidy packages** (Germany: 200B EUR, France: bouclier tarifaire).
7. **Pre-trend F-test** and Rambachan-Roth sensitivity bounds.
8. **Business demography mechanism:** Enterprise deaths in energy-intensive sectors of gas-dependent countries (annual, BD_SIZE).
9. **Randomization inference** on country-level gas dependence assignment.

## Power Assessment

- **Countries:** ~22 EU member states with Comext data
- **Products:** 10 HS2 categories (7 treated + 3 placebo)
- **Months:** 72 (Jan 2019 – Dec 2024)
- **Total cells:** ~22 × 10 × 72 ≈ 15,840 country-product-month observations
- **Pre-treatment months:** 37 (Jan 2019 – Jan 2022)
- **Post-treatment months:** 35 (Feb 2022 – Dec 2024)
- **Cluster-level variation:** Continuous gas dependence × binary energy intensity

## Data Sources

| Source | Dataset | Frequency | Access |
|--------|---------|-----------|--------|
| Eurostat Comext | DS-059331 (extra-EU trade by HS2, partner, country) | Monthly | Open API, no key |
| Eurostat | STS_INPR_M (industrial production index by NACE) | Monthly | Open API |
| Eurostat | BD_SIZE (business demography by NACE) | Annual | Open API |
| Eurostat | nrg_cb_gasm (natural gas imports by partner) | Monthly | Open API |
| IEA/Eurostat | Pre-war Russian gas dependence shares | Annual | Public data |
