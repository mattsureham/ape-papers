# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-04-02T00:36:05.677465

---

## 1. Idea Fidelity

The submitted paper does **not** ultimately pursue the core empirical question in the manifest. The original idea was about whether *Alice* induced **small-entity abandonment, exit from patenting, and recomposition of innovation**, using application-level data from PatEx plus Office Actions and a within-TC continuous-treatment DiD based on art-unit-specific increases in §101 rejection intensity. By contrast, the paper studies **art-unit-quarter rejection rates**, not abandonment or exit, and does not distinguish small from large entities. The distributional and innovation-system questions that made the original idea especially interesting are therefore absent.

Relatedly, the identification strategy in the paper departs in a consequential way from the manifest. The intended treatment was art-unit exposure to *Alice*-driven eligibility tightening, to be used for downstream outcomes such as abandonment. In the current draft, treatment is defined as the **pre/post change in the §101 rejection rate**, and the main outcome is often the **§101 rejection rate itself**. That makes the treatment mechanically tied to the outcome and weakens any causal interpretation substantially. So while the paper preserves the broad setting—within-TC heterogeneity after *Alice*—it misses the most compelling research question and the most credible use of the shock.

## 2. Summary

This paper documents substantial heterogeneity across TC 3600 art units in the rise of §101 eligibility rejections following *Alice*. Its central claim is that *Alice* created “eligibility traps” within a single technology center, with some art units experiencing near-prohibitive rejection rates while others changed little.

The descriptive pattern is interesting and potentially important. However, the current empirical design does not credibly identify a causal effect because treatment is constructed from the same post-*Alice* change the paper seeks to explain, and the analysis remains too close to restating the shock rather than estimating its consequences.

## 3. Essential Points

1. **The main specification is mechanically circular.**  
   The paper defines `AliceShock_a` as the art unit’s pre/post change in §101 rejection rates, then estimates the effect of `AliceShock_a × Post_t` on the §101 rejection rate. This is not a valid DiD design: the treatment intensity is itself built from the post-period realization of the dependent variable. Unsurprisingly, units with larger post-period increases in §101 rates are estimated to have larger post-period increases in §101 rates. This is the paper’s central problem and must be fixed before any causal claims can be taken seriously.

2. **The empirical outcome does not match the substantive research question.**  
   Even on its own terms, the paper asks whether *Alice* “reshaped patent prosecution,” but the results mostly show that §101 rejections rose more in some art units than in others. That is a useful descriptive fact, but not yet an economically meaningful consequence. The stronger question—also the one in the manifest—is whether this doctrinal change altered abandonment, grant probabilities, prosecution duration, applicant exit, or differential impacts on small entities. Without such outcomes, the paper is much closer to a descriptive note than an AER: Insights-style causal paper.

3. **The identification argument against confounding is incomplete.**  
   The paper repeatedly argues that within-TC variation isolates quasi-exogenous doctrine exposure. But art units differ systematically in technology composition, claim type, applicant sophistication, examiner assignment, and pre-*Alice* exposure to abstract-idea concerns. Those differences are not nuisances; they are likely the very reason some units saw larger §101 changes. Quarter fixed effects do not solve this. The paper needs a design where treatment is predetermined or instrumented, or it needs to retreat to a descriptive interpretation.

## 4. Suggestions

The paper has a real descriptive contribution, and I think there is a promising paper here, but it likely needs to be re-centered around outcomes and a cleaner source of variation.

**1. Rebuild the design around downstream outcomes rather than rejection rates.**  
The most natural fix is to return to the original idea: use art-unit-specific *Alice* exposure to study **application abandonment**, **allowance/grant**, **time to disposal**, **RCE/refiling behavior**, and ideally **applicant exit from future patenting**. These are economically meaningful outcomes and are not mechanically embedded in the treatment definition. If you can bring in small-entity indicators, the paper becomes much more compelling: a clean question is whether *Alice* disproportionately pushed small entities out of the prosecution process in highly exposed art units.

Concretely, I would encourage constructing an application-level panel or disposal-level dataset with:
- filing cohort,
- art unit at first action or first substantive action,
- small/large/micro entity status,
- abandonment and grant outcomes,
- prosecution duration,
- future application activity by applicant.

Then estimate whether applications routed to more *Alice*-exposed art units after June 2014 became more likely to be abandoned, especially among small entities. That would align much better with the motivating policy question.

**2. Use a treatment measure that is not defined by the post-period realization of the dependent variable.**  
At minimum, the paper needs a treatment proxy that is not “the change in §101 rates” when the outcome is §101 rates. Several possibilities:

- **Predetermined technological exposure**: construct an art unit’s pre-*Alice* share of applications in clearly exposed domains (e.g., business methods, finance, e-commerce, software claims). This is not perfect, but it is conceptually different from the realized post-*Alice* rejection rate.
- **Pre-*Alice* textual exposure**: use pre-2014 claim language associated with abstract-idea vulnerability, measured from application texts or CPC/USPC classes.
- **Examiner-level propensity**: if you pursue an IV design, you need a strong first-stage story that examiner assignment creates plausibly exogenous variation in the intensity of *Alice* implementation, conditional on art unit and time. This would be hard, but potentially powerful if assignment within art unit is quasi-random.
- **Predetermined art-unit exposure based on pre-*Alice* litigation invalidation risk** or historical business-method classification.

A weaker but still useful revision would be to frame the current exercise honestly as **descriptive measurement of heterogeneity** rather than causal estimation. In that case, the contribution is documenting the extent of within-TC divergence after *Alice*, not estimating the effect of “Alice shock” on §101 rates.

**3. Show actual event-study figures and formal pre-trend tests.**  
The paper repeatedly states that there are no pre-trends, but no event-study figure appears in the draft, and the appendix language is not persuasive. For this design, visuals are essential. Please provide:
- event-study coefficients with confidence intervals,
- the underlying raw means for high- vs low-exposure units,
- a joint test of pre-period coefficients,
- sensitivity to alternative omitted baseline quarters.

Because treatment is continuous, it would also help to bin exposure into quartiles for visualization, while keeping continuous treatment in the estimating equation. This gives readers a clearer sense of the underlying data.

**4. Clarify the unit of observation and sample size.**  
The paper says there are 71 or 73 art units over 20 quarters, which would imply far more than 146 observations unless many cells are missing. Table counts do not line up cleanly with the data description. This matters because inference with very few clusters or sparse panels can be fragile. Please reconcile:
- 71 vs 73 art units,
- 146 observations in within-TC regressions,
- 170 observations in cross-TC regressions,
- whether the panel is balanced,
- whether quarters with zero actions are dropped and how often that occurs.

Relatedly, if clustering is at the art-unit level with roughly 70 clusters, that is likely acceptable, but if effective sample size is much smaller in some specifications, I would report wild-bootstrap p-values as a robustness check.

**5. Reconsider the interpretation of the §103 placebo.**  
The paper calls §103 a placebo, but a negative effect is found and then interpreted as “substitution.” That may be true, but once a placebo moves significantly, it is no longer simply validating the design. The substitution interpretation is plausible and interesting, yet it cuts in two directions:
- it may mean examiners changed the *mix* of rejection grounds rather than total stringency;
- it raises the question whether §101 increases partly displaced prior-art examination rather than reflecting pure treatment intensity.

I would suggest broadening the analysis to all major rejection bases (§101, §102, §103, §112) and perhaps the total number of rejection grounds per office action. If *Alice* changed the composition rather than the level of scrutiny, that is itself an important finding.

**6. Improve the cross-TC comparison or drop it.**  
TC 1600 (chemistry/pharma) is a poor control group for TC 3600 if the goal is causal corroboration. These centers differ dramatically in technology, claim drafting, prosecution norms, applicant mix, and preexisting §101 doctrine. The appendix even says the control is a random subsample of about 15 art units, which further weakens the comparison. Unless you can justify why TC 1600 supplies a meaningful counterfactual trend, I would either:
- demote this to a descriptive benchmark, or
- replace it with a more comparable set of non-TC3600 software-adjacent units.

As written, the within-TC comparison is much more credible than the cross-TC exercise.

**7. Exploit examiner-level variation carefully if available.**  
The manifest mentions “examiner Alice compliance as instrument.” That could become a serious contribution if done well. For example, among applications in the same art unit and time period, assigned to examiners with different propensities to issue §101 rejections after *Alice*, do abandonment and continuation outcomes differ? But this would require:
- a clear institutional argument about assignment,
- examiner pre/post propensities estimated out-of-sample or leave-one-out,
- controls for application vintage and applicant characteristics,
- attention to selection into examiner workloads.

This would move the paper much closer to an examination-process paper with credible quasi-experimental content.

**8. Connect the findings to applicants, not only examiners.**  
The current draft is almost entirely about examiner behavior. To make the economics more compelling, show what happened to applicants:
- Did continuation filings rise?
- Did applicants stop responding after first §101 rejection?
- Did prosecution duration increase?
- Did applicants shift filings to other art units or CPC classes?
- Were small entities especially likely to abandon after a first §101 rejection?

Even a single table on abandonment after first office action, by entity size and exposure quartile, would greatly improve the paper.

**9. Tighten the claims throughout.**  
The prose currently overstates what the evidence establishes. Phrases like “clean identification,” “plausibly exogenous,” and “the within-TC design rules out alternative explanations” are too strong for the present design. I recommend revising the tone to something like:
- “I document pronounced heterogeneity…”
- “These patterns are consistent with…”
- “Within-TC comparisons reduce some confounds but do not fully eliminate technology-specific differential trends.”

A more modest framing would actually increase credibility.

**10. If the paper remains focused on rejection rates, reposition it explicitly as a measurement paper.**  
There is still a publishable short paper in documenting the internal geography of *Alice* within the USPTO. But then the contribution is:
- new measurement of heterogeneity at the art-unit level,
- evidence that aggregate analyses obscure major within-center divergence,
- suggestive evidence of substitution across rejection grounds.

That is a different paper from the one currently claimed. If you choose this route, I would strip back the causal language and make the paper a sharp descriptive contribution.

Overall, I think the setting is promising and the underlying variation is real. But the paper, in its current form, does not yet deliver a credible causal estimate, and it stops short of the economically important outcomes that would justify the project. The best path forward is to return to the original question—small-entity abandonment and exit—and use the art-unit heterogeneity as a source of exposure rather than as the outcome itself.
