# Research Plan: The Pill Pipeline

## Research Question
Does disability benefit receipt causally increase opioid prescribing? Specifically, does the quasi-random assignment of Social Security disability appeals to more lenient Administrative Law Judges (ALJs) — which increases local disability enrollment — lead to higher county-level opioid pill shipments and overdose mortality?

## Identification Strategy
**ALJ Leniency Instrumental Variable** (Maestas et al. 2013 AER; Gelber et al. 2024 JPubE)

Within each SSA hearing office, cases are randomly assigned to ALJs who exhibit large, persistent differences in allowance rates (within-office SD ~15 pp). This quasi-random assignment creates exogenous variation in local disability enrollment.

**Instrument construction:** For each hearing office h in fiscal year t, compute the case-weighted average ALJ leniency (leave-one-out allowance rate). This instruments for the hearing-office-level disability award rate.

**Key equations:**
- First stage: DisabilityRate_{ht} = α + β × AvgALJLeniency_{ht} + HearingOfficeFE + YearFE + X_{ht}γ + ε_{ht}
- Second stage: OpioidOutcome_{ht} = α + δ × DisabilityRate_hat_{ht} + HearingOfficeFE + YearFE + X_{ht}γ + u_{ht}
- Reduced form: OpioidOutcome_{ht} = α + π × AvgALJLeniency_{ht} + HearingOfficeFE + YearFE + X_{ht}γ + v_{ht}

**Exclusion restriction:** Conditional on hearing-office and year FE, ALJ leniency affects opioid prescribing only through the disability enrollment channel. ALJ generosity does not directly cause local physicians to prescribe more opioids.

## Expected Effects and Mechanisms
- **Primary mechanism:** SSDI → Medicare (24-month wait) → Part D coverage → opioid access. SSI → Medicaid (immediate) → opioid access.
- **Expected sign:** Positive — more lenient ALJs → more disability awards → more insurance coverage → more opioid prescriptions → more pills shipped to local pharmacies.
- **Built-in timing test:** SSDI has 24-month Medicare waiting period; SSI gives immediate Medicaid. The opioid effect should be immediate for SSI beneficiaries but lagged for SSDI.
- **Magnitude prior:** Savych et al. (2019) document that SSDI receipt explains 28-46% of county opioid prescribing variation in cross-section. Causal IV estimates should be smaller than OLS but still economically meaningful.

## Primary Specification
2SLS at hearing-office × fiscal-year level, with hearing-office and year fixed effects, clustering at hearing-office level (~165 clusters). Controls: county demographics (population, unemployment, income, manufacturing share), healthcare supply (physicians per capita, hospitals).

## Data Sources and Fetch Strategy

### 1. SSA ALJ Disposition Data
- **Source:** SSA.gov/appeals, data.gov
- **Content:** ALJ-level allowance rates, total dispositions, hearing office assignment
- **Access:** Public monthly/annual files. Will attempt to download FY2007-2015 files.
- **Fallback:** If historical files unavailable, construct hearing-office-level leniency from published ALJ-level statistics.

### 2. DEA ARCOS (County-Level Opioid Shipments)
- **Source:** Mendeley Data (doi:10.17632/dwfgxrh7tn.7), pre-aggregated county-level
- **Content:** County-year opioid pill counts (oxycodone + hydrocodone), 2006-2014
- **Access:** Direct download from Mendeley (~small compared to 6.89GB bulk)

### 3. CDC WONDER Overdose Mortality
- **Source:** CDC WONDER API (data.cdc.gov)
- **Content:** County-level drug overdose death rates (ICD-10 X40-X44)
- **Access:** REST API, confirmed working

### 4. Hearing Office-County Crosswalk
- **Source:** SSA hearing office locations (public), geocoded to counties
- **Access:** Manual construction from SSA office directory

### 5. County Controls
- **Source:** BLS LAUS (unemployment), Census ACS (demographics), AHRF (healthcare supply)
- **Access:** APIs (BLS, Census) confirmed working
