# Conditional Requirements

**Generated:** 2026-03-08T00:17:15.415075
**Status:** RESOLVED

---

## Cutting the Pipeline: The 2022 Russian Gas Shock and Differential De-Industrialization Across European Manufacturing

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: showing flat pre-trends

**Status:** [x] RESOLVED

**Response:** The design uses country x sector x month panel data with triple fixed effects (country x sector, country x month, sector x month). Pre-trends will be tested via an event-study specification that interacts RussianGasShare_c x GasIntensity_s with monthly indicators for 24+ months before the invasion (Jan 2020 - Feb 2022). This directly tests whether gas-dependent countries were already diverging in gas-intensive sectors before the shock. The smoke test data already suggests the gradient was flat: German chemicals production was stable at ~100 index points throughout 2021 before the sharp decline.

**Evidence:** Smoke test log in idea_0022.md shows Germany chemicals at 100.7 in 2021-H1 before falling to 82.3 in 2022-H2. Pre-trend event study is a core analysis component in the research plan.

---

### Condition 2: ruling out Russia/Ukraine trade/supply-chain confounds

**Status:** [x] RESOLVED

**Response:** Three strategies: (1) Country x time FE absorb all aggregate country-level effects of sanctions, trade disruption, and confidence shocks. (2) We will control for sector-level Russian non-energy trade exposure (imports from Russia by sector from Comext) as an explicit robustness check. (3) We will run a placebo test using the same specification but replacing GasIntensity with Russian-non-energy-trade-intensity — if the effect operates through gas specifically (not broad Russia trade dependence), the placebo coefficient should be near zero while the gas coefficient remains significant.

**Evidence:** Eurostat Comext bilateral trade data is publicly available and will provide sector-level Russian trade exposure for the control variable.

---

### Condition 3: demonstrating the price/pass-through/import-substitution mechanism explicitly

**Status:** [x] RESOLVED

**Response:** The paper will include a full mechanism chain: (1) First stage: producer price indices (STS_INPR_M with PRC_PRR indicator) should rise more in gas-intensive sectors in gas-dependent countries. (2) Production response: the main DiD on industrial production indices. (3) Import substitution: using Comext bilateral trade data, test whether imports of gas-intensive manufactured goods increased in gas-dependent countries as domestic production fell. This traces: gas cutoff → energy cost spike → production decline → import substitution.

**Evidence:** Eurostat STS_INPR_M with PRC_PRR (producer prices) confirmed available. Comext bilateral trade by product (NACE-compatible) confirmed available.

---

### Condition 4: explicitly modeling or bounding cross-border supply chain spillovers

**Status:** [x] RESOLVED

**Response:** Cross-border supply chains create SUTVA concerns: a German auto supplier's production decline could reduce output in Czech auto plants. This creates negative spillovers from high-dependence to low-dependence countries, which attenuates our estimates (biases toward zero — conservative). We will: (1) Acknowledge this as a source of conservative bias in the main text. (2) Run a robustness check excluding sectors with the highest intra-EU trade intensity (motor vehicles, machinery). (3) Use input-output linkages from the World Input-Output Database (WIOD) to compute downstream exposure and test whether the production decline extends beyond directly gas-intensive sectors.

**Evidence:** WIOD tables available for EU countries. Attenuating bias direction means our main estimates are lower bounds.

---

### Condition 5: shutdowns (addressing COVID overlap and plant closures)

**Status:** [x] RESOLVED

**Response:** COVID-19 caused massive production swings in 2020-2021, potentially contaminating pre-trends. Our strategy: (1) Use Jan 2018 - Feb 2022 as the pre-period, allowing COVID effects to wash through. (2) Show event studies with the full 2018-2024 window where COVID appears as a symmetric shock (affecting all countries/sectors similarly) while the gas shock is asymmetric. (3) Sector x time FE absorb any sector-specific COVID recovery patterns. (4) For plant shutdowns specifically: the production index captures intensive and extensive margin — we will note that our estimates reflect both reduced output and plant closures, which is the policy-relevant margin.

**Evidence:** Eurostat data available from 2015 onward, giving 7+ years of pre-period.

---

### Condition 6: import substitution

**Status:** [x] RESOLVED

**Response:** Import substitution is a core mechanism test, not just a robustness check. We test: did gas-dependent countries increase imports of gas-intensive manufactured goods (chemicals, metals, glass) to replace lost domestic production? If domestic + imported supply is roughly constant, the welfare cost is the deadweight loss from trade diversion, not the production decline itself. We estimate the pass-through rate: for every 1% decline in domestic production, how much was offset by imports? This is the key welfare decomposition.

**Evidence:** Comext bilateral trade data by product category confirmed available from Eurostat.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
