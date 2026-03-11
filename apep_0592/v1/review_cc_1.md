# Internal Review — Round 1

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The paper exploits staggered state prohibition adoption (1907–1919) interacted with county-level alcohol industry employment shares. The identification strategy has several strengths: (i) clear policy variation across 30 treated and 15 control states, (ii) within-state variation in treatment intensity via county alcohol shares, and (iii) individual-level panel data that eliminates compositional effects.

**Critical weaknesses:**
- The pre-trend test is contaminated by 5 early-adopting states, and the paper honestly acknowledges this. The large positive coefficient (5.34 vs. 0.80 in the main period) is a serious concern for the parallel trends assumption.
- The 1910 alcohol share is post-treatment for the 5 pre-1910 adopters, creating measurement error in treatment intensity. The paper argues this biases toward zero (conservative), which is reasonable.
- Column (4) with state FE does not estimate the same quantity as the interaction specification. The paper now correctly notes this, but the fact that the within-state AlcShare coefficient (0.35) is less than half the interaction coefficient (0.80) suggests that between-state variation may be driving part of the main result.

### 2. Inference and Statistical Validity

- Standard errors clustered at the state level (45 clusters) — adequate but borderline.
- Wild cluster bootstrap and randomization inference provide important robustness. The RI p-value of 0.098 is weaker than the parametric p-value of 0.004, reflecting the small number of permutable units.
- Leave-one-out analysis shows stability across state exclusions.
- Sample sizes are consistent across specifications (8,732,156 male workers).

### 3. Robustness and Alternative Explanations

- The significant pre-trend is the paper's Achilles' heel. The honest framing is appropriate.
- Alternative treatment measures (bartender share, bev manufacturing share, binary high-exposure) confirm sign and significance.
- The zero-exposure placebo is informative.
- The 1920–1930 reversal is intriguing but is framed as "differential persistence" rather than a clean treatment effect (correct, since national prohibition eliminates untreated group).

### 4. Contribution and Literature Positioning

The paper positions itself at the intersection of three literatures: (i) Prohibition history, (ii) industry destruction and local labor markets, and (iii) social infrastructure. The contribution is novel — no prior work examines non-alcohol labor market spillovers from Prohibition using individual-level linked data. The literature coverage is adequate (16 citations in intro, 24 total).

### 5. Results Interpretation and Claim Calibration

- The standardized effect (0.018 SD) is appropriately described as "modest."
- The paper does not over-claim causality given the pre-trend concern.
- The mechanism decomposition and heterogeneity patterns are the paper's strongest contributions.
- Binary outcome interpretations are now correctly described.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Promote figures to main text:** The paper has zero figures in the main body. The prohibition rollout timeline, binscatter, and coefficient plots should be in the main text.
2. **Split Table 5:** The long-run reversal is a major finding — it deserves its own table, not shared with the suggestive women's results.
3. **Translate the effect size:** 0.80 OCCSCORE points needs a real-world anchor (e.g., "roughly the gap between a janitor and a factory hand").
4. **Strengthen the dynamic interpretation:** The short-run gain / long-run reversal pattern is the paper's most distinctive finding. It could be made more central to the framing.

## 6. Actionable Revision Requests

**Must-fix:**
1. None — the paper has addressed the major internal consistency issues.

**High-value:**
1. Promote key figures to main text (timeline, binscatter, coefficient plots).
2. Split Table 5 into separate long-run and women's tables.
3. Add real-world translation of the 0.80 effect size.

**Optional polish:**
1. Remove the "organized as follows" roadmap paragraph.
2. Improve transitions between mechanism and heterogeneity sections.

## 7. Overall Assessment

**Strengths:** Novel question, excellent institutional background, honest treatment of pre-trend concerns, rich mechanism decomposition, individual-level linked data.

**Weaknesses:** Pre-trend contamination complicates causal interpretation, no figures in main text, long-run reversal finding is understated.

**Publishability:** Publishable after minor revision. The pre-trend concern is fundamental but the paper's honest framing, mechanism decomposition, and dynamic patterns provide genuine contributions to understanding industry destruction and labor market adjustment.

DECISION: MINOR REVISION
