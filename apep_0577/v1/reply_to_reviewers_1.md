# Reply to Reviewers — Round 1

## Response to GPT-5.4 (R1): REJECT AND RESUBMIT

### 1. Pre-treatment convergence trends (Must-fix)
**Concern:** Employment event study shows strong monotonic pre-trends; need formal trend adjustment.

**Response:** We agree this is the central identification issue. We now report:
- A formal joint Wald test of pre-treatment coefficients (F = 2.02, p = 0.034 for employment; F = 9.99, p < 0.001 for enterprises) — confirming the pre-trends are statistically significant.
- A trend-adjusted specification controlling for C20 × micro-share × year (linear trend). This reduces the employment estimate from -0.451 to 0.038 — essentially zero (Table 4, Row 2).
- We honestly acknowledge this result and reframe the employment finding as suggestive rather than causal throughout the paper.
- We cite Roth (2022) and Rambachan & Roth (2023) and discuss our findings in their framework.

### 2. Treatment intensity endogeneity (Must-fix)
**Concern:** 2014-2017 micro-share may be contaminated by earlier REACH phases.

**Response:** We now report results using 2008-only micro-firm shares (measured before REACH's effective implementation). The employment coefficient attenuates to -0.325 and loses significance (Table 4, Row 3). The enterprise result is unchanged. This confirms the reviewer's concern that the 2014-2017 measure may partly reflect earlier REACH-induced restructuring.

### 3. Strengthen inference for employment (Must-fix)
**Concern:** RI p = 0.064 is materially weaker than cluster-robust p = 0.014.

**Response:** We now foreground the RI p-value throughout the paper and describe the discrepancy transparently. We cite MacKinnon & Webb (2017) and acknowledge that finite-sample exact inference should be the primary benchmark with 27 clusters. The combined evidence — trend adjustment nullifying the result, RI p = 0.064, and pre-REACH intensity attenuating — leads us to characterize the employment finding as suggestive rather than definitive.

### 4. Control sector validity (Must-fix)
**Concern:** C22-C25 may be indirectly affected through chemical inputs.

**Response:** We provide additional institutional discussion of why these sectors face no comparable registration requirements and report that both narrower (C22-C23) and wider (C24-C25) control groups yield consistent results. We acknowledge that indirect REACH exposure through input prices may attenuate the DDD estimate.

### 5. Mechanism claims (Must-fix)
**Concern:** "Downsizing not exit" and "supply-chain restructuring" are too strong.

**Response:** We have substantially softened all mechanism claims throughout the paper. The abstract, introduction, and conclusion now present the enterprise null as the robust finding and the employment pattern as suggestive. "REACH did not kill small firms. It shrank them." has been removed from the abstract. Mechanisms are framed as hypotheses pending firm-level data.

### 6. Common sample (High-value)
**Concern:** Enterprise/employment divergence may reflect differential sample composition.

**Response:** We now report common-sample estimates (Table 4, Row 4): enterprise = 0.129, employment = -0.446. The divergence is substantive, not compositional.

---

## Response to GPT-5.4 (R2): REJECT AND RESUBMIT

The concerns overlap substantially with R1. Key additional points addressed:

### Drop 2020 / shorter windows
We now report estimates excluding 2020 (enterprise = 0.144, employment = -0.429) and a short window 2014-2019 (enterprise = -0.052, employment = -0.211). Results are in Table 4, Rows 5-6.

### Weighting
We acknowledge that unweighted estimates give equal weight to Malta and Germany. The LOO analysis (particularly dropping Germany) shows the enterprise null is not driven by leverage.

### Business demography data
We acknowledge that enterprise counts are a weak proxy for exit and that business demography birth/death data would permit sharper tests. The BD data was downloaded but not used due to coverage limitations for the DDD design.

---

## Response to Gemini-3-Flash: MAJOR REVISION

### 1. Formally address non-parallel pre-trends (Must-fix)
**Response:** Done — see Table 4 (trend-adjusted specification) and joint F-test results. The honest conclusion is that the employment result does not survive trend adjustment.

### 2. Clarify medium-firm result (High-value)
**Response:** We now frame this as a hypothesis rather than a confirmed mechanism. We note that the 50-249 estimate is only marginally significant (p = 0.097) and that without employment-by-size data, the mechanism remains conjectural.

### 3. Trade data (Optional)
**Response:** Not addressed in this revision due to data access constraints, but noted as a valuable direction for future research.

---

## Response to Exhibit Review (Gemini)

- **Figure 1 color scheme:** Not changed in this revision (single-hue conversion would require regenerating figures).
- **Figure 4 (raw trends):** Moved to Appendix E as recommended.
- **Figure 6 (LOO) and Figure 7 (RI):** Moved to Appendix E as recommended.
- **Mean dep var in Table 2:** Noted but not added (available in Table 1, which is directly adjacent).
- **Table C4 promoted to main text:** Not promoted, but prominently referenced from the robustness section.

---

## Response to Prose Review (Gemini)

- **Deleted roadmap paragraph** (Section 1, last paragraph of introduction).
- **Sharpened Section 4.3 opening:** Rewrote threats to validity to lead with the threat rather than "Several threats warrant discussion."
- **Tightened abstract:** Removed interpretive claims, added sensitivity caveat.
- **Human stakes detail:** Left for future revision — the current reframing prioritizes honesty over advocacy.

---

## Summary of Changes

| Change | Files Modified |
|--------|---------------|
| Trend-adjusted DDD specification | 02_clean_data.R, 03_main_analysis.R |
| 2008 (pre-REACH) treatment intensity | 02_clean_data.R, 03_main_analysis.R |
| Common sample estimation | 03_main_analysis.R |
| Joint F-test of pre-trends | 03_main_analysis.R |
| Drop-2020 and short-window robustness | 04_robustness.R |
| New Table 4 (Sensitivity) | 06_tables.R, paper.tex |
| Softened causal claims throughout | paper.tex (abstract, intro, results, discussion, conclusion) |
| Added Roth (2022), Rambachan & Roth (2023), MacKinnon & Webb (2017) | references.bib, paper.tex |
| Moved Figures 4, 6, 7 to appendix | paper.tex |
| Removed roadmap paragraph | paper.tex |
| Reframed mechanisms as hypotheses | paper.tex |
