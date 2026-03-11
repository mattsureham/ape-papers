# Research Plan: PDUFA Deadline Bunching and Post-Market Drug Safety

## Research Question

Does the FDA's PDUFA 300-day standard review deadline — which creates a massive institutional spike in drug approvals — compromise post-market drug safety? The PDUFA clock forces reviewers to complete action on New Drug Applications within 10 months, generating a 10x bunching of approvals at the deadline window. We exploit this bunching as quasi-experimental variation to estimate whether deadline-induced timing distortion causally increases adverse event rates.

## Identification Strategy

**Primary design: Regression Discontinuity at the 300-day PDUFA deadline**

Running variable: `review_days = approval_date - receipt_date` for standard-review NMEs.

The PDUFA standard review goal creates a sharp mass point at day 300: 63 of 526 standard-review drugs in the PDUFA era (1993-2024) were approved in the [300-310) day window, compared to 1-8 per 10-day window on either side. This spike represents institutional manipulation — FDA reviewers accelerate or delay final action letters to meet the performance goal.

**Causal logic:** Drugs approved in the bunching window include marginal cases that would have been approved earlier (under less time pressure) or later (needing more review time) absent the deadline. The counterfactual is drugs approved outside the deadline cluster — particularly those in adjacent windows (280-290 and 310-340) that were not subject to the deadline distortion.

**Specifications:**
1. **RD at day 300:** Jump in post-market AE rates at the 300-day threshold
2. **Donut-RD:** Exclude [295-305] window (most manipulated), compare 275-295 vs 305-340
3. **Bunching estimator:** Excess mass at 300 vs counterfactual smooth density → identify marginal drugs
4. **Poisson regression:** AE counts as function of review time, controlling for therapeutic class and approval year

## Expected Effects and Mechanisms

**Hypothesis:** Deadline-bunched drugs have higher post-market adverse event rates because:
- Reviewers may cut corners on review completeness under time pressure
- Marginal drugs that needed more review time are pushed through at the deadline
- Complete Response Letters (rejections) are deferred past the deadline window

**Alternative (null):** The deadline is met through efficient resource allocation, not quality compromise. FDA reviewers work harder near deadlines without compromising thoroughness. In this case, bunched drugs would show no differential safety signal.

**Magnitude:** Hseih et al. (2008, NEJM) found drugs approved in the 2 months before PDUFA deadlines were 5.5x more likely to be withdrawn. Our design should give a more precise, causal estimate. We expect a smaller but well-identified effect.

## Primary Specification

```r
# Main RD specification
rdrobust(y = ae_rate, x = review_days, c = 300,
         kernel = "triangular", p = 1,
         covs = cbind(approval_year, therapeutic_class))
```

Where `ae_rate` = total serious adverse events per 100,000 patient-years in first 5 years post-approval.

## Data Sources

1. **FDA NME Compilation** (data.gov/FDA): 1,341 NME approvals 1985-2024 with receipt dates, approval dates, review designation (standard vs priority), breakthrough/accelerated flags
2. **openFDA FAERS API**: 20M+ adverse event reports with NDA number linkage, seriousness indicators, death outcomes
3. **openFDA Drug Enforcement API**: Recalls, market withdrawals by NDA number
4. **openFDA Drug Labeling API**: Black box warning additions (supplemental)

## Fetch Strategy

1. Download FDA NME compilation CSV directly
2. Query openFDA FAERS API for adverse events linked to each NDA number (paginated)
3. Query openFDA enforcement API for recalls/withdrawals by NDA
4. Construct panel: drug × post-approval-year with cumulative AE counts

## Key Risks

- **Sample size:** ~120 NMEs in ±45-day RD bandwidth. Manageable for RDD but warrants sensitivity analysis.
- **AE reporting bias:** FAERS is voluntary reporting. Mitigate by using serious events only and controlling for therapeutic class.
- **Sorting:** Agencies may strategically time submissions. But FDA receipt date is determined by submission timing (company), not review timing (FDA).
- **Confounders:** Priority vs standard review is a potential concern — we restrict to standard-review drugs only.
