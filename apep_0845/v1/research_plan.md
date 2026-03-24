# Research Plan: Insured into Monoculture? India's PMFBY Crop Insurance Withdrawals and Agricultural Risk-Taking

**Idea:** idea_0761
**Paper:** apep_0845/v1

## Research Question

Does crop insurance encourage monoculture through moral hazard? When six Indian states withdrew from the Pradhan Mantri Fasal Bima Yojana (PMFBY) — the world's largest crop insurance scheme — did farmers diversify their crop portfolios, or did the removal of the safety net entrench existing cropping patterns?

## Identification Strategy

**Staggered Difference-in-Differences using Callaway-Sant'Anna (2021).**

Treatment: State withdrawal from PMFBY at three staggered timepoints:
- **Cohort 1 (Kharif 2018):** Bihar — 38 districts
- **Cohort 2 (Kharif 2019):** West Bengal — 19 districts
- **Cohort 3 (Kharif 2020):** Andhra Pradesh, Telangana, Jharkhand — ~41 districts
- **Gujarat:** Intermittent 2019–20 — 25 districts

Total treated: ~123 districts across 6 states.
Control group: ~190 districts in states that remained in PMFBY (Maharashtra, MP, Rajasthan, Karnataka, UP, Tamil Nadu, etc.).

**Why exogenous?** States withdrew due to fiscal burden (25–30% premium subsidy cost), not agricultural outcomes. PIB press release PRID 1906871 confirms fiscal motivation.

**Key threats and mitigation:**
1. *Endogenous withdrawal:* Fiscal motivation is orthogonal to crop composition. Pre-trend tests confirm.
2. *COVID overlap (2020 cohort):* Cohorts 1 and 2 (2018, 2019) are pre-COVID. We can test robustness excluding 2020 cohort.
3. *Replacement schemes:* Some states launched weaker alternatives (Bihar's BRBN Yojana). These have lower coverage and subsidies than PMFBY — we note this as attenuation bias.
4. *Clustering:* 20 states total. Wild cluster bootstrap and randomization inference for robustness.

## Expected Effects and Mechanisms

**Primary hypothesis:** Insurance removal → increased crop diversification (reduced moral hazard).

Theory: PMFBY subsidizes risk → farmers concentrate on high-value but risky cash crops (cotton, oilseeds) → withdrawal forces diversification into safer staples (rice, wheat, pulses) as self-insurance.

Alternative: Insurance removal → reduced diversification if insurance enabled farmers to experiment with new crops (de-risking innovation).

**Expected sign:** Positive effect on diversification index (insurance removal increases diversity). This is the moral hazard prediction.

## Primary Specification

$$Y_{dt} = \alpha_d + \gamma_t + \sum_g \beta_g \cdot \mathbf{1}[G_d = g] \cdot \mathbf{1}[t \geq g] + \epsilon_{dt}$$

Where:
- $Y_{dt}$: Simpson Diversification Index for district $d$ in year $t$
- $G_d$: Treatment cohort (2018, 2019, or 2020)
- $\alpha_d$, $\gamma_t$: District and year fixed effects
- Estimated via `did::att_gt()` with never-treated control group

**Outcome variables:**
1. Simpson Diversification Index (1 − Σ(share_i²)) across crop categories
2. Risky crop share: (cotton + oilseeds area) / total cropped area
3. Commercial crop share: (cotton + sugarcane + oilseeds) / total
4. HHI (Herfindahl-Hirschman Index) of crop concentration

## Data Sources

1. **ICRISAT District Level Database (DLD):** District-level crop area/production/yield for 20 crop categories, 313 districts, 20 states, 1966–2017. API: `data.icrisat.org/dldAPI/`
2. **India DES/Agricultural Statistics:** Extend crop data through 2023 via Directorate of Economics and Statistics or data.gov.in
3. **PMFBY Portal:** Enrollment and claims data for treatment verification
4. **data.gov.in:** Agricultural production statistics (resource 9ef84268 for Agmarknet; other crop production datasets)

## Fetch Strategy

1. Query ICRISAT DLD API for all district × crop × year data (2010–2017)
2. Search data.gov.in for post-2017 district-level crop production data
3. If DES data unavailable via API, use SHRUG agricultural tables (`shrug_ag`) for district-level crop data
4. Construct Simpson Index from crop area shares at district-year level
5. Merge with PMFBY withdrawal treatment indicator (from PIB dates)

## Robustness Checks

1. Event study (pre-trend validation)
2. Exclude 2020 cohort (COVID robustness)
3. Wild cluster bootstrap at state level
4. Randomization inference (permute treatment across states)
5. Leave-one-state-out (sensitivity to any single state)
6. Placebo: non-agricultural outcomes (nightlights) shouldn't respond
7. Dose-response: Kharif 2020 voluntary reform × baseline loanee farmer share
