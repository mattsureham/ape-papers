# Reply to Reviewers

**Paper:** Rockets Down, Feathers Up? Asymmetric Tax Pass-Through in Malaysia's GST-to-SST Transition (apep_0570)

We thank all three reviewers for thorough and constructive engagement with the paper. The reviews converge on several important concerns -- particularly the statistical fragility of the asymmetry claim, pre-trend violations, overweighting of the full-sample estimate, and insufficient inference for derived quantities. We have undertaken a substantial revision addressing each point. Below we respond point-by-point, grouped by reviewer.

---

## Reviewer 1 (GPT R1)

### 1A. Core DiD design not credible given pre-trend failures

> "The paper's own evidence shows that the key identifying assumption is violated... the 12-month pre-trend test still rejects at p = 0.011."

**Response:** We agree this is the paper's central empirical challenge and have revised to confront it more directly. We now cite Roth (2022) on pretest limitations and Rambachan and Roth (2023) on sensitivity under non-parallel trends. We clearly state that pre-trend F-tests reject at both 36-month and 12-month windows. The short-window specification is motivated as the preferred estimate, but we no longer claim it fully resolves the pre-trend concern. Instead, we present the short-window result as a local reduced-form estimate under a more credible but imperfect design.

### 1B. Control group is substantively problematic (zero-rated + exempt combined)

> "Group C combines zero-rated and exempt products. These are economically very different categories."

**Response:** We added a robustness check separating zero-rated controls (10 product classes) from exempt controls (5 product classes). Both subsamples show consistent negative coefficients for the GST removal effect, indicating results are not driven by one control subgroup.

### 1C. Treatment classification endogeneity concerns

> "Using post-treatment price movements to validate or potentially refine treatment assignment risks circularity."

**Response:** We revised the classification description to state that treatment assignment is "based entirely on the legal text of the relevant Acts, constructed ex ante without reference to post-2018 price movements." The prior language ("corroborated by observed price behavior") was misleading -- price patterns were consulted only as an ex post diagnostic and no reclassification was performed based on outcomes. This is now explicit.

### 1D. 2015 GST introduction contaminates identification

> "If the treatment group was selected precisely by tax status under the GST regime, then the 2015 introduction mechanically creates lasting divergence."

**Response:** We acknowledge this more forthrightly. The full-sample estimate is now explicitly labeled "descriptive rather than causal" and demoted from the headline findings. The paper is restructured to lead with the short-window (2017--2019) estimate as preferred. We discuss the 2015 introduction not as a nuisance but as the primary reason the full-sample specification fails to isolate the 2018 reform.

### 1E. DDD for SST reimposition -- promising but not convincing

> "The estimated reimposition coefficient is imprecise (0.038, SE 0.030)... not statistically distinguishable from zero."

**Response:** We added a formal Wald test of symmetry (chi-sq = 3.17, p = 0.075) and delta-method confidence intervals for the asymmetry ratio ([-0.16, 1.03]). We also report bootstrap inference for the DDD specification (999 replications; bootstrap SE = 0.031 vs. clustered SE = 0.030), confirming that the imprecision is genuine rather than an artifact of standard error computation. The asymmetry is now described as "suggestive" throughout, and we note explicitly that the reimposition coefficient is not significant at conventional levels (p > 0.10).

### 1F. Treatment timing -- anticipation concerns

> "Even limited late-May adjustment could contaminate the May/June comparison."

**Response:** We note the 16-day announcement-to-implementation window and discuss its implications, though we acknowledge that with monthly data we cannot fully rule out within-month anticipatory adjustment. We have not added higher-frequency data as none is available at this level of product disaggregation.

### 2A. Inference incomplete for pass-through rates and asymmetry ratios

> "The 55% pass-through estimate should have a confidence interval... the asymmetry ratio of 0.44 should have a confidence interval."

**Response:** We now report delta-method confidence intervals for the pass-through rate and for the asymmetry ratio ([-0.16, 1.03]). This makes the imprecision of the asymmetry finding transparent.

### 2B. Asymmetry claim statistically unsupported

> "There is no test that the ratio differs from 1... no test that upward and downward responses differ significantly."

**Response:** We added a formal Wald symmetry test (chi-sq = 3.17, p = 0.075). The null of equal-magnitude responses is not rejected at the 5% level. We revised all language from "demonstrated" asymmetry to "suggestive" asymmetry, and changed the title to a question form ("Rockets Down, Feathers Up?") to signal the tentative nature of the finding.

### 2C. Randomization inference is not a fix for violated parallel trends

> "RI can tell you that the observed assignment aligns with unusual differences... it does not establish that those differences are caused by the policy."

**Response:** We agree. We retain the RI results as supplementary evidence that the treatment-control contrast is unusual under random reassignment, but we no longer present RI as addressing the pre-trend concern. The text now clarifies that RI tests the sharpness of the cross-sectional pattern, not the validity of the identifying assumption.

### 2D. Small number of effective clusters in DDD

> "The DDD reimposition effect is identified off a much smaller subset, especially the 20 Group A classes."

**Response:** We added bootstrap inference for the DDD specification (999 replications). Bootstrap SE (0.031) is close to the clustered SE (0.030), suggesting cluster-robust inference is not misleadingly tight for this parameter.

### 3A--B. Robustness checks document fragility; placebo tests undermine the design

> "The most relevant robustness finding is that estimates are highly sensitive to window choice, and placebo dates are significant."

**Response:** We restructured the discussion of sensitivity. Placebo results are now presented as evidence against the long-panel DiD, motivating the short-window specification rather than serving as robustness support. The window sensitivity is discussed honestly as reflecting sensitivity to the pre-trend contamination window.

### 3C. Mechanism claims not separated from reduced form

> "The data do not identify among them."

**Response:** We explicitly label political salience and anti-profiteering enforcement as "hypotheses" and "conjectures" rather than established mechanisms. These are presented as candidate explanations consistent with the reduced-form patterns, not as tested channels.

### 3D. External validity and scope

> "Policy lessons should be scaled back substantially."

**Response:** We narrowed the policy implications, conditioning them explicitly on the identifying assumptions and the imprecision of the asymmetry estimate.

### 3E. Missing robustness exercises (separate controls, food exclusion, balanced panel, weighted regressions, etc.)

> "The paper would be much stronger with: separate zero-rated vs exempt controls..."

**Response:** We added the zero-rated vs. exempt control separation (point 1 on this list). The remaining suggestions (expenditure-weighted regressions, product-specific trends, donut specifications, SST-rate heterogeneity) are valuable and noted for future work, but were infeasible within the current revision given data limitations on CPI expenditure weights at the 4-digit level and insufficient within-group variation in SST rates for a credible heterogeneity analysis.

### 4C--D. Literature coverage

> "The paper should engage more directly with recent work on pre-trends and DiD sensitivity."

**Response:** We added Roth (2022) and Rambachan and Roth (2023) to the bibliography and cite both in the empirical strategy section when discussing pre-trend diagnostics and sensitivity.

### 5A--E. Overclaiming in abstract and introduction; inconsistency between preferred and asymmetry estimates

> "The abstract currently gives a clean-sounding causal result... That is too strong."

**Response:** The abstract, introduction, and conclusion have been revised. The short-window estimate leads as the preferred finding. The full-sample 130% pass-through is labeled descriptive. The asymmetry result is presented as suggestive evidence with its formal test statistics (Wald p = 0.075) and confidence interval reported. The title is now a question. The paper no longer claims to have "demonstrated" a reversal of Peltzman's rockets-and-feathers finding.

---

## Reviewer 2 (GPT R2)

### 1A--C. DiD identification fails; full-sample estimates should not carry causal weight; short-window still not fully convincing

> "This is a direct failure of the core identifying assumption... the full-sample estimate does not isolate the June 2018 GST zeroing."

**Response:** See responses to R1 points 1A and 1D above. The paper is restructured: the short-window estimate leads, the full-sample estimate is demoted to descriptive context, and pre-trend failures are acknowledged as central rather than peripheral.

### 1D. Control-group construction problematic; classification "validated against observed price behavior"

> "Using outcome behavior as validation is dangerous unless clearly separated from construction."

**Response:** See response to R1 point 1C. The language has been changed to make clear that classification is based entirely on legal texts and that price behavior was never used to reclassify products.

### 1E. DDD asymmetry design not compelling

> "The reimposition estimate is not statistically distinguishable from zero... the asymmetry ratio is built from coefficients from a specification with known pre-trend problems."

**Response:** See response to R1 point 1E. Formal symmetry test, delta-method CIs, and bootstrap inference are now reported. Asymmetry language is softened throughout.

### 1F. CPI collection timing limits interpretation

> "Monthly CPI is coarse for studying immediate pass-through."

**Response:** We have added a brief discussion of CPI collection mechanics, noting that Malaysia's Department of Statistics collects prices throughout the month. Since the GST zeroing took effect on June 1, 2018, the June CPI predominantly reflects post-reform prices. However, we temper "impact-effect" language given the monthly frequency.

### 2A--B. Clustered SEs; RI not a substitute for identification

> "For the DDD reimposition effect, effective identifying variation is much smaller... RI exercise permutes treatment labels... it does not solve nonparallel trends."

**Response:** See responses to R1 points 2C and 2D. Bootstrap inference added for the DDD. RI is repositioned as supplementary.

### 2C. Placebo tests weaken the design

> "This is central evidence that the main design is not valid unless restructured."

**Response:** Agreed and addressed. See response to R1 points 3A--B.

### 3A--C. Robustness section shows sensitivity; no alternative control strategy; no local design attempted

> "The large variation in magnitude is a warning sign."

**Response:** We added the zero-rated vs. exempt control separation. The window sensitivity is now presented honestly as reflecting the pre-trend contamination problem. A fully local discontinuity-in-time design is an important suggestion for future work but beyond the scope of the current revision given the monthly frequency of the data.

### 3D--E. Mechanism claims speculative; heterogeneity analysis not informative enough

> "The paper has no direct measure of enforcement intensity, market competition, media salience by category."

**Response:** Mechanism claims are now explicitly labeled as conjectures/hypotheses. We acknowledge the absence of direct enforcement or competition measures.

### 3F. Welfare calculations premature

> "They also use broad assumptions... without uncertainty propagation."

**Response:** The welfare discussion is retained but explicitly conditioned on the identifying assumptions and qualified as illustrative back-of-the-envelope calculations rather than precise estimates.

### 4A--B. Contribution not yet differentiated; missing econometric references

> "Literature coverage is mostly adequate on pass-through, but missing some econometric references."

**Response:** Roth (2022) and Rambachan and Roth (2023) have been added and cited. The contribution is reframed as suggestive evidence from a novel policy setting rather than definitive causal evidence overturning the rockets-and-feathers literature.

### 5A--D. Overclaiming throughout; 130% estimate not meaningful; asymmetry ratio not statistically validated

> "The abstract overstates both the removal and asymmetry findings."

**Response:** See response to R1 points 5A--E. All headline claims have been recalibrated.

---

## Reviewer 3 (Gemini)

### Parallel trends violation in short window

> "The joint F-test still rejects parallel trends even over a 12-month pre-period (p = 0.011)."

**Response:** This is now acknowledged clearly in the text. We cite Roth (2022) on the limitations of pre-trend testing and Rambachan and Roth (2023) on sensitivity under trend violations. The short-window specification is motivated by the visual flatness of the immediate pre-treatment coefficients and the institutional argument that the 2015 reform explains the longer-horizon divergence, but we no longer claim this fully resolves the identification concern.

### Statistical significance of asymmetry

> "The author should perform a formal test of the hypothesis that |beta_1| = |beta_2| and report the p-value. If the null of symmetry cannot be rejected, the title and framing must be softened."

**Response:** Done. We report a formal Wald test of symmetry (chi-sq = 3.17, p = 0.075). The null of symmetric pass-through is not rejected at the 5% level. The title has been changed to question form ("Rockets Down, Feathers Up?"), and all language throughout the paper has been softened from "demonstrated" to "suggestive."

### Tax instrument differences (GST multi-stage vs. SST single-stage)

> "The lower SST pass-through might simply reflect its narrower base or a different incidence along the supply chain rather than behavioral asymmetry."

**Response:** This is an important point. We have expanded the discussion of the GST/SST instrument differences, acknowledging that the single-stage SST is levied at the manufacturer/importer level rather than at each stage of the supply chain. This structural difference means the asymmetry ratio may partly reflect differences in tax instrument design rather than pure behavioral asymmetry in price adjustment. This caveat is now stated explicitly in the discussion section.

### Overclaiming in abstract and conclusion

> "Claiming a 'striking asymmetry' (p. 4) is aggressive given the lack of statistical significance for the upward adjustment."

**Response:** The phrase "striking asymmetry" has been removed. The abstract, introduction, and conclusion now present the asymmetry as suggestive evidence, report the Wald test p-value and delta-method confidence interval, and note that the reimposition coefficient is not individually significant.

### Inconsistency between preferred removal estimate and asymmetry ratio

> "The 'preferred' removal estimate is -0.032 (55% pass-through), but the asymmetry ratio is calculated using the full-sample DDD estimate (-0.087)."

**Response:** This tension is now addressed directly. The paper leads with the short-window estimate as the preferred causal finding for GST removal. The asymmetry ratio, which necessarily relies on the full-sample DDD (since the short-window specification does not have sufficient post-September 2018 variation for DDD estimation), is explicitly flagged as resting on a less credible specification. The contribution is reframed accordingly: credible evidence of immediate GST-removal pass-through, with suggestive but imprecise evidence of asymmetry.

---

## Summary of Key Changes

| Change | Sections Affected |
|--------|-------------------|
| Formal Wald symmetry test (chi-sq = 3.17, p = 0.075) | Results, Tables |
| Delta-method CIs for pass-through rate and asymmetry ratio [-0.16, 1.03] | Results, Tables |
| Bootstrap inference for DDD (999 reps, SE = 0.031) | Results, Appendix |
| Language softened from "demonstrated" to "suggestive" throughout | Abstract, Intro, Results, Conclusion |
| Title changed to question form | Title |
| Full-sample 130% pass-through demoted to descriptive | Abstract, Results |
| Short-window estimate repositioned as preferred | Abstract, Intro, Results |
| Treatment classification clarified as ex ante, legally grounded | Data section |
| Zero-rated vs. exempt control separation | Robustness |
| Mechanism claims labeled as hypotheses/conjectures | Discussion |
| Added Roth (2022), Rambachan and Roth (2023) | References, Empirical Strategy |
| Pre-trend failures acknowledged as central identification challenge | Empirical Strategy, Diagnostics |
