# Research Plan: apep_1230

## Research Question

Does CMS's Provisional Period of Enhanced Oversight (PPEO) — targeting new hospice enrollments in AZ, CA, NV, TX from July 2023 — reduce fraudulent entry, reshape market structure, and improve end-of-life care quality?

## Motivation

The US hospice industry grew from $2.9B (2000) to $24B (2023). For-profit hospices became the majority of providers, with 96% of new entrants in 2021 being for-profit. OIG estimated $198M in suspected hospice fraud in FY2023. CMS activated PPEO in four states (AZ, CA, NV, TX) in July 2023, subjecting all newly enrolling hospices to enhanced scrutiny including prepayment claim review. By December 2025: 817 hospices reviewed, 181 revoked, 40% of claims denied. The four treated states had 86% of all new hospice certifications in 2021; this share dropped to 47% by 2024.

## Identification Strategy

**Design:** Difference-in-Differences comparing hospice market outcomes in AZ/CA/NV/TX (treated, July 2023) vs. all other states (control).

**Unit:** State × quarter panel.

**Estimator:** Since treatment timing is common across 4 states (all July 2023), standard TWFE DiD is appropriate (no staggered timing concerns). Event study with quarterly leads/lags.

**Pre-period:** Q1 2017 – Q2 2023 (26 quarters)
**Post-period:** Q3 2023 – Q4 2025 (10 quarters)

**Key threats and mitigation:**
1. *CA moratorium (Jan 2022):* CA imposed its own moratorium 18 months before PPEO. Run specifications with and without CA.
2. *Few treated clusters (4 states):* Use wild cluster bootstrap (fwildclusterboot) and randomization inference (permute treatment across states).
3. *Selection into treated states:* States were chosen because they had 86% of new certifications — selection was based on pre-treatment levels, not trends. Verify with pre-trend tests.

**Placebo tests:**
- Non-hospice Medicare provider certifications (should not respond to hospice-specific PPEO)
- Wave 2 states (GA, OH, added Dec 2025) as staggered validation

## Primary Outcomes

1. **New hospice certifications per state-quarter** (entry rate)
2. **For-profit share of new certifications** (market composition)
3. **Per-beneficiary spending** (cost efficiency)

## Secondary Outcomes / Mechanism Tests

4. **Quality: Hospice Care Index (HCI) scores** (care quality)
5. **Visits in last days of life** (care intensity)
6. **Early discharge rates** (adverse selection indicator)

## Data Sources

All from CMS public APIs (data.cms.gov), no API key needed:
1. **CMS Hospice Provider Data** — 6,943 hospices with certification dates, ownership type, state
2. **CMS Hospice Quality Reporting** — 465,181 records including HCI scores, per-beneficiary spending
3. **CMS Hospice Utilization** — State-level total patients, payments, covered days

## Analysis Pipeline

1. `01_fetch_data.R` — Download from CMS APIs, validate
2. `02_clean_data.R` — Construct state × quarter panel, treatment indicators
3. `03_main_analysis.R` — TWFE DiD + event study for primary outcomes
4. `04_robustness.R` — Wild cluster bootstrap, RI, exclude CA, Wave 2 validation
5. `05_tables.R` — All tables including SDE appendix

## Expected Effects

- **Entry rate:** Large negative (PPEO directly screens new entrants)
- **For-profit share:** Negative (for-profit entrants disproportionately affected)
- **Per-beneficiary spending:** Negative (fraudulent high-spend providers removed)
- **Quality scores:** Positive or null (surviving providers are higher quality, but composition change takes time)

## Key Risk

The 4 treated states are very large hospice markets. If the mechanism is primarily CA's pre-existing moratorium, the federal PPEO effect may be attenuated. Running with/without CA is essential.
