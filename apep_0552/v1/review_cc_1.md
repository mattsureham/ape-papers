# Internal Review — Claude Code (Round 1)

**Role:** Reviewer 2 (harsh, skeptical)
**Paper:** Stranded by the Label? Regulatory Bans, Energy Certificates, and Property Values in France

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:** The paper exploits a genuine institutional transition—France's 2021 DPE reform that converted informational energy labels into regulatory instruments with progressive rental bans. The triangulation strategy (DiD, triple-difference, multi-cutoff RDD, DiDisc) is ambitious.

**Concerns:**

- **Limited pre-treatment periods.** Data begin in 2020H2, providing only one pre-reform semester before the July 2021 treatment. A single pre-reform coefficient cannot establish pre-trends. The paper acknowledges this honestly.

- **Concurrent methodology change.** The reform simultaneously changed regulatory consequences AND the DPE calculation methodology. The DiD estimate necessarily bundles regulatory and methodological effects.

- **Spatial matching quality.** The 50m nearest-neighbor match is pragmatic but may match neighboring units in dense apartments.

### 2. Inference and Statistical Validity

- Standard errors clustered at commune level—appropriate.
- Sample sizes large (814,887) and reported consistently.
- Main DiD result (−0.020, p < 0.001) is statistically robust.
- RDD uses rdrobust with IK bandwidth selection—standard practice.

### 3. Robustness and Alternative Explanations

**Strengths:** Bandwidth sensitivity, alternative timing, département × year-quarter FE, donut RDD, McCrary density tests.

**Weaknesses:** Triple-difference fails (wrong sign). No covariate balance test at RDD threshold. No power calculation.

### 4. Contribution and Literature Positioning

Well-positioned. Key citations appropriate. The manipulation finding is the paper's most novel contribution.

### 5. Results Interpretation

Admirably honest about limitations. The reframing in the revision acknowledges that the post-reform penalty reflects a composite of multiple channels.

### 6. Actionable Revision Requests

**Must-fix:** RDD covariate balance table; power analysis for RDD.
**High-value:** CS/SA estimator consideration; methodology change discussion.
**Optional:** Confidence interval for aggregate calculation; move Figure 2 to appendix.

### 7. Overall Assessment

**Key strengths:** Genuine natural experiment, large sample, novel manipulation finding, honest reporting.
**Critical weaknesses:** Channel decomposition incomplete, limited pre-treatment data, concurrent methodology change.

DECISION: MINOR REVISION
