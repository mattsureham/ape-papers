# Research Plan: Who Counts the Dead?

## Research Question
Do elected coroners — who typically lack medical training — systematically misclassify drug overdose deaths compared to appointed medical examiners? What is the causal magnitude of this "detection gap," and how much does it bias national opioid mortality statistics?

## Identification Strategy
**Border-county pair design with state fixed effects.**

Within 16 US states that have within-state variation in medicolegal death investigation (MDI) system type, we identify contiguous county pairs where one county uses an elected coroner and the adjacent county uses an appointed medical examiner. State fixed effects absorb all state-level confounders (drug prevalence, policing, demographics, policy environment). The comparison is strictly within-state, across-border.

**Key outcome:** Share of drug overdose deaths classified as "unspecified" (ICD-10 T50.9) vs. drug-specific codes (T40.1 fentanyl, T40.2 heroin, T40.3 methadone, T40.4 synthetic opioids, T40.5 cocaine, T40.6 other narcotics).

**Theory-matched placebos:** MDI type should NOT predict death rates for causes not requiring forensic classification — cancer (C00-C97) and heart disease (I00-I99). If it does, our design is contaminated by selection.

## Expected Effects and Mechanisms
- **Primary hypothesis:** Coroner counties have higher unspecified drug overdose shares (positive effect, moderate-to-large SDE)
- **Mechanism:** Coroners perform fewer autopsies and toxicology screens; lack training to code drug-specific deaths
- **Welfare object:** National undercount of specified opioid deaths attributable to the coroner system

## Primary Specification
```
UnspecifiedShare_cst = α + β × Coroner_c + γ × X_c + δ_s + ε_cst
```
Where c = county, s = state, t = year. State FE δ_s absorbs state-level confounders. X_c = county demographics (population, poverty, urbanicity, racial composition). Border-pair FE variant restricts to contiguous cross-system pairs. SE clustered at state level.

## Data Sources
1. **CDC COMEC:** County-level MDI system classification (3,143 counties: 1,544 coroner, 1,146 ME, 453 other)
2. **CDC WONDER Multiple Cause of Death:** County-level drug overdose deaths by ICD-10 code, 1999-2022
3. **CDC VSRR:** Provisional drug overdose death counts (county-month)
4. **Census/ACS:** County demographics for controls
5. **County adjacency file:** Census Bureau county adjacency definitions for border-pair construction

## Fetch Strategy
1. Download CDC COMEC CSV (direct URL from CDC website)
2. Query CDC WONDER for county-level MCD data (drug overdose deaths + cause-specific codes)
3. Download Census county adjacency file
4. Merge on FIPS codes
5. Construct border-county pairs and estimate
