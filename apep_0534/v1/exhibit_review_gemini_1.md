# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T03:41:45.284146
**Route:** Direct Google API + PDF
**Tokens:** 19437 in / 1847 out
**Response SHA256:** f7fcf7ec008a7705

---

This review evaluates the visual exhibits of the paper "The Patent System and Green Innovation" against the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Y02 Green Patent Applications, 2001–2018"
**Page:** 10
- **Formatting:** Clean and professional. Uses standard booktabs style.
- **Clarity:** Excellent. Variables are clearly named. The use of P25, Median, and P75 is helpful for skewed patent data.
- **Storytelling:** Provides a clear scale of the data. The "Mean" of ~26,600 for follow-on patents immediately tells the reader these are subclass aggregates, not individual counts.
- **Labeling:** Good. "Examiner Grant Share (LOO)" is properly defined in the notes.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Balance Test: Application Characteristics on Examiner Grant Share"
**Page:** 15
- **Formatting:** Standard regression format. Decimal alignment is good.
- **Clarity:** The horizontal layout is slightly sparse with only two columns. 
- **Storytelling:** Essential for the IV design. It shows that while statistically significant (due to large N), the magnitudes are tiny.
- **Labeling:** Explicitly mentions "Under random assignment, coefficients should be zero."
- **Recommendation:** **REVISE**
  - Merge this with Figure 6 (Balance Test Detail) or add more balance variables (e.g., filing year, primary CPC) to make the table more substantial.

### Table 3: "Effect of Examiner Grant Share on Follow-on Green Innovation"
**Page:** 16
- **Formatting:** Good. Standard `fixest` output style.
- **Clarity:** Clear distinction between 3-year and 5-year outcomes.
- **Storytelling:** This is the "Money Table." It clearly shows the null result across specifications.
- **Labeling:** Significance codes are standard. Clustered errors are noted.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Effect of Examiner Grant Share on Follow-on Green Innovation"
**Page:** 17
- **Formatting:** Clean, but the "Effect of Examiner Leniency" title inside the plot area is redundant with the caption.
- **Clarity:** Very high. Coefficient plots are preferred over tables for null results.
- **Storytelling:** Visualizes the precisely estimated zero.
- **Labeling:** Y-axis labels are clear. X-axis specifies units.
- **Recommendation:** **REVISE**
  - Remove the internal plot title.
  - Increase the font size of the axis labels for better readability in print.

### Table 4: "Heterogeneity by Y02 Technology Domain"
**Page:** 18
- **Formatting:** Seven columns make the font slightly small.
- **Clarity:** Logical grouping.
- **Storytelling:** Shows the null is not driven by one specific "dirty" or "clean" sector.
- **Labeling:** Good notes on why N does not sum to the total.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 2 conveys this information much more effectively. The table is redundant for the main text.

### Figure 2: "Heterogeneity by Y02 Technology Domain"
**Page:** 18
- **Formatting:** Professional. Good use of horizontal bars.
- **Clarity:** Excellent. Can see at a glance that all CIs cross zero.
- **Storytelling:** Stronger than Table 4.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Promote as the primary heterogeneity exhibit).

### Figure 3: "Follow-on Innovation by Examiner Grant Share Quintile"
**Page:** 19
- **Formatting:** The y-axis does not start at zero, which exaggerates the "flatness" or "noise." 
- **Clarity:** The line plot implies a trend where a bin-scatter or bar chart might be more appropriate for quintiles.
- **Storytelling:** Intended to show monotonicity/non-linearity. 
- **Labeling:** "Examiner Leniency" is used in the plot, but "Grant Share" is used in the text. Be consistent.
- **Recommendation:** **REVISE**
  - Change to a **Bin-scatter plot** (e.g., 20 or 50 bins) with a linear fit line. This is the standard "First Stage/Reduced Form" visualization in modern IV papers.

### Figure 4: "Effect of Examiner Grant Share Over Time"
**Page:** 21
- **Formatting:** The shaded confidence ribbon is professional.
- **Clarity:** The jump in the final period is the main visual takeaway.
- **Storytelling:** Crucial for the discussion on right-censoring.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 5: "Distribution of Leave-One-Out Examiner Grant Share"
**Page:** 32
- **Formatting:** Standard histogram.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Balance Test: Application Characteristics on Examiner Grant Share"
**Page:** 33
- **Storytelling:** Redundant with Table 2.
- **Recommendation:** **REMOVE** (The table is more precise for balance tests).

### Figure 7: "Y02 Green Patent Filing Trends, 2001–2018"
**Page:** 33
- **Clarity:** Panel B (stacked area) is very effective.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This should be "Figure 1" in the main text to establish the context of the "Green Patent Boom."

### Table 6: "Additional Reduced-Form Specifications"
**Page:** 34
- **Storytelling:** Shows the citation effect (the only positive result).
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - The divergence between citations (positive) and patenting (null) is a key part of the paper's "story." This should not be hidden in the appendix.

### Table 7: "Patent Scope IV"
**Page:** 34
- **Formatting:** Clear 1st and 2nd stage.
- **Recommendation:** **KEEP AS-IS** (Appendix is appropriate).

### Table 8: "Heterogeneity by Assignee Type"
**Page:** 35
- **Recommendation:** **KEEP AS-IS** (Appendix is appropriate).

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 4 Main Figures; 3 Appendix Tables, 3 Appendix Figures.
- **General quality:** High. The paper uses modern "Coefficient Plot" styles which are very popular in the AEA journals. The tables follow standard "Chicago/AER" style formatting.
- **Strongest exhibits:** Figure 2 (Heterogeneity) and Table 3 (Main Null).
- **Weakest exhibits:** Figure 3 (Line plot for quintiles) and Table 2 (Sparse balance table).

### Missing Exhibits:
1. **A First-Stage Illustration:** Even though this is a reduced-form paper, a figure showing that "Examiner Grant Share" actually predicts an individual application's grant probability (perhaps using a small sample of data where denials are known, or citing the literature more visually) would strengthen the "Relevance" claim.
2. **Subclass Map/Example:** A small table or "cloud" showing the most common CPC subclasses in the Y02 category to help non-patent experts understand what a "subclass" represents.

### Top 3 Improvements:
1. **Restructure the Narrative Flow:** Move the Citation results (Table 6) and the Trend results (Figure 7) to the main text. They are central to the "Storytelling" aspect.
2. **Convert Figure 3 to a Bin-scatter:** Replace the quintile line plot with a proper bin-scatter of the outcome on the instrument. This is the "Econometrica/QJE" standard for visualizing IV relationships.
3. **Consolidate Heterogeneity:** Use Figure 2 as the main text exhibit for technology domains and move Table 4 to the appendix to reduce clutter in the results section.