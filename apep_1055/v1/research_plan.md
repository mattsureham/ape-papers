# Research Plan: When the Mail Slows Down

## Research Question

Did the October 2021 USPS service standard change — which added 1–2 days to First-Class Mail delivery for long-distance routes — increase preventable hospitalizations in counties where residents depend on mail-order prescriptions?

## Identification Strategy

**Difference-in-Differences with continuous treatment intensity.**

Treatment = change in expected mail delivery time per county, constructed from the Federal Register rule's mechanical distance thresholds to USPS processing facilities. The October 1, 2021 revision (86 FR 43949) reassigned service standards:
- Local mail (≤3hr drive): retained 2-day standard (control)
- Mid-distance (≤20hr combined drive): extended to 3-day
- Long-distance (remaining contiguous US): extended to 4-day
- Non-contiguous: extended to 5-day

Approximately 39% of First-Class Mail volume shifted to longer standards.

**Triple-difference:** county × pharmacy-desert-status × post-2021. Health effects should concentrate in pharmacy desert counties where residents depend on mail-order prescriptions. Counties with abundant retail pharmacies serve as a natural placebo.

## Expected Effects and Mechanisms

**Primary mechanism:** Mail slowdowns disrupt mail-order prescription delivery → medication non-adherence → preventable hospitalizations for chronic conditions (diabetes, COPD, heart failure, hypertension).

**Expected direction:** Positive effect on preventable hospitalizations in treated counties, amplified in pharmacy deserts.

**Magnitude prior:** The effect could be small (SDE 0.01–0.05) given that mail-order is one of many prescription channels. A null result with power would also be informative — it would suggest the postal infrastructure channel is not as consequential as advocates claim.

## Primary Specification

```
PrevHosp_{ct} = β₁ · MailSlowdown_c × Post_t + β₂ · MailSlowdown_c × Post_t × PharmDesert_c
                + γ_c + δ_t + ε_{ct}
```

Where:
- PrevHosp_{ct} = preventable hospitalization rate per 100K Medicare enrollees, county c, year t
- MailSlowdown_c = continuous treatment intensity (average increase in delivery days)
- Post_t = 1 if year ≥ 2022
- PharmDesert_c = 1 if county is a pharmacy desert (bottom quartile of pharmacies per capita)
- γ_c, δ_t = county and year fixed effects
- Cluster SEs at state level (50 clusters)

## Data Sources

1. **County Health Rankings (countyhealthrankings.org):** Preventable hospitalization rate, 2019–2024, ~3,125 counties. Annual download of analytic data files.

2. **USPS Service Standard Changes:** Federal Register 86 FR 43949 (August 2021). Treatment assignment from 3-digit ZIP pair service standards (PRC docket filing). Map 3-digit ZIPs to counties using HUD USPS ZIP crosswalk.

3. **Pharmacy Desert Status:** HRSA Area Health Resource File (AHRF) — pharmacies per capita by county. Alternatively: NACDS pharmacy count data or CDC Social Vulnerability Index pharmacy access component.

4. **Controls:** County-level demographics from Census ACS (population, median income, % elderly, % uninsured), rurality from USDA ERS.

## Robustness Checks

1. Event-study specification (year-by-year coefficients, 2019–2024)
2. Placebo test: outcomes that should NOT respond to mail slowdowns (motor vehicle deaths, homicides)
3. Dose-response: counties with 2-day increase vs 1-day increase
4. Exclude non-contiguous states (Alaska, Hawaii)
5. Alternative pharmacy desert definitions (terciles, continuous)
6. Wild cluster bootstrap (50 state clusters)

## Key Risks

1. County Health Rankings data may be too aggregated/noisy to detect small effects
2. Treatment assignment requires mapping ZIP-pair service standards to counties (imprecise)
3. COVID-19 disruptions overlap with treatment period — must address empirically
4. Pharmacy desert status may correlate with other post-2021 changes (e.g., pharmacy closures)
