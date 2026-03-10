# Initial Research Plan: EU Medical Device Regulation and the Innovation-Safety Tradeoff

## Research Question

Did the EU Medical Device Regulation (MDR, Regulation 2017/745) reduce medical device production and innovation, particularly for higher-risk device classes? What was the supply-side mechanism?

## Policy Background

The EU MDR replaced the Medical Device Directives (MDD 93/42/EEC) effective 26 May 2021 (delayed one year from May 2020 due to COVID-19). Key changes:
- Reclassified many devices upward (e.g., Class I → IIa, Class IIa → IIb)
- Required notified body re-certification of ~23,000 existing certificates
- Imposed new clinical evaluation, unique device identification (UDI), post-market surveillance, and Person Responsible for Regulatory Compliance (PRRC) obligations
- Transition deadlines staggered by risk class: Class III and implantable IIb by Dec 2027; Class IIa and lower IIb by Dec 2028

Critically, the number of active notified bodies collapsed from ~80 under MDD to ~20 under MDR, creating a severe supply-side bottleneck. By end-2022, only 14% of existing MDD certificates had been converted to MDR certificates.

## Identification Strategy

### Primary: Within-Country Industry DiD (country × sector × year panel)

**Outcome:** Eurostat annual industrial production index (2021=100) for NACE sectors
**Treatment:** NACE C325 (manufacture of medical/dental instruments) × post-May-2021
**Control sectors:**
- C21 (manufacture of pharmaceuticals) — regulated by EMA, NOT by MDR
- C265 (manufacture of measuring/testing instruments) — general manufacturing, no MDR
- C26 (computer, electronic, optical products) — broader manufacturing

**Panel:** 7 countries × 4 NACE sectors × 11 years (2015-2025) = ~308 observations

**Specification:**
$$Y_{cst} = \alpha + \beta \cdot (\text{C325}_s \times \text{Post2021}_t) + \gamma_{cs} + \delta_{ct} + \epsilon_{cst}$$

where $\gamma_{cs}$ = country × sector FE, $\delta_{ct}$ = country × year FE. $\beta$ captures the differential production change for medical devices vs. control sectors after MDR, absorbing all country-level shocks and all sector-level trends.

**Countries with C325 data:** DE, EL, ES, FR, IT, LT (EU members), TR (non-EU control)
- Turkey is NOT subject to MDR → placebo test: β should be zero for Turkey

### Secondary: US Counterfactual (FDA 510(k) Time Series)

FDA 510(k) clearances per year (2015-2025) by device class document stable US innovation (~3,000/year). Compare EU production trends to US clearance trends as a geographic placebo.

### Tertiary: EUDAMED Cross-Sectional Analysis (Device-Level)

1.29M device registrations from EUDAMED API, with risk class (I, IIa, IIb, III), manufacturer country, and device status. Test whether higher-risk devices disproportionately have non-active status.

## Exposure Alignment (DiD Requirements)

- **Who is actually treated?** EU medical device manufacturers subject to MDR (NACE C325)
- **Primary estimand population:** EU medical device firms (DE, EL, ES, FR, IT, LT)
- **Placebo/control population:** (1) Same-country pharmaceutical firms (C21); (2) Same-country measuring instrument firms (C265); (3) Turkish medical device firms (non-EU, no MDR)
- **Design:** Industry DiD within EU countries, with Turkey as geographic placebo

## Power Assessment

- **Pre-treatment periods:** 6 years (2015-2020) for C325
- **Treated clusters:** 6 EU countries × 1 treated sector = 6 country-sector units
- **Post-treatment periods:** 4+ years (2021-2025)
- **MDE given sample size:** With 6 treated country-sectors and 18 control country-sectors across 11 years, power is modest. Supplemented by:
  - EUDAMED device-level analysis (N=1.29M)
  - FDA 510(k) time series
  - Wild cluster bootstrap and randomization inference for robust inference

## Expected Effects and Mechanisms

**Direction:** Negative effect of MDR on EU medical device production (β < 0)
**Mechanism:** Notified body capacity constraints
- Collapse from ~80 to ~20 active bodies → certification bottleneck
- Higher-risk devices face stricter requirements → disproportionate impact on Class IIb/III
- SMEs face disproportionate compliance costs → exit or relocation

**Predicted heterogeneity:**
1. Larger effects for countries with more higher-risk device manufacturing
2. Effects concentrated in 2022-2023 (initial transition period) before partial recovery
3. No effect on pharmaceuticals (regulated by EMA, not MDR)
4. No effect on Turkish medical device production (not subject to MDR)

## Planned Robustness Checks

1. COVID delay placebo test (May 2020 as false treatment date)
2. Turkey as geographic placebo (should show no effect)
3. Pharmaceutical production as within-country placebo sector
4. Leave-one-country-out stability
5. Wild cluster bootstrap (few treated clusters)
6. Randomization inference (permute treatment timing across sectors)
7. Alternative control sectors (C26, C2651, broader manufacturing)
8. Rambachan-Roth sensitivity analysis for parallel trends violations

## Data Sources

1. **Eurostat `sts_inpr_a`**: Annual production index (2021=100), NACE C325/C21/C265/C26, 7 countries, 2015-2025
2. **Eurostat `sbs_na_ind_r2`**: SBS enterprise counts and turnover, NACE C325, 27 countries, 2015-2020
3. **FDA openFDA 510(k)**: 174,263 US device clearances with decision dates, product codes, device classes
4. **EUDAMED UDI-DI API**: 1,293,060 EU device registrations with risk class, manufacturer country, device status
5. **FRED**: EUR/USD exchange rate for trade-related adjustments
