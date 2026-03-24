# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-23T14:51:02.024181

---

# Review: Coal Dust in the Dark

## 1. Idea Fidelity

The paper largely adheres to the core empirical question and data sources outlined in the manifest: it uses QWI data (NAICS 211/212) to evaluate the 2014 MSHA dust rule's impact on mining employment. However, there are notable deviations in the identification strategy. The manifest proposed a **stacked-cohort DiD (Callaway-Sant'Anna 2021)** comparing top-quintile coal counties against oil/gas controls. The implemented paper uses a **continuous treatment DiD (TWFE)** across all mining counties with >10 employees. Additionally, the manifest suggested a Clean Power Plan (NAICS 22) placebo, whereas the paper employs a time-placebo (2012). While the continuous design exploits more variation, it diverges from the proposed quasi-experimental boundary and introduces sensitivity to functional form assumptions regarding the "coal share" intensity.

## 2. Summary

This paper estimates the labor market effects of MSHA's 2014 respirable coal dust rule using county-level QWI data from 2011–2019. The authors find no aggregate employment effect but uncover significant heterogeneity: Appalachian counties (predominantly underground mining) experienced employment declines, while non-Appalachian counties saw gains. The analysis attributes the aggregate null result to the contemporaneous oil price collapse, which disproportionately affected the oil-and-gas-heavy control group, masking the regulatory cost shock to coal.

## 3. Essential Points

1.  **Violation of Parallel Trends:** The event study (Table 2) reveals statistically significant pre-trends (e.g., Quarter -4 coefficient is 0.28, $p<0.01$). This fundamentally undermines the credibility of the pooled DiD estimator. The paper acknowledges this but proceeds with interpretation. You cannot credibly claim causal identification when pre-trends are significant without a more robust control group (e.g., synthetic control) or a justification for why the trend break coincides exactly with the rule rather than the commodity cycle.
2.  **Inference and Clustering:** Standard errors are clustered by state. With 822 counties across roughly 50 states, you have approximately 15–20 clusters per state on average, but effectively only ~50 independent clusters for inference. Given the spatial correlation of commodity shocks (e.g., the shale boom/bust is regionally concentrated), state clustering may be insufficient. The Appalachian coefficient ($\hat{\beta} = -0.23$, $SE = 0.21$) is statistically indistinguishable from zero ($t \approx 1.1$). Claiming an "economically meaningful" effect based on an insignificant coefficient risks overinterpretation.
3.  **Magnitude Plausibility (Hires):** The coefficient on log new hires (0.62) implies a ~60% increase in hiring in coal-intensive counties relative to controls. This is counterintuitive for a compliance cost shock. If the rule forces exits, hires should fall or remain flat. If this reflects churn (replacement hiring), it needs explicit decomposition. A cost shock of this nature should not generate massive hiring spikes unless it is inducing a complete workforce turnover, which requires evidentiary support beyond the reduced form.

## 4. Suggestions

The following recommendations aim to strengthen the econometric validity and economic interpretation of the paper. Addressing these will significantly improve the robustness of your claims.

**Refine the Control Group Strategy**
The current control group (Oil & Gas counties) is problematic because oil and coal markets diverged structurally during this period (fracking boom vs. coal decline). The significant pre-trends confirm this.
*   **Suggestion:** Consider a **within-coal** design. Compare Appalachian counties (underground, high dust, high compliance cost) directly against Western coal counties (surface, low dust, low compliance cost). Both are subject to the same coal price shocks, isolating the regulatory cost variation. This avoids the oil-coal commodity mismatch.
*   **Suggestion:** If retaining the Oil/Gas control, implement a **Synthetic Control Method (SCM)** at the county or state level to construct a counterfactual trend for coal-intensive counties that better matches pre-2014 dynamics. This would address the pre-trend failure visually and statistically.

**Address Estimator Bias and Inference**
The shift from the proposed Stacked DiD to TWFE with continuous treatment warrants caution regarding heterogeneous treatment effects.
*   **Suggestion:** Perform a **Goodman-Bacon decomposition** to check if the TWFE estimator is driven by specific timing groups or negative weights, even with continuous treatment.
*   **Suggestion:** Re-estimate standard errors using the **wild cluster bootstrap** (Cameron, Gelbach, and Miller 2008) given the limited number of state clusters. Alternatively, use **Conley spatial standard errors** to account for geographic correlation in employment shocks that state clusters might miss. Report whether the Appalachian result survives these stricter inference tests.
*   **Suggestion:** Implement the **Callaway-Sant'Anna estimator** as originally proposed in the manifest. Even with continuous treatment, grouping counties into bins (e.g., high/med/low coal share) allows for a staggered adoption style estimation that is more robust to dynamic treatment effects.

**Clarify Mechanisms and Magnitudes**
The hiring result and the magnitude of the employment effect need deeper economic grounding.
*   **Suggestion:** Decompose the employment flow. Is the decline in Appalachia driven by **cessations** (mine closures) or **contractions** (layoffs)? QWI data often allows distinguishing continuing vs. new establishments. If the effect is driven by mine closures, link this to MSHA enforcement data (available via the manifest's Regulations.gov link) to show that violations actually increased post-rule.
*   **Suggestion:** Contextualize the 23% decline. If this is a log-point estimate, it implies a substantial local labor market shock. Compare this magnitude to the estimated compliance costs ($\$22k-\$50k$ per mine). Does the math hold? If a mine employs 50 workers, a 23% cut is ~11 jobs. Does the compliance cost justify closing the mine versus laying off workers? A simple back-of-the-envelope cost-benefit calculation would ground the economic narrative.
*   **Suggestion:** Explain the hiring spike. Is it possible that the rule required *new* certified personnel (e.g., dust monitor operators), driving up hires temporarily? Or is it high turnover due to harsher working conditions? Without a mechanism, the hiring coefficient looks like noise or a data artifact.

**Improving Presentation and Interpretation**
*   **Suggestion:** Be precise with log-point interpretations. A coefficient of 0.15 is approximately a 16% increase ($100 \times (e^{0.15} - 1)$), not 15%. In the abstract and text, ensure percentage changes are calculated correctly for larger coefficients (like the 0.62 hires estimate).
*   **Suggestion:** Temper the conclusion regarding the Appalachian effect. Currently, you state the rule "did appear to accelerate employment exit" based on an insignificant coefficient. Revise to: "Point estimates suggest a decline in Appalachia, but we lack statistical precision to rule out zero." This honesty strengthens credibility.
*   **Suggestion:** Include a map of the treatment intensity. Visualizing the "coal share" across counties helps the reader understand the spatial correlation of the treatment and why state clustering might be insufficient (e.g., if all treated counties are in one state).

**Data and Sample Robustness**
*   **Suggestion:** Test sensitivity to the sample cutoff (10 mining employees). Small counties may have volatile employment data that drives noise. Re-run excluding the bottom quartile of county mining employment to see if the Appalachian result sharpens.
*   **Suggestion:** The manifest mentioned filtering for private sector only. Confirm this is done in the code, as QWI includes local government. Mining is mostly private, but support services might not be. Ensure consistency with the manifest's data protocol.

By tightening the control group to within-coal comparisons, robustifying the inference procedure, and carefully interpreting the magnitudes, this paper can make a compelling contribution to the literature on environmental regulation and labor markets. The current draft identifies an interesting heterogeneity pattern but rests on an identification strategy that is currently too fragile to support causal claims.
