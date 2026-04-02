# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-04-02T13:57:08.642310

---

# Review: The Secrecy Premium: Beneficial Ownership Transparency and Business Formation in Europe

## 1. Idea Fidelity

The paper diverges significantly from the Original Idea Manifest in three critical dimensions. First, the manifest proposed using micro-level data from the Companies House PSC register and the ICIJ Offshore Leaks database to track *shell company formation* and *beneficial owner nationality*. The paper instead relies on aggregate Eurostat business registration indices (`sts_rb_q`). Second, the manifest identified the UK as a crucial "always-treated" control group to anchor the difference-in-differences design; the paper explicitly excludes the UK from the main analysis (Appendix Table notes), relying instead on variation within EU states where all are eventually treated. Third, the manifest specified a Callaway-Sant'Anna estimator to handle staggered adoption; the paper reverts to Two-Way Fixed Effects (TWFE), noting in the appendix that the staggered estimator failed to converge. While the core policy shock (AMLD5/CJEU) remains the same, these deviations weaken the identification strategy and shift the outcome from illicit capital flows to aggregate business demography.

## 2. Summary

This paper exploits the adoption and subsequent judicial reversal of public beneficial ownership registers in the EU to estimate the effect of transparency on business formation. Using quarterly Eurostat data for 21 member states, the author finds no statistically significant evidence that public access deters legitimate business registration. A placebo test using manufacturing data suggests that observed declines in rolled-back countries are driven by macroeconomic shocks (e.g., the energy crisis) rather than regulatory changes. The results challenge the empirical basis of the CJEU's proportionality argument, suggesting transparency imposes negligible costs on aggregate economic activity.

## 3. Essential Points

1.  **Outcome Variable Validity (Signal-to-Noise Ratio):** The primary econometric concern is the mismatch between the research question (illicit flows/shell companies) and the outcome variable (aggregate business registrations). Anonymous shell companies used for money laundering constitute a tiny fraction of total enterprise births. Even if transparency perfectly eliminated illicit shells, the effect on the aggregate Eurostat index would be statistically indistinguishable from zero due to noise from legitimate startups. A null result on aggregate births does not imply transparency fails to deter illicit activity; it implies the outcome measure is too coarse.
2.  **Identification Strategy and the UK Control:** Excluding the UK removes the strongest source of identification proposed in the manifest. The UK serves as a natural "never-untreated" control (public register always on, unaffected by CJEU). By restricting the sample to EU states where all units eventually receive treatment, the design relies on timing variation alone, which is susceptible to Goodman-Bacon bias when treatment effects are heterogeneous. The appendix notes the Callaway-Sant'Anna estimator failed; this is likely due to the lack of a never-treated group within the EU sample. Re-integrating the UK would resolve the convergence issue and provide a cleaner counterfactual.
3.  **Inference and Cluster Count:** The analysis clusters standard errors by country (N=21). With treated groups as small as 7 countries (rolled-back), asymptotic inference is unreliable. While the permutation inference (p=0.038) is a robustness check, it assumes exchangeability that may not hold given the economic heterogeneity between rolled-back (e.g., Germany, Netherlands) and maintained countries. Wild cluster bootstrap procedures should be employed to verify the significance of the reversal coefficient, as standard clustered SEs often under-reject in small-cluster settings.

## 4. Suggestions

**Refine the Outcome Measure to Match the Mechanism**
The most impactful improvement would be to return to the micro-data strategy outlined in the manifest. The Eurostat aggregate index is appropriate for measuring general economic activity, but not for measuring *secrecy demand*.
*   **Companies House Micro-Data:** Utilize the Companies House PSC bulk data to construct a panel of UK-incorporated companies owned by EU nationals. If EU transparency deters illicit actors, we should see a spike in UK incorporations by EU nationals when EU registers go public (substitution effect), and a drop when EU registers close (return effect). This leverages the UK as a consistent measuring stick.
*   **Sectoral Heterogeneity:** If aggregate Eurostat data must be used, decompose the outcome by sector. Transparency should theoretically impact "holding companies" (NACE K64.2) or "consulting activities" (NACE M70) much more than "restaurants" or "manufacturing." A difference-in-differences comparing high-opacity sectors vs. low-opacity sectors within countries would isolate the transparency channel better than the total economy vs. manufacturing placebo. The current manufacturing placebo is clever but imperfect; manufacturing firms also have beneficial owners, even if opacity is less critical to their operation.

**Re-engage the UK Control Group**
The exclusion of the UK is a missed opportunity that complicates the estimation.
*   **Estimator Convergence:** The appendix states the Callaway-Sant'Anna estimator failed due to balanced panel requirements. However, recent implementations (e.g., `did` package in R or `csdid` in Stata) handle unbalanced panels and universal treatment better if a never-treated group (UK) is included. The UK was not subject to the CJEU reversal, making it a valid never-untreated control for the reversal event.
*   **Triple Differences:** Consider a Difference-in-Difference-in-Differences (DDD) design: (EU vs. UK) × (Pre vs. Post AMLD5) × (High-Risk vs. Low-Risk Sectors). This would difference out common shocks affecting both the UK and EU (like global pandemic recovery) while isolating the regulatory impact.

**Strengthen Inference and Robustness**
Given the small number of treated clusters (7 rolled-back countries), standard inference is fragile.
*   **Wild Cluster Bootstrap:** Implement a wild cluster bootstrap-t procedure (e.g., `cgmwildboot` in Stata or `boottest` in R) to compute p-values. This is standard practice in macro-finance DiD with few clusters and will lend greater credibility to the permutation results.
*   **Synthetic Control:** For the rolled-back countries (especially large ones like Germany or Netherlands), construct synthetic controls using weighted combinations of maintained countries. This provides a visual and statistical check on the parallel trends assumption that TWFE imposes linearly.
*   **Pre-Trends:** The appendix notes positive pre-trends for adoption. This suggests early adopters were already experiencing higher business growth. Include leads of the treatment variable in the main TWFE specification to formally test and visualize parallel trends, rather than relegating this to the appendix.

**Nuance the Policy Interpretation**
The discussion currently argues that the null result "collapses" the CJEU's proportionality reasoning. This is slightly overstated given the outcome variable limitations.
*   **Privacy vs. Economic Cost:** The CJEU ruling focused on privacy rights (GDPR) versus AML effectiveness, not necessarily aggregate business formation rates. The court's concern was disproportionate interference with private life, not macroeconomic damping. Reframe the contribution: the paper shows transparency does not harm *legitimate* business formation, which counters industry lobbying arguments that transparency kills competitiveness, even if it doesn't fully address the privacy jurisprudence.
*   **Composition vs. Quantity:** As noted in the discussion, transparency may change the *composition* of firms (fewer shells, more operating companies) without changing the *count*. Emphasize this distinction. If the goal of AMLD5 was to reduce illicit flows, a null effect on total births is consistent with success (illicit shells drop, legitimate firms stay constant), but the data cannot confirm this without the micro-data decomposition suggested above.

**Data and Code Transparency**
*   **Replication Package:** Ensure the code used to construct the `PublicRegister` and `RolledBack` indicators is fully documented. The staggered dates (e.g., Germany's August 2021 vs. Netherlands' June 2019) are critical. Provide a mapping table of country-specific implementation dates in the appendix.
*   **Missing Data:** The data appendix notes 6 EU countries are missing from the Eurostat index (including Greece and Hungary). Discuss whether these excluded countries differ systematically in terms of secrecy or AML risk. If missing countries are high-secrecy jurisdictions, their exclusion might bias the results.

**Final Thought**
The reversal design is genuinely novel and valuable. The CJEU shock provides a rare "undo" button in policy evaluation. However, to publish this in a top field journal, the measurement strategy must align with the theoretical mechanism. Aggregate business births are too blunt a tool to measure the cost of secrecy. By pivoting back to the micro-data promises in the manifest (UK PSC data, sectoral heterogeneity), you can transform this from a null result on macro data into a precise estimate of regulatory arbitrage.
