# Research Plan: Did India's Health Mission Save Newborns? Evidence from the World's Largest Community Health Worker Deployment

## Research Question

Did India's National Rural Health Mission (NRHM) — which deployed 900,000 community health workers and offered conditional cash transfers for institutional delivery — succeed in shifting births from homes to facilities and improving maternal/neonatal health outcomes? Through which channel?

## Policy Background

**NRHM (April 2005):** India's largest-ever primary health intervention, with three interlocking components:
1. **ASHA deployment:** One Accredited Social Health Activist per ~1,000 rural population
2. **JSY cash incentives:** Conditional cash transfers for institutional delivery
3. **Facility strengthening:** PHC/CHC upgrades, supply chain improvements

**Staggered treatment (the identification source):**
- **Phase 1 (2005-06):** 18 high-focus states — 8 EAG states (Bihar, Chhattisgarh, Jharkhand, MP, Odisha, Rajasthan, Uttarakhand, UP) + 8 NE states + J&K + HP. Higher JSY incentive: INR 1,400/delivery (universal eligibility).
- **Phase 2 (2008-10):** Remaining states. Lower JSY incentive: INR 800/delivery (BPL women only).

## Identification Strategy

**Primary: Generalized DiD**

Compare health outcome trajectories across 18 high-focus states (early treatment, high intensity) vs 10+ non-high-focus states (late treatment, low intensity) using DHS/NFHS subnational panel (NFHS-3 → NFHS-4 → NFHS-5).

Treatment intensity = (high-focus status × JSY incentive level × ASHA density).

**Estimating equation:**
Y_st = α + β₁(HighFocus_s × Post2005_t) + X_st'γ + δ_s + θ_t + ε_st

where s indexes states, t indexes survey rounds, δ_s are state FEs, θ_t are survey FEs.

Use Callaway-Sant'Anna (2021) for heterogeneity-robust estimation.

**Key assumption:** Conditional parallel trends — high-focus and non-high-focus states would have followed parallel health trajectories absent NRHM. Validated by:
1. NFHS-1 (1993) and NFHS-2 (1999) as pre-period falsification
2. SRS annual IMR/NMR if available for 2000-2004 pre-trends
3. HonestDiD / Rambachan-Roth (2023) sensitivity bounds

## Expected Effects and Mechanisms

**Causal chain:** ASHA + JSY → Increased ANC visits → Increased institutional delivery → Improved neonatal outcomes

**Expected magnitudes:**
- Institutional delivery: Large positive (50+ pp in EAG states, based on raw DHS data)
- ANC 4+ visits: Moderate positive
- Neonatal mortality: Negative (decline), but magnitude uncertain — depends on facility quality
- Immunization: Moderate positive (ASHA's secondary mandate)

**The facility quality paradox (the interesting angle):** If institutional delivery surged but neonatal outcomes improved only modestly, this suggests ASHAs succeeded in changing WHERE women deliver but the quality of care at facilities remained inadequate. This reframes the global debate from "deploy more CHWs" to "fix facility quality first."

## Primary Specification

**Outcome variables (from DHS API, subnational):**
1. Institutional delivery rate (RH_DELP_C_DHF) — primary
2. ANC 4+ visits (RH_ANCN_W_N4P) — mechanism
3. DPT3 immunization (CH_VACS_C_DP3) — secondary
4. Basic vaccination (CH_VACS_C_BAS) — secondary
5. Anemia prevalence (AN_ANEM_W_ANY) — placebo
6. National-level NMR/IMR from World Bank for context

**Panel:** ~28-30 states × 3-5 survey rounds (1993, 1999, 2006, 2015, 2020) = 120-150 state-survey observations

**State classification:**
- High-focus (treated early): Bihar, Chhattisgarh, Jharkhand, MP, Odisha, Rajasthan, UP, Uttarakhand, Arunachal Pradesh, Assam, Manipur, Meghalaya, Mizoram, Nagaland, Sikkim, Tripura, J&K, HP
- Non-high-focus (treated late): AP/Telangana, Gujarat, Haryana, Karnataka, Kerala, Maharashtra, Punjab, Tamil Nadu, West Bengal, Goa, Delhi

**Fixed effects:** State + Survey round
**Clustering:** State level (28-30 clusters)
**Inference:** Wild cluster bootstrap + randomization inference (given modest cluster count)

## Planned Robustness Checks

1. **Pre-trends:** NFHS-1/2 (1993, 1999) falsification — no differential trends before NRHM
2. **Placebo outcomes:** Anemia (not directly targeted by NRHM), urban delivery (no ASHAs in urban areas)
3. **Restrict to EAG states only** (most comparable group) vs non-EAG high-focus (NE states)
4. **Exclude NE states** (geographically distinct, small populations)
5. **JSY intensity:** Exploit INR 1,400 vs 800 differential as continuous treatment
6. **HonestDiD sensitivity:** Bound on pre-trend violations
7. **Leave-one-out:** Drop each high-focus state individually to test outlier dependence
8. **Triple-difference:** (High-focus × Post × Neonatal indicator) vs (adult/placebo indicator)
9. **Dose-response:** States with higher ASHA-per-capita should show larger effects

## Data Sources

| Source | Variables | Level | Coverage |
|--------|-----------|-------|----------|
| DHS API (NFHS-3/4/5) | Institutional delivery, ANC, immunization, anemia | State | 1993-2021 |
| World Bank API | National NMR, IMR, MMR | National | 1990-2022 |
| SRS (if available) | State-level annual IMR/NMR | State | 2000-2020 |
| NRHM Annual Reports | ASHA deployment, JSY beneficiaries | State | 2005-2020 |
