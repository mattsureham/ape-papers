# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T11:42:10.776076
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 17261 in / 5214 out
**Response SHA256:** 2adb014be2935544

---

This paper asks an important and policy-relevant question: whether a major broadband infrastructure upgrade affected anti-system voting in France. The paper is commendably transparent about some of its own weaknesses, especially the discrepancy between TWFE and Callaway-Sant’Anna estimates and the failed pre-trend placebo. That transparency is a strength. However, in its current form, the paper is not publication-ready for a top general-interest journal or AEJ: Economic Policy. The core problem is that the empirical design does not currently support the paper’s causal claims. The identifying variation is weak and highly entangled with election-type differences, treatment timing is compressed into very few post periods, and the paper’s preferred result rests on a TWFE specification that the paper itself acknowledges is vulnerable. The heterogeneity-robust designs do not deliver confirmatory evidence.

Below I organize the review around identification, inference, robustness, contribution, claim calibration, and revision priorities.

## 1. Identification and empirical design

### A. The central causal claim is not yet credibly identified

The paper’s main claim is causal—FTTH rollout “reduced” anti-system voting—but the evidence presented does not currently justify that interpretation.

The core design uses department-by-election variation with department and election fixed effects (Section 4, equation (1)). That could be informative in principle, but here there are several major design limitations:

1. **The treatment period is extremely short and concentrated**.  
   FTTH data begin only in Q4 2017, and meaningful variation appears only from 2019 onward (Sections 3.1, 4.2, 4.3). So the design effectively has only three post-treatment elections with nontrivial coverage variation: 2019 European, 2022 presidential, 2024 European. That is a very thin basis for a staggered-adoption causal design, especially when outcomes are observed only at election dates.

2. **Treatment timing is highly compressed across units**.  
   The paper notes that most departments cross the 50% threshold in 2022 or 2024 (Section 3.4, Section 5.2). This makes the cohort structure poorly suited for modern staggered DiD: there are few early-treated cohorts, very limited post-treatment exposure by cohort, and rapidly shrinking comparison groups.

3. **Election-type heterogeneity is not a nuisance here—it is central to the identifying variation**.  
   The panel stacks presidential first rounds and European Parliament elections, which differ sharply in turnout, strategic incentives, party supply, and the meaning of “anti-system voting” (Sections 2.4, 4.3, 5.3, 6.1). The paper argues that election fixed effects absorb these differences, but that is insufficient. Election fixed effects absorb average level differences across election dates; they do not solve the problem if departments differentially evolve across presidential and European cycles in ways correlated with FTTH rollout speed. The oscillating event-study pre-trends are almost certainly picking up exactly this problem.

4. **The paper directly documents a failure of parallel trends**.  
   Section 6.4 reports a pre-trend falsification test rejecting the null at \(p=0.012\). This is not a minor caveat; it is a serious identification failure. Once future FTTH rollout predicts pre-rollout trends in anti-system voting, the core DiD identifying assumption is undermined. The paper is admirably honest about this, but then it still frames the negative TWFE estimate as a substantive main finding. That is not warranted.

### B. The institutional argument for quasi-random rollout timing is too weak at the department-election level

The paper argues that zoning under Plan France Très Haut Débit was determined in 2011–2013 and is therefore plausibly exogenous to later political outcomes (Section 2.1). This is suggestive background, but it is not enough for the design actually estimated.

Why not?

- The treatment is not zone assignment; it is **department-level realized FTTH coverage at election dates**.
- Realized coverage by 2019/2022/2024 depends heavily on urban density, operator incentives, procurement capacity, construction constraints, pre-existing infrastructure, and local market characteristics.
- These same characteristics are likely correlated with both levels and trends in anti-system voting.

The balance tests in Section 7.3 do not rescue this. Cross-sectional regressions of 2022 FTTH coverage on 2012 anti-system vote share and turnout are weak evidence for identification. In particular:
- turnout strongly predicts FTTH coverage;
- that strongly suggests rollout is correlated with urban-rural structure;
- and urban-rural structure is precisely a likely source of differential political trends.

A top journal would require either a much more convincing source of quasi-exogenous variation or a design that more convincingly absorbs geography-specific trends.

### C. The treatment measurement raises additional design concerns

There are several issues here:

1. **Setting pre-2017 FTTH coverage to zero** (Section 3.1) is not innocuous.  
   For 1999–2014 this is probably fine, but the 2017 presidential election is mismeasured by construction, and the paper concedes nonzero national coverage by then. One mismeasured election may not be fatal, but with only 11 elections total and only 3 meaningful post periods, even one problematic timing assignment matters.

2. **Connectability is not adoption**.  
   The paper is clear that FTTH is measured as premises connectable, not subscribed. That means the treatment is a supply-side intent-to-treat exposure. This is acceptable if framed properly, but the causal interpretation should be “effect of local FTTH availability,” not “effect of high-speed internet use.”

3. **Department-level aggregation is likely too coarse**.  
   The paper itself notes this in the conclusion. Within-department rollout heterogeneity is presumably substantial. If urban centers within departments get fiber first while surrounding areas do not, department averages may be poor proxies for actual exposure.

### D. The anti-system outcome definition is plausible but not fully innocuous

The choice to combine RN/FN, LFI, and Reconquête into a single “anti-system” bloc may be defensible substantively, but it needs more conceptual and empirical defense.

Concerns:
- these parties are not equivalent across elections or periods;
- party supply differs sharply between presidential and European races;
- some “anti-system” coding choices rely on list names or broad nuance categories (Section 3.2, Appendix);
- the meaning of anti-system voting in presidential versus European elections may differ substantially.

At minimum, the paper should show results separately for far-right and far-left blocs. If the combined outcome masks opposite movements, the headline claim is misleading.

## 2. Inference and statistical validity

### A. Basic uncertainty reporting is present, but inference is not yet convincing enough for the main claim

The paper reports standard errors and p-values throughout, and clusters at the department level for TWFE (Section 4.1; Tables 1 and 4). That is necessary and appropriate at a minimum with 96 clusters.

However, several issues remain.

### B. TWFE is not acceptable as the principal estimator in this setting

The paper correctly acknowledges the standard problems with naive TWFE under staggered adoption (Section 4.1). Yet the paper still treats the TWFE result as the main finding, even though:
- treatment timing is staggered;
- treatment effects are plausibly heterogeneous;
- already-treated units may serve as controls in ways that distort the estimate.

The paper attempts to address this by reporting Callaway-Sant’Anna and Sun-Abraham estimates. But once those estimators do not confirm the result—especially given the pre-trend problems—the proper conclusion is not that TWFE is “main” because it has “more power.” More power does not justify relying on a biased estimand.

This is a central inferential issue. In a staggered DiD paper for a top field or general-interest journal, the authors cannot privilege TWFE simply because robust alternatives are noisier.

### C. The heterogeneity-robust estimators do not provide confirmatory support

- **Callaway-Sant’Anna ATT is null** (Table 2).
- **Event-study pre-trends are problematic** (Figure 3; Section 5.3).
- **Sun-Abraham has significant pre-trends and effectively only one post period for many cohorts** (Section 6.3).

That leaves the paper without a clean estimator that both addresses staggered timing concerns and supports the causal conclusion.

### D. Inference with only a handful of post-treatment election dates needs more care

Even with 96 clusters, the effective time variation is limited because treatment changes matter at only a few election dates. This can produce overconfident inference in panel settings where treatment is highly persistent and time shocks are few.

The paper should consider:
- wild cluster bootstrap inference;
- randomization/permutation inference tailored to treatment timing or rollout speed;
- sensitivity to collapsing the panel into fewer pre/post windows.

Without such checks, I would be reluctant to put much weight on \(p=0.02\) or \(p=0.03\) main effects.

### E. Sample-size coherence is mostly fine, but design power is weak

The reported observation counts are coherent:
- 1,056 total department-election observations,
- 480 presidential,
- 576 European,
- 672 in the pre-trend placebo.

That said, the paper’s own statement about minimum detectable effects (Section 4.3) is underdeveloped and somewhat inconsistent with the confident interpretation of the main estimates. If power is only sufficient for 3–4 pp effects, the precision around some key claims is overstated.

## 3. Robustness and alternative explanations

### A. The most important “robustness” result actually weakens the paper

The pre-trend placebo in Section 6.4 is the single most probative robustness test, and it fails. That should be elevated from a caveat to a central conclusion: the current design does not cleanly distinguish FTTH effects from differential pre-existing trends.

### B. The by-election-type split is informative but also reveals instability

Section 6.1 is one of the paper’s most important analyses:
- pooled TWFE: \(-0.017\),
- presidential only: \(+0.017\), insignificant,
- European only: \(-0.051\), highly significant.

This is not just heterogeneity; it suggests that the pooled result may be an artifact of combining structurally distinct political environments. The very large European-election estimate is especially concerning. A 5.1 pp reduction relative to an 11 pp mean (as the paper notes) is enormous. Such magnitude demands much stronger identification than currently available.

### C. Threshold robustness is not reassuring

The threshold results in Section 6.2/Table 4 are non-monotonic:
- negative at 25%,
- negative at 50%,
- positive at 75%.

This pattern is hard to reconcile with a stable causal effect of increasing FTTH exposure. It suggests either model instability, changing composition of treated units, or confounding by urban departments reaching saturation at particular times. The paper mentions this, but understates its seriousness.

### D. The blank/null result is not a valid placebo in the sense used here

The paper describes blank/null votes as a “positive control” or placebo-like outcome (Section 6.4). But blank/null voting is itself a political outcome plausibly affected by the same confounds—especially urbanization, turnout composition, and election-type dynamics. So a significant blank/null effect is not validating in the way a true placebo outcome would be.

A more convincing placebo would be:
- pre-treatment outcomes that should not react to future FTTH,
- party vote shares for categories with no clear theoretical channel,
- or outcomes in elections/periods where FTTH exposure is known to be negligible.

### E. Mechanism claims are underidentified

Section 7 appropriately acknowledges the lack of direct measures of information exposure. But the discussion and conclusion still lean heavily on “reducing alienation,” “information access,” and “alternative channels for expression.” Those are speculative. The paper currently presents reduced-form correlations with no direct evidence on media use, misinformation exposure, or political information.

Mechanism discussion should be explicitly downgraded unless new evidence is brought in.

### F. External validity is limited and should be stated more sharply

This is not “the effect of broadband” in general. It is potentially the effect of:
- a **late-stage DSL-to-fiber upgrade**,
- in **metropolitan France**,
- over **2017–2024**,
- measured at the **department-election** level,
- mostly identified off **European elections**.

That is already a narrow and interesting question, but the paper currently sometimes speaks more broadly about broadband and polarization than the evidence warrants.

## 4. Contribution and literature positioning

### A. The topic is relevant, but the incremental contribution is not yet sharply differentiated

The paper is positioned against work on broadband and political behavior, especially Guriev et al., Lelkes et al., Campante et al., and Falck et al. This is broadly appropriate. The most distinctive feature is the focus on **second-wave broadband infrastructure (fiber)** rather than earlier broadband/mobile internet expansions.

That is potentially a meaningful contribution. But for top-journal placement, the paper needs a much cleaner statement of what is learned beyond:
- earlier broadband-adoption papers,
- mobile internet/populism papers,
- and election-specific studies of anti-system voting.

Right now the headline finding is too fragile for the contribution to feel secure.

### B. Literature coverage should be expanded on both methods and domain

Several literatures need stronger engagement.

#### Methods / DiD / event-study credibility
The paper cites the core staggered-DiD papers, but should engage more directly with recent work on DiD credibility and pre-trends:
- Roth, Sant’Anna, Bilinski, Poe, “What’s Trending in Difference-in-Differences?” / related Roth work on pre-tests and trend sensitivity.
- Rambachan and Roth (2023), on robust inference under violations of parallel trends.
- Goodman-Bacon (2021), more directly if TWFE remains reported.
- de Chaisemartin and D’Haultfœuille, especially for non-binary or multi-valued treatment settings.

#### Broadband / internet / politics
The paper should more fully engage:
- Guriev, Melnikov, and Zhuravskaya (2021), on 3G and populism;
- Campante, Durante, and Sobbrio (2018), on broadband and participation;
- Falck, Gold, and Heblich (2014), on internet and voting;
- additional European evidence on broadband/media access and political behavior;
- French political geography work on RN/LFI spatial patterns, which is central here.

Concrete additions that would help:
1. **Rambachan and Roth (2023)** — because the paper has explicit pre-trend violations and should bound treatment effects under imperfect parallel trends.
2. **de Chaisemartin and D’Haultfœuille on continuous/multi-valued treatments** — because the preferred treatment is continuous FTTH coverage, and the binary-threshold robust estimators are not estimating the same parameter.
3. **Recent work on broadband rollout and misinformation/political behavior in Europe** — to better position why fiber, as distinct from first-wave internet or mobile broadband, should have different effects.

## 5. Results interpretation and claim calibration

### A. The paper overstates what the evidence shows

The abstract and conclusion still read too strongly relative to the actual evidence. The paper says:
- TWFE finds a significant reduction,
- Callaway-Sant’Anna is null,
- event-study pre-trends are concerning,
- placebo pre-trend rejects parallel trends.

Given that combination, the appropriate substantive conclusion is not “FTTH reduced anti-system voting.” It is closer to:
> “The raw panel evidence is consistent with a negative association in TWFE, concentrated in European elections, but the causal interpretation is undermined by failed pre-trend diagnostics and non-confirmation in heterogeneity-robust estimators.”

That may sound less exciting, but it is the scientifically defensible interpretation.

### B. Some effect magnitudes are too large to be taken at face value without stronger design

The European-election estimate of \(-5.1\) pp is extremely large. The paper itself notes this is roughly a 46% reduction relative to the mean. Yet the discussion still entertains substantive behavioral stories for this result. Without a stronger design, those narratives are premature.

### C. The policy implications are overstated

The conclusion says policymakers can evaluate broadband rollout “without fear that connectivity expansion will radicalize the electorate.” That is too strong. The evidence does not support that level of reassurance:
- one estimator says negative effect,
- robust estimator says null,
- pre-trends fail.

The policy statement should be much more cautious.

### D. There are internal inconsistencies in how the paper treats conflicting estimates

The paper alternates between commendable caution and selective emphasis:
- it rightly notes TWFE problems;
- then still centers TWFE because it uses continuous variation and has “more power”;
- it treats CS-DiD as possibly underpowered rather than as contradictory evidence;
- it acknowledges pre-trend failure;
- yet still draws directional conclusions in the abstract and conclusion.

This needs to be resolved one way or another. A top-journal paper cannot simultaneously say “identification may fail” and “the evidence shows broadband reduced alienation” unless there is a stronger redesign.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild the empirical design around a credible source of identification
- **Issue:** The current department-by-election staggered DiD does not credibly identify a causal effect because of failed parallel trends, compressed treatment timing, and election-type confounding.
- **Why it matters:** This is the core scientific validity problem.
- **Concrete fix:** Redesign the empirical strategy. Promising directions:
  - move to a finer geographic unit (commune or municipality) if feasible;
  - exploit predetermined rollout zones more structurally;
  - use pre-specified exposure to RIP/AMII/ZTD as treatment intensity interacted with post periods;
  - exploit commune-level copper-closure timing once more overlap exists, if data can be extended;
  - or use an IV-type strategy based on pre-existing network topology / engineering constraints if defensible.

#### 2. Do not present TWFE as the main causal estimate unless you can validate it
- **Issue:** Preferred results come from naive TWFE in a staggered setting, while heterogeneity-robust estimators do not confirm the result.
- **Why it matters:** Invalid inference on the main parameter is disqualifying.
- **Concrete fix:** Either:
  - shift the paper to a descriptive/reduced-form association paper, or
  - produce a robust estimator for the continuous-treatment setting that directly targets the estimand of interest and survives diagnostic scrutiny.

#### 3. Address the parallel-trends violation directly, not rhetorically
- **Issue:** The pre-trend placebo rejects parallel trends.
- **Why it matters:** This undermines causal interpretation.
- **Concrete fix:** Implement sensitivity/bounding approaches, e.g. Rambachan-Roth style bounds, or explicitly allow differential trends by pre-treatment political/geographic characteristics. Show how much of the estimated effect survives under reasonable departures from parallel trends.

#### 4. Separate presidential and European elections in the main design, not as a side robustness check
- **Issue:** Pooling election types appears to be a major source of instability.
- **Why it matters:** The pooled estimate may be uninterpretable.
- **Concrete fix:** Make election-type-specific analyses primary. Ideally, estimate separate designs for presidential and European elections, and explain why one or both are credible despite very small numbers of elections. If neither is credible, say so.

#### 5. Recalibrate the paper’s claims in abstract, introduction, discussion, and conclusion
- **Issue:** Current language overstates causal certainty.
- **Why it matters:** Claims should match the evidence.
- **Concrete fix:** Replace directional causal language with appropriately cautious wording unless identification is materially improved.

### 2. High-value improvements

#### 6. Provide results by political bloc, not only the combined anti-system measure
- **Issue:** Combining RN/FN, LFI, and Reconquête may mask offsetting responses.
- **Why it matters:** Interpretation of “anti-system” effects depends on whether effects are common across ideologically distinct parties.
- **Concrete fix:** Report separate estimates for far-right and far-left vote shares, and possibly a residual mainstream share.

#### 7. Add richer controls for geography-specific trends
- **Issue:** Urbanization is an acknowledged confound but only partially addressed.
- **Why it matters:** Differential trends by urbanicity likely drive much of the result.
- **Concrete fix:** Include interactions of time with pre-determined covariates: urbanization, density, education, age structure, baseline turnout, baseline anti-system share, income/unemployment, zoning type shares. Show whether results survive.

#### 8. Use stronger inference procedures
- **Issue:** Standard clustered SEs may overstate precision in this thin-post-period setting.
- **Why it matters:** Marginal p-values are not reliable enough.
- **Concrete fix:** Add wild-cluster bootstrap p-values and permutation/randomization inference based on rollout timing/intensity.

#### 9. Improve treatment timing measurement
- **Issue:** 2017 treatment is mismeasured; binary thresholds are coarse; continuous treatment is preferred but not yet robustly estimated.
- **Why it matters:** Timing error matters in a short panel.
- **Concrete fix:** At minimum, drop 2017 from main specifications and show robustness. If possible, recover earlier FTTH data or a more precise rollout history from ARCEP/industry sources.

#### 10. Strengthen the institutional linkage between zoning and realized rollout
- **Issue:** Exogeneity is asserted at the zoning stage, but treatment is realized department coverage.
- **Why it matters:** The chain from zoning to coverage must be empirically shown.
- **Concrete fix:** Show first-stage evidence: how much of department FTTH rollout is predicted by ex ante zone composition? If this relationship is strong and predetermined, it may support a revised design.

### 3. Optional polish

#### 11. Clarify the estimand throughout
- **Issue:** The paper shifts between effects of coverage, treatment crossing, internet access, and fiber use.
- **Why it matters:** Conceptual precision helps readers assess external validity.
- **Concrete fix:** Consistently define the estimand as effect of premises-level FTTH availability unless adoption data are added.

#### 12. Replace “placebo” terminology where outcomes are not true placebos
- **Issue:** Blank/null votes are not a placebo.
- **Why it matters:** Terminology matters for interpretation.
- **Concrete fix:** Call them secondary or auxiliary outcomes, and reserve “placebo/falsification” for tests that should truly be null under the maintained hypothesis.

#### 13. Expand discussion of limitations of department-level aggregation
- **Issue:** The paper mentions this late, but it is fundamental.
- **Why it matters:** Aggregation may blur or fabricate effects.
- **Concrete fix:** Discuss ecological concerns earlier and, if possible, quantify within-department heterogeneity in rollout.

## 7. Overall assessment

### Key strengths
- Important, timely question at the intersection of infrastructure and political economy.
- Valuable data assembly linking ARCEP rollout data with French election results.
- Strong transparency: the author does not hide the null robust estimator or failed pre-trend test.
- The paper usefully highlights that “broadband” effects may differ between first-wave internet adoption and later fiber upgrades.
- The election-type split is insightful and reveals genuinely interesting heterogeneity, even if not yet causally identified.

### Critical weaknesses
- Identification is not currently credible for the causal claim.
- The preferred TWFE estimate is not reliable in this staggered setting, especially given conflicting robust estimators.
- Parallel trends fail in a direct placebo test.
- Pooling presidential and European elections likely contaminates the design.
- Treatment timing is too compressed, with too few informative post-treatment election periods.
- Mechanism and policy claims are too strong relative to the evidence.

### Publishability after revision
In its current form, this is not publishable in a top general-interest journal or AEJ: Economic Policy. The paper could become publishable if the empirical design is substantially reworked around a more credible source of exogenous variation or if the paper is reframed more modestly as descriptive evidence rather than causal estimation. But the necessary changes are substantial, not marginal.

DECISION: REJECT AND RESUBMIT