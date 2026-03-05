# Reply to Reviewers — Round 1

## Response to GPT-5.2 (Major Revision)

### 1. Exposure mismatch / "home commune" analysis
> The reform does not treat a constituency; it changes the feasible office-holding set for individual politicians. Aggregating all communes in the constituency can mechanically attenuate the estimand.

We agree this is the most important limitation. We now lead the caveats section with this point, explicitly noting that constituency-level aggregation may dilute commune-specific effects. We note that a direct test requires identifying each deputy-mayor's specific commune from Wikidata and constructing appropriate counterfactual communes — a substantial data extension we flag as the highest-priority direction for future work. We also note that the commune-level robustness check (Table 3, Column 4) applies constituency-level treatment to all communes, which does not solve the exposure problem.

### 2. Discretionary grant disaggregation
> Total "concours de l'État" bundles formula-based and discretionary grants.

Added a paragraph in the data limitations section explicitly acknowledging that DGFiP/OFGL report grants as an aggregate, and that isolating DETR/DSIL discretionary grants would provide a stronger test.

### 3. Sparse post-period / COVID year
> With only 2020 and 2023 post years, one is a pandemic year.

Added a new robustness subsection ("Excluding 2020") showing results are virtually identical when 2020 is dropped and 2023 is the sole post-treatment year (invest: -0.014, SE=0.012).

### 4. Inference: wild cluster bootstrap
We acknowledge this would strengthen inference but note that with 539 clusters (far above the conventional 50-cluster threshold), asymptotic cluster-robust inference is reliable. The suggestion is noted for future work.

### 5. Debt marginal significance / claim calibration
> "Not a single fiscal outcome exhibits a significant response" is not strictly accurate when debt is p=0.09.

Revised to explicitly acknowledge debt's marginal significance and note that with seven outcomes tested, an isolated p=0.09 is best interpreted as noise.

### 6. Claims recalibrated
Throughout the paper, we have toned down claims from "no pork-barrel" to "no detectable constituency-level fiscal effects." The abstract now uses "no detectable effects" rather than "precisely estimated null effects."

---

## Response to Grok-4.1-Fast (Minor Revision)

### 1. Joint F-test on pre-trends
> Standard for DiD validity (e.g. QJE). Add p-value for joint pre-coefs=0.

Added. Joint F-tests for all four event-study outcomes: Investment (F=1.43, p=0.17), Equipment (F=1.31, p=0.23), Grants (F=0.87, p=0.55), Operating Expenditure (F=0.64, p=0.77). All fail to reject the null of zero pre-trends.

### 2. Own-commune treatment
See response to GPT-5.2 #1 above. Acknowledged as key limitation and future work.

### 3. Post-treatment sparse
Added COVID-exclusion robustness. Results unchanged.

---

## Response to Gemini-3-Flash (Minor Revision)

### 1. "Home Commune" analysis
See response to GPT-5.2 #1 above. Acknowledged as the most important limitation.

### 2. Senator substitution channel
> Control for whether the constituency is also represented by a cumulard Senator.

Interesting suggestion. The 2017 reform affected Senators at a later date (2017 senatorial elections for those up for renewal). We cannot implement this directly without additional data on Senate cumulards, but we discuss substitution through senators as a plausible mechanism for the null in Section 7.1.

### 3. Grant disaggregation
See response to GPT-5.2 #2 above. Acknowledged as limitation.

---

## Prose and Exhibit Improvements

### Prose (from prose review)
- Rewrote opening paragraph with a hook ("In 2012, nearly half of the members...")
- Rewrote results Section 5.1 lead with economic story, not table narration
- Added "14 euros per person" real-world magnitude translation
- Softened abstract language

### Exhibits (from exhibit review)
- Fixed Table 1 constituency count reversal (291 Non-cumulard, 248 Cumulard)
- Cleaned Table 3 variable labels (no more underscored R variable names)
- Added adjustbox to Table 2 (no more overfull hbox)
- Added Appendix tables for triple-diff (Table C) and HonestDiD (Table D)
