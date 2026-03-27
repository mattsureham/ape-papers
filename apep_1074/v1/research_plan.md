# Research Plan: The Detection Dividend — Drug-Type Decomposition of Fentanyl Test Strip Legalization Effects on Overdose Mortality

## Research Question

Does fentanyl test strip (FTS) legalization reduce overdose deaths differentially across drug types with varying fentanyl contamination risk? If FTS work through information revelation, the effect should concentrate in high-contamination drug categories (cocaine, heroin) and be absent for drugs with near-zero contamination risk (methadone, prescription opioids).

## Contribution

Bhai et al. (2025, MCRR) estimated a 7% aggregate reduction. APEP paper apep_0227 found aggregate null effects and discussed "fentanyl saturation" but never decomposed by drug type. This paper provides the first causal test of the information-revelation mechanism by exploiting differential contamination risk across drug categories.

## Identification Strategy

**Triple-Difference (DDD):**
1. State dimension: FTS-legalized states vs. not-yet-legalized states
2. Time dimension: Pre vs. post FTS legalization
3. Drug-type dimension: High-contamination drugs (cocaine T40.5, heroin T40.1) vs. low-contamination drugs (methadone T40.3, natural/semi-synthetic opioids T40.2)

State x time FE absorbs all state-level shocks. The DDD estimand isolates the drug-type composition channel.

## Data Source

CDC VSRR Provisional Drug Overdose Deaths (data.cdc.gov SODA API): state x month x drug indicator, 2015-2023.

## Robustness

1. Event study with leads/lags
2. Synthetic opioids (T40.4) as additional high-contamination category
3. Leave-one-out by state
4. Randomization inference
5. Alternative clustering
