# Internal Review — Claude Code (Round 1)

**Role:** Reviewer 2 (harsh, skeptical)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T19:15:00

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The triple-difference (DDD) design is well-motivated and represents a genuine improvement over standard DiD for this setting. Comparing investment-type vs. owner-occupier properties within treated vs. control cities absorbs city-wide shocks that would confound a simple DiD. The "identified sample" restriction (excluding Paris and Lille) is a responsible choice that strengthens the causal claim, even at the cost of statistical power.

**Concerns:**
- The classification of "investment-type" properties based on observables (≤2 rooms, apartment) rather than actual tenure status introduces measurement error. The paper acknowledges this attenuates estimates toward zero, but the magnitude of misclassification is unknown.
- With only 5 treated city groups and at most 2 years of pre-treatment data, the event study has limited power to detect pre-trend violations. The single pre-treatment coefficient (k=-2) is populated only by Bordeaux and Montpellier.
- The concentration of the result in Bordeaux (leave-one-out analysis) limits external validity considerably.

### 2. Inference and Statistical Validity

Standard errors clustered at the commune level (42 clusters) are reported throughout. The paper supplements with randomization inference (RI) and leave-one-out analysis, which is appropriate for the few-cluster setting.

**Concerns:**
- The RI p-value of 0.46 does not reject the null. The paper argues this reflects low power rather than absence of effect, which is a reasonable but somewhat convenient interpretation.
- The baseline DDD without controls (p=0.191) is not significant. Significance only emerges with controls (p=0.017). While controls can improve precision, the sensitivity to specification raises questions about robustness.

### 3. Robustness and Alternative Explanations

The robustness section is thorough: COVID exclusion, post-COVID-only cities, stacked DiD, wild cluster bootstrap, HonestDiD bounds, and size heterogeneity. The stacked DiD confirming TWFE results is reassuring.

The size gradient (studios most negative, 3-room positive) is the strongest piece of mechanism evidence.

### 4. Contribution and Literature Positioning

The literature review is solid, covering Autor et al. (2014), Diamond et al. (2019), Breidenbach et al. (2022), Mense et al. (2023), and Ahlfeldt et al. (2022). The paper clearly differentiates itself: studying introduction (not removal) of rent control, multi-city staggered adoption, and triple-difference design.

### 5. Results Interpretation

The paper is admirably honest about limitations: null RI, Bordeaux concentration, short pre-treatment window. The conclusion appropriately hedges the main finding.

---

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. The Bordeaux result could be strengthened by examining whether Bordeaux's rent control was particularly binding (e.g., comparing reference rents to market rents).
2. A heterogeneity analysis by building age or furnished/unfurnished status could provide additional mechanism evidence.
3. The paper could benefit from a back-of-envelope power calculation showing the MDE given the sample size and cluster structure.

---

## DECISION

**Key strengths:** Novel question, clean identification strategy, honest reporting of limitations, strong institutional knowledge, compelling size gradient.

**Critical weaknesses:** Result concentrated in one city, baseline specification not significant, RI does not reject null.

**DECISION: MINOR REVISION**
