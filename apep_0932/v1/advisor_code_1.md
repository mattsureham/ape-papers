# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T15:47:49.872357

---

**Idea Fidelity**

The paper faithfully follows the original idea manifest. It exploits the IPUMS MLP v2 crosswalk to construct an individual-level 1920–1940 panel, merges in Fishback et al. county New Deal spending, and targets the question of whether New Deal work relief widened Black–White occupational mobility gaps within counties. The empirical strategy mirrors the proposed difference-in-difference-in-differences, and the analysis concentrates on the same dataset (men aged 18–55 in 1930, OCCSCORE change, WPA/FERA per capita spending). The additional emphasis on the South versus non-South heterogeneity, wage and migration outcomes, and pre-trend validation also align with the manifest’s suggested robustness checks. Thus, the paper delivers the promised identification approach and research question.

---

**Summary**

The paper constructs an unprecedented linked panel of 11 million men across the 1920, 1930, and 1940 censuses and merges it with county-level New Deal spending. Using a triple-difference specification (race × county spending × pre/post) with county and occupation fixed effects, it finds that higher New Deal spending counties saw larger Black–White occupational mobility gaps—an effect driven almost entirely by Southern counties. The “gatekeeper’s dividend” interpretation is supported by dose-response patterns, robustness checks, and divergent wage versus occupational findings.

---

**Essential Points**

1. **Pre-trend concerns weaken the identifying assumption.** The 1920–1930 interaction coefficient is nearly 60% of the magnitude of the 1930–1940 effect and, while statistically insignificant, non-trivially large. Given the continuous nature of the spending variable, the pre-trend suggests that counties with higher later New Deal spending already exhibited differential racial occupational dynamics. The paper acknowledges this briefly but needs to more rigorously assess whether the post–pre comparison truly isolates the treatment. Possible approaches: (a) show that the spending variable is orthogonal to trends conditional on observed county characteristics (e.g., 1920–1930 occupational change interacted with covariates); (b) instrument New Deal spending with predetermined determinants (political representation, relief offers) to isolate exogenous variation; (c) regress the pre-period interaction on future spending to test for predictive power. Without such work, causal interpretation remains tenuous.

2. **Interpretation of OCCSCORE changes conditional on initial occupation requires clarification.** The main specification includes 1930 occupation fixed effects, so the estimated coefficient captures differential 1940 outcomes for Black versus white men starting from the *same* occupation. This implicitly compares Black and white workers who, in 1930, held identical occupation codes—effectively a within-occupation matching. However, the paper’s narrative focuses on occupational mobility into higher-status roles, which may involve transitions across occupations. Since the 1930 occupation FE absorb initial occupational composition, the estimate may reflect differences in volatility or within-occupation drift rather than upward mobility. The authors should (a) explicate what exactly their coefficient captures—is it the probability of moving up within the same OCCSCORE bracket, or a trajectory that is independent of where one started? (b) Provide supplemental regressions where the outcome is 1940 OCCSCORE (not change) with 1930 OCCSCORE included as covariate, or a transition matrix, to clarify the movement story. (c) Examine whether the gatekeeper effect appears in upward transitions explicitly (e.g., binary indicator of moving into a higher decile) rather than in the continuous OCCSCORE change.

3. **Mechanism claims need more grounding.** The “gatekeeper’s dividend” interpretation is plausible but currently relies on suggestive patterns (Southern focus, wage vs occupational divergence). However, there is little direct evidence on how local administrators assigned Black workers or what occupations they were concentrated in post–New Deal. The mechanism would be strengthened by (a) a descriptive tabulation of occupational transitions for Black and white men in high-spending Southern counties—e.g., the share of WPA-type occupations (construction, maintenance) versus supervisory roles; (b) evidence that high-spending counties hired more whites into upward-facing occupations relative to Blacks; (c) linkage to stay-on-program indicators (e.g., whether men listed WPA employment in 1940) if available. Without such grounding, the claim of channeling into low-status WPA jobs remains speculative.

If these essential issues are not addressed, the paper’s causal claim and interpretation remain in doubt. However, each concern can be tractably mitigated with additional analysis.

---

**Suggestions**

- **Strengthen the pre-trend analysis.** The 1920–1930 coefficient deserves further attention. Consider estimating the same specification for 1910–1920 (if linkable) or for other pre-New Deal outcomes (e.g., changes in farm/nonfarm status) to see whether the pattern persists. Alternatively, show that the interaction is zero when using as “treatment” a placebo spending variable from a later period—this would support the notion that the actual New Deal spending is the driver. Another approach is to estimate the model on the subset of counties whose spending quintile rank does not change much between 1930 and 1940, to see whether the effect survives.

- **Elaborate on the outcome scale and interpretation.** Since the outcome is a change in OCCSCORE conditional on occupation fixed effects, consider presenting the residualized OCCSCORE change by race and spending tercile to visualize the disparities. Adding figures that plot the estimated treatment effect across quantiles of initial OCCSCORE would help readers grasp the substantive magnitude. Also explain how to interpret 0.18 points—does it move someone like a Black carpenter less toward a white foreman’s score? Consider converting the effect into percentiles or occupational categories.

- **Explore additional outcomes or mediators.** Given that wage income increases for Black men but occupational status declines, the paper could dig deeper into this divergence. Are wages rising because Black workers were disproportionately in WPA-funded construction jobs whose pay was high relative to their prior occupations? If WPA occupation codes can be inferred, compare wage gains by occupation type. The migration result is already suggestive—expanding on it could clarify whether work relief anchored Black workers spatially, contributing to occupational stagnation.

- **Contextualize the county spending variable.** Since the treatment is continuous standardized spending, clarify whether this primarily reflects WPA intensity, agricultural relief, or other FERA programs. If possible, separate WPA spending from other grants to show which component drives the result. Presenting a map or histogram of spending intensity across the South versus non-South could help readers understand whether the distribution differs meaningfully by region.

- **Discuss general equilibrium concerns.** The counterfactual of high spending without racial gatekeeping implies that occupational gaps would have narrowed. But it is worth reflecting on how local labor markets adjusted: did increased WPA hiring for whites crowd out some private-sector opportunities for Blacks? Were there spillovers that could affect the estimated differential? Even a short discussion of these dynamics would enrich the policy implications.

- **Clarify the role of migration and sample selection.** The linked panel necessarily excludes individuals who could not be tracked across censuses. Explain whether differential linkage rates by race or region might bias the results—e.g., if high-spending Southern counties had lower linkage for Black men (due to migration), how does that influence the estimated gap? Present linkage rates by race and spending quintile to reassure readers.

- **Expand on the “dose-response” exploration.** The quintile results are compelling. Complement them with a binned scatterplot or a smoothing spline that plots the estimated interaction across continuous spending levels. That visualization, particularly if shown separately for the South, would underscore the claimed monotonicity.

- **Improve robustness to alternative specifications.** For example, include models that control for county-level changes in industrial composition or unemployment between 1930 and 1940, since these may correlate with both spending and occupational mobility. Alternatively, instrument spending with lagged unemployment (pre-New Deal) to isolate exogenous shocks.

- **Make the mechanism discussion more concrete.** The “gatekeeper’s dividend” narrative could be strengthened with archival evidence, quotes, or citations that directly link Southern WPA administrators’ choices to occupational stratification. If such direct evidence is scarce, frame the mechanism as a suggestive interpretation rather than a definitive conclusion.

- **Consider gender.** Although the main sample focuses on men, the placebo exercise uses women and finds a large positive effect (column 2). Expanding briefly on why women show a positive coefficient—does this reflect that higher-spending counties benefitted women differently—could offer additional insights.

- **Clarify data construction.** Provide an appendix figure or table showing how many individuals are lost at each linkage step (1920–1930, 1930–1940) by race and region. This transparency would help readers assess representativeness.

These suggestions aim to enhance clarity, strengthen causal claims, and provide richer context for the paper’s important findings.
