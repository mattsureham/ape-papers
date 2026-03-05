# Gemini-3-Flash Review

**Role:** External referee review
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T20:34:09.016682
**Route:** Direct Google API + PDF
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 17352 in / 1255 out
**Response SHA256:** 24c61e32f1ca7e64

---

This review evaluates "Can't Ask, Won't Tell: Salary History Bans and the Gender Earnings Gap at Hire." The paper uses a triple-difference (DDD) design and administrative QWI data to test whether salary history bans (SHBs) compress the gender earnings gap for new hires.

### 1. IDENTIFICATION AND EMPIRICAL DESIGN
The identification strategy is highly credible. The use of the **Quarterly Workforce Indicators (QWI)** is a major advancement over prior literature (e.g., Hansen et al. 2020) because it allows for a clear separation of "new hires" from "continuing workers."
*   **Triple-Difference (DDD):** The design—comparing new-hire gender gaps to continuing-worker gender gaps within the same state-quarter—is a powerful "built-in" mechanism test. If SHBs work by breaking the link to prior pay, the effect *must* show up for new hires and should be absent for incumbent workers. 
*   **Assumptions:** Parallel trends are rigorously tested via event studies and joint F-tests (p=0.99, p. 12). The "within-state placebo" (continuing workers) effectively controls for state-level shocks and concurrent policies like pay transparency.
*   **Threats:** The author acknowledges the potential "contamination" of the continuing worker group over time (p. 12) but correctly notes this is a long-run concern that doesn't invalidate short-run findings.

### 2. INFERENCE AND STATISTICAL VALIDITY
The statistical foundation is robust.
*   **Precision:** The paper produces "precisely estimated zeros." With an MDE of 0.7 log points for DiD and 2.0 log points for DDD (p. 13-14), the paper has sufficient power to reject the 1–2 percentage point effects found in earlier studies.
*   **Staggered Adoption:** The author proactively addresses the "forbidden comparison" problem by implementing **Callaway–Sant’Anna (2021)** and **Sun–Abraham (2021)** estimators. The convergence of results across these estimators (Table 6) is a strong sign of validity.
*   **Randomization Inference:** Providing an RI p-value (0.45, p. 21) addresses concerns about the finite number of treated clusters (20 states).

### 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS
The robustness section is comprehensive:
*   **Composition Effects:** The test for changes in the female share of new hires (Table 4, col 3) is critical and rules out the "statistical discrimination" backlash found in "Ban the Box" literature.
*   **Bundled Policies:** The exclusion of CO, CA, and WA (states with bundled transparency laws) ensures the null isn't masked by overlapping mandates.
*   **Heterogeneity:** The industry-level analysis (Figure 2) shows no effect even in high-negotiation sectors (finance, professional services), where the mechanism should be strongest.

### 4. CONTRIBUTION AND LITERATURE POSITIONING
The paper makes a significant contribution by providing a rigorous "null" result that challenges the emerging consensus. It correctly positions itself against Hansen et al. (2020) and Sinha (2023), explaining why the QWI administrative data provides a more reliable estimate than the CPS.

### 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION
The author is careful not to over-claim. The discussion (Section 6) provides nuanced reasons for the null:
*   **Imperfect Compliance/Porousness:** Candidates may still volunteer info.
*   **Redundancy:** Market equilibrium may already price workers at marginal product.
*   **Structural vs. Informational:** The gender gap may be driven more by occupational sorting than by "anchoring" to prior salaries.

### 6. ACTIONABLE REVISION REQUESTS

#### 1. Must-fix issues:
*   **Standard Error Correction (Table 3):** On page 16, the author notes that standard errors for the CS-DiD were computed as the "root-mean-square of group-time cell-level bootstrap SEs" due to software issues. This is an ad-hoc approximation. 
    *   *Fix:* Use the latest version of the `did` or `fixest` (specifically `sunab`) packages in R/Stata to produce properly aggregated, clustered standard errors for the overall ATT.

#### 2. High-value improvements:
*   **The "Strategic Disclosure" Hypothesis:** On p. 22, the author discusses strategic disclosure (high earners disclose, low earners stay silent). 
    *   *Fix:* If the data allows, test if there is a change in the *variance* of new-hire earnings by sex. If high-earning women still disclose and low-earning women stay silent, we might see the lower tail of the female distribution move differently than the upper tail.
*   **Clarify SUTVA/Spillovers:** The mention of national employers (Amazon, etc.) adopting policies nationwide is important (p. 13). 
    *   *Fix:* A brief descriptive test looking at whether the gender gap narrowed in *non-ban* states during the peak adoption years (2018-2020) would help assess if spillovers are attenuating the results.

### 7. OVERALL ASSESSMENT
This is a high-quality empirical paper. Its primary strength lies in the use of "universe" administrative data to provide a definitive answer on a popular policy lever. The results are "precisely null," which is as scientifically valuable as a positive finding in this context. It is well-suited for a top general-interest journal or *AEJ: Policy*.

**DECISION: MINOR REVISION**