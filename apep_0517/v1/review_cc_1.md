# Internal Review - Claude Code (Round 1)

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The boundary discontinuity design is well-motivated and appropriately executed. The key identifying assumption—that areas just across a PFA boundary are similar in unobserved determinants of crime—is clearly stated and directly testable via the balance test (Table 3).

**Strengths:**
- The event study (Figure 4) is the paper's strongest identification tool. The flat coefficient profile from 2011–2024 is compelling evidence that the discontinuity is pre-existing rather than caused by differential policing.
- Fixed bandwidth of 2 km is well-justified given the mass points issue with MSE-optimal bandwidth selection.
- The paper honestly reports a null result and does not torture the data for significance.

**Weaknesses:**
- The paper could strengthen the balance test by adding non-crime covariates (IMD, population density, age structure). The single-row balance table using pre-period crime is informative but thin.
- The McCrary test uses only the latest year's cross-section (N=31,748) rather than the full panel, which is reasonable but should be more prominently justified.

### 2. Inference and Statistical Validity

- Standard errors are correctly clustered by boundary pair.
- The `masspoints = "adjust"` parameter is appropriate given the discrete LSOA centroids.
- Sample sizes are now consistently reported across all tables (N_eff present in Tables 2, 3, and 4).
- The very small SEs for sparse crime types (robbery: 0.0007) are mechanically correct given 75,748 observations but should be interpreted with caution.

### 3. Robustness

- Bandwidth sensitivity (1–4 km) shows stable coefficients.
- COVID exclusion is well-handled.
- Donut RDD is properly flagged as not directly comparable due to different bandwidth method.
- Placebo cutoff tests provide useful supplementary evidence.

### 4. Contribution and Literature

- The paper engages well with the core police-crime literature (Levitt 1997, Draca et al. 2011, Mello 2019, Chalfin & McCrary 2022).
- The null-result framing is a genuine contribution—showing that BDD at administrative boundaries can be confounded by geographic sorting.
- Missing citations: Dell (2010) on geographic RDD methodology, Machin & Marie (2011) on UK police and crime.

### 5. Results Interpretation

- The "wrong sign" narrative is compelling and honestly presented.
- The conclusion that geographic sorting explains the boundary discontinuity is well-supported by the event study evidence.
- The paper appropriately cautions that the null result pertains specifically to the BDD design, not to whether police affect crime in general.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Add a map figure** showing PFA boundaries and the intensity of officer cuts. This is the most impactful missing exhibit for a geographic paper.
2. **Expand the balance test** to include non-crime covariates if available (IMD, Census demographics).
3. **Consider a "dose-response" specification** that interacts the boundary dummy with the cut differential between adjacent forces.
4. **Discuss the aggregation issue** more prominently—LSOA-level data may mask micro-location effects near boundaries.

## DECISION

### Key Strengths
- Honest null result with compelling temporal evidence
- Clean geographic RDD implementation
- Well-written narrative arc

### Critical Weaknesses
- Thin balance evidence (single covariate)
- No map for a geographic paper
- Some data construction details require additional clarification

### Overall
This is a solid empirical paper that makes a genuine methodological contribution by demonstrating how geographic sorting can confound boundary discontinuity designs. The null result is well-documented and the temporal evidence is convincing.

DECISION: MINOR REVISION
