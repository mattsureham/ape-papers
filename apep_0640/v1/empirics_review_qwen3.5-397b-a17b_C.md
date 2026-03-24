# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-13T17:37:42.691664

---

# Review: Verify or Vanish? Mandatory E-Verify and the Formal-Sector Displacement of Hispanic Workers

## 1. Idea Fidelity

The paper deviates significantly from the Original Idea Manifest in two critical dimensions: identification strategy and data granularity. The Manifest proposed a Difference-in-Difference-in-Differences (DDD) design exploiting county $\times$ industry $\times$ ethnicity variation to absorb state-specific shocks and maximize power. The implemented paper employs a standard staggered Difference-in-Differences (DiD) at the **state level** (Equation 1), treating non-Hispanic employment as a post-hoc placebo test rather than the third difference in the identifying equation. Furthermore, while the Manifest confirmed feasibility at the county-industry level (~928,000 observations), the main specification aggregates to state-year observations ($N=856$). This aggregation discards the cross-sectional variation promised in the proposal, directly contributing to the power issues evident in the inference section. The core research question remains intact, but the empirical engine is substantially downgraded from the design document.

## 2. Summary

This paper leverages administrative Census QWI data to estimate the impact of state-level mandatory E-Verify laws on Hispanic employment. Using a staggered Sun--Abraham estimator, the author finds a 6 percent decline in formal Hispanic employment following mandate adoption, concentrated in high-immigrant industries, with no effect on non-Hispanic workers. The study represents a significant data upgrade over prior CPS-based literature, offering near-universe coverage of formal employment. However, the statistical robustness of the main finding is compromised by the limited number of treated units and the discrepancy between asymptotic and randomization inference.

## 3. Essential Points

1.  **Inference Integrity (Asymptotic vs. Randomization):** The abstract and Table 1 claim statistical significance at conventional levels (p<0.01) based on clustered standard errors, yet the Randomization Inference (RI) p-value is 0.166. With only 10 treated clusters, asymptotic inference is known to be oversized (rejecting the null too often). The RI p-value is the appropriate metric for this design. Claiming significance in the abstract while reporting an insignificant RI p-value in the table is misleading. The paper must either temper its claims or reconcile this discrepancy.
2.  **Identification Downgrade (DiD vs. DDD):** The Manifest proposed a DDD design (Hispanic vs. Non-Hispanic $\times$ Treated vs. Control $\times$ Pre vs. Post). The paper implements a DiD on Hispanic workers only, using Non-Hispanic workers as a separate placebo regression. A true DDD specification would difference out state-specific economic shocks common to both ethnic groups, improving identification validity and statistical power. The current design is more vulnerable to omitted variable bias (e.g., state-specific recessions correlating with mandate adoption).
3.  **Data Granularity Mismatch:** The Manifest confirmed feasibility at the county-industry level, yet the main analysis aggregates to the state level. This reduces the sample size from ~928,000 to 856 observations. While clustering must remain at the state level for inference, estimating coefficients at the county-industry level would improve precision and allow for richer heterogeneity analysis (e.g., urban vs. rural enforcement differences) without violating independence assumptions.

## 4. Suggestions

The following recommendations are intended to strengthen the empirical validity and alignment with the proposed design. Implementing these changes would transform this from a suggestive analysis into a definitive contribution.

**Reconcile Inference and Claims**
The discrepancy between the asymptotic p-value (<0.01) and the Randomization Inference p-value (0.166) is the most critical issue. In settings with few treated clusters ($G=10$), the distribution of the test statistic under the null may not converge to the normal distribution quickly enough for clustered SEs to be reliable. The RI p-value suggests that a 6% effect could plausibly arise by chance given the specific assignment of treatment across states.
*   **Action:** Revise the abstract and conclusion to reflect the RI results. Use language such as "suggestive evidence" or "precisely estimated but statistically marginal under permutation inference." Do not claim conventional significance if the RI does not support it.
*   **Action:** Report a power analysis. Given 10 treated states and the observed variance, what is the minimum detectable effect (MDE) at 80% power? If the MDE is larger than 6%, acknowledge that the study is underpowered to detect smaller effects, framing the 6% estimate as an upper bound or best estimate rather than a precise truth.
*   **Action:** Consider using the wild cluster bootstrap (Webb, 2014) as an alternative to RI, which often performs better with few clusters, though RI is generally preferred for treatment assignment inference.

**Implement the DDD Specification**
The Manifest correctly identified that a DDD design is superior for this question. State-level shocks (e.g., the 2008 housing crash hitting Arizona and Nevada hard) could correlate with both E-Verify adoption and employment declines. A DiD on Hispanic workers alone cannot fully separate these shocks from the policy effect.
*   **Action:** Re-estimate the main equation as a DDD: $Y_{s,e,t} = \alpha_{s,e} + \gamma_{t} + \beta (Post_{st} \times Treat_{s} \times Hispanic_{e}) + \varepsilon_{s,e,t}$. This uses the non-Hispanic workers as a control group *within* the regression, rather than in a separate table.
*   **Action:** This specification effectively differences out any state-time shock that affects all workers equally. It isolates the differential effect on Hispanic workers. This should improve the t-statistic and potentially lower the RI p-value by reducing residual variance.
*   **Action:** Ensure standard errors are clustered at the state level (the level of treatment variation), even if the unit of observation is state-ethnicity.

**Exploit County-Industry Granularity**
There is no econometric justification for aggregating to the state level if the QWI data provides county-industry counts. Aggregation throws away information.
*   **Action:** Run the regression at the county-industry-ethnicity level. The equation becomes: $Y_{c,i,s,e,t} = \alpha_{c,i,e} + \gamma_{t} + \beta (Post_{st} \times Treat_{s}) + \varepsilon_{c,i,s,e,t}$.
*   **Action:** Continue to cluster standard errors at the state level to account for correlation within states. The coefficient estimation will benefit from the larger $N$ and the ability to control for county-industry fixed effects, which absorb time-invariant local industry shocks (e.g., a specific factory closing in Maricopa County).
*   **Action:** This allows for a test of spatial spillovers. Did Hispanic employment increase in counties bordering treated states (displacement effect)? The Manifest mentioned this possibility; the county-level data allows you to test it directly by including border counties as a separate interacted group.

**Refine the Control Group**
The paper treats all non-mandate states as controls. However, many states have voluntary E-Verify usage or sector-specific mandates (e.g., public contractors) that might contaminate the control group.
*   **Action:** Construct a measure of "voluntary E-Verify penetration" by state-year (using USCIS data) and include it as a control variable or interact it with the treatment.
*   **Action:** Consider a "cleaner" control group excluding states with high voluntary uptake or local ordinances (e.g., cities in non-mandate states requiring E-Verify). This reduces noise in the control group.
*   **Action:** Address the "Arizona Pre-Trend" issue transparently. The paper notes significant negative coefficients at leads -13 to -14. This suggests Arizona was on a different trajectory long before 2008. Consider dropping Arizona from the main specification (as done in robustness) but make that the primary specification if the RI p-value improves, noting that Arizona is an outlier in both policy and labor market structure.

**Deepen the Mechanism Analysis**
The earnings result (null short-run, negative long-run) is economically counterintuitive for a supply shock. Standard theory suggests reducing labor supply should increase wages for remaining workers.
*   **Action:** Decompose the earnings effect. Is the decline driven by composition (lower-skilled authorized workers remaining) or within-job wage changes? QWI data allows for some decomposition by age or tenure proxies if available.
*   **Action:** Investigate the "informal sector" hypothesis more rigorously. If workers move to informal employment (cash jobs), tax revenue drops. Can you link this to state-level sales tax or income tax revenue data as a secondary outcome? This would strengthen the welfare implication section.
*   **Action:** Explore the hiring vs. separation margin. Table 1 shows hiring and separation rates. Did mandates reduce hiring flows (deterring application) or increase separation flows (firing existing workers)? The Manifest promised this decomposition; the paper mentions it but does not show results. Providing flow dynamics would distinguish between deterrence and displacement.

**Clarify Data Limitations**
The QWI ethnicity imputation is not perfect. It relies on name matching and administrative records which may misclassify Hispanic workers, particularly in states with large indigenous populations (e.g., Mixtec workers in agriculture classified as Non-Hispanic).
*   **Action:** Add a paragraph in the Data section discussing the known accuracy rates of QWI ethnicity flags. If possible, compare QWI Hispanic shares to ACS Hispanic shares by state to validate the measure.
*   **Action:** Acknowledge that "Hispanic" is an imperfect proxy for "Unauthorized." Some Hispanic workers are authorized citizens. This attenuation bias means the true effect on unauthorized workers is likely larger than the 6% estimate (scaled by the share of unauthorized within the Hispanic workforce). Explicitly calculate this scaling factor to provide an estimate of the effect on the unauthorized population specifically.

By addressing the inference discrepancy, implementing the promised DDD design, and utilizing the full granularity of the QWI data, this paper can move from a suggestive finding to a robust, definitive estimate of E-Verify's labor market consequences. The data asset is unique and valuable; the econometrics must match its quality.
