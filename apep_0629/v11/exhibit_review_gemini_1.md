# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-14T09:58:36.042906
**Route:** Direct Google API + PDF
**Tokens:** 12157 in / 1847 out
**Response SHA256:** fa04ac6bfde048b9

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Corpus Summary Statistics"
**Page:** 4
- **Formatting:** Clean and professional. Good use of horizontal rules (booktabs style).
- **Clarity:** Excellent. It clearly distinguishes between the training and analysis sets, which is crucial for this paper's ML design.
- **Storytelling:** Strong. It justifies the temporal split and explains the imbalance in conversation counts between chambers.
- **Labeling:** Clear. Notes define the acronyms (HF, GovInfo, BPE).
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Perplexity of Congressional speech by year and chamber"
**Page:** 7
- **Formatting:** Standard academic plot. The gridlines are a bit heavy; consider light gray or dotted lines to make the data series pop. 
- **Clarity:** High. The distinction between "House" and "Senate" is immediately visible. The "All" line provides a helpful baseline.
- **Storytelling:** This is the "hook" of the paper. It shows the persistent predictability gap and the 2020 spike.
- **Labeling:** Descriptive title. Axis labels are clear.
- **Recommendation:** **REVISE**
  - Add a vertical dashed line at 2014/2015 to visually separate the "in-sample" training period from the "out-of-sample" evaluation period mentioned in the caption.

### Table 2: "Perplexity by Chamber, Selected Years"
**Page:** 8
- **Formatting:** Professional. Decimal-aligned columns.
- **Clarity:** Good, but it essentially replicates the data from Figure 1 in tabular form for specific years.
- **Storytelling:** It provides the exact point estimates for the "3–8 point gap" mentioned in the abstract. 
- **Labeling:** "PPL" is defined in the notes.
- **Recommendation:** **MOVE TO APPENDIX**
  - The figure tells the story better for the main text. Keep the point estimates in the appendix for reference, or integrate the most important gap (e.g., the 2024 gap) as an annotation directly on Figure 1.

### Table 3: "Deliberation Index Summary"
**Page:** 9
- **Formatting:** Good use of grouping (By chamber, By party, By year).
- **Clarity:** The "N turns" column is vital here given the sampling explanation in the notes.
- **Storytelling:** This table introduces the "paradox"—the House has higher predictability (Fig 1) but also a higher Deliberation Index (Table 3).
- **Labeling:** Definition of $D$ in the notes is excellent.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event study: congressional speech perplexity around FEMA major disaster declarations"
**Page:** 10
- **Formatting:** High quality. The shaded "first week" region helps guide the eye.
- **Clarity:** Busy but readable. The 7-day moving average is necessary to see the trend through the daily noise (grey dots).
- **Storytelling:** Effectively shows the "disruption and overshoot" pattern.
- **Labeling:** $N=635$ is clearly noted. Y-axis label "Perplexity deviation from pre-period mean" is precise.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 4: "Model Specifications"
**Page:** 16
- **Formatting:** Clear "Parameter/Value" layout.
- **Clarity:** Essential for reproducibility in an Econometrica or AEJ-type paper.
- **Storytelling:** Documents the "from scratch" nature of the model.
- **Labeling:** Notes define technical terms like MPS.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Training Progression (depth=6, 40.6M parameters)"
**Page:** 17
- **Formatting:** Minimalist and clean.
- **Clarity:** Shows the convergence and the logic for the early stopping at step 11,000.
- **Storytelling:** Purely diagnostic.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Speaker identification accuracy over time (1994–2024)"
**Page:** 18
- **Formatting:** Two-panel layout. Panel B uses a log scale, which is appropriate given the 0.06% baseline.
- **Clarity:** Good. Legends are clear.
- **Storytelling:** Validates that the model learns "fingerprints," even if it doesn't predict party better than a coin flip.
- **Labeling:** Panel labels (A, B) are clear.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Speaker Identification Accuracy"
**Page:** 18
- **Formatting:** Professional.
- **Clarity:** Summarizes Figure 3 with exact means.
- **Storytelling:** Provides the "80 times random baseline" evidence mentioned in the intro.
- **Recommendation:** **KEEP AS-IS** (Wait, see Overall Assessment regarding merging).

### Figure 4: "Party classification accuracy: neural model (GPT) versus classical baselines..."
**Page:** 19
- **Formatting:** Good contrast between the neural and TF-IDF lines.
- **Clarity:** The structural break in 2011 is very obvious.
- **Storytelling:** This is a crucial validation exhibit: it proves the model is picking up on *structure*, not just the *partisan vocabulary* that peaked during the Tea Party era.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This is a vital "mechanism" figure that distinguishes this paper from previous NLP-in-Econ work (like Gentzkow et al.).

### Figure 5: "Party identification versus individual identification"
**Page:** 20
- **Formatting:** The "Party uniformity gap" shading is a clever visual way to show the difference.
- **Clarity:** High.
- **Storytelling:** Shows that while individuals are hard to predict, their party is much easier, suggesting a "party line" in language.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Party Classification Accuracy: All Methods"
**Page:** 20
- **Formatting:** Clean.
- **Clarity:** Comparison across methods is easy to read.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 2 main figures, 5 appendix tables, 3 appendix figures (after proposed moves).
- **General quality:** Extremely high. The exhibits are clearly generated with a consistent style (likely Matplotlib/Seaborn with a custom theme) and follow "booktabs" conventions for tables.
- **Strongest exhibits:** Figure 2 (Event Study) and Figure 4 (Neural vs. Classical comparison).
- **Weakest exhibits:** Table 2 (redundant with Fig 1) and Table 6 (could be merged with Table 7).
- **Missing exhibits:** 
    - **Regression Table:** Currently, the paper relies on t-stats in the text (e.g., $t=4.2$). A formal regression table for the FEMA event study (showing different windows or controls for chamber/party) is standard for top journals.
    - **Examples Exhibit:** A table showing 2-3 examples of "High Deliberation Index" turns vs. "Low/Negative" turns would help the reader "feel" what the model is measuring.

- **Top 3 improvements:**
  1. **Consolidate Validation:** Merge Table 6 and Table 7 into a single "Speaker and Party Identification Performance" table to save space and make the comparison across tasks/models immediate.
  2. **Promote Figure 4:** Move the "Neural vs. Classical" comparison to the main text. It is the strongest evidence that the paper's method captures something fundamentally different from existing word-frequency methods.
  3. **Visual Cues for Train/Test:** In all time-series figures (1, 3, 4, 5), add a subtle background shading or a vertical line at 2014 to denote where training ends and "true" out-of-sample evaluation begins. This builds significant trust with reviewers regarding the ML methodology.