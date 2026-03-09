# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T17:10:03.930763
**Route:** Direct Google API + PDF
**Tokens:** 22557 in / 2059 out
**Response SHA256:** a05bd9ab19e883d2

---

# Exhibit-by-Exhibit Review

This assessment evaluates the visual exhibits of the paper "Cap On, Cap Off: Credit Rationing Hysteresis from Kenya’s Interest Rate Ceiling" against the standards of top-tier economics journals (AER, QJE).

---

## Main Text Exhibits

### Figure 1: "Policy Timeline: Interest Rate Cap and Repeal"
**Page:** 7
- **Formatting:** Clean and professional. The use of shaded regions for the treatment period and "COVID" is standard.
- **Clarity:** Excellent. The 10-second test is passed: it clearly shows the CBR and the +4% cap.
- **Storytelling:** Essential. It establishes the "on-off" nature of the experiment.
- **Labeling:** Axis labels are clear. Legend is intuitive.
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics by Bank Tier and Policy Period"
**Page:** 12
- **Formatting:** Good use of horizontal rules (Booktabs style). Numbers are aligned.
- **Clarity:** The grouping by Tier (1, 2, 3) and then by time period is logical.
- **Storytelling:** Crucial. It provides the "raw" look at the hysteresis before the regressions.
- **Labeling:** Units (KES bn, %) are clearly marked. Notes are comprehensive.
- **Recommendation:** **REVISE**
  - **Change:** Add a column for "N (Banks)" within each tier for each period to show the compositional change (22 to 16) mentioned in the text.

### Table 2: "Differential Impact of Interest Rate Cap by Bank Tier"
**Page:** 16
- **Formatting:** Professional. Decimal points are aligned.
- **Clarity:** Strong. The inclusion of both Cap-On and Post-Repeal coefficients makes the hysteresis test immediate.
- **Storytelling:** The core table of the paper.
- **Labeling:** The use of brackets for RI p-values is a good touch given the small cluster count.
- **Recommendation:** **REVISE**
  - **Change:** Add a row at the bottom for "Mean of Dep. Var (Pre-Cap)" for Tier 3. This helps the reader scale the coefficients (e.g., -0.04 on a base of 0.55).

### Figure 2: "Event Study: Tier 3 vs. Tier 1 Loan-to-Asset Ratio"
**Page:** 17
- **Formatting:** Journal-ready. Use of markers and shaded 95% CIs is standard.
- **Clarity:** The message is undeniable: flat pre-trend, sharp break, no reversal.
- **Storytelling:** The most important figure in the paper.
- **Labeling:** Clearly identifies the omitted period and the transition year.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Loan-to-Asset Ratio by Bank Tier, 2010–2023"
**Page:** 18
- **Formatting:** Clean. Line weights are good.
- **Clarity:** Very high. Shows the raw divergence.
- **Storytelling:** Provides the "raw data" context for Figure 2.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - **Change:** These individual raw plots (Figures 3, 4, 5) take up a lot of real estate. **Consolidate** Figures 3, 4, and 5 into a single "Figure 3: Raw Portfolio Trends" with Panels A, B, and C. This is a common AER/QJE layout.

### Figure 4: "Government Securities as Share of Total Assets by Bank Tier, 2010–2023"
**Page:** 19
- **Formatting:** Consistent with Figure 3.
- **Clarity:** High.
- **Storytelling:** Supports the substitution mechanism.
- **Recommendation:** **REVISE**
  - **Change:** Consolidate as Panel B of a combined portfolio figure.

### Figure 5: "Non-Performing Loan Ratio by Bank Tier, 2010–2023"
**Page:** 20
- **Formatting:** Consistent.
- **Clarity:** High.
- **Storytelling:** Supports the quality deterioration mechanism.
- **Recommendation:** **REVISE**
  - **Change:** Consolidate as Panel C of a combined portfolio figure.

### Table 3: "Cross-Country Difference-in-Differences: Kenya vs. East African Peers"
**Page:** 21
- **Formatting:** Standard.
- **Clarity:** Logical layout.
- **Storytelling:** Essential for external validity/macro shocks.
- **Labeling:** Significance stars correctly defined.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Domestic Credit to Private Sector (% of GDP): Kenya vs. East African Peers"
**Page:** 22
- **Formatting:** Good.
- **Clarity:** A bit cluttered with four lines.
- **Storytelling:** Supports Table 3.
- **Recommendation:** **REVISE**
  - **Change:** Use a thicker line or a different color/marker for Kenya to make it "pop" against the peers.

### Figure 7: "Cross-Country Event Study: Kenya vs. East African Peers"
**Page:** 23
- **Formatting:** Consistent with Figure 2.
- **Clarity:** Noisier than Figure 2, but expected for country-level data.
- **Storytelling:** Strong evidence that the trend is unique to Kenya.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Symmetry Test: Does Repeal Reverse Credit Rationing?"
**Page:** 24
- **Formatting:** Clean.
- **Clarity:** Excellent summary of the "reversal ratio."
- **Storytelling:** This is the "punchline" table.
- **Recommendation:** **KEEP AS-IS** (Consider moving this closer to Table 2 or merging it as a bottom panel in Table 2).

### Figure 8: "Credit Rationing Hysteresis: Tier 3 Differential Across Policy Regimes"
**Page:** 24
- **Formatting:** Bar chart style.
- **Clarity:** Good, though it repeats information from Figure 2.
- **Storytelling:** It visualizes the coefficients from the main regression.
- **Recommendation:** **MOVE TO APPENDIX**
  - **Reason:** It is largely redundant with Figure 2 (Event Study). Figure 2 is a more sophisticated way to show the same thing.

---

## Appendix Exhibits

### [Table, Unnumbered]: "Pre-treatment coefficients and their standard errors"
**Page:** 37
- **Recommendation:** **REVISE**
  - **Change:** Give this a formal label (e.g., Table A.1) and professional formatting. Currently, it looks like a text snippet.

### Table 5: "Robustness: Alternative Specifications for Loan/Asset Ratio"
**Page:** 28
- **Formatting:** Good.
- **Clarity:** High.
- **Storytelling:** Standard robustness table.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "CBK Central Bank Rate and Implied Interest Rate Cap, 2010–2023"
**Page:** 40
- **Formatting:** Good.
- **Clarity:** Very high.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Standardized Effect Sizes for Main Outcomes"
**Page:** 41
- **Formatting:** Unusual but helpful.
- **Clarity:** The "Research Question" and "Method" summaries in the notes are very helpful for transparency.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 8 main figures, 2 appendix tables, 0 appendix figures.
- **General quality:** High. The figures are modern (likely ggplot2) and the tables follow the "Less is More" philosophy of top journals.
- **Strongest exhibits:** Figure 2 (Event Study) and Table 4 (Symmetry Test).
- **Weakest exhibits:** Figure 8 (Redundant) and the unnumbered table on page 37.
- **Missing exhibits:** A **Figure on Digital Credit Growth**. The text mentions M-Shwari/Tala growth from 200k to 2M. A figure showing this "hockey stick" growth against the bank credit decline would be a "killer" visual for the welfare argument.

### Top 3 Improvements:
1.  **Consolidate raw series:** Merge Figures 3, 4, and 5 into a single multi-panel figure. This saves space and allows the reader to see the "mirroring" of loans and government securities in one glance.
2.  **Add Descriptive Data to Table 1:** Specifically, the number of banks per tier-year to address the "Compositional Change" argument mentioned in the text.
3.  **Visualizing the Alternative:** Create a figure for the "Digital Credit Substitution" (Section 7.3). Showing the explosion of 138% APR loans while bank credit (14% APR) vanished is the most compelling welfare story in the paper.