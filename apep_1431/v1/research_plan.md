# Research Plan: The Composition Illusion

**Paper ID:** apep_1431/v1
**Idea:** idea_2278
**Date:** 2026-04-08

---

## Research Question

Does France's April 2025 DMTO increase (0.5pp in 73 departments) generate anticipatory timing manipulation, and is the pre-tax transaction surge a composition illusion — driven disproportionately by high-value buyers who can retime, not a broad market response?

---

## Policy Background

Article 116 of the 2025 Finance Law authorized French departmental councils to raise the droits de mutation à titre onéreux (DMTO) by 0.5 percentage points, from 4.5% to 5.0%, effective April 1, 2025. The law was debated publicly from late 2024. By the effective date, 73 of ~95 eligible departments had adopted the increase; ~20 had not. The increase applies only to existing residential properties — not new construction.

A first-time buyer exemption (purchases ≤250,000 EUR) was separately authorized, effective June 1, 2025.

---

## Identification Strategy

**Design:** Difference-in-differences with event study
- Treated: 73 departments that adopted the DMTO increase effective April 1, 2025
- Control: ~20 departments that did NOT adopt by April 1, 2025
- Time: Monthly observations, January 2020 – June 2025
- Unit: Department-month cells (N ≈ 97 departments × 66 months = ~6,400 obs)

**Main estimating equation:**

Y_{dt} = α_d + α_t + Σ_k β_k × (Treated_d × 1[t=k]) + X_{dt}'γ + ε_{dt}

Where:
- Y_{dt} = log(transaction count) or log(mean transaction value) in department d, month t
- α_d = department fixed effects
- α_t = month-year fixed effects
- k indexes months relative to April 2025 (event time)
- β_k = monthly DiD coefficients (event study)
- Treated_d = 1 if department adopted DMTO increase

**Pre-trends validation:** 60 months of pre-period (Jan 2020 – Mar 2025) provide strong power to detect differential pre-trends. Key pre-trend test: parallel trends in 2020–2024 transaction volumes and values.

**Anticipation effects:** Expect positive β_k for k = -2, -1 (Feb–Mar 2025 rush) and negative β_k for k = +1, +2 (April–May hangover) in treated departments.

**Composition analysis:** Decompose the March surge by value quartile. If the rush is compositional, the surge in high-value transactions will exceed the surge in low-value transactions. Formally: regress share of transactions in top value quartile on Treated × Feb/Mar2025.

---

## Primary Outcomes

1. **Transaction count**: log monthly number of property transactions, by department
2. **Mean transaction value**: log average transaction value (EUR), by department-month
3. **Value composition**: share of transactions in top quartile of value distribution (within-department)

---

## Secondary Outcomes / Mechanism Tests

- Property type split: existing dwellings (maisons + appartements, subject to DMTO) vs land/commercial
- First-time buyer threshold: density of transactions near 250,000 EUR (RDD component for June exemption)
- Intertemporal elasticity: quantifying how many future transactions were "borrowed" by the rush

---

## Data

**DVF (Demandes de Valeurs Foncières)**
- Source: data.gouv.fr, bulk CSV download, free, no authentication
- Coverage: All property transactions in France, 2018–present
- Fields: date_mutation, valeur_fonciere, type_local, commune, code_departement, surface
- Download by year: 2020, 2021, 2022, 2023, 2024, 2025 H1
- Granularity: Transaction-level, aggregate to department-month panel

**Department adoption list**
- Source: Media reports + departmental council deliberations (Légifrance/departmental assemblies)
- Need to compile list of 73 adopters vs non-adopters
- Fall-back: Use BDM/SDMX indicators on actual DMTO tax receipts to verify adoption

---

## Estimation Details

- Standard errors: Clustered at department level
- Estimator: TWFE for event study (treatment is simultaneous across all adopters → no staggered design issue; CS-DiD not needed)
- Sample restriction: Metropolitan France (departments 01–95), excluding overseas territories (DOM)
- Placebo: Shift treatment date back 1 year (April 2024 "fake" treatment) to test pre-trends

---

## Expected Results

Based on the smoke test data in the idea manifest:
- March-to-February ratio in treated depts: 1.35 (vs 1.15 in controls) → 0.20pp differential
- Mean value March treated: 902K EUR (vs 579K in February) → large compositional shift
- April/May: expect reversal ("hangover") as the pipeline of rushed transactions clears

---

## Paper Format

AER: Insights format
- 5 tables maximum, 0 figures
- ~8–12 pages

Tables planned:
1. Summary statistics (department characteristics, transaction volumes 2020–2024 vs 2025 Q1)
2. Event study on transaction counts (monthly DiD coefficients, 6-month window)
3. Compositional decomposition (value quartiles, property types)
4. Robustness: placebo date, alternative control group, controlling for department characteristics
5. SDE appendix

---

## Commit Checkpoint

Will commit this plan before fetching data.
