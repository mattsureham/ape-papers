# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T13:02:13.200468
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 21855 in / 4849 out
**Response SHA256:** bb3ddcf10ac08601

---

This paper studies labor-market spillovers from staggered state prohibition using linked full-count census panels and county-level pre-prohibition alcohol employment shares. The topic is interesting, the data effort is substantial, and the paper is unusually candid about an important threat to identification. That candor is a strength. But for a top general-interest journal or AEJ: Economic Policy, the current design does not support the paper’s central causal or quasi-causal claims, and several inference and interpretation issues remain unresolved. In its current form, I do not think the paper is publication-ready.

## 1. Identification and empirical design

### Core identification problem

The paper’s main design is an interaction of county alcohol share and an indicator for whether a state adopted prohibition by 1919, estimated on decadal changes in outcomes (Section 4, equation (1)). This is not a clean difference-in-differences design in the modern sense. It is closer to a cross-sectional exposure design with one pre/post difference, where treatment intensity is partly determined by preexisting local industrial structure and where the “treated” indicator collapses substantial timing variation.

The central identifying assumption is that, absent prohibition, high-alcohol-share counties in eventually dry states would have had similar occupational-change trends to comparable counties in wet states, conditional on controls and region fixed effects (Section 4.1). The paper’s own earlier-period exercise strongly undermines this assumption. In the 1900–1910 panel, the analogous coefficient is 5.34 (SE 1.93), much larger than the main 1910–1920 estimate of 0.80 (Section 4.2; Appendix Table A1). Even granting the author’s caveat that five states were partly treated during 1907–1909, this is not a minor nuisance result. It indicates that the interaction of future treatment status and alcohol concentration was already strongly associated with occupational upgrading before the main window.

That issue is fundamental, not ancillary. Once this earlier differential trend exists, the paper cannot treat the 1910–1920 estimate as even moderately credible evidence of a prohibition effect without a substantially stronger design.

### Treatment timing is not coherently exploited

The paper has staggered policy adoption across 1907–1919, yet the main specification reduces this to a binary Treated indicator for all states adopting by 1919 (Section 4.1). That throws away the main source of plausibly useful variation. More importantly:

- Five states were already treated before the 1910 baseline, so the 1910 alcohol share is post-treatment for them (Section 4.2).
- Twenty-five treated states adopted between 1910 and 1919, so exposure length differs materially within the “treated” group.
- The control group becomes treated nationally in 1920, making the 1920–1930 analysis a persistence comparison rather than treatment-versus-control (Section 5.5).

The paper acknowledges these issues, but they are not repaired by acknowledgment. A top-journal paper would need to exploit timing in a principled way or convincingly justify why a collapsed treated indicator identifies a meaningful estimand.

### Post-treatment exposure measurement is a serious design flaw

For the five early-adopting states, the exposure variable is measured after treatment in 1910 (Section 4.2). The manuscript argues this likely attenuates estimates. That is possible, but not sufficient. Post-treatment measurement can do more than attenuate: it can change the meaning of the treatment-intensity variable differentially across treated cohorts. If saloon closure compressed cross-county variation in alcohol share, then “high exposure” is measured with policy-induced error in exactly the treated states most important for timing variation. This is a conceptual flaw in the design.

### Within-state variation is overstated

The paper repeatedly says it “exploits within-state variation in county-level alcohol industry concentration” (e.g., Introduction; Section 3.4). But the preferred specification in Table 2, column 3 includes region fixed effects, not state fixed effects. Identification is therefore not primarily within-state; it still relies substantially on cross-state contrasts between dry and wet states with very different social, political, and economic trajectories. The paper correctly notes that the state-FE specification is not the treatment effect, but that admission weakens the claim that within-state variation underpins causal interpretation.

### Omitted local trends and confounders

High alcohol-share counties in 1910 were likely more urban, more immigrant, more industrial, more connected to transport networks, and on different occupational trajectories independent of prohibition. Individual controls do not solve county-level or state-by-county structural confounding. The design lacks:

- county or commuting-zone controls for baseline urbanization/industrial composition,
- state-specific trends,
- interactions of baseline county characteristics with treatment timing,
- any attempt to balance treated and control counties on observables,
- any design addressing the possibility that alcohol share proxies for urban commercial density rather than exposure to saloons per se.

This is especially problematic because the paper’s interpretation leans heavily on urban labor-market reallocation and social infrastructure mechanisms.

### Long-run design is not causally interpretable

The 1920–1930 analysis (Section 5.5; Table 5) uses 1910 alcohol share × pre-1920 dry-state status to measure “differential persistence” after national prohibition begins. This is not a treatment effect in any standard sense, because by 1920 all states are treated. The coefficient may capture any number of preexisting differences in trajectories between previously dry and wet states, differential recovery from WWI, urban-rural 1920s growth, immigrant assimilation, or selective linkage/survival. The manuscript states this cautiously in places, but elsewhere describes the reversal as the paper’s “most distinctive finding” and uses it to motivate social-infrastructure interpretations. That is overreach relative to the design.

## 2. Inference and statistical validity

### Small-cluster inference is handled partly, but not fully convincingly

The paper clusters at the state level, which is appropriate given policy assignment, and recognizes the limits of asymptotics with 45 clusters (Section 6). Reporting randomization inference is good practice. However:

- The preferred estimate has clustered p = 0.004 but RI p = 0.098 (Table 2; Section 6). Those do not tell the same substantive story. For a paper of this ambition, the more credible finite-sample inference is the randomization-based result, which is only marginal at 10%.
- The wild cluster bootstrap p = 0.002 is hard to reconcile with the RI p = 0.098 in a way that the paper does not explain. Given the small number of clusters and the nonrandom treatment assignment, RI seems especially relevant here.
- If treatment was not randomly assigned across states, permutation of state labels may not correspond to a meaningful sharp null experiment unless restricted by covariate balance, region, or adoption propensity.

The paper should not foreground conventional clustered significance while relegating RI to a cautionary note. The more conservative inference should lead the presentation.

### Sample sizes are reported, but comparability across panels is not adequately addressed

The paper reports large samples in each linked panel and subgroup tables. However, the causal interpretation depends heavily on comparability across the 1900–1910, 1910–1920, and 1920–1930 linked samples. Those samples differ mechanically due to linkage, survival, migration, and labor-force attachment. The paper mentions selection into linkage (Sections 3.1 and 7.4), but there is no analysis of whether treatment intensity predicts linkage or survival into later panels. Since the long-run “reversal” is central, differential composition across linked decades is a first-order concern.

### Binary outcomes estimated with LPM are acceptable, but interpretation is sloppy

Self-employment and occupation switching are modeled as 0/1 outcomes, apparently by OLS. That is fine if presented as a linear probability model, but some magnitudes seem implausibly large relative to the scaling of treatment:

- A coefficient of -0.061 per one percentage-point increase in alcohol share is described as a 6.1 percentage-point reduction in self-employment (Section 5.2). Given the underlying exposure distribution, that may still be plausible, but the paper should benchmark this relative to baseline self-employment rates and typical variation in county alcohol share. Otherwise readers cannot tell whether implied changes are modest or enormous.
- Similar issues arise for occupation switching.

### Inference for subgroup differences is incomplete

The paper reports separate subgroup regressions for immigrants, natives, low/high occupational score, etc. (Table 4) and then interprets differences in point estimates as meaningful. But there are no formal tests of equality across subgroup coefficients. For example, the claim that immigrant effects are “three times larger” than native effects should be backed by an interaction model or explicit p-value for the difference.

## 3. Robustness and alternative explanations

### Robustness checks do not solve the main design problem

The placebo in zero-alcohol counties, leave-one-out analysis, alternative exposure measures, and non-South subsample are all useful descriptive checks (Section 6). But none addresses the central concern that high-alcohol-share areas in dry states were already on different trajectories.

The zero-exposure placebo is especially weak as validation. If the identification concern is that high-exposure areas in eventually dry states differ from low-exposure areas in eventually wet states, a null among zero-exposure counties is not informative. The threat is about differential trends along the intensive margin of alcohol exposure, not about a pure treated-state main effect.

### Alternative explanations remain more plausible than the preferred mechanism story

The paper’s favored interpretation is that short-run upgrading reflects resource reallocation and long-run decline reflects destruction of saloon-based social infrastructure. That is an interesting hypothesis, but the design does not distinguish it from several simpler alternatives:

1. **Urbanization and industrial convergence**  
   High-alcohol-share counties are likely urban and commercially dynamic. Differential occupational upgrading could reflect those trajectories rather than prohibition.

2. **Immigrant assimilation and compositional mobility**  
   The larger immigrant coefficient may arise because immigrant-heavy urban places had steeper occupational mobility trends generally.

3. **Mechanical mean reversion and conditioning on baseline OCCSCORE**  
   The sign reversal between columns (2) and (3) of Table 2 after adding baseline OCCSCORE is striking. The paper attributes this to regression to the mean, but this needs more scrutiny. Conditioning on lagged outcomes in change-score regressions can induce nontrivial statistical artifacts, especially with noisy occupational coding and linked data error.

4. **WWI and 1920s sectoral shocks**  
   Manufacturing and retail gains from 1910 to 1920 could reflect wartime demand or urban sectoral changes correlated with alcohol presence and dry-state politics. The long-run 1920s reversal could likewise reflect postwar adjustment and differential urban growth patterns.

5. **Selective linkage and mortality**  
   Alcohol-exposed places may differ in migration, mortality, or match quality across decades.

### Mechanism claims are not distinguished from reduced-form heterogeneity

The paper often phrases subgroup patterns as “consistent with” mechanisms, which is appropriate. But elsewhere it slides into stronger language: “Together, the mechanism results paint a picture of creative destruction” (Section 5.2). They do not. They show heterogeneous reduced-form associations by industry and outcome under the same identification weaknesses as the main effect. Since the supply-chain result actually goes opposite the simple upstream-harm story, the mechanism discussion reads as somewhat post hoc.

### External validity is bounded, but not cleanly framed

The paper’s broader implications for modern industry destruction are suggestive, but historical prohibition is a highly unusual policy shock with strong moral, political, ethnic, and urban-rural dimensions. The discussion section gestures at modern policy relevance, but the paper should be clearer that its evidence is context-specific and not obviously transportable to current closures of mines, factories, or fossil-fuel sectors.

## 4. Contribution and literature positioning

### Substantive contribution is potentially interesting

The paper’s strongest contribution is not a credible causal estimate, but the assembly of linked historical microdata to study spillovers of a major institutional shock on non-alcohol workers. That is a worthwhile question. The descriptive heterogeneity and dynamic patterns may be of interest to economic historians.

### But the contribution is not yet differentiated enough for a top general-interest outlet

For AER/QJE/JPE/ReStud/Ecta/AEJ:EP, the paper needs either:
- a much sharper design that can support a causal claim, or
- a distinctly new dataset/fact with overwhelming descriptive importance.

At present it offers suggestive patterns under a design the paper itself concedes is compromised. That is below the bar.

### Literature gaps to address

The paper cites several relevant DiD papers, but the methods positioning is incomplete for a design that mixes staggered adoption with continuous exposure. The author should engage more directly with literatures on:
- continuous-treatment DiD / dose-response DiD,
- shift-share identification concerns,
- historical linked-data selection and representativeness.

Concrete citations worth considering:

- de Chaisemartin, C., and D’Haultfoeuille, X. (2020, 2022) on two-way fixed effects and heterogeneous treatment, including non-binary settings.
- Borusyak, Jaravel, and Spiess (2024) on imputation/event-study approaches for staggered adoption.
- Adao, Kolesar, and Morales (2019) for shift-share inference concerns, since the paper itself notes the design is “closer in spirit to shift-share.”
- Goldsmith-Pinkham, Sorkin, and Swift (2020) on shift-share designs and where identifying variation comes from.
- Recent work in economic history using linked census panels that explicitly addresses linkage selection, e.g., Abramitzky, Boustan, and Eriksson beyond the cited general references.

On the policy domain side, the paper may also need closer engagement with historical work on local option laws and saloon geography, since statewide prohibition may partly proxy preexisting anti-urban politics rather than an exogenous industry shutdown.

## 5. Results interpretation and claim calibration

### The paper improves on calibration in the abstract, but still overstates some conclusions

To its credit, the abstract now acknowledges the pre-trend and describes the contribution as “descriptive evidence.” That is appropriate. However, the main text still goes beyond that in several places.

Examples:

- “prohibition induced labor market churning” (Section 5.2) is too causal.
- “Together, the mechanism results paint a picture of creative destruction” (Section 5.2) is too strong.
- “The most striking finding of this paper concerns the long-run dynamics” (Section 5.5) suggests a level of identification not warranted.
- “The reversal suggests that something changed between the two periods” (Section 6) is true, but the paper then gives too much prominence to social infrastructure destruction relative to many other plausible explanations.

### Magnitudes need better discipline

The paper repeatedly translates coefficients into economically meaningful effects, but sometimes without enough context. For a top journal, I would want:

- treatment effect benchmarks using realistic percentiles of county alcohol share,
- implied effect sizes relative to baseline outcome levels for binary outcomes,
- careful explanation of the role of conditioning on baseline OCCSCORE in producing the sign change,
- a more restrained approach to the long-run reversal magnitude, given panel composition issues.

### Some internal contradictions remain

The paper says the main contribution lies in decomposition, heterogeneity, and dynamic reversal rather than the level of the main coefficient. But all of those analyses use the same identification strategy and are equally vulnerable to the differential-trend concern. If the design does not identify the average effect, it also does not cleanly identify subgroup effects or mechanisms. Those analyses may still be informative descriptively, but the text sometimes treats them as structurally revealing rather than descriptive.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Fundamental redesign of identification
- **Issue:** The current treated-state × alcohol-share design is undermined by strong earlier differential trends and post-treatment exposure measurement for early adopters.
- **Why it matters:** Without a credible identification strategy, the paper cannot support causal claims, and even descriptive claims about prohibition-specific effects are weak.
- **Concrete fix:** Rebuild the design around treatment timing. At minimum, restrict to states untreated at the 1910 baseline and exploit adoption timing between 1910 and 1919 using cohort-specific exposure. If only decadal outcomes are available, define treatment by exposure duration between censuses more cleanly and justify the estimand. Better still, move to repeated cross-sections or county-level annual/intercensal data if possible.

#### 2. Remove or sharply recast causal language throughout
- **Issue:** The text alternates between caution and causal phrasing.
- **Why it matters:** The current evidence does not support causal mechanism claims.
- **Concrete fix:** Reframe the paper consistently as descriptive unless and until identification is materially improved. Every “induced,” “effect,” or mechanism statement should be audited for whether it survives the pre-trend problem.

#### 3. Address baseline differential trends directly, not rhetorically
- **Issue:** The 1900–1910 result is treated as a caveat, but the analysis stops there.
- **Why it matters:** This is the central empirical challenge.
- **Concrete fix:** Implement a more systematic pre-period analysis using untreated cohorts only, or show whether the result survives controlling for county urbanization, industrial composition, immigrant share, manufacturing share, and their interactions with treatment status. If possible, estimate specifications that partial out baseline county characteristics and state-specific trends.

#### 4. Deal with post-treatment measurement of alcohol share
- **Issue:** Exposure is measured in 1910 for states already dry by then.
- **Why it matters:** This compromises treatment-intensity measurement.
- **Concrete fix:** Either exclude pre-1910 adopters from the main design or construct exposure from pre-treatment data for those states. If 1900 exposure is noisy, show sensitivity to both approaches and make one of them the main specification.

#### 5. Reassess the 1920–1930 analysis
- **Issue:** The long-run “reversal” is not identified as a treatment effect once national prohibition starts.
- **Why it matters:** This is currently presented as a headline result.
- **Concrete fix:** Recast it explicitly as a descriptive persistence pattern. Test whether treatment predicts linkage into the 1920–1930 sample. If possible, compare formerly early-dry vs late-dry states by exposure duration, rather than dry-by-1919 vs wet-until-1920.

### 2. High-value improvements

#### 6. Formal tests for subgroup differences
- **Issue:** Heterogeneity claims rely on comparing separate regressions.
- **Why it matters:** Without interaction tests, statements about larger effects across groups are not statistically grounded.
- **Concrete fix:** Estimate pooled models with interaction terms and report p-values for differences, especially immigrant vs native and high- vs low-OCCSCORE.

#### 7. Strengthen controls for local structure
- **Issue:** County alcohol share likely proxies for urban and industrial characteristics.
- **Why it matters:** This is a major confounding channel.
- **Concrete fix:** Add baseline county controls and interactions: urban share, manufacturing share, population density, immigrant share, retail share, perhaps county size bins. Ideally saturate with state-by-baseline-characteristic controls.

#### 8. Clarify the role of lagged outcome control
- **Issue:** The main result flips sign when adding baseline OCCSCORE.
- **Why it matters:** This could reflect more than “regression to the mean.”
- **Concrete fix:** Show levels, changes, and ANCOVA-style specifications side by side; discuss implications of measurement error in baseline OCCSCORE; show robustness to coarser occupation categories or rank outcomes.

#### 9. Probe linkage selection
- **Issue:** Differential linkage may bias comparisons across space and time.
- **Why it matters:** Linked historical panels are not random samples.
- **Concrete fix:** Report whether treatment intensity predicts successful linkage, survival to next census, or inclusion in long-run panels. Consider inverse-probability reweighting using observables from the base census.

#### 10. Improve finite-sample inference discussion
- **Issue:** RI and clustered/bootstrap inference tell different stories.
- **Why it matters:** The strength of evidence is currently overstated.
- **Concrete fix:** Put RI front and center for headline estimates; explain permutation scheme carefully; consider restricted randomization within regions or adoption-propensity strata.

### 3. Optional polish

#### 11. Tighten the estimand and terminology
- **Issue:** The paper refers interchangeably to DiD, treatment intensity, shift-share spirit, and differential persistence.
- **Why it matters:** Precision would help readers understand what is and is not identified.
- **Concrete fix:** Define one estimand for each analysis and maintain that terminology consistently.

#### 12. Calibrate binary-outcome magnitudes better
- **Issue:** Some implied percentage-point changes are hard to interpret.
- **Why it matters:** Readers need scale.
- **Concrete fix:** Report baseline means, interquartile-range treatment contrasts, and implied changes at realistic exposure levels.

#### 13. Deepen historical validation of the exposure proxy
- **Issue:** IND1950 = 869 may include non-saloon establishments.
- **Why it matters:** The policy relevance depends on actual alcohol exposure.
- **Concrete fix:** Provide validation against city directories, license data, brewery maps, or narrower occupational proxies where possible.

## 7. Overall assessment

### Key strengths
- Ambitious use of linked full-count census data.
- Interesting and potentially important question about spillovers to non-targeted workers.
- Commendable transparency about the pre-trend problem.
- Rich descriptive heterogeneity that may be valuable to economic historians.

### Critical weaknesses
- Identification is not credible for the stated causal or quasi-causal interpretation.
- The main estimate is directly undermined by large earlier differential trends.
- Exposure is measured post-treatment for early adopters.
- The staggered policy timing is not exploited in a principled way.
- The 1920–1930 “reversal” is not causally interpretable.
- Mechanism and subgroup claims inherit the same identification problems.

### Publishability after revision
As written, this is not close to publication-ready for a top general-interest journal or AEJ: Economic Policy. I do think there may be a publishable historical labor-market paper here, but only after major redesign. The likely path is to reposition the paper as a descriptive economic-history study unless the author can develop a materially sharper design that addresses timing, pre-trends, and exposure measurement. That is more than a routine revision.

DECISION: REJECT AND RESUBMIT