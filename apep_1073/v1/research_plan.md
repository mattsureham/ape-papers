# Research Plan: The Detection Dividend — Drug-Type Decomposition of Fentanyl Test Strip Legalization Effects on Overdose Mortality

## Research Question

Does fentanyl test strip (FTS) legalization reduce overdose deaths differentially across drug types with varying fentanyl contamination risk? If FTS work through information revelation (users learn their drugs contain fentanyl and adjust behavior), the effect should concentrate in high-contamination drug categories (cocaine, heroin) and be absent for drugs with near-zero contamination risk (methadone, prescription opioids).

## Contribution

Bhai et al. (2025, MCRR) estimated a 7% aggregate reduction in overdose deaths from FTS legalization. APEP paper apep_0227 found aggregate null effects and discussed "fentanyl saturation" but never decomposed by drug type. This paper provides the first causal test of the information-revelation mechanism by exploiting differential contamination risk across drug categories. The triple-difference design uses methadone — dispensed from clinics with zero street contamination risk — as a built-in negative control.

## Identification Strategy

**Triple-Difference (DDD):**
1. **State dimension:** FTS-legalized states vs. not-yet-legalized states
2. **Time dimension:** Pre vs. post FTS legalization
3. **Drug-type dimension:** High-contamination drugs (cocaine T40.5, heroin T40.1) vs. low-contamination drugs (methadone T40.3, natural/semi-synthetic opioids T40.2)

**Estimating equation:**
Y_sdt = alpha + beta_1 (Post_st x HighContam_d) + gamma_sd + delta_dt + lambda_st + epsilon_sdt

where Y_sdt is overdose deaths per 100,000 in state s, drug type d, year t. The coefficient beta_1 is the DDD estimand: the differential effect of FTS legalization on high-contamination vs. low-contamination drug deaths.

**Fixed effects:** State x drug (gamma_sd), drug x time (delta_dt), state x time (lambda_st). The state x time FE absorbs all state-level shocks (including aggregate FTS effects), isolating the drug-type composition channel.

**Key assumption:** Absent FTS legalization, high- and low-contamination drug overdose deaths would have followed parallel trends within states. Testable via pre-treatment event study.

## Expected Effects

- beta_1 < 0: FTS legalization reduces high-contamination drug deaths more than low-contamination drug deaths (information-revelation mechanism confirmed)
- beta_1 approx 0: No differential effect by drug type — either FTS don't work, or they work through non-informational channels (e.g., contact with harm reduction services)
- Methadone placebo: If FTS work through information, methadone deaths (clinic-dispensed, zero contamination risk) should show zero effect. Any significant methadone effect signals confounding.

## Primary Specification

Staggered DDD with state x time, drug x time, and state x drug fixed effects. Cohorts defined by FTS legalization year. Outcome: overdose death count (or rate per 100,000) by state x drug-type x year.

## Data Source and Fetch Strategy

**Primary:** CDC WONDER Multiple Cause of Death (via API or VSRR)
- State x year x drug-type mortality counts
- ICD-10 codes: T40.1 (heroin), T40.2 (natural opioids), T40.3 (methadone), T40.4 (synthetic opioids), T40.5 (cocaine), T43.6 (psychostimulants)
- Years: 2015-2023

**Alternative:** CDC VSRR Provisional Drug Overdose Deaths (data.cdc.gov SODA API)
- State x month x drug indicator provisional counts
- More timely but provisional; may have suppressed cells

**FTS legalization dates:** Compiled from legislative records. Key waves:
- 2018: RI, MA
- 2019: NC, VA
- 2021: ~12 states
- 2022: ~24 states
- 2023: ~36 states

## Robustness Checks

1. Event study with leads/lags (pre-trend validation)
2. Synthetic opioids (T40.4) as additional high-contamination category
3. Psychostimulants (T43.6) as intermediate contamination
4. Leave-one-out by state
5. Randomization inference (permute treatment timing)
6. Alternative clustering (state vs. state x drug)
