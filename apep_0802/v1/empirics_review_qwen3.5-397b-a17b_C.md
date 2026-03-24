# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-23T11:58:55.594654

---

# Review: Building the Exemption: Tax Incentives and the Composition of Housing Supply in New Zealand

## 1. Idea Fidelity

The paper deviates significantly from the Original Idea Manifest in three critical dimensions: data source, unit of analysis, and identification strategy. The Manifest proposed using the **MBIE Tenancy Bond Registry** across **67 Territorial Authorities** to measure *rental stock supply* (active bonds), exploiting variation in the **share of new-build rentals** within markets. The submitted paper instead uses **Stats NZ Building Consents** across **16 Regions** to measure *construction flow*, exploiting variation between **multi-unit dwellings and stand-alone houses**.

While the policy question (impact of the interest deductibility removal) remains consistent, the empirical execution diverges. The Manifest's proposed strategy (Existing vs. New-Build Rental Stock) was a cleaner direct test of the exemption rule (CCC date). The paper's strategy (Multi-unit vs. House) relies on a noisier proxy: that multi-unit consents disproportionately represent "new-build exempt investor properties" relative to houses. Additionally, the pre-treatment period was shortened from the proposed 36 months to approximately 9 months (Jan 2021–Oct 2021), limiting the ability to test parallel trends amidst COVID volatility. The authors should explicitly justify why the Manifest's proposed data (confirmed feasible in the smoke test) was abandoned for building consents.

## 2. Summary

This paper evaluates New Zealand's 2021 removal of mortgage interest deductibility for existing rental properties, which exempted new builds. Using a difference-in-differences design comparing multi-unit dwelling consents to stand-alone houses across 16 regions, the authors find that the tax wedge increased multi-unit consents by approximately 42 percent relative to houses. The effect partially reversed following the 2024 policy restoration, suggesting the tax incentive successfully redirected housing investment composition toward denser, rental-oriented dwelling types, though the effect was transient.

## 3. Essential Points

1.  **Inference with Few Clusters:** The primary specification clusters standard errors at the region level ($N=16$). With only 16 clusters and high-dimensional fixed effects (region$\times$type and month), conventional cluster-robust standard errors are known to severely over-reject the null hypothesis (MacKinnon & Webb, 2017). The reported $p$-values (e.g., $p=0.014$) are likely optimistic. The authors must employ inference methods robust to few clusters, such as the wild cluster bootstrap or Conley tabular inference, to confirm statistical significance.
2.  **Validity of the Treatment Proxy:** The identification rests on the assumption that multi-unit consents are disproportionately exposed to the *new-build exemption* relative to houses. However, many multi-unit purchases are owner-occupiers (especially in Auckland), and many stand-alone houses are investor-owned new builds. Without data linking consents to investor status or CCC dates, the "Multi-unit" dummy conflates dwelling type with investor exposure. This measurement error likely attenuates the coefficient, but if zoning changes or demographic shifts correlated with multi-unit construction during this period, it could bias the estimate upward.
3.  **Pre-Treatment Period and COVID Confounds:** The pre-treatment window (9 months) is insufficient to establish parallel trends given the structural breaks caused by COVID-19 lockdowns and border closures in 2020–2021. The Manifest proposed 36 months of pre-data (available from 2018). Restricting the sample to start in 2021 excludes critical variation needed to distinguish policy effects from pandemic-induced supply chain shocks that differentially affected multi-unit construction (e.g., higher reliance on imported materials).

## 4. Suggestions

**Robust Inference and Standard Errors**
Given the small number of clusters (16 regions), you should prioritize robust inference techniques. I recommend implementing the **wild cluster bootstrap percentile-t method** (Cameron, Gelbach, & Miller, 2008) to generate confidence intervals. Alternatively, report **Conley et al. (2012) spatial HAC standard errors** if geographic correlation extends beyond region boundaries. If these methods widen the confidence intervals to include zero, the claim of statistical significance must be tempered. Additionally, consider leaving out one region at a time (leave-one-out jackknife) to ensure results are not driven solely by Auckland, which dominates the multi-unit market. While you exclude Auckland in Column 3 of Table 1, the clustering still relies on the remaining 15 regions; ensure the bootstrap accounts for this.

**Strengthening the Identification Strategy**
The proxy of "Multi-unit = Treated" is the paper's weakest link compared to the Manifest's proposed "New-build CCC date" strategy. To bolster this:
*   **Investor Share Calibration:** Use Census data or loan book data (if accessible via RBNZ) to document the actual share of investor purchases in multi-unit vs. house consents. If 60% of multi-units are owner-occupied, your treatment intensity is diluted. You can adjust the treatment effect magnitude by this exposure rate to estimate the Local Average Treatment Effect (LATE) on actual investors.
*   **Triple Difference (DDD):** Consider adding a third dimension. If you can access TA-level data (as per the Manifest), interact Region$\times$Type with the **pre-existing share of rental stock**. Areas with higher investor intensity should show larger compositional shifts. This would align closer to the Manifest's Equation 3 and help rule out national zoning changes that favored multi-units everywhere regardless of tax status.
*   **Zoning Controls:** The National Policy Statement on Urban Development (NPS-UD) was active during this period, forcing cities to allow more density. You must control for this. Include an interaction between *time* and *initial zoning strictness* to ensure you aren't capturing deregulation effects rather than tax incentives.

**Magnitude Plausibility and Interest Rate Headwinds**
The estimated 42% increase in multi-unit consents is economically large, particularly given the concurrent monetary tightening (OCR rising from 0.25% to 5.50%). Standard housing supply models suggest investment should contract sharply under such rate hikes.
*   **Decompose the Shock:** Explicitly model the interest rate shock. Interact the OCR level with dwelling type. If investors were insensitive to interest rates but sensitive to tax deductibility, this is a novel finding worth highlighting. However, if the tax wedge merely offset the rate hike, the net effect might be zero growth, not positive growth.
*   **Consents vs. Completions:** Building consents are a noisy proxy for supply; many consents lapse. If possible, link to **Building Completions data** (also Stats NZ) to see if these consents translated into actual stock. If consents rose but completions did not (due to construction cost inflation), the policy failed to increase actual housing supply.

**Data Alignment and Pre-Trends**
Revisit the Manifest's data proposal. The MBIE Tenancy Bond Registry was confirmed feasible in the smoke test.
*   **Hybrid Approach:** Even if you prefer consents for timing, use the Bond Registry to validate the *mechanism*. Show that new-build bonds (identifiable via tenure type or linkage) grew relative to existing stock bonds. This would directly test the Manifest's original outcome variable.
*   **Extend Pre-Period:** If using Building Consents, extend the data back to 2018 as originally planned. Stats NZ building consent data is available monthly from 2008. Plotting the event study from 2018 would allow you to show 3+ years of parallel trends, vastly improving credibility over the current 9-month window. This is crucial to rule out pre-existing densification trends unrelated to the tax policy.

**Clarifying the Reversal Mechanism**
The paper notes a partial reversal in 2024. This is a strong validity check, but the mechanism needs nuance.
*   **Pipeline Lags:** Building consents have long lags to completion. A reversal in *consents* in April 2024 suggests developers reacted instantly to tax news. Discuss whether this is realistic given planning consent lead times. If developers locked in consents before the election result was certain, the reversal might be weaker than expected.
*   **Expectation Effects:** Did the market anticipate the reversal during the 2023 election campaign? Consider adding a "Election Period" dummy (Aug–Oct 2023) to see if the effect unwound before the legislative change.

**Writing and Presentation**
*   **Table 1 Clarity:** In Column 2 (Dosage), clarify the unit of the "new_build_premium." Is it 0–100 or 0–1? The coefficient 43.22 suggests a 1 percentage point increase yields 43 consents, which seems large if the premium moves from 0 to 75. Ensure the interpretation matches the scale.
*   **Abstract Precision:** The abstract claims a "42 percent increase." Specify that this is relative to the control group (houses), not an absolute increase in total housing supply. This distinction is vital for policy interpretation.
*   **Manifest Reconciliation:** In the Data section, add a brief paragraph explaining why Building Consents were chosen over Tenancy Bonds. Was it timeliness? Granularity? Acknowledging the deviation from the initial proposal demonstrates scholarly transparency.

By addressing the inference issues, strengthening the treatment proxy, and extending the pre-treatment period, this paper could move from a suggestive correlation to a definitive causal estimate of tax-induced housing composition changes. The policy reversal element is a unique asset that deserves rigorous exploitation to rule out secular trends.
