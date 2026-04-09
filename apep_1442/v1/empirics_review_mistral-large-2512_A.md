# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-04-09T14:39:14.807508

---

 Here is my rigorous but constructive referee report:

---

### 1. Idea Fidelity

The paper largely pursues the original idea but deviates in two critical ways:

**a. Identification Strategy Mismatch**
The manifest proposed a two-stage IV design (site-level and LPA-level) to estimate causal effects on housing supply, prices, and development activity. The paper instead implements a diagnostic exercise focused on the *feasibility* of the leniency instrument itself, abandoning the housing outcomes entirely. This is a defensible pivot (small-sample bias is a real concern), but the paper should explicitly acknowledge that it no longer addresses the original research question about housing supply.

**b. Data Scale Undershoot**
The manifest anticipated ~100,000 cases (20,000/year × 5 years) and ~300 inspectors. The paper uses only 2,227 cases (2% of the expected sample) and 720 inspectors (many with only 1–2 cases). While the manifest’s feasibility assessment was correct (data are accessible), the paper’s sample is too small to implement the proposed design. The median of 2.2 cases/inspector is far below the 30–50 cases/inspector minimum suggested by the literature (e.g., Frandsen et al. 2023).

**Missed Opportunity**
The manifest’s "Design B" (LPA-level aggregation) could have been attempted even with the small sample. The paper could have shown whether the negative first stage persists when aggregating to LPA-quarters, which might smooth out some of the noise.

---

### 2. Summary

The paper exploits quasi-random assignment of planning inspectors in England to test the feasibility of an examiner leniency IV design. Using a novel dataset of 2,227 appeals, it finds that leave-one-out leniency scores produce a *negative* first stage (inspectors with higher allow rates are less likely to allow a focal case), driven by small-sample bias (median 2.2 cases/inspector). Lagged leniency, however, confirms persistent inspector styles. The paper provides a cautionary tale about the data requirements for examiner designs and introduces a scalable method for extracting inspector identities from decision letters.

---

### 3. Essential Points

**1. Clarify the Research Question**
The paper no longer addresses the manifest’s original question (housing supply effects). It should:
- Explicitly state that the goal is to *diagnose* the feasibility of the leniency instrument, not estimate housing supply effects.
- Justify why the housing outcomes (MHCLG completions, Land Registry prices) were abandoned. If the issue is sample size, say so; if it’s data quality, explain.
- Discuss whether the full-sample design (100,000 cases) would resolve the small-sample bias. The manifest’s "Design B" (LPA-level aggregation) might work even with noisy inspector-level data.

**2. Strengthen the Small-Sample Bias Argument**
The paper’s core claim—that the negative first stage reflects mean reversion—is plausible but could be bolstered with:
- **Simulations**: Show that a negative first stage emerges mechanically when inspectors have 2–3 cases/cell, even if true leniency is positive. Compare this to the canonical setting (e.g., Dobbie et al. 2018) where inspectors have hundreds of cases.
- **Alternative Instruments**: Test whether a *leave-two-out* leniency score (for inspectors with ≥4 cases) produces a positive first stage. This would directly test the mean-reversion hypothesis.
- **Cell-Size Sensitivity**: Report how the first-stage coefficient varies with the minimum number of cases/inspector (e.g., 3 vs. 5 vs. 10). If the negative sign disappears with more cases, this would confirm the small-sample bias.

**3. Address the Lagged Leniency Puzzle**
The lagged leniency result (0.225, p < 0.001) is compelling but raises questions:
- **Temporal Stability**: How stable are inspector styles over time? If inspectors’ leniency drifts (e.g., due to training or policy changes), lagged leniency may not be a valid instrument for contemporaneous outcomes.
- **Exclusion Restriction**: The paper argues that lagged leniency is a better instrument than contemporaneous leave-one-out. But if inspectors’ styles change, lagged leniency may violate the exclusion restriction (e.g., if inspectors become stricter over time due to policy pressure, lagged leniency could correlate with unobserved case difficulty).
- **First Stage**: Report the first-stage F-statistic for lagged leniency. If it’s strong, this could be a viable alternative instrument for future work.

---

### 4. Suggestions

**Data and Sample**
- **Scale Up**: The paper’s sample is too small to implement the manifest’s design. The authors should either:
  - Collect the full sample (100,000 cases) and re-run the analysis, or
  - Explicitly state that the paper is a *pilot* and that the full-sample design is needed for credible results.
- **Inspector-Level Analysis**: Report summary statistics on inspector characteristics (e.g., credentials, tenure). Do leniency scores vary systematically by inspector background (e.g., architects vs. surveyors)?
- **Case-Type Heterogeneity**: The paper pools all case types but notes that the negative first stage is stronger for planning appeals than householder appeals. Test whether the leniency instrument works better for specific case types (e.g., major developments vs. minor extensions).

**Methodology**
- **Leave-Two-Out**: For inspectors with ≥4 cases, construct a leave-two-out leniency score and test whether it produces a positive first stage. This would directly address the mean-reversion hypothesis.
- **Alternative Instruments**: Test whether inspector fixed effects (for inspectors with ≥10 cases) produce a positive first stage. This would avoid the small-sample bias entirely.
- **Monotonicity**: The paper notes that the allow rate is flat across leniency quintiles. Test whether monotonicity holds for inspectors with ≥10 cases. If it does, this would suggest that the instrument works when the sample is large enough.
- **Falsification Tests**: The manifest proposed three falsification tests (pre-decision placebo, balance on observables, pre-trends). The paper reports balance tests but should also:
  - Test whether lagged leniency predicts pre-existing housing trends (e.g., LPA-level completions in T−3).
  - Test whether leniency predicts case characteristics *outside* the conditioning cells (e.g., appellant type, site size).

**Interpretation**
- **Policy Implications**: The paper argues that the "inspector lottery" is real (lagged leniency predicts outcomes). Discuss whether this heterogeneity is economically meaningful. For example, how much does the allow rate vary across inspectors? Could this explain a non-trivial share of the housing supply gap?
- **Institutional Design**: The paper notes that PINS assigns inspectors from a national pool to prevent regulatory capture. Discuss whether this design is optimal. For example, could geographic specialization improve consistency (at the cost of capture)?
- **Comparison to Literature**: The paper cites Frandsen et al. (2023) on the minimum sample size for examiner designs. Compare the planning inspector setting to other contexts (e.g., judges, patent examiners) in terms of:
  - Number of cases/decision-maker,
  - Heterogeneity in decision-making styles,
  - Quasi-randomness of assignment.

**Writing and Structure**
- **Abstract**: The abstract should clarify that the paper is a *diagnostic* exercise, not an estimate of housing supply effects. For example:
  > "This paper tests the feasibility of an examiner leniency IV design in England’s planning appeals system. Using a novel dataset of 2,227 appeals, I find that leave-one-out leniency scores produce a *negative* first stage, driven by small-sample bias (median 2.2 cases/inspector). Lagged leniency, however, confirms persistent inspector styles, suggesting that the design could work with a larger sample."
- **Introduction**: The introduction should explicitly state that the paper is a cautionary tale about data requirements, not an estimate of housing supply effects. For example:
  > "This paper documents what happens when an examiner leniency design meets insufficient data. The planning inspector setting is ideal in principle: quasi-random assignment from a national pool, no geographic specialization, standardized case procedures. But with a median of 2.2 cases per inspector, the leave-one-out leniency score is dominated by sampling noise, producing a negative first stage."
- **Conclusion**: The conclusion should discuss the path forward. For example:
  > "The full PINS case archive contains over 100,000 appeals across 300 inspectors—enough for stable leniency estimation. Future work should collect the full sample and test whether the design works when inspectors have 30–50 cases each. The lagged leniency result suggests that inspector heterogeneity is real and economically meaningful,  but the contemporaneous leave-one-out score cannot recover it from thin data."

**Tables and Figures**
- **Table 1 (Summary Statistics)**: Add a row for the number of cases/cell (case type × year). This would help readers assess the small-sample bias.
- **Table 2 (First Stage)**: Add a column for the lagged leniency first stage (coefficient and F-statistic).
- **Figure 1**: Plot the distribution of cases/inspector (e.g., a histogram). This would visually emphasize the small-sample problem.
- **Figure 2**: Plot the first-stage coefficient as a function of the minimum number of cases/inspector (e.g., 3 vs. 5 vs. 10). This would show how the negative sign disappears with more cases.

**Robustness**
- **Cell Definition**: The paper defines cells as case type × year. Test whether the results are sensitive to the cell definition (e.g., case type × quarter, or case type × LPA × year).
- **Standard Errors**: The paper clusters standard errors at the LPA level. Test whether the results are sensitive to clustering at the inspector level or two-way clustering (LPA and inspector).
- **Outliers**: Test whether the negative first stage is driven by outliers (e.g., inspectors with extreme leniency scores). Report results with and without the top/bottom 1% of inspectors.

**Policy Relevance**
- **Housing Supply**: The paper should discuss whether inspector heterogeneity could explain a meaningful share of the housing supply gap. For example, if the allow rate varies by 20 percentage points across inspectors, how many additional homes could be built if all inspectors were as lenient as the top quartile?
- **Policy Reforms**: The paper notes that the Planning and Infrastructure Bill proposes reforms to the appeals system. Discuss whether the bill’s proposals (e.g., expanding inspector capacity) would address the small-sample bias or the inspector heterogeneity.

---

### Final Assessment

This is a well-executed diagnostic exercise that makes a valuable contribution to the literature on examiner leniency designs. The paper’s core finding—that small-sample bias can produce a negative first stage—is important and should be published. However, the paper must address the three essential points above (clarify the research question, strengthen the small-sample bias argument, and address the lagged leniency puzzle) before it is ready for publication.

**Recommendation**: Revise and resubmit. The paper’s insights are novel and policy-relevant, but the current version does not fully engage with the manifest’s original research question or the implications of its findings. With the suggested revisions, this could be a strong contribution to *AER: Insights* or a field journal.
