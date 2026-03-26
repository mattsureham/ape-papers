# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-26T16:14:14.645358

---

### 1. Idea Fidelity

The paper largely adheres to the original idea manifest but deviates in several important ways:

**Strengths:**
- The core research question—whether firms shrink to dodge IR35—is preserved, though the paper finds the *opposite* effect (firms growing past the threshold).
- The identification strategy (bunching-difference design) and key data source (Companies House/NOMIS) are correctly implemented.
- The focus on contractor-intensive SIC codes (62, 70, 71, 74) and the use of trade sectors (46, 47) as controls align with the manifest.

**Deviations:**
- The manifest proposed using *Companies House XBRL data* for firm-level analysis, but the paper relies on *NOMIS UK Business Counts* (aggregate sizeband data). This is a significant shift: the manifest envisioned a granular, firm-level approach (e.g., tracking headcount changes or subsidiary restructuring), while the paper uses coarse, sector-level aggregates. The loss of firm-level variation weakens the ability to test mechanisms (e.g., contractor-to-employee conversion) or rule out alternative explanations (e.g., differential growth trends).
- The manifest emphasized *mechanism tests* (headcount reduction, subsidiary restructuring), but the paper only indirectly infers contractor conversion from delayed effects and heterogeneity. The lack of direct evidence (e.g., from HMRC contractor data or Companies House filings) is a major omission.
- The manifest’s "COVID delay placebo" (April 2020 announcement) is underutilized. The paper treats 2020 as a placebo but does not exploit the staggered timing (announcement vs. implementation) to test anticipatory effects.

**Missed Opportunities:**
- The manifest’s feasibility check noted "29 companies at 40–50 vs. 9 at 50–60 employees," suggesting a sharp discontinuity. The paper’s aggregate approach cannot exploit this.
- The manifest’s focus on *demand-side* responses is preserved, but the paper does not engage with the supply-side literature (e.g., PSC formation) to contextualize its findings.

---

### 2. Summary

This paper examines how the UK’s 2021 IR35 extension—exempting small firms (<50 employees) from off-payroll working rules—affected the size distribution of contractor-intensive firms. Using a difference-in-bunching design with NOMIS data, the authors find that contractor-intensive sectors (e.g., programming, consultancy) experienced a *decline* in the ratio of firms below the 50-employee threshold relative to those above, contrary to the predicted "bunching" response. The effect is driven by sectors with high contractor intensity and strengthens over time, suggesting contractor-to-employee conversion as the mechanism. The paper argues this creates a "compliance trap," where firms’ efforts to avoid IR35 costs inadvertently push them past the exemption threshold.

---

### 3. Essential Points

**Critical Issue 1: Identification and Data Limitations**
The shift from firm-level (XBRL) to aggregate (NOMIS) data severely weakens the identification strategy. The paper’s key outcome—the bunching ratio—is constructed from *counts of firms in sizebands*, not actual firm transitions. This introduces three problems:
- **Ecological fallacy**: The paper cannot observe whether *individual firms* crossed the threshold or whether the aggregate shift reflects entry/exit dynamics (e.g., new firms entering above 50 employees).
- **Mechanism ambiguity**: The contractor-to-employee conversion hypothesis is inferred from delayed effects and heterogeneity, but the data cannot distinguish this from other mechanisms (e.g., differential growth, mergers, or reporting changes). For example, firms might reclassify contractors as employees *without* changing headcount (e.g., by adjusting hours or roles).
- **Alternative explanations**: The significant placebo at the 20-employee threshold (Table 7, Panel B) suggests broader trends (e.g., post-COVID labor market shifts) may confound the IR35 effect. The pre-trend test (Panel C) is marginally significant, further complicating causal interpretation.

*Constructive suggestion*: The authors must either:
1. **Revert to firm-level data** (e.g., Companies House XBRL or HMRC contractor records) to track individual firms’ headcounts and contractor usage over time, or
2. **Acknowledge the limitations** of aggregate data and reframe the paper as a *descriptive* study of sector-level trends, not a causal analysis of firm behavior.

**Critical Issue 2: Mechanism Credibility**
The paper’s central claim—that contractor conversion drives the effect—rests on weak evidence:
- The delayed response (2024–2025) is consistent with conversion but also with other gradual processes (e.g., firm growth, reporting lags).
- The heterogeneity by SIC code (Table 5) aligns with contractor intensity but does not rule out sector-specific shocks (e.g., tech sector growth post-COVID).
- The paper does not test alternative mechanisms, such as:
  - *Subsidiary restructuring*: Firms might spin off contractor-heavy units to stay below 50 employees.
  - *Turnover/balance sheet manipulation*: Firms could avoid the threshold by adjusting financial metrics (e.g., deferring revenue) rather than headcount.
  - *Contractor substitution*: Firms might replace contractors with non-employee labor (e.g., agency workers) to avoid IR35 costs without increasing headcount.

*Constructive suggestion*: The authors should:
1. **Test for subsidiary restructuring** using Companies House data on corporate group structures.
2. **Examine turnover/balance sheet data** to rule out financial manipulation of the threshold.
3. **Engage with HMRC data** (if possible) to directly measure contractor-to-employee conversions.

**Critical Issue 3: Policy Relevance and External Validity**
The paper’s claim that the "compliance trap" informs EU Platform Work Directive implementation is overstated:
- The EU directive’s firm-size exemptions are based on *platform size* (not headcount), and the regulated activity (platform work) is distinct from IR35’s focus on contractor misclassification.
- The paper does not discuss whether the UK’s experience is generalizable to other contexts (e.g., countries with different labor market institutions or contractor prevalence).

*Constructive suggestion*: The authors should:
1. **Clarify the limits of generalizability** and avoid overclaiming policy relevance.
2. **Compare IR35 to other size-based regulations** (e.g., ACA employer mandate, EU VAT thresholds) to contextualize the findings.

---

### 4. Suggestions

**Data and Identification:**
1. **Firm-level analysis**: Use Companies House XBRL data to:
   - Track individual firms’ headcounts and contractor usage over time.
   - Test for discontinuities in growth rates at the 50-employee threshold.
   - Examine subsidiary restructuring (e.g., firms splitting into multiple entities).
2. **Alternative data sources**:
   - **HMRC contractor data**: If accessible, use administrative records to measure contractor-to-employee conversions directly.
   - **Linked employer-employee data**: Test whether firms near the threshold increased permanent hiring post-2021.
3. **Refine the bunching ratio**:
   - Use narrower sizebands (e.g., 45–49 vs. 50–54) to sharpen the discontinuity.
   - Control for sector-specific trends (e.g., tech sector growth) using synthetic control methods.

**Mechanism Testing:**
4. **Direct tests for contractor conversion**:
   - Compare the growth of permanent vs. contractor employment in firms near the threshold.
   - Examine wage bills or benefit costs (e.g., pension contributions) as proxies for employee conversion.
5. **Alternative mechanisms**:
   - Test for subsidiary restructuring by analyzing corporate group structures.
   - Examine turnover/balance sheet data to rule out financial manipulation of the threshold.
6. **Survey evidence**: Conduct a short survey of firms near the threshold to ask about IR35 responses (e.g., "Did you convert contractors to employees to avoid compliance costs?").

**Robustness and Specification:**
7. **Address the 20-employee placebo**:
   - The significant effect at the 20-employee threshold suggests broader trends (e.g., post-COVID labor market shifts). The authors should:
     - Test whether the effect is larger at 50 than at 20 employees (e.g., triple-difference with sizeband interactions).
     - Control for sector-specific trends using synthetic controls.
8. **Pre-trend analysis**:
   - The marginally significant pre-trend (Table 7, Panel C) is concerning. The authors should:
     - Show event-study coefficients for all years (not just post-2021) to assess parallel trends.
     - Use a longer pre-period (e.g., 2010–2020) to test for differential trends.
9. **COVID sensitivity**:
   - The paper excludes 2020–2021 but does not test whether the effect is driven by post-COVID recovery. The authors should:
     - Compare 2022–2025 to 2015–2019 (excluding 2020–2021 entirely).
     - Test for differential effects in sectors more/less affected by COVID (e.g., tech vs. retail).

**Theory and Interpretation:**
10. **Model the compliance trap**:
    - Develop a simple theoretical model of firm behavior near the threshold, incorporating:
      - Compliance costs (per contractor).
      - Conversion costs (e.g., higher wages/benefits for employees).
      - Threshold manipulation costs (e.g., restructuring, financial reporting).
    - Use the model to derive testable predictions (e.g., effect heterogeneity by contractor intensity).
11. **Compare to other thresholds**:
    - Test for bunching at other regulatory thresholds (e.g., 250 employees for audit requirements) to assess whether the effect is IR35-specific.
12. **Discuss alternative explanations**:
    - The paper briefly mentions differential growth but does not engage with it seriously. The authors should:
      - Compare growth rates in contractor-intensive vs. control sectors pre- and post-2021.
      - Test whether the effect is driven by entry/exit dynamics (e.g., new firms entering above 50 employees).

**Presentation and Clarity:**
13. **Improve the abstract and introduction**:
    - The abstract should clearly state the *counterintuitive* finding (firms growing past the threshold) upfront.
    - The introduction should better motivate why the compliance trap is surprising (e.g., contrast with standard bunching literature).
14. **Clarify the bunching ratio**:
    - The paper defines the bunching ratio as (20–49)/(50–99), but this is unconventional (most studies use a narrower window around the threshold). The authors should:
      - Justify the choice of sizebands.
      - Show robustness to alternative definitions (e.g., (45–49)/(50–54)).
15. **Visualize the data**:
    - Add a figure showing the distribution of firms around the 50-employee threshold pre- and post-2021, with separate panels for contractor-intensive and control sectors.
    - Include an event-study plot with confidence intervals for all years (not just post-2021).

**Policy Implications:**
16. **Engage with the EU Platform Work Directive**:
    - The paper’s claim that the findings inform EU policy is speculative. The authors should:
      - Discuss key differences between IR35 and the EU directive (e.g., platform work vs. contractor misclassification).
      - Highlight whether similar "compliance traps" could arise in the EU context.
17. **Quantify the welfare effects**:
    - The back-of-the-envelope calculation (£0.5–8M/year) is useful but incomplete. The authors should:
      - Estimate the deadweight loss from reduced labor market flexibility (e.g., firms avoiding contractors).
      - Compare the compliance costs to the tax revenue generated by IR35.

**Minor Suggestions:**
18. **Clarify the sample**:
    - The paper uses 2-digit SIC codes but does not explain why 3-digit codes (e.g., 62010, 62020) were not used for finer sectoral classification.
19. **Discuss data limitations**:
    - The NOMIS data are aggregate and do not distinguish between single-site and multi-site firms. The authors should discuss how this might affect the results.
20. **Improve table readability**:
    - Tables 1–7 are dense and could be streamlined (e.g., combine Panels A and B in Table 1, use horizontal lines sparingly).

---

### Final Assessment

This paper presents a provocative and timely finding with important implications for regulatory design. However, the shift from firm-level to aggregate data weakens the identification strategy, and the mechanism remains speculative. With additional data and robustness checks, the paper could make a strong contribution to the literature on firm-size manipulation and regulatory avoidance. As it stands, the results are suggestive but not definitive.

**Recommendation**: Revise and resubmit, contingent on addressing the critical issues above—particularly the data limitations and mechanism ambiguity. The authors should either:
1. **Revert to firm-level analysis** (preferred), or
2. **Reframe the paper as a descriptive study** and tone down causal claims.
