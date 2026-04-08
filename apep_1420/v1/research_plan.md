# Research Plan: The Coding Dividend

## Research Question

When CMS mechanically reclassifies ICD-10 diagnosis codes between CC (Complication or Comorbidity) and MCC (Major Complication or Comorbidity) severity tiers, does hospital treatment intensity respond—or only coding? The MS-DRG payment system creates discrete payment jumps of $3,000–$15,000 between severity tiers. If hospitals respond to reclassification by changing actual resource use (charges as proxy), severity-based payment shapes treatment. If only coding patterns shift, the $200B IPPS system incentivizes a multi-billion-dollar Clinical Documentation Improvement (CDI) industry with no allocative benefit.

## Identification Strategy

**Difference-in-differences** at the hospital × DRG-triplet × year level.

- **Treatment:** DRG triplets containing a diagnosis code reclassified by CMS in a given fiscal year (e.g., MCC→CC demotion, CC→MCC promotion, CC→non-CC demotion).
- **Control:** DRG triplets with no reclassification event in the same fiscal year.
- **Unit of observation:** Hospital × DRG × fiscal year.
- **Key outcome:** Average submitted charges per discharge (proxy for treatment intensity). Average Medicare payment per discharge (mechanical benchmark—should move by construction). Discharge volume (composition/selection margin).

**Identifying assumption:** Absent the reclassification, trends in charges and discharges would have been parallel between affected and unaffected DRG triplets at the same hospitals. Supported by:
1. Reclassifications are determined by CMS's clinical review process, not by hospital behavior.
2. Pre-trends test using 3+ years of pre-reclassification data.
3. Placebo: FY2020 proposed-but-blocked reclassification of ~1,492 codes (proposed April 2019, withdrawn in Final Rule August 2019 after lobbying). If the parallel-trends assumption holds, these proposed-but-not-enacted changes should show zero effect.

## Expected Effects and Mechanisms

- **Payment (mechanical):** Demoted codes (MCC→CC) should see Medicare payment drop by the DRG weight differential × base rate. Promoted codes should see payment rise. This is a first-stage sanity check.
- **Charges (treatment intensity):** If hospitals adjust treatment, charges should move in the same direction as payment but by less (partial pass-through). If only coding responds, charges should be flat.
- **Volume (composition):** If hospitals selectively code patients into higher-severity tiers when possible, demotions should increase volume in the base DRG while reducing it in the demoted tier. Promotions should do the reverse.

**Named empirical object: "The Coding Dividend"** — the fraction of the payment change that translates into actual treatment intensity changes. A coding dividend near zero means the system only rewards documentation, not care.

## Primary Specification

```
Y_{h,d,t} = α + β × Reclassified_{d,t} + γ_h + δ_d + λ_t + ε_{h,d,t}
```

Where:
- Y = log average submitted charges, log average Medicare payment, or log discharges
- Reclassified = 1 in the fiscal year of and after reclassification for affected DRG triplets
- γ_h = hospital FE, δ_d = DRG FE, λ_t = year FE
- Cluster SEs at the DRG level (treatment varies at DRG level)

**Event study:** Leads and lags around reclassification year to test pre-trends and dynamic effects.

## Data Sources

1. **CMS Medicare Inpatient Hospitals by Provider and Service PUF** (2013–2023)
   - URL: `https://data.cms.gov/provider-summary-by-type-of-service/medicare-inpatient-hospitals/medicare-inpatient-hospitals-by-provider-and-service`
   - 146,427 hospital-DRG rows/year; fields: provider_id, drg_cd, total_discharges, avg_submitted_chrg_amt, avg_ttl_pymt_amt, avg_mdcr_pymt_amt
   - 11 fiscal years of data

2. **IPPS Final Rule Tables** (ICD-10 MS-DRG reclassification lists)
   - Published annually in Federal Register. Tables 6A-6J contain CC/MCC code lists.
   - FY2020 Proposed Rule (April 2019) vs Final Rule (August 2019) identifies the blocked reclassification.
   - CMS ICD-10 MS-DRG Conversion Tables map diagnosis codes to DRG triplets.

## Key Risks

1. **Charges as proxy:** Submitted charges are list prices, not costs. They may not track treatment intensity well. Mitigation: charges are the best available proxy in PUF data; cost-to-charge ratios are stable within hospital.
2. **Aggregation:** PUF reports at hospital × DRG level, not claim level. Cannot observe individual patient coding. Mitigation: DRG-level aggregation is the relevant margin for payment policy.
3. **Reclassification endogeneity:** If CMS targets codes that are being gamed, reclassification is endogenous. Mitigation: The blocked FY2020 reclassification provides a placebo test; pre-trends test identifies anticipation.
