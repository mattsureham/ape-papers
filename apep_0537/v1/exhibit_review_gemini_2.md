# Exhibit Review — Gemini 3 Flash (Round 2)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T13:15:09.709317
**Route:** Direct Google API + PDF
**Tokens:** 20997 in / 1638 out
**Response SHA256:** 2024b6f2c52971da

---

This review evaluates the visual exhibits of the paper "Is Generative AI Seniority-Biased?" based on the standards of top-tier economics journals (AER, QJE, Econometrica).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 10
- **Formatting:** Generally clean. Use of horizontal rules is appropriate (Booktabs style).
- **Clarity:** Excellent. The two-panel structure (National Shares vs. Industry Exposure) is logical.
- **Storytelling:** Essential. It establishes the base rates (entry-level is ~50% of the market).
- **Labeling:** Good. Standard deviations and N are clearly marked.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Employment Shares by Seniority Tier, 2015–2024"
**Page:** 11
- **Formatting:** Modern and clean. However, the use of "Entry-Level" vs "Senior" (red/green) might be difficult for colorblind readers if the lines crossed more frequently.
- **Clarity:** High. The 10-second takeaway (the gap is closing) is immediate.
- **Storytelling:** Vital for descriptive motivation.
- **Labeling:** Good axis labels. The vertical dashed line for ChatGPT release is helpful context.
- **Recommendation:** **REVISE**
  - Add markers (shapes) to the lines (e.g., circles for Entry, triangles for Senior) to ensure accessibility.
  - Remove the internal title ("Entry-Level Employment Share...") as this info should stay in the caption.

### Table 2: "Effect of AI Exposure on Entry-Level Employment Share"
**Page:** 15
- **Formatting:** Professional. Standard errors are correctly in parentheses.
- **Clarity:** Logical progression from continuous to binary treatment.
- **Storytelling:** This is the "money table" for the first half of the paper.
- **Labeling:** Clear. Significance stars are well-defined in the notes.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Additional Regression Results: Senior Share, QCEW, and Heterogeneity"
**Page:** 16
- **Formatting:** A bit crowded. Column 4 uses a different specification (level of observation) than Columns 1-2.
- **Clarity:** Mixing different outcomes (Senior share vs. QCEW total emp vs. Occ Emp) makes the "Notes" section dense and hard to parse.
- **Storytelling:** Column 4 (Heterogeneity) is actually the strongest result in the paper according to the text. It feels buried here.
- **Recommendation:** **REVISE**
  - **Split this table.** Move the QCEW (Column 3) to the Appendix or its own small table. 
  - Promote Column 4 to its own table to highlight the "Task Channel" mechanism, which is more theoretically interesting than simple share regressions.

### Table 4: "Triple-Difference: AI Exposure × Seniority × Post"
**Page:** 17
- **Formatting:** Standard.
- **Clarity:** The coefficients are all insignificant for the main interaction. 
- **Storytelling:** This table shows a "null" result that the author explains away as a power issue. 
- **Recommendation:** **MOVE TO APPENDIX**
  - Since the main findings are in Table 2 and Table 3 (Col 4), this null triple-diff distracts from the main narrative in the text.

### Figure 2: "Event Study: Entry-Level Share × AI Exposure"
**Page:** 19
- **Formatting:** High quality. Confidence intervals are clear.
- **Clarity:** The pre-trend is "painfully" clear, which is honest and scientifically rigorous.
- **Storytelling:** This is the most important figure in the paper as it refutes a simple "ChatGPT caused this" causal story.
- **Labeling:** Reference year (2022) is correctly omitted/marked.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Entry-Level Employment Share by AI Exposure Tercile"
**Page:** 21
- **Formatting:** Clean.
- **Clarity:** Good. Shows the levels rather than just the coefficients.
- **Storytelling:** Complements Figure 2.
- **Recommendation:** **REVISE**
  - Combine with Figure 5 (Senior Share) into a single two-panel figure (Panel A: Entry-Level, Panel B: Senior). This would allow the reader to see the "mirror image" effect immediately.

### Table 5: "Robustness Checks"
**Page:** 22
- **Formatting:** This is a "Summary Table" of other regressions. This is becoming more common but can look "unacademic" if not handled well.
- **Clarity:** Very high.
- **Storytelling:** Excellent way to show stability across 7 different specs without 7 pages of tables.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 4: "Generative AI Mentions in SEC 10-K Filings"
**Page:** 34
- **Formatting:** Bar chart style is consistent.
- **Clarity:** Very clear.
- **Storytelling:** Justifies the "Post" period timing.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Event Study Coefficients: Entry-Level Share × AIOE"
**Page:** 35
- **Formatting:** Standard.
- **Clarity:** Good for readers who want the exact numbers from Figure 2.
- **Storytelling:** Purely supportive.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Senior Employment Share by AI Exposure Tercile"
**Page:** 38
- **Formatting:** Consistent with Figure 3.
- **Recommendation:** **REVISE**
  - **Promote to Main Text** as Panel B of a combined Figure 3/5.

---

## Overall Assessment

- **Exhibit count:** 5 Main Tables, 3 Main Figures, 1 Appendix Table, 2 Appendix Figures.
- **General quality:** Extremely high. The paper follows the modern "Visual First" trend where the story is told through the exhibits. Tables use proper LaTeX booktabs formatting and notes are comprehensive.
- **Strongest exhibits:** Figure 2 (Event Study) and Table 5 (Robustness Summary).
- **Weakest exhibits:** Table 3 (Too many different concepts in one table) and Table 4 (A null result that takes up too much space).
- **Missing exhibits:** A map of AI exposure by US State or a Bar Chart of the "Most Exposed" vs "Least Exposed" industries would add helpful descriptive flavor.

**Top 3 Improvements:**
1.  **Consolidate Levels Figures:** Merge Figure 3 and Figure 5 into a single two-panel figure (Entry vs. Senior shares) in the main text.
2.  **Highlight the Mechanism:** Break Table 3's Column 4 (Heterogeneity) into its own dedicated table. This is your strongest evidence that the effect is driven by AI-exposed *tasks* rather than just industry-wide shocks.
3.  **Streamline Main Text:** Move Table 4 (Triple-Diff null) to the appendix. It clutters the results section with non-results that require significant "excusing" in the text.