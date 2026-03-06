# Internal Review — Claude Code (Round 1)

**Reviewer:** Claude Code (Internal)
**Paper:** Is Generative AI Seniority-Biased? Evidence from U.S. Occupational Employment Data
**Round:** 1

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The paper's identification strategy relies on difference-in-differences comparing high- vs. low-AIOE industries before and after 2022. The author is commendably honest about the pre-trend issue: the event study (Figure 2) reveals a clear monotonic decline in the AIOE × Year coefficient from 2015 to 2022, violating parallel trends. The reconciliation paragraph (Section 5.4) effectively explains how the negative DiD coefficient is consistent with the near-zero post-2022 event study coefficients—both are driven by the convergence that occurred throughout 2015–2022.

**Key concern:** The paper acknowledges this pre-trend undermines causal interpretation but still frames results as evidence of "seniority-biased technological change." The framing could be tightened to make clear throughout that the descriptive pattern is robust but the causal channel is uncertain.

### 2. Inference and Statistical Validity

- Standard errors clustered at 2-digit NAICS (25 clusters) — adequate but at the lower bound for cluster-robust inference. The paper acknowledges this.
- The continuous treatment coefficient (-0.013, p=0.10) is marginal. The binary treatment (-0.018, p<0.05) is stronger.
- Sample sizes are correctly reported (250 for industry-year panels, 750 for DDD, 2000 for heterogeneity).
- The heterogeneity specification (-0.27, t=-5.30) is the strongest result, operating on a different dependent variable (log occupational employment).

### 3. Robustness and Alternative Explanations

- Seven robustness specifications are reported in Table 5, covering alternative FE, sample restrictions, weighting, and QCEW cross-validation.
- The 2020 placebo test reveals significance (β=-0.019, t=-2.83), consistent with the pre-trend. The author correctly interprets this as evidence against a discrete GenAI break.
- Healthcare placebo is useful but qualitative.
- QCEW evidence (insignificant total employment effect) supports the compositional-change interpretation.

### 4. Contribution and Literature Positioning

The paper positions itself well relative to Hosseini Maasoum & Lichtinger (2025), who use résumé data. The contribution of using OEWS/O*NET data is clear. Literature coverage appears adequate for the policy domain.

### 5. Results Interpretation

The paper is honest about its limitations. The conclusion appropriately hedges causal claims. Policy implications are reasonable given the evidence presented.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. The within-occupation heterogeneity result (Table 3, Col 4) is the paper's strongest finding. Consider promoting it more prominently in the abstract and introduction.
2. Consider adding wild cluster bootstrap p-values given the small number of clusters (25).
3. The SEC EDGAR analysis (27 filings) could be expanded or removed—it adds complexity without much analytical leverage.

## OVERALL ASSESSMENT

**Strengths:** Honest treatment of pre-trends, multiple data sources (OEWS + QCEW), clear writing, strong heterogeneity result, useful policy framing.

**Weaknesses:** Pre-trend undermines causal claims, small number of clusters, continuous treatment coefficient only marginally significant.

**Publishability:** The paper makes a genuine descriptive contribution and is honest about its limitations. With the current framing (acknowledging pre-trends, emphasizing descriptive patterns), it is appropriate for a policy-oriented journal.

DECISION: MINOR REVISION
