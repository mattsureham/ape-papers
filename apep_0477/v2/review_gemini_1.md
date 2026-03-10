# Gemini-3-Flash Review

**Role:** External referee review
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T01:42:32.483669
**Route:** Direct Google API + PDF
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 21512 in / 1400 out
**Response SHA256:** fe4b3317dbb6f456

---

This review evaluates the paper "Do Energy Labels Move Markets? A Well-Powered Null from English Property Transactions." The paper uses a multi-cutoff regression discontinuity (RD) design and a difference-in-discontinuities approach to test for price effects at Energy Performance Certificate (EPC) band boundaries, specifically focusing on the regulatory "cliff" at the E/F boundary created by the Minimum Energy Efficiency Standards (MEES).

### 1. IDENTIFICATION AND EMPIRICAL DESIGN
The identification strategy is generally strong, leveraging the discrete mapping of a continuous SAP score (1–100) into categorical grades (A–G).
*   **Regulatory vs. Informational:** The design cleverly distinguishes between purely informational boundaries (e.g., C/D) and the regulatory boundary (E/F).
*   **Sorting and Manipulation:** The author identifies significant McCrary density test failures at several boundaries, notably E/F (p < 0.001) and B/C. This indicates "assessor rounding" or strategic improvements to clear thresholds. The author correctly notes that this violates the standard RD continuity assumption. The use of "donut" specifications (Table 8) is a necessary and standard response, though the bias at E/F likely remains downward (conservative) as lower-quality properties are pushed just above the threshold.
*   **Treatment Timing:** The use of April 2018 as the MEES enactment date is correct, and the exploration of the 2021–2023 energy crisis provides a powerful test of the "salience" hypothesis.

### 2. INFERENCE AND STATISTICAL VALIDITY
*   **Mass Points:** The running variable (SAP score) is discrete (integers 1–100). The author appropriately uses the `rdrobust` package with mass-point adjustments and clusters standard errors at the local authority district level.
*   **Power:** A major strength of the paper is its "well-powered null." By using a 500,000-observation subsample (and validating with the 7.1 million full sample), the paper provides narrow confidence intervals that exclude the effect sizes reported in previous hedonic literature (5–10%).
*   **Effective Sample Sizes:** Reported in Table 2, these are large (e.g., $N_{eff} = 255,058$ at C/D), supporting the validity of the asymptotic approximations used in RD inference.

### 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS
*   **Alternative Specifications:** The results are robust to bandwidth choices (Figure 9), polynomial orders (Table 13), and the inclusion of covariates (Table 2).
*   **Mechanism vs. Reduced Form:** The author differentiates between the price effect and a volume effect. Table 14 shows a significant volume jump at E/F post-MEES, which suggests the regulation *is* moving the market (via strategic selling or assessment manipulation), even if it does not manifest in price discontinuities.
*   **Tenure:** The split between "Private Rental" and "Owner-Occupied" (Table 12) is critical, as MEES only applies to the former. The null persists in both, which suggests that even where the regulation is legally binding, it is not being capitalized into prices at the margin.

### 4. CONTRIBUTION AND LITERATURE POSITIONING
The paper makes a significant contribution by reconciling the "EPC premium" found in hedonic studies (Fuerst et al., 2015) with an RD framework. It convincingly argues that previous studies likely captured smooth pricing of the continuous score or omitted variable bias rather than discrete label effects. The positioning within the "Energy Efficiency Gap" and "Salience" literatures is appropriate.

### 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION
*   **The "Threshold vs. Smooth" Distinction:** The author is careful to state that a null RD effect does not mean energy efficiency isn't priced; it means the *discrete letter grade* does not add a jump. This is supported by Figure 11, which shows a smooth, positive price-score relationship.
*   **E/F Boundary Caution:** The author appropriately caveats the E/F results due to manipulation. However, the "Difference-in-Discontinuities" (Table 5) helps mitigate this by looking at the *change* in the discontinuity, assuming the manipulation bias is somewhat stable over time.

---

### 6. ACTIONABLE REVISION REQUESTS

#### 1. Must-fix issues
*   **Address the A/B Boundary result:** Table 2 shows a significant negative result for A/B (-11.3%, p=0.04). While the author dismisses this as "unreliable" due to low $N$ and bunching, the full-sample validation (Section 7.9) says this "disappears." The author should provide a table or appendix figure showing the full-sample RD plots for A/B to conclusively prove this was a small-sample artifact.
*   **Standardize the Diff-in-Disc Windows:** Table 5 uses a 2-year window, while the "Post-MEES Pre-Crisis" period in other tables is longer. Clarify if the Diff-in-Disc result is sensitive to the window length (e.g., 1-year vs 3-year).

#### 2. High-value improvements
*   **Exemption Data:** Section 2.5 mentions that exemptions (the £3,500 cap) may explain the null. If the "PRS Exemptions Register" is public, can the author provide a descriptive statistic on how many F-rated properties in the sample actually hold exemptions? This would strengthen the "weak enforcement" interpretation.
*   **Visualizing the Volume Effect:** Figure 2 shows price, but the paper argues volume *does* react (Table 14). A binned scatter plot of transaction counts (frequency) around the E/F boundary before and after 2018 would be a powerful visual accompaniment to the price null.

---

### 7. OVERALL ASSESSMENT
The paper is an excellent example of a "informative null." It uses a rigorous, state-of-the-art empirical design on a massive dataset to challenge established wisdom in the energy economics literature. The multiple layers of checks (informational vs. regulatory, pre- vs. post-crisis, rental vs. owner-occupied) make the null result highly credible. The McCrary bunching is handled transparently.

**DECISION: MINOR REVISION**