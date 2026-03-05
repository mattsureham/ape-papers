# Internal Review - Round 1

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The paper implements a boundary discontinuity design across eight US state borders, complemented by a triple-difference specification exploiting the SALT cap. The identification strategy is generally credible but has important limitations that the paper commendably acknowledges.

**Strengths:**
- The SALT cap triple-difference is the cleanest identification in the paper
- Honest treatment of the placebo failure and covariate imbalance
- Multiple bandwidth robustness checks

**Concerns:**
- The nonparametric RDD and parametric specifications have opposite sign conventions, creating confusion. The paper now explains this well but it remains a fundamental interpretive challenge.
- The NJ-PA estimate (35.9 pp, N=30) dominates the pooled result. The paper acknowledges this but still reports it as a main table row.
- The covariate balance failures (total returns, log total returns) indicate that the RDD assumptions are violated for the cross-sectional comparison. The paper correctly notes this motivates the triple-difference.

### 2. Inference and Statistical Validity

- Standard errors are properly clustered at the ZIP level throughout
- Sample sizes are reported for all specifications
- The nonparametric bandwidth (3.3 km) is MSE-optimal from rdrobust
- The triple-diff N=29,346 is correctly explained as stacked observations

**Concerns:**
- The period-specific estimates (Post-SALT, COVID) are imprecise with p > 0.10 — the paper handles this honestly
- The welfare elasticity of 33 from the cross-sectional estimate is correctly flagged as implausible

### 3. Robustness

The robustness section is thorough: donut designs, bandwidth sensitivity, polynomial order, metro-only subsample, suppression sensitivity. Table 7 consolidates these well.

- Bandwidth sensitivity showing sign reversal is the key finding
- Donut designs strengthen the case for local tax sorting
- McCrary test passes

### 4. Contribution and Literature

The paper is well-positioned relative to Young (2016), Moretti & Wilson (2017), Kleven et al. (2013, 2014). The ZIP-code boundary design is a genuine methodological contribution. The SALT natural experiment adds temporal variation to what would otherwise be a purely cross-sectional design.

### 5. Results Interpretation

The paper is admirably honest about null and mixed results. The central narrative — that pre-existing economic geography dominates the cross-sectional pattern while taxes operate at the margin — is well-calibrated to the evidence.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Must-fix:** None remaining — prior fatal errors have been addressed.

2. **High-value improvements:**
   - Consider excluding NJ-PA from the pooled nonparametric estimate and reporting it separately, given N=30
   - Add a map showing the 8 border segments
   - The event study figure would benefit from adding the raw pre/post means alongside the coefficients

3. **Optional polish:**
   - The contributions paragraph could be streamlined into flowing narrative
   - Period table (Table 5) could move to appendix given low power

## 7. Overall Assessment

**Strengths:** Novel use of ZIP-code IRS data at state borders; honest treatment of mixed results; well-designed triple-difference exploiting SALT cap; comprehensive robustness checks.

**Weaknesses:** Cross-sectional RDD assumptions are violated (covariate imbalance); bandwidth sensitivity limits causal claims from the main RDD; NJ-PA outlier dominates pooled estimates.

**Publishability:** This paper makes a credible contribution to the tax competition literature. The SALT triple-difference result is the strongest identification, and the paper's honest engagement with the limitations of boundary designs in this setting is itself a contribution. Suitable for AEJ: Economic Policy after minor revisions.

DECISION: MINOR REVISION
