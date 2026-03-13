# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-13T20:47:24.735986
**Route:** Direct Google API + PDF
**Tokens:** 11637 in / 1665 out
**Response SHA256:** 7aed5e8e56a77ffe

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Corpus Summary Statistics"
**Page:** 4
- **Formatting:** Clean and professional. Use of horizontal rules is appropriate (booktabs style). Number alignment is good.
- **Clarity:** Excellent. The distinction between training and validation sets is immediately clear.
- **Storytelling:** Essential. It establishes the scale of the data and the temporal split which is crucial for the "from scratch" training claim.
- **Labeling:** Proper notes explaining abbreviations (HF, BPE).
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Perplexity of Congressional speech by year and chamber (1994–2024)"
**Page:** 7
- **Formatting:** High quality. Gridlines are subtle. Markers are distinct.
- **Clarity:** The message—the House is more predictable (lower) than the Senate—is clear. However, the "All" line adds clutter and competes with the chamber-specific lines.
- **Storytelling:** This is the "money plot." It visually proves the primary institutional hypothesis (H1).
- **Labeling:** Good. The note regarding 2015 being the out-of-sample boundary is vital.
- **Recommendation:** **REVISE**
  - Remove the "All" black line. It muddies the comparison between House and Senate, which is the core argument.
  - Add a vertical dashed line at the year 2015 to visually separate in-sample vs. out-of-sample results.

### Table 2: "Perplexity by Chamber, Selected Years"
**Page:** 8
- **Formatting:** Simple, but perhaps too simple.
- **Clarity:** Clear, but redundant with Figure 1.
- **Storytelling:** This table feels like a "placeholder" for the text. It doesn't add much that Figure 1 hasn't already shown visually.
- **Labeling:** Sufficient.
- **Recommendation:** **REMOVE**
  - The text already mentions the 3–8 point gap. Figure 1 covers the trends. To save space for top journals, integrate these specific numbers into Figure 1 (as a small text annotation) or just keep them in the text.

### Table 3: "Deliberation Index Summary"
**Page:** 9
- **Formatting:** Good use of grouping by category (Chamber, Party, Year).
- **Clarity:** Very high. One can immediately see that the House has a higher index than the Senate.
- **Storytelling:** This provides the nuance to the main finding: the House is more formulaic but more responsive to context. 
- **Labeling:** Clear definition of $D = H_m - H_c$.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event study: congressional speech perplexity around FEMA major disaster declarations"
**Page:** 10
- **Formatting:** Journal-standard event study plot. The 95% CI band is clear.
- **Clarity:** The "overshoot" and "recovery" are visible, though the daily mean dots are quite scattered.
- **Storytelling:** Strongest evidence of the mechanism. It proves the measure reacts to exogenous shocks.
- **Labeling:** "Perplexity deviation from pre-period mean" is a bit long for a Y-axis; consider "$\Delta$ Perplexity". 
- **Recommendation:** **REVISE**
  - Increase the line weight of the "7-day moving average" to make it stand out more against the scatter of grey dots.
  - Add a horizontal line at $y=0$ (it exists but is faint) to make the overshoot more prominent.

---

## Appendix Exhibits

### Table 4: "Model Specifications"
**Page:** 15
- **Formatting:** Clear technical table.
- **Clarity:** High. Important for reproducibility.
- **Storytelling:** Standard for papers using custom LLM architectures.
- **Labeling:** Good explanation of MPS/Metal.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Training Progression"
**Page:** 16
- **Formatting:** Standard.
- **Clarity:** Shows the "Val PPL" clearly.
- **Storytelling:** This justifies why training stopped at 12k steps (overfitting).
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Speaker identification accuracy over time"
**Page:** 17
- **Formatting:** Two-panel figure. Panel B's log scale is appropriate given the random baseline.
- **Clarity:** Good, but the legend in Panel A is slightly small.
- **Storytelling:** Proves the model "knows" who is speaking, validating the embeddings.
- **Labeling:** Excellent inclusion of "Random baseline."
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Speaker Identification Accuracy"
**Page:** 17
- **Formatting:** Clean summary.
- **Clarity:** Good comparison of Mean vs. Range.
- **Storytelling:** Provides the hard numbers for Figure 3.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Party classification accuracy: neural model (GPT) versus classical baselines"
**Page:** 18
- **Formatting:** Complex but readable.
- **Clarity:** The contrast between the SVM's structural break and the GPT's stability is the key takeaway.
- **Storytelling:** **Extremely important.** This defends the model against "just a vocabulary classifier" critiques.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This figure is too important for the Appendix. It handles the "Gentzkow et al. (2019) already did this" objection.

### Figure 5 / Table 7: "Party vs. Individual Identity" / "Party Classification Accuracy"
**Page:** 19
- **Formatting:** Redundant with Figure 4 and Table 6.
- **Storytelling:** These are essentially robustness checks of the identification task.
- **Recommendation:** **KEEP AS-IS (In Appendix)**

---

## Overall Assessment

- **Exhibit count:** 3 main tables (if Table 2 is removed), 2 main figures, 4 appendix tables, 3 appendix figures.
- **General quality:** Extremely high. The exhibits are generated with a consistent aesthetic (Matplotlib/Seaborn style) that feels modern and precise. 
- **Strongest exhibits:** Figure 1 (Core Trend) and Figure 2 (Event Study).
- **Weakest exhibits:** Table 2 (Redundant) and Figure 5 (Niche).
- **Missing exhibits:** A **"Representative Text" Exhibit**. For a top journal (AER/QJE), the reader needs to see the "Perplexity" in action. A table showing 2-3 examples of high-perplexity turns vs. low-perplexity turns (with the model's top predicted next words) would make the abstract concept concrete.

- **Top 3 improvements:**
  1. **Consolidate and Promote:** Move Figure 4 (Neural vs. Classical) to the main text. It is a critical defense of the paper's methodology.
  2. **Visual Differentiation:** In Figure 1, remove the "All" line and add a vertical line at 2015 to distinguish the holdout set.
  3. **Add Qualitative Evidence:** Create a "Table 4" (Main Text) showing raw text snippets from the Congressional Record with their calculated perplexity scores to provide intuition for the metric.