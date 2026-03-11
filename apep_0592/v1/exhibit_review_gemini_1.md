# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T12:43:24.332023
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 1986 out
**Response SHA256:** 382ad24b21c84734

---

# Exhibit-by-Exhibit Review

This assessment evaluates the visual exhibits of the paper "When the Saloons Closed: Labor Market Spillovers from State Prohibition, 1910–1930" against the standards of top-tier economics journals (AER, QJE, etc.).

---

## Main Text Exhibits

### Table 1: "Summary Statistics by Treatment Group"
**Page:** 11
- **Formatting:** Professional and clean. Uses booktabs-style horizontal lines. Decimal alignment is generally good, though the "N" row should be right-aligned or comma-separated clearly.
- **Clarity:** Excellent. Provides a clear comparison of baseline characteristics.
- **Storytelling:** Essential. It immediately highlights the "urban-rural divide" mentioned in the text, justifying the need for the interaction design and controls.
- **Labeling:** Clear. Note is missing, but the units (%) are in the stubs.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Main Results: Effect of Prohibition Exposure on $\Delta$OCCSCORE"
**Page:** 15
- **Formatting:** Good use of parentheses for SEs. The row for "region fixed effects" uses checkmarks, which is standard, but the font size for column headers (1)-(5) is repetitive.
- **Clarity:** The table is dense. The transition from Column 2 to 3 (adding 1910 OCCSCORE) is the "money shot" of the paper but is buried in the middle.
- **Storytelling:** Logical progression. However, Column 4 (State FE) estimates a different parameter—it should perhaps be noted more prominently that this is a within-state check.
- **Labeling:** Comprehensive table notes. Significance stars defined.
- **Recommendation:** **REVISE**
  - Group Columns 1-3 as "Main Specification" and Columns 4-5 as "Robustness/Alternative."
  - Ensure the "1910 OCCSCORE Control" row is more prominent, as it flips the sign of the result.

### Table 3: "Mechanism Tests by Pre-Prohibition Industry and Outcome"
**Page:** 16
- **Formatting:** A bit cramped. 
- **Clarity:** This table mixes different dependent variables ($\Delta$OCCSCORE in Cols 1-3 and indicators in 4-6) without clear headers.
- **Storytelling:** Tries to do too much. The industry heterogeneity (Cols 1-3) is a distinct story from the extensive margin outcomes (Cols 4-6).
- **Labeling:** The note is helpful, but the column headers need units (e.g., "$\Delta$OCCSCORE" vs "Prob.").
- **Recommendation:** **REVISE**
  - **Split** into two tables. Table 3A: Industry Heterogeneity (currently Fig 6). Table 3B: Other Outcomes (Self-Employment, Mobility, Switching).
  - Use Panel A and Panel B if you want to keep them together, but clearly label the change in dependent variable.

### Table 4: "Heterogeneity by Race, Nativity, and Initial Occupation"
**Page:** 18
- **Formatting:** Standard.
- **Clarity:** Clean. The comparison between Immigrant and Native-born is the highlight here.
- **Storytelling:** Strong. Supports the "saloon as social infrastructure" hypothesis.
- **Labeling:** Clear. 
- **Recommendation:** **KEEP AS-IS** (Consider moving to a figure, see Figure 7).

### Table 5: "Women's Employment and Long-Run Effects"
**Page:** 19
- **Formatting:** Column headers are slightly inconsistent.
- **Clarity:** Very confusing. It combines two completely different samples: Women (1910-1920) and Men (1920-1930).
- **Storytelling:** These are two different "extensions" of the paper. Putting them in one table feels like a "leftovers" table. The Long-Run result is a major contribution of the paper; burying it here weakens it.
- **Labeling:** "LR" abbreviation should be spelled out in the note (Long-Run).
- **Recommendation:** **REVISE**
  - **Promote** the Long-Run results (Cols 3-4) to their own dedicated Table (Table 6).
  - **Move** the Women's results (Cols 1-2) to the Appendix or a small separate table. The effect is null/suggestive; it shouldn't crowd out the significant long-run reversal.

---

## Appendix Exhibits

### Table 6: "Earlier-Period Comparison: 1900–1910"
**Page:** 32
- **Formatting:** Matches main text.
- **Clarity:** Very high.
- **Storytelling:** This is the "Pre-trend" check. Given it's a "bad" result (significant pre-trend), it's correctly placed in the appendix but discussed candidly.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Summary of Robustness Checks"
**Page:** 34
- **Formatting:** Excellent summary format. 
- **Clarity:** Allows a reader to see the "coefficient stability" at a glance.
- **Recommendation:** **KEEP AS-IS** (This is a "best practice" table).

### Figure 1: "Leave-One-Out Sensitivity..." & Figure 2: "Randomization Inference..."
**Page:** 35
- **Formatting:** Clean, standard.
- **Storytelling:** Essential for showing the result isn't driven by one state (NY/PA).
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Timeline of State Prohibition Adoption, 1880–1920"
**Page:** 36
- **Formatting:** Dot plot is much better than a list.
- **Clarity:** High. 
- **Recommendation:** **PROMOTE TO MAIN TEXT**. This is crucial for understanding the staggered DiD design. Place it in Section 2.

### Figure 4: "Mean $\Delta$OCCSCORE by Alcohol Share Decile..."
**Page:** 37
- **Formatting:** Legends are clear.
- **Clarity:** Excellent visual evidence of the "upgrading" effect.
- **Recommendation:** **PROMOTE TO MAIN TEXT**. This is the most intuitive visualization of the "interaction" identification strategy.

### Figure 5: "Pre-Trend vs. Post-Treatment Coefficient Comparison"
**Page:** 37
- **Formatting:** Clean.
- **Recommendation:** **KEEP AS-IS** (Appendix)

### Figure 6: "Treatment Effects by Pre-Prohibition Industry"
**Page:** 38
- **Formatting:** Coefficient plot is excellent.
- **Recommendation:** **PROMOTE TO MAIN TEXT**. Replaces Table 3, Columns 1-3.

### Figure 7: "Treatment Effects by Race and Nativity"
**Page:** 38
- **Formatting:** Good.
- **Recommendation:** **PROMOTE TO MAIN TEXT**. Replaces Table 4.

### Figure 8: "Distribution of County-Level Alcohol Industry Employment Shares"
**Page:** 39
- **Formatting:** Standard histogram.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 0 main figures, 2 appendix tables, 8 appendix figures.
- **General quality:** The tables are standard and professional. The figures are actually **stronger** than the tables for storytelling but are currently buried in the appendix.
- **Strongest exhibits:** Table 7 (Robustness Summary), Figure 4 (Decile Plot).
- **Weakest exhibits:** Table 5 (Confusing mix of Women/Long-run), Table 3 (Cluttered outcomes).
- **Missing exhibits:** A **Map** showing treatment intensity (county alcohol shares) across the US. This is standard for any spatial/historical paper in the AER/QJE.

### Top 3 Improvements:

1.  **Bring the Figures to the Main Text:** The paper currently has zero figures in the main text. Top journals prefer "Visual DiD." Promote Figures 3, 4, 6, and 7 to the main text. They tell the story of the staggered timing, the raw data, industry heterogeneity, and nativity much better than the tables.
2.  **Unbundle Table 5:** The "Long-Run Reversal" is a core part of the paper's contribution (the "reversal of social capital"). It needs its own Table 6 in the main text, perhaps paired with an event-study style figure if the data allows. Move the "Women's Employment" suggestive results to the appendix.
3.  **Add a Treatment Map:** Add a Figure 0 (or 1) showing a map of the US with counties shaded by 1910 alcohol employment. This establishes the "Geography of the Saloon" immediately for the reader.