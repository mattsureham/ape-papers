# Research Plan: The Fiscal Shadow of the Pill Mill

## Research Question
Does pharmaceutical opioid supply exposure causally increase downstream Medicaid addiction treatment demand? We estimate the supply-to-treatment pipeline elasticity: for every additional standard deviation of pills shipped to a state, how many additional Medicaid beneficiaries enter medication-assisted treatment (MAT) 6-12 years later?

## Identification Strategy
**Method:** Instrumental Variables (2SLS)

**Instrument:** Pre-1988 triplicate prescription program adoption (binary). Seven states (CA, ID, IL, IN, NY, TX, WA) adopted triplicate prescription programs between 1961-1988, requiring carbon-copy prescriptions for Schedule II controlled substances. When Purdue Pharma launched OxyContin in 1996, internal documents show they deliberately under-marketed in triplicate states because monitoring made aggressive prescribing harder. This created large, persistent cross-state variation in opioid supply exposure determined by a pre-1988 bureaucratic choice.

**Endogenous variable:** Log pills per capita shipped to each state (ARCOS, 2006-2012 average).

**Outcome:** Log MAT claims per Medicaid beneficiary (T-MSIS, 2018-2024 average), including methadone (H0020), buprenorphine injections (J0571-J0575), and naltrexone (J2315).

**Assignment story:** Triplicate programs were adopted 1961-1988 for administrative drug monitoring — decades before OxyContin existed (1996). Purdue's marketing response was a corporate strategy, not a response to local demand conditions.

**Exclusion story:** Triplicate status affects MAT demand only through its effect on opioid supply/addiction. Placebo test: triplicate status should NOT predict non-opioid SUD treatment (alcohol, stimulant use disorder). 30+ year lag from program adoption to outcome measurement makes direct effects implausible.

**Estimand:** The LATE identifies the effect of opioid supply on treatment demand for states whose supply was constrained by triplicate monitoring. Given that non-triplicate states were the high-exposure states, this identifies the supply-to-treatment pipeline on the relevant margin.

## Expected Effects and Mechanisms
- **Main hypothesis:** Higher pill supply → more OUD → more MAT demand. Expect positive coefficient.
- **Mechanism:** Supply creates addiction stock; addiction stock generates treatment demand with a lag.
- **Magnitudes:** Powell et al. (2020 JHE) found 14.1% treatment admission increase per 10% supply increase using TEDS data. We expect a similar or larger elasticity given T-MSIS captures Medicaid-specific treatment that TEDS misses.

## Primary Specification
State-level cross-sectional IV (N=50 states + DC):
- First stage: log(pills_pc_s) = α + β × Triplicate_s + X_s'γ + ε_s
- Second stage: log(MAT_pc_s) = α + δ × log(pills_pc_s)_hat + X_s'γ + ε_s
- Controls: log population, poverty rate, % uninsured, urbanization rate
- Inference: HC2 robust standard errors (50 clusters too few for cluster-robust)

## Data Sources
1. **ARCOS** (Azure: `raw/arcos/arcos_county_annual.parquet`) — County-year pill shipments 2006-2012. Aggregate to state level.
2. **T-MSIS** (local: `data/medicaid_provider_spending/tmsis.parquet`) — 227M Medicaid claims. Filter for MAT HCPCS codes, geocode NPIs to states via NPPES.
3. **CDC WONDER** — County/state-level opioid overdose deaths (validation of the supply-mortality pathway).
4. **Census/ACS** — State population, poverty, insurance, urbanization.
5. **CMS Medicaid enrollment** — State-level Medicaid beneficiary counts for normalization.

## Tables (planned)
1. Summary statistics (supply variation, treatment variation, state characteristics)
2. First stage (triplicate → pills per capita)
3. Main IV results (pills per capita → MAT claims)
4. Placebo: non-opioid SUD treatment
5. Robustness: alternative specifications
F1. SDE table (appendix)
