# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-13T15:10:59.773361
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 1580 out
**Response SHA256:** efcc9058ea4a6aac

---

# Exhibit-by-Exhibit Review

This review evaluates the exhibits in "Perplexity in Congress: Habermas Meets Shannon" against the standards of top-tier economics journals (AER, QJE).

---

## Main Text Exhibits

### Table 1: "Corpus Summary Statistics"
**Page:** 7
- **Formatting:** Generally professional. Uses horizontal rules appropriately.
- **Clarity:** Clear distinction between training and validation sets. The "Validation set by chamber" sub-section is a good use of nested headers.
- **Storytelling:** Essential for establishing the data's credibility and the 2011 "break" in data sources.
- **Labeling:** Note is comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Model Specifications"
**Page:** 12
- **Formatting:** Clean layout. Technical parameters are well-organized.
- **Clarity:** High. Separating architecture, training, and hardware is logical.
- **Storytelling:** Important for the "accessibility" argument of the paper (training on a laptop).
- **Labeling:** Good. "MPS" and "BPE" are defined in notes or text.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Perplexity of Congressional speech by year and chamber (1994–2024)"
**Page:** 14
- **Formatting:** Use of different markers (circle, square, triangle) and line styles is excellent for accessibility/black-and-white printing.
- **Clarity:** The message—the persistent House-Senate gap—is immediately obvious.
- **Storytelling:** This is the "hook" figure of the paper.
- **Labeling:** Y-axis needs more detail. "Perplexity" is correct, but the note should explicitly mention that lower is more predictable (which it does). 
- **Recommendation:** **REVISE**
  - Add a vertical dashed line at the 2015 mark to visually separate "In-Sample" from "Out-of-Sample" (Holdout) data, as this is a major methodological claim.

### Table 3: "Perplexity by Chamber, Selected Years"
**Page:** 15
- **Formatting:** Standard professional table.
- **Clarity:** Very high.
- **Storytelling:** This table is largely redundant with Figure 1. In top journals, we prefer the visualization unless the exact point estimates are critical for a subsequent calculation.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - The figure tells the story; the table clutters the main text flow.

### Table 4: "Deliberation Index Summary"
**Page:** 16
- **Formatting:** Good use of grouping (By chamber, By party, By year).
- **Clarity:** "Mean D" is the hero metric. 
- **Storytelling:** Essential. It proves the "Deliberation Index" is positive (context matters).
- **Labeling:** The note explaining $D = H_m - H_c$ is vital.
- **Recommendation:** **REVISE**
  - Add a column for p-values or stars testing whether $D > 0$. While the mean is +2.52, showing statistical significance is standard for econ journals.

### Figure 2: "Speaker identification accuracy over time (1994–2024)"
**Page:** 18
- **Formatting:** Dual panels (A and B) are standard.
- **Clarity:** Panel B is a bit busy with four lines.
- **Storytelling:** Validates that the model actually "knows" who is speaking, lending credence to the marginal perplexity ($H_m$) calculation.
- **Labeling:** Legend in Panel B is readable.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Speaker Identification Accuracy"
**Page:** 19
- **Formatting:** Clean.
- **Clarity:** Excellent comparison to "Chance Baseline."
- **Storytelling:** Summary of Figure 2.
- **Labeling:** "R vs. D" should be fully spelled out as "Republican vs. Democrat" in the notes.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Party classification accuracy: neural model (GPT) versus classical baselines..."
**Page:** 20
- **Formatting:** Good use of contrasting colors/markers.
- **Clarity:** Clear message about the 2011 structural break in the SVM baseline.
- **Storytelling:** Crucial "Neural vs. Classical" comparison that justifies why we need LLMs instead of just bag-of-words.
- **Labeling:** Title is descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Party vs. Individual Identity in Congressional Speech"
**Page:** 21
- **Formatting:** The "shading" of the gap is very effective.
- **Clarity:** High.
- **Storytelling:** A bit "extra" for the main text. It reinforces the "party uniformity" point but isn't central to the Habermas/Shannon thesis.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

---

## Appendix Exhibits

### Table 6: "Training Progression (depth=6, 40.6M parameters)"
**Page:** 33
- **Formatting:** Professional.
- **Clarity:** Standard loss curve data.
- **Storytelling:** Good for technical reproducibility.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Party Classification Accuracy: All Methods"
**Page:** 34
- **Formatting:** Clean.
- **Clarity:** Good summary of the horse race.
- **Storytelling:** Supports Section 6.4.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 3 main tables (recommended), 2 main figures (recommended), 4 appendix tables, 2 appendix figures.
- **General quality:** High. The paper uses modern "clean" formatting. Figures are well-designed for both screen and print.
- **Strongest exhibits:** Figure 1 (Gap visualization) and Table 4 (Deliberation Index).
- **Weakest exhibits:** Table 3 (Redundant) and Figure 4 (Niche finding).
- **Missing exhibits:** 
    - **A "Turn Example" Table:** A table showing a specific turn of debate with high $D$ vs. low $D$ (actual text) would make the abstract math "real" for the reader.
- **Top 3 improvements:**
  1. **Consolidate and Trim:** Move Table 3 and Figure 4 to the Appendix. Main text exhibits should focus exclusively on the House/Senate gap and the Deliberation Index.
  2. **Statistical Rigor:** Add p-values/t-stats to Table 4 to prove the Deliberation Index is significantly different from zero.
  3. **Visual Cues:** Add a vertical line at 2015 in all time-series figures to distinguish the training period from the holdout (measurement) period.