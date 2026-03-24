# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-14T15:56:09.841512

---

# Referee Report

## 1. Idea Fidelity

The paper deviates significantly from the Original Idea Manifest in three critical dimensions. First, the **data vintage** differs substantially: the Manifest confirmed access to DfE Explore Education Statistics through 2024/25, whereas the paper relies on the GOV.UK FE Data Library ending in 2019/20. This truncates the post-treatment period to only three years (two full academic years plus a COVID-truncated year), reducing the ability to detect medium-run equilibrium effects. Second, the **sample coverage** is reduced from the promised 321 Local Authorities (LAs) to 123 LAs. The authors attribute this to boundary changes or name mismatches, but dropping nearly 60% of the geographic units raises concerns about selection bias and statistical power. Third, and most importantly, the **outcome variable** shifts from the Manifest's core focus—*Level 2 (entry-level) starts*—to *total apprenticeship starts*. The Manifest's "Smoke Test" confirmed a 52% collapse in Level 2 starts; the paper admits it cannot measure this at the LA level and instead tests for crowding out of *total* volume. This fundamentally alters the research question from "did the levy crowd out entry-level training?" to "did the levy change total training volume?", masking the compositional substitution that drives the policy concern.

## 2. Summary

This paper investigates whether the UK's 2017 Apprenticeship Levy generated negative geographic spillovers by crowding out apprenticeship provision in Local Authorities with high concentrations of levy-paying firms. Using a Bartik shift-share design across 123 English Local Authorities from 2010 to 2020, the author finds no evidence that levy exposure differentially affected total apprenticeship starts. The author concludes that the policy's well-documented compositional shift—from entry-level to degree apprenticeships—occurred within firms rather than through local labor market capacity constraints.

## 3. Essential Points

1.  **Outcome Variable Mismatch:** The central policy concern outlined in the Manifest is the collapse of *entry-level* (Level 2) training for young entrants. By using *total* starts as the outcome, the paper cannot detect whether entry-level training was specifically crowded out in high-exposure areas while degree apprenticeships increased. If high-exposure LAs saw a substitution from Level 2 to Level 6 that low-exposure LAs did not, the *total* starts coefficient would be null, yet the distributional harm would be real. The paper's conclusion that "geographic crowding out... finds no support" is unsupported because the specific margin of crowding out (entry-level) is unobserved.
2.  **Violation of Parallel Trends:** The event study analysis reveals statistically significant pre-trends at $t=-7$ and $t=-5$, with a joint $F$-test rejecting the null of parallel pre-trends ($p=0.004$). While the author notes these attenuate by $t=-2$, the rejection of the joint test undermines the credibility of the Bartik identification strategy. In a difference-in-differences framework, significant pre-trends suggest that high-exposure LAs were on different growth trajectories prior to the policy, biasing the counterfactual.
3.  **Sample Selection and Power:** The reduction from 321 to 123 LAs significantly impacts statistical power and external validity. The Manifest confirmed data availability for 321 LAs; the paper's failure to utilize this coverage requires justification beyond "name mismatches," which are typically resolvable in administrative data. Furthermore, with only 123 clusters, the standard errors may be underestimated despite clustering, and the ability to detect modest crowding-out effects is diminished. The "precise null" claim is difficult to sustain without a formal power calculation demonstrating that the sample could have detected an effect size consistent with the national Level 2 collapse.

## 4. Suggestions

The paper addresses a timely and important policy question, but the current execution limits its contribution to the *AER: Insights* format. The following recommendations aim to align the empirical strategy with the original research question and strengthen the causal claims.

**Align Outcomes with the Mechanism**
The most critical improvement is to recover the Level 2 vs. Level 6 distinction at the LA level. The Manifest explicitly listed "DfE Explore Education Statistics" as a confirmed data source, noting it contains starts by age and level. The paper's Data section states this data was not used because it prevents a direct test of compositional shifts, which contradicts the Manifest's feasibility check.
*   **Action:** Re-merge the DfE Explore Education Statistics data referenced in the Manifest. Even if the time series is shorter (e.g., 2016–2024), having the *level* of apprenticeship is essential. You should estimate the main specification separately for Level 2 starts and Level 6+ starts. If the hypothesis is correct, you should see a negative $\beta$ for Level 2 in high-exposure LAs and a positive $\beta$ for Level 6, even if the total is null. This would transform the paper from a null result on total volume to a nuanced finding on compositional spillovers.

**Address Identification Concerns**
The significant pre-trends ($p=0.004$) threaten the validity of the design. Dismissing them because they attenuate near the treatment window is risky when the joint test fails.
*   **Action:** Implement a "double-debiased" difference-in-differences estimator (e.g., Gardner 2021 or Callaway & Sant'Anna 2021) to handle potential heterogeneity in treatment effects and trends. Alternatively, include LA-specific linear time trends to absorb the differential growth observed in the early pre-period. You should also report a placebo test using a pseudo-treatment date (e.g., 2014) to demonstrate that the null result is not driven by low power alone. If pre-trends persist, consider a Synthetic Control Method at the LA level, constructing a weighted average of low-exposure LAs to match the pre-trend trajectory of high-exposure LAs.

**Clarify Data Construction and Coverage**
The drop from 321 to 123 LAs is substantial and requires transparency. Administrative data on UK Local Authorities usually allows for consistent mapping via ONS codes (e.g., LAD19CD).
*   **Action:** Provide a mapping table in the appendix detailing which LAs were dropped and why. If boundary changes occurred (e.g., unitary authority creations), aggregate the data to a consistent geographic baseline (e.g., 2019 boundaries) rather than dropping observations. Additionally, conduct a power calculation following the method of *AER* guidelines (e.g., using the variance of the exposure measure and residual variance) to show the minimum detectable effect size. If the minimum detectable effect is larger than the national average decline in Level 2 starts, the null result is uninformative.

**Refine the Economic Narrative**
The current narrative argues that provider capacity did not bind. However, an alternative explanation is that SMEs switched providers or traveled to adjacent LAs for training, diluting the geographic spillover.
*   **Action:** Discuss the possibility of cross-boundary training substitution. If learners in high-exposure LAs travel to neighboring low-exposure LAs for Level 2 apprenticeships, the LA-level data will miss the crowding out. While data on provider location vs. learner residence may be limited, acknowledging this limitation strengthens the discussion. Additionally, refine the interpretation of the "null." If total starts are unchanged but composition shifted nationally, the policy still failed its original goal of boosting entry-level training. The conclusion should emphasize that the Levy did not *exacerbate* geographic inequality, rather than implying it did not harm entry-level training overall.

**Formatting and Presentation**
*   **Tables:** Ensure Table 1 (Summary Statistics) reports the variation in the treatment variable (Levy Exposure) clearly. The mean is reported as 0.0041 (0.41%), but the text describes it as 0.35%. Consistency is key.
*   **Event Study Plot:** The paper presents the event study in table format. For an *Insights* paper, a visual event study plot with confidence intervals is standard and allows readers to instantly assess the pre-trend issue.
*   **References:** Ensure all citations (e.g., `fuller2019`, `patrignani2021`) are fully populated in the bibliography. The current LaTeX source references a `.bib` file that is not provided; ensure the final submission includes a complete reference list formatted to *AER* standards.

By recovering the level-specific data and rigorously addressing the pre-trend violations, this paper could provide a definitive answer on whether training levies generate local market externalities. Currently, the data limitations prevent a test of the core mechanism proposed in the research design.
