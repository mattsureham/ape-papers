# Internal Review — Claude Code (Round 1)

**Role:** Referee (harsh, skeptical)
**Model:** claude-opus-4-6
**Paper:** The CROWN Act and Occupational Sorting
**Timestamp:** 2026-03-05T16:30:00

---

## 1. IDENTIFICATION AND EMPIRICAL DESIGN

**Strengths:**
- The staggered adoption of CROWN Acts across 22 states with 5 distinct cohorts (2019-2023) provides genuine temporal variation. The 30 never-treated state-equivalents form a clean control group.
- The Callaway-Sant'Anna (2021) doubly robust estimator is the appropriate modern method for staggered DiD, avoiding the well-documented pitfalls of naive TWFE.
- The triple-difference design (Black × CROWN state × Post) with state×year, state×race, and race×year FEs is a strong complement that absorbs race-specific national trends—particularly important given COVID-era disruptions.
- The Goodman-Bacon decomposition showing 82% clean treated-vs-untreated weight is reassuring.

**Concerns:**
- The paper's headline finding (1.28 pp shift in customer-facing occupations) comes exclusively from the TWFE triple-difference specification. The CS-DiD estimate for the same outcome is 0.005 (p=0.36)—directionally consistent but statistically insignificant. The paper acknowledges this honestly (Section 6.2, abstract), but the tension remains: the primary estimator (CS-DiD) does not find the primary result. The triple-diff finding should be presented with appropriate caution.
- The parallel trends assessment (Section 6.3) notes "some noise at longer leads (e = -3 and e = -4)." This deserves more scrutiny. Pre-treatment coefficients that are noisy at longer horizons could indicate differential trends that the design fails to capture.
- Selection into treatment is a concern the paper discusses but doesn't fully resolve. Early adopters (NY, NJ, CA) are systematically different from later adopters (TX, TN, NE). The post-2020 robustness check is helpful but doesn't eliminate this concern.

## 2. INFERENCE AND STATISTICAL VALIDITY

**Strengths:**
- Standard errors clustered at the state level are appropriate for state-level policy variation.
- Randomization inference (494 permutations, p=0.666) provides non-parametric confirmation of the employment null.
- The 95% CI of [-0.015, 0.008] for employment is informative—rules out effects larger than 1.5 pp.

**Concerns:**
- With 52 clusters, clustering is adequate but not overwhelming. Wild cluster bootstrap would strengthen inference.
- The occupation outcome N (733) is notably below the theoretical maximum (832 = 52×8×2) due to Census suppression. The paper should discuss whether suppression is non-random (e.g., more suppression in small states that may differ systematically).
- No power calculation is provided. What is the minimum detectable effect for the customer-facing outcome? Given the noise in the CS-DiD estimate, the design may be underpowered for this outcome.

## 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS

**Strengths:**
- The Asian-White placebo test (ATT = -0.001, p = 0.92) is clean and convincing.
- Post-2020 adopters subsample addresses COVID contamination.
- Sun-Abraham estimation confirms the null on employment.
- The Bacon decomposition visualization is well-executed.

**Concerns:**
- No placebo test for customer-facing occupations using Asian workers. The paper only reports Asian-White employment placebos. Since the occupation effect is the main finding, a placebo for that outcome would be valuable (though the paper notes occupation data isn't available for Asian populations—this limitation should be more prominent).
- No heterogeneity analysis by state characteristics (Black population share, baseline gap size, enforcement intensity). The paper's discussion of enforcement heterogeneity (Section 7.4) is speculative without empirical evidence.
- The simultaneous decrease in professional occupation share (-1.40 pp) alongside the increase in customer-facing share could reflect a less favorable interpretation: Black workers being channeled into lower-status jobs. The welfare discussion (Section 7.3) acknowledges this but it deserves more emphasis.

## 4. CONTRIBUTION AND LITERATURE POSITIONING

**Strengths:**
- The paper is well-positioned in three literatures (antidiscrimination policy, racial discrimination/sorting, staggered DiD methodology).
- The comparison with "ban the box" (Section 7.2) is insightful—distinguishing information-restriction from practice-prohibition policies.
- The conceptual framework (Section 3) is simple but clear, generating testable predictions.

**Concerns:**
- The literature review could cite Neumark (2018) on employment discrimination law more broadly.
- The "first causal evidence" claim in the conclusion is appropriate given no prior econometric studies of the CROWN Act exist, but the paper should acknowledge the concurrent legal scholarship on CROWN Acts.

## 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION

- The abstract and introduction present findings honestly, including the CS-DiD imprecision.
- The back-of-the-envelope calculation (167,000 affected workers) is reasonable but should note it assumes the triple-diff estimate is correct; the CS-DiD estimate would imply roughly 65,000.
- The "14% reduction in the gap" framing is appropriate given the 9 pp pre-treatment gap.

## 6. ACTIONABLE REVISION REQUESTS

### Must-fix:
1. **Add power analysis**: Report minimum detectable effects for both employment and occupation outcomes given the sample size and clustering structure.
2. **Discuss non-random suppression**: Address whether Census cell suppression could bias the occupation estimates.

### High-value improvements:
3. **Wild cluster bootstrap**: Add as sensitivity check for the triple-diff specification.
4. **Heterogeneity by state characteristics**: Even simple splits (high vs. low Black population share) would strengthen the mechanism story.
5. **Tone down the triple-diff finding slightly**: Given the CS-DiD imprecision, present the occupational sorting result as "suggestive" or "consistent with" rather than definitive.

### Optional polish:
6. Move Figures 4, 5, 6 to appendix to streamline the main text.
7. Add a choropleth map of CROWN Act adoption.

## 7. OVERALL ASSESSMENT

**Key strengths:** Novel policy question with clear policy relevance; strong institutional background; honest treatment of null and imprecise results; comprehensive methodological toolkit (CS-DiD, TWFE triple-diff, Bacon decomposition, Sun-Abraham, randomization inference).

**Critical weaknesses:** The main positive finding (customer-facing occupation shift) is statistically significant only in the triple-diff specification, not in the primary CS-DiD estimator. The paper handles this tension well but it fundamentally limits the strength of the causal claim. The lack of power analysis makes it difficult to determine whether the CS-DiD imprecision reflects insufficient power or a genuinely smaller effect.

**Publishability:** This is a solid working paper with a novel question and competent execution. The identification strategy is credible, the data is real, and the analysis is thorough. The tension between CS-DiD and triple-diff results is a limitation but also an honest reflection of the data. With minor revisions addressing power and inference, this paper would be competitive at a field journal (e.g., Journal of Labor Economics, Journal of Human Resources).

DECISION: MINOR REVISION
