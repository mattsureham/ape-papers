# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-26T23:36:46.007073

---

### 1. Idea Fidelity

The paper largely adheres to the original idea manifest but deviates in two critical ways:

**Missed Key Identification Opportunity:**
The manifest proposed a "bunching migration experiment" using the April 2025 threshold increase (small turnover rising from £10.2M to £15M) to test whether firms would shift bunching behavior. The paper does not exploit this natural experiment, despite its potential to provide causal evidence on the role of the two-of-three rule. The 2025 reform is mentioned only in passing (Section 2.4), and no pre/post analysis is conducted.

**Underutilized Data:**
The manifest highlighted the "two-of-three rule" as generating "cross-dimensional bunching predictions" (e.g., firms bunching on turnover or balance sheet instead of employees). The paper focuses almost exclusively on employee counts, ignoring turnover and balance sheet data in the Companies House microdata. This is a missed opportunity to test the core mechanism (compliance slack) directly.

**Alignment with Other Elements:**
The paper faithfully executes the multi-cutoff bunching strategy, uses the promised data sources (Companies House and NOMIS), and addresses the research question about regulatory costs. The null result is consistent with the manifest’s emphasis on the two-of-three rule, though the paper could have tested this more rigorously.

---

### 2. Summary

This paper investigates whether UK private firms bunch below regulatory size thresholds (10, 50, or 250 employees) under the Companies Act 2006, which imposes escalating compliance costs (e.g., audits, IR35, Modern Slavery reporting). Using microdata from Companies House and aggregate data from the Inter-Departmental Business Register, the authors find no evidence of bunching at any threshold. They attribute this to the "two-of-three rule," which requires firms to exceed two of three criteria (employees, turnover, balance sheet) for two consecutive years before reclassification, creating compliance slack. The paper contributes a clean null result to the bunching literature and highlights how multi-dimensional thresholds can reduce allocative distortions.

---

### 3. Essential Points

**1. The 2025 Threshold Reform is a Missed Causal Test**
The April 2025 increase in financial thresholds (turnover and balance sheet) while holding employee thresholds constant is a natural experiment to test the two-of-three rule. The paper should:
- Compare bunching behavior pre/post-2025, focusing on firms near the new financial thresholds. If the two-of-three rule is the mechanism, bunching should *increase* post-reform (as the financial "safe harbor" widens, reducing the incentive to distort employee counts).
- Use the reform to distinguish between compliance slack and inattention. If firms were previously inattentive, the reform should have no effect; if compliance slack matters, bunching should rise.

**2. The Two-of-Three Rule Needs Direct Evidence**
The paper argues that the two-of-three rule explains the null result but provides no direct evidence. To test this:
- Use the Companies House microdata to estimate bunching on *turnover* or *balance sheet* dimensions. If the rule creates slack, firms should bunch below the financial thresholds (e.g., £10.2M turnover) even if they don’t bunch on employees.
- Test whether firms near the employee threshold (e.g., 45–55 employees) are more likely to be below the financial thresholds (e.g., turnover < £10.2M). This would show firms actively exploiting the rule.

**3. Power and Interpretation of the Null**
The paper claims the null is "definitive" but does not fully address alternative explanations:
- **Measurement error:** Employee counts in iXBRL filings may be noisy or manipulated in ways that obscure bunching. The paper should compare the microdata to administrative payroll data (e.g., HMRC PAYE records) to validate reporting accuracy.
- **Dynamic effects:** Firms may temporarily exceed thresholds and then revert, masking bunching in annual snapshots. The paper should use panel data to track firms over time (e.g., do firms with 49 employees in year *t* grow to 50 in year *t+1* and then shrink back?).
- **Heterogeneity:** The null may hide bunching among specific subgroups (e.g., high-growth firms, labor-intensive industries). The paper should test for bunching within SIC codes or firm age cohorts.

---

### 4. Suggestions

**A. Strengthen the Causal Argument**
1. **Leverage the 2025 Reform:**
   - Collect pre-2025 data (2020–2024) and post-2025 data (2025–2026) to compare bunching at the 50-employee threshold before and after the financial thresholds increased. If the two-of-three rule matters, the density ratio at 50 employees should rise post-reform (as firms face less pressure to distort employee counts).
   - Test whether the reform reduced bunching on financial dimensions (e.g., turnover just below £10.2M pre-reform vs. £15M post-reform).

2. **Exploit IR35 as a Shock:**
   - The 2021 IR35 extension to medium/large firms increased compliance costs at the 50-employee threshold. The paper shows no bunching response but should:
     - Test for bunching on *turnover* post-2021, as firms may have shifted distortion to the financial dimension to avoid IR35.
     - Compare firms just below/above 50 employees in labor-intensive industries (e.g., construction, consulting) vs. capital-intensive industries. IR35 costs are higher for the former, so bunching should be more pronounced.

**B. Test the Two-of-Three Rule Directly**
1. **Multi-Dimensional Bunching:**
   - Estimate bunching at the turnover and balance sheet thresholds (e.g., £10.2M, £5.1M) using the Companies House microdata. If the two-of-three rule creates slack, firms should bunch below these thresholds even if they don’t bunch on employees.
   - Use a triple-difference design: compare bunching on employees vs. financial dimensions for firms near the 50-employee threshold (where compliance costs are high) vs. the 10-employee threshold (where costs are low).

2. **Persistence Requirement:**
   - The two-year persistence rule means firms can exceed a threshold for one year without reclassification. The paper should:
     - Test whether firms with 50 employees in year *t* are more likely to have <50 employees in year *t+1* (reversion) than firms with 49 employees (no reversion).
     - Use the 2025 reform to test whether the persistence rule matters: firms near the new financial thresholds (e.g., £14M turnover) should be less likely to distort in year *t* if they expect to exceed the threshold in year *t+1*.

**C. Address Alternative Explanations**
1. **Measurement Error:**
   - Validate the Companies House employee counts against HMRC PAYE data (available via the DWP’s "Real Time Information" system). If the two sources disagree, the paper should use the administrative data for robustness checks.
   - Test whether bunching is more pronounced in firms with higher audit quality (e.g., those using Big 4 auditors), where reporting is likely more accurate.

2. **Dynamic Effects:**
   - Use the NOMIS panel data to track firms over time. Test whether firms with 49 employees in year *t* are more likely to:
     - Stay at 49 in year *t+1* (bunching).
     - Grow to 50 in year *t+1* and then shrink back (temporary distortion).
     - Grow to 50 and stay there (no distortion).
   - Compare these patterns to firms with 48 employees (no bunching expected).

3. **Heterogeneity:**
   - Test for bunching by industry (SIC code), firm age, or ownership structure (e.g., family firms vs. private equity-backed firms). Labor-intensive industries (e.g., hospitality) may face higher IR35 costs and thus bunch more.
   - Use the NOMIS data to test whether bunching varies by region (e.g., London vs. post-industrial areas), where regulatory enforcement or compliance costs may differ.

**D. Improve Robustness and Transparency**
1. **Data Accessibility:**
   - Provide a replication package with the parsed Companies House data and NOMIS extracts. The current paper lacks details on how the iXBRL files were processed (e.g., which XBRL tags were used, how missing data were handled).
   - Include a code appendix with the bunching estimator implementation (e.g., polynomial degree selection, bandwidth choices).

2. **Visual Evidence:**
   - Add a figure showing the raw employee count distribution around the 10-employee threshold (e.g., 1–20 employees) with the polynomial counterfactual. This would make the null result more intuitive.
   - Plot the density ratios over time (as in Table 6) with confidence intervals to show the lack of trend post-2021.

3. **Placebo Tests:**
   - Expand the placebo tests to include non-regulatory thresholds (e.g., 20, 30, 40 employees) and non-round numbers (e.g., 13, 17, 23 employees). This would rule out spurious bunching at arbitrary points.

**E. Policy Implications**
1. **Cost-Benefit of the 2025 Reform:**
   - The paper argues that the two-of-three rule already reduces distortion, so the 2025 threshold increase may be unnecessary. To test this:
     - Estimate the compliance cost savings from the reform (e.g., fewer firms subject to audit) and compare them to the potential loss of regulatory oversight (e.g., more firms exempt from Modern Slavery reporting).
     - Survey firms near the new thresholds to ask whether they changed behavior post-reform (e.g., hiring more employees, increasing turnover).

2. **Generalizability:**
   - Compare the UK’s two-of-three rule to other multi-dimensional thresholds (e.g., EU SME definitions, US Small Business Administration size standards). Does the UK’s approach reduce distortion more effectively?
   - Simulate the effect of switching to a single-dimensional threshold (e.g., employees only). How much bunching would emerge, and what would be the welfare implications?

**F. Minor Suggestions**
1. **Clarify the Power Calculation:**
   - The MDE of 0.16 at the 10-employee threshold is well below the effects in the literature, but the paper should explain how this was calculated (e.g., using the bootstrap SE and assuming a normal distribution).
   - Report power for the 50- and 250-employee thresholds, even if the sample is small.

2. **Discuss External Validity:**
   - The UK’s private company landscape is unique (e.g., high density of micro-firms, strong audit culture). The paper should discuss whether the results generalize to other countries with different firm size distributions or regulatory enforcement.

3. **Address the "Deficit" at 10 Employees:**
   - The negative bunching estimate at 10 employees (a deficit) is puzzling. The paper should explore whether this reflects:
     - A reporting artifact (e.g., firms rounding down to avoid disclosure).
     - A real economic effect (e.g., firms with 10 employees growing faster than those with 9).
     - A selection issue (e.g., firms with 10 employees being more likely to report counts).

4. **Improve Table 4 (Density Rates):**
   - The mean rate at non-regulatory boundaries is reported as 2.92, but this includes the 500–999 to 1000+ transition (rate = 7.08), which is an outlier. The paper should exclude this transition or report a trimmed mean.
   - Add confidence intervals to the density rates to test whether the differences are statistically significant.

5. **Discuss the Role of Auditors:**
   - Auditors may discourage firms from distorting employee counts (e.g., by flagging inconsistencies between payroll and reported employees). The paper should test whether bunching is more pronounced in firms without auditors (e.g., micro-entities).
