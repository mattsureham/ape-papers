# Research Plan: The Fifty-Bed Cliff

## Research Question

Does the Medicare Rural Health Clinic (RHC) payment threshold at 50 hospital beds distort hospital capacity decisions? Specifically:
1. Do hospitals bunch below 50 beds to preserve uncapped cost-based RHC reimbursement?
2. Did the 2018 Bipartisan Budget Act (which introduced per-visit caps for RHCs at 50+ bed hospitals) intensify this bunching?
3. Did the 2023 Rural Emergency Hospital (REH) conversion option (available to hospitals ≤50 beds) add a second layer of bunching incentive?

## Identification Strategy

**Bunching estimation** (Kleven & Waseem 2013; Kleven 2016):
- **Running variable:** Total facility bed count (integer, from CMS HCRIS Worksheet S-3)
- **Notch:** Hospitals below 50 beds receive uncapped cost-based RHC reimbursement; hospitals at 50+ beds face per-visit payment caps
- **Excess mass:** Estimate the counterfactual bed distribution absent the notch using polynomial fit to the distribution excluding the bunching region, then compute excess mass at 49-50 relative to the missing mass at 51+
- **Two natural experiments:**
  - Pre-2018 vs. post-2018 (BBA RHC cap introduction)
  - Pre-2023 vs. post-2023 (REH conversion eligibility)

**Placebos:**
- Bunching at 40 beds (round number, no regulatory significance)
- Bunching at 60 beds (round number, no regulatory significance)
- Bunching at 25 beds (CAH threshold — should show its own bunching, distinct from 50-bed)
- Critical Access Hospital (CAH) sample excluded from main analysis (they have their own 25-bed threshold)

## Expected Effects and Mechanisms

1. **Capacity distortion:** Hospitals constrain inpatient bed count to stay below 50, sacrificing inpatient capacity to preserve uncapped outpatient RHC revenue — the "cross-subsidy distortion"
2. **Intensification post-2018:** The BBA made the payment notch explicit; expect excess mass to grow
3. **REH option value (2023):** The REH conversion (≤50 beds) adds a second incentive layer; hospitals at 51-55 beds may downsize to preserve the REH option
4. **Geographic concentration:** Bunching should be strongest in rural areas with active provider-based RHCs

## Primary Specification

Estimate counterfactual density using polynomial fit (order 7) to the bed distribution from 20-80 beds, excluding the manipulation region (45-55). Compute:
- Excess bunching ratio: b̂ = (observed mass at 46-50) / (counterfactual mass at 46-50)
- Missing mass above: proportion of hospitals that would have been at 51-55 absent the notch
- Bootstrap standard errors (500 replications)

For temporal variation:
- Split sample into pre-BBA (2010-2017) and post-BBA (2018-2023) periods
- Test for structural break in excess mass

## Data Source and Fetch Strategy

**CMS Hospital Cost Report Information System (HCRIS)**
- Source: CMS.gov public use files
- Years: FY2010–FY2023
- Key fields: Provider number, total bed count (Worksheet S-3, Part I, Line 14, Col 2), rural/urban indicator, state, provider type
- Download: Direct CSV from CMS data.cms.gov
- Size: ~4,700 non-CAH hospitals per year

**Fetch plan:**
1. Download HCRIS 2552-10 numeric and alpha tables from CMS
2. Extract bed count variable (worksheet S-3, line 14, column 2)
3. Merge with provider characteristics (rural indicator, state, Medicare participation dates)
4. Exclude CAH-designated hospitals (provider type codes)
5. Construct panel: provider × fiscal year

## Key Risks

1. **Bed count measurement:** HCRIS reports licensed/certified beds, which may differ from staffed beds. Licensed beds are the regulatory variable for the threshold.
2. **CAH contamination:** CAH hospitals have their own 25-bed cap; must cleanly exclude them.
3. **Small hospitals:** Very small hospitals (<20 beds) may have different dynamics; test sensitivity to sample restrictions.
4. **RHC linkage:** Not all hospitals below 50 beds operate provider-based RHCs; heterogeneity analysis by RHC presence would strengthen the mechanism test but requires linking to CMS RHC enrollment data.
