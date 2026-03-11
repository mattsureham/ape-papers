# Internal Claude Code Review — Round 1

**Paper:** The Illusion of Permanence: Relabeling vs. Real Reform in Spain's 2022 Temporary Contract Ban
**Paper ID:** apep_0594 v1
**Date:** 2026-03-11
**Reviewer:** Claude Code (self-review)

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The continuous-treatment DiD design is appropriate for a national reform with regional exposure variation. The treatment variable (pre-reform regional temporary employment share) provides clean cross-sectional variation exploiting Spain's well-known North-South labor market dualism.

**Strengths:**
- 45-quarter pre-period provides a long baseline for event-study validation
- Treatment timing is sharp (RDL 32/2021 effective March 30, 2022)
- The paper correctly frames this as continuous-treatment DiD, not shift-share

**Concerns:**
- Mean reversion: treatment intensity measured from the outcome variable. Mitigated by region-specific trends robustness (beta=-0.250 survives) and flat pre-trends
- Only 19 clusters limits power for the unweighted specification
- Sectoral confounding acknowledged but not directly addressed with controls

### 2. Inference and Statistical Validity

Standard errors are properly clustered at the region level. The paper reports wild cluster bootstrap (Webb weights, 9,999 iterations) and randomization inference (1,000 permutations).

- Unweighted: beta=-0.220, SE=0.205, bootstrap p=0.365 — imprecise
- Weighted: beta=-0.462, SE=0.046, bootstrap p=0.009 — robust
- RI p=0.179 — weak but consistent with few-cluster power limitations
- Sample sizes (1,140 obs) are coherent and consistent across tables

The weighted/unweighted divergence is transparently presented.

### 3. Robustness and Alternative Explanations

Robustness battery includes:
- Leave-one-out (19 regions) — stable
- Wild cluster bootstrap — reported for all specs
- Randomization inference — p=0.179
- Alternative treatment timing (2022Q1, 2022Q3) — similar
- Shorter pre-period (2016+) — similar magnitude
- Population weighting — strengthens result
- Region-specific linear trends — survives (beta=-0.250)
- COVID exclusion (drop 2020-2021) — similar (beta=-0.208)

Missing: sector-composition controls, placebo reform dates, pre-2020 treatment intensity. These are acknowledged as limitations.

### 4. Contribution and Literature Positioning

The paper fills a clear gap: no prior design-based evaluation of Spain's 2022 reform exists. Literature coverage includes Bentolila et al., Dolado et al., Cahuc et al. (dual labor market theory), and Goldsmith-Pinkham et al. (exposure design context). The contribution paragraph is well-calibrated.

### 5. Results Interpretation and Claim Calibration

Claims are appropriately hedged after revision:
- "consistent with substantial contract relabeling" (not "proves relabeling")
- Total employment null presented as informative but not definitive
- Fijo discontinuo legal benefits acknowledged
- Broader analogies toned down

One remaining tension: the title "Illusion of Permanence" still implies the reform was illusory, but the text now properly hedges this. Acceptable as a provocative title if the body delivers nuance.

---

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Pre-2020 treatment intensity:** Using 2018-2019 average Zr would eliminate COVID contamination concern. Rankings are stable so results should be similar.
2. **Region-sector panel:** If EPA provides sector data at the regional level, a triple-difference (region × sector × time) design would be much more powerful.
3. **Wage/hours outcomes:** If available from EPA, these would directly test job quality changes vs. pure relabeling.
4. **Binned event study:** While the full quarterly version is informative, a companion binned specification (2-year bins) would provide cleaner inference with 19 clusters.

---

## 6. ACTIONABLE REVISION REQUESTS

### Must-fix: None remaining
All critical issues from advisor and external review have been addressed.

### High-value improvements:
1. Pre-2020 treatment intensity as a robustness check
2. Sector-composition controls if data permit

### Optional polish:
1. Engage with Rambachan-Roth (2023) on event-study inference
2. Add binned event study as appendix figure

---

## 7. OVERALL ASSESSMENT

**Key strengths:**
- Important, timely policy question with broad relevance
- Clean data from INE EPA with long pre-period
- Appropriate inferential methods for 19-cluster setting
- Well-calibrated claims after revision

**Critical weaknesses:**
- Unweighted baseline is imprecise (power limitation with 19 clusters)
- Mean reversion threat mitigated but not eliminated
- Mechanism inference (relabeling) is suggestive rather than definitive

**Publishability:** Ready for publication at a strong field journal (e.g., Journal of Labor Economics, Labour Economics, ILR Review). With richer administrative data, potentially upgradeable to AEJ:EP.

DECISION: MINOR REVISION
