# Internal Review — Round 1

**Paper:** Protecting Landscapes, Punishing Renters? (apep_0567)
**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-10

## Verdict: MINOR REVISION

## Strengths

1. **Clean identification setting.** The 20% threshold is arbitrary (set by initiative sponsors, not economic analysis), and the surprise vote outcome limits anticipation. Three decades of pre-treatment data enable robust parallel trends testing.

2. **Compelling narrative.** The paper opens with a vivid hook (nurse in Verbier), weaves through a clear causal chain (construction ban → reduced supply → tighter rental markets → population decline), and closes with actionable policy lessons.

3. **Honest treatment of null RDD.** The paper does not oversell the RDD results — it presents the null finding transparently, explains why the RDD is underpowered (small effective sample near cutoff, dose-response means effects are weakest at threshold), and relies on the DiD as the primary identification.

4. **Strong robustness battery.** RI p < 0.001, leave-one-canton-out stability, placebo timing tests, donut DiD, continuous treatment, alternative timing all support the main finding.

5. **Dose-response evidence.** The treatment intensity heterogeneity (high-intensity -0.58 vs low-intensity -0.18 pp) is the single most compelling piece of evidence for the causal mechanism.

## Concerns

1. **Pre-trend visual inspection.** The event study (Figure 2) shows some non-zero pre-treatment coefficients, particularly around t=-9 and t=-8. While individually these might be noise, a formal pre-trends test (joint F-test of all pre-treatment coefficients = 0) should be reported.

2. **Population effect magnitude.** The -0.118 log point estimate (≈12%) is very large. This means treated municipalities lost 12% of their population relative to controls over the post-treatment period. The paper should discuss whether this is cumulative, whether it reflects level vs. growth effects, and compare to Hilber & Vermeulen (2020) magnitudes.

3. **Wild cluster bootstrap marginal.** The WCB p-value of 0.11 is honestly reported. The paper could strengthen this by noting that canton-level clustering may be too conservative if within-canton treatment effect heterogeneity is large (which the intensity results suggest).

4. **Employment data starts 2011.** Only 2 pre-treatment years for employment outcomes. The mechanism evidence from sectoral employment thus rests on a shorter pre-treatment period. This limitation should be explicitly noted.

5. **Missing Callaway-Sant'Anna event study figure.** The text mentions CS-DiD but no figure is shown. Either add a CS-DiD event study to the appendix or remove the claim.

## Minor Issues

- The conceptual framework section could be shortened by ~1 page without loss
- Some figure captions still reference 1990-2023 when data actually runs 1995-2025
- The SDE table in the appendix now correctly uses log-space SDs

## Recommendation

The paper is publication-ready with minor revisions. The core identification is credible, the results are honestly presented, and the policy implications are well-drawn. Proceed to external review.
