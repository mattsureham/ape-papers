# Research Plan: apep_0873

## Research Question

Does disability benefit receipt causally increase opioid prescribing? Using quasi-random assignment of Social Security disability appeals to Administrative Law Judges (ALJs) with varying allowance rates as an instrumental variable, this paper estimates the causal effect of SSDI/SSI enrollment on county-level opioid pill shipments and overdose mortality.

## Identification Strategy

**Design:** ALJ leniency instrumental variable (Maestas, Mullen & Strand 2013 AER; Gelber, Moore & Strand 2024 JPubE).

**Instrument:** Within hearing offices, cases are quasi-randomly assigned to ALJs who vary substantially in allowance rates (~15pp within-office SD). For each hearing office h in year t, compute the case-weighted leave-one-out mean ALJ allowance rate. This instruments for the hearing-office-level disability award rate.

**First stage:** ALJ leniency → disability enrollment rate in the hearing office's catchment area.

**Second stage:** Instrumented disability enrollment → county-level opioid prescribing/mortality.

**Key assumptions:**
1. Relevance: F >> 100 (documented in Maestas et al. 2013)
2. Independence: Within-office assignment is quasi-random
3. Exclusion: ALJ leniency affects opioid outcomes only through disability receipt (conditional on office + year FE)

**Mechanism test:** SSDI recipients face a 24-month Medicare waiting period; SSI recipients get Medicaid immediately. If the channel is insurance-mediated prescription access, opioid effects should appear faster for SSI-eligible populations.

## Expected Effects and Mechanisms

**Primary mechanism:** Disability receipt → Medicare/Medicaid enrollment → prescription drug coverage → access to opioid analgesics → higher local prescribing rates.

**Expected signs:**
- Disability enrollment → opioid pill shipments per capita: **Positive**
- Disability enrollment → opioid overdose mortality: **Positive** (but may be attenuated)
- Placebo: Disability enrollment → non-opioid drug deaths: **Null**

**Effect size prior:** Savych et al. (2019) and Lazo & Cossio (2021) find SSDI receipt explains 28-46% of county opioid prescribing variation (correlational). The causal IV estimate should be smaller but economically meaningful.

## Primary Specification

```r
# Two-stage least squares
# First stage: ALJ leniency → disability award rate
# Second stage: disability awards → opioid prescribing

ivreg(opioid_pills_pc ~ disability_rate | alj_leniency,
      data = panel,
      weights = population,
      cluster = ~hearing_office)

# With controls and FE:
feols(opioid_pills_pc ~ 1 | office + year |
      disability_rate ~ alj_leniency,
      data = panel, cluster = ~hearing_office)
```

## Data Sources

1. **SSA ALJ Disposition Data** — ALJ-level allowance rates by hearing office. Monthly public data from SSA (ssa.gov/appeals/DataSets). Need to assess year coverage.
2. **DEA ARCOS via Mendeley** — County-level opioid pill shipments 2006-2013. doi:10.17632/dwfgxrh7tn.7.
3. **CDC WONDER** — County-level drug overdose mortality by cause. data.cdc.gov API.
4. **SSA Disability Statistics** — County/state-level SSDI/SSI enrollment. ssa.gov/policy/docs/statcomps.
5. **Census/BLS controls** — Population, unemployment, median income via FRED/Census APIs.
6. **SSA Hearing Office Locations** — Geographic crosswalk to counties.

## Planned Robustness

1. Event study around disability award timing
2. Placebo: non-opioid drug mortality
3. Alternative clustering (state vs hearing office)
4. Controls for concurrent opioid policies (PDMP mandates, pill mill laws)
5. Heterogeneity: high vs low baseline prescribing areas
6. Reduced-form: ALJ leniency directly on opioid outcomes (avoids 2SLS assumptions)

## Power Assessment

- ~165 SSA hearing offices × ~8 years (2006-2013) ≈ 1,320 office-year observations
- Within-office ALJ variation: ~15pp SD in allowance rates
- First-stage F >> 100 (documented)
- Clustering: ~165 hearing office clusters (well above minimum)
