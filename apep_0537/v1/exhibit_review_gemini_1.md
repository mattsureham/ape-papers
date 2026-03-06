# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T12:42:35.670648
**Route:** Direct Google API + PDF
**Tokens:** 18397 in / 1652 out
**Response SHA256:** c306a974bcc251c4

---

This review evaluates the exhibits for "Is Generative AI Seniority-Biased?" following the standards of top-tier economics journals (AER, QJE).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 9
- **Formatting:** Generally professional. Uses horizontal rules appropriately (Booktabs style). Numbers are readable.
- **Clarity:** Clear, though Panel A and Panel B have different "N" values (10 years vs. 25 industries), which is standard but should be flagged in the notes for clarity.
- **Storytelling:** Good foundation. It establishes the scale of the seniority tiers.
- **Labeling:** Good. Uses clear descriptions.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Employment Shares by Seniority Tier, 2015–2024"
**Page:** 10
- **Formatting:** High quality. Clean background, no gridlines, distinct colors.
- **Clarity:** Very high. The "ChatGPT Release" vertical line is well-placed.
- **Storytelling:** Central to the paper. Shows the aggregate "seniority-bias" trend. 
- **Labeling:** Clear axis labels. The secondary title inside the plot area is slightly redundant with the figure caption.
- **Recommendation:** **REVISE**
  - Remove the internal title ("Entry-Level Employment Share Declining...") as the figure caption handles this. In AER/QJE, titles are usually in the caption, not the plot area.

### Table 2: "Effect of AI Exposure on Entry-Level Employment Share"
**Page:** 13
- **Formatting:** Standard three-line table. Professional.
- **Clarity:** Good. Columns are logically ordered (Continuous $\rightarrow$ Binary $\rightarrow$ Log).
- **Storytelling:** This is the "money" table. It presents the core DiD results.
- **Labeling:** Defines significance stars and clustering.
- **Recommendation:** **REVISE**
  - Add the "Mean of Dep. Var." in the bottom rows. This helps readers interpret the magnitude of the -0.0132 coefficient relative to the baseline share.
  - In column (2), the coefficient for `High AIOE x Post` is missing its t-stat or p-value if the author wants to be consistent with the text's mention of $t = -2.11$.

### Table 3: "Triple-Difference: AI Exposure x Seniority x Post"
**Page:** 14
- **Formatting:** Clean and professional.
- **Clarity:** Slightly cluttered due to the long variable names.
- **Storytelling:** Crucial for the mechanism. It shows that the industry-level shock is ubiquitous across seniority levels within industries.
- **Labeling:** Clear notes.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event Study: Entry-Level Share x AI Exposure"
**Page:** 15
- **Formatting:** Professional. Shaded CIs are standard.
- **Clarity:** The message is clear: there is a significant pre-trend.
- **Storytelling:** This is the most honest exhibit in the paper, as it undermines the causal claim. It is essential for a top-tier journal.
- **Labeling:** Y-axis label is descriptive.
- **Recommendation:** **REVISE**
  - Remove the internal plot title.
  - The 2022 point (reference year) should be a solid dot at zero with no CI. It is currently correctly placed but visually distinct from the other dots might help.

### Figure 3: "Entry-Level Employment Share by AI Exposure Tercile"
**Page:** 16
- **Formatting:** Clean. Consistent with Figure 1.
- **Clarity:** Shows the "dose-response" clearly.
- **Storytelling:** Supports the DiD by showing the levels.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Robustness Checks"
**Page:** 17
- **Formatting:** This is a "summary of results" table rather than a full regression table. While efficient, top journals often prefer the full coefficients/SEs for a few key robustness checks.
- **Clarity:** High.
- **Storytelling:** Consolidates many tests.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - This table is a bit "bare bones" for the main text of an AER/QJE paper. I would move this to the appendix and replace it with a more detailed table for the two most important robustness checks (e.g., excluding Tech/Prof Services).

---

## Appendix Exhibits

### Figure 4: "Generative AI Mentions in SEC 10-K Filings"
**Page:** 30
- **Formatting:** Simple bar chart.
- **Clarity:** High.
- **Storytelling:** Validates the "Post" period (2023+).
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Event Study Coefficients: Entry-Level Share x AI Exposure"
**Page:** 31
- **Formatting:** Standard.
- **Clarity:** Redundant with Figure 2.
- **Storytelling:** Provides the exact numbers for the figure.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (Standard for appendices).

### Figure 5: "Senior Employment Share by AI Exposure Tercile"
**Page:** 33
- **Formatting:** Consistent with Figure 3.
- **Clarity:** High.
- **Storytelling:** The "mirror image" of the main result.
- **Labeling:** Good.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - If space permits, this should be Panel B of Figure 3. Showing both the decline in entry-level and the rise in senior share together makes a much more powerful visual argument for "seniority-biased" change.

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 3 main figures, 2 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. The visuals are cleaner than many first-round submissions to top journals. The use of color and whitespace is professional and modern.
- **Strongest exhibits:** Figure 2 (Event Study) and Figure 1 (Raw Trends).
- **Weakest exhibits:** Table 4 (too summarized for main text).
- **Missing exhibits:** A table showing the **top 10 and bottom 10 industries by AI Exposure** would be very helpful for the reader to understand what "High AI" actually means in the data.

### Top 3 Improvements:
1.  **Merge Figures 3 and 5:** Create a single "Figure 3: Employment Share Trends by AI Exposure" with Panel A (Entry-Level) and Panel B (Senior). This tells the "reallocation" story in one glance.
2.  **Clean up Figure internal titles:** Remove the bolded text inside the plot areas (Figures 1, 2, 3, 4, 5). Top journals strictly prefer all descriptive text to be in the caption below the figure.
3.  **Add a "Data Preview" table:** Add a table (either in text or appendix) listing the 2-digit NAICS industries and their calculated AIOE scores. This grounds the abstract index in real-world sectors.