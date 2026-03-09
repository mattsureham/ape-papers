# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T12:04:53.839579
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 21010 in / 5338 out
**Response SHA256:** 1293fe3f6c5b2d5a

---

This paper studies whether Nigerian states’ anti-open grazing laws reduced farmer-herder violence, using a staggered-adoption triple-difference design that compares pastoral and non-pastoral LGAs within treated and untreated states over 2010–2024. The topic is important, the policy question is salient, and the paper is ambitious in trying to recover a causal effect from difficult conflict data. The design has an appealing intuition: if the laws matter, they should affect violence disproportionately in places exposed to pastoral activity.

However, in its current form, I do not think the paper is publication-ready for a top general-interest journal or AEJ: Economic Policy. The central concerns are not cosmetic; they are about what is being identified, whether the identifying variation is substantively credible, and whether the inference is reliable enough to support the paper’s strong causal claims. The main estimate is interesting, but the paper currently overstates what the evidence can bear.

## 1. Identification and empirical design

### A. The core identification claim is weaker than the paper suggests

The preferred specification is

\[
Y_{ist} = \beta (D_{st}\times P_i) + \gamma_i + \delta_{st} + \varepsilon_{ist},
\]

with LGA fixed effects and state-by-year fixed effects (Section 4.1). This is a valid DDD-style setup in principle. But the actual identifying variation is much narrower than the framing implies.

By the paper’s own “effective sample” analysis (Table 4 / Table `effective_sample`), the coefficient is identified only from states that contain both pastoral and non-pastoral LGAs. That leaves only **12 states total, and only 6 treated states** contributing to identification: Ebonyi, Oyo, Akwa Ibom, Lagos, Ogun, and Rivers. The most policy-relevant treated states discussed throughout the paper—Benue, Taraba, Ekiti, Ondo, Osun, Enugu, Delta, Abia—either contribute nothing or are absorbed by state-year fixed effects.

This is a major issue for interpretation. The title, abstract, and introduction repeatedly frame the result as evidence on “anti-open grazing laws in Nigeria,” but the estimate is actually local to a small subset of mixed-composition states, many of which have very low measured pastoral exposure (e.g., 1 pastoral LGA in Oyo, 1 in Ebonyi, 1 in Akwa Ibom; Table 4). That is not a minor caveat; it fundamentally changes the estimand.

**Why this matters:** The paper’s strongest substantive claims are effectively being driven by a small and unusual set of treated states, not the prominent high-conflict adopters. This makes external validity narrow and raises concern that the result is picking up state-specific changes in those mixed states rather than a general effect of anti-grazing laws.

**Needed fix:** Recast the estimand transparently throughout the paper, and rework the empirical design so that the main claim does not rest on such a limited subset. At minimum, the abstract, introduction, conclusion, and title-level framing must clearly state that identification comes from 6 treated mixed states.

### B. The “pastoral” classification is a major source of concern

The paper classifies LGAs as pastoral using the union of:
1. at least two pre-2016 non-state violence events, and
2. membership in eight Middle Belt states (Section 3.4).

This is problematic for several reasons.

#### 1. The classification is partially outcome-based
Using pre-treatment non-state violence to define exposure creates a clear risk of regression to the mean and selection on transitory conflict intensity. The paper acknowledges this, but the defense is not convincing. The DDD structure does not automatically solve this problem if high-pretrend or mean-reverting LGAs differ systematically across treated and control mixed states.

More importantly, the paper’s own robustness check is concerning: the “conflict-only pastoral” definition yields a **positive** coefficient (Table `robustness`: 0.384, SE 0.557). The paper presents this as reassuring because it is insignificant, but substantively it suggests that the sign and magnitude are quite sensitive to how exposure is defined. That should be front and center, not relegated to a robustness table.

#### 2. The geographic criterion is state-level and largely non-identifying
The “Middle Belt” component assigns **all** LGAs in several states as pastoral. But with state-by-year fixed effects, states that are 100% pastoral contribute no identifying variation. Indeed, most of these geographic-classification states do not identify the treatment effect. So the geographic rule is doing much less useful work than the paper implies, while the identifying treated states appear to rely heavily on the conflict-based classification.

#### 3. Some “pastoral” classifications are substantively implausible
The effective-sample table assigns pastoral LGAs to states like Lagos, Rivers, Bayelsa, and Cross River. That may be possible in a broad sense, but for a paper making precise causal claims about farmer-herder violence, this requires much stronger validation. Are these LGAs genuinely on transhumance routes or hosting pastoral-farmer interface zones? Or are they simply places with some pre-period non-state violence that may be unrelated to herding?

**Why this matters:** If the treatment-exposure interaction is mismeasured or partly defined by prior conflict, the main DDD coefficient may not recover the causal effect of law adoption on “pastoral zones” in any economically meaningful sense.

**Needed fix:** The paper needs a much stronger, non-outcome-based measure of pastoral exposure—e.g., historical grazing routes, livestock density, transhumance corridor shapefiles, ecological suitability, or independent pastoral settlement data. If such data are unavailable, the paper’s causal ambition should be scaled down substantially.

### C. The outcome does not cleanly measure farmer-herder violence

The paper uses all UCDP **Type 2 non-state violence** as the primary outcome (Section 3.1), arguing this is “the closest match” to farmer-herder clashes. But UCDP non-state violence includes a wide range of organized group violence: communal, militia, cult, ethnic, and other inter-group clashes. In places like Rivers or Lagos, Type 2 violence may often be unrelated to herders.

This is, in my view, one of the paper’s biggest substantive weaknesses. The laws are specific to grazing. But the outcome is a broad conflict category. The null result on state-based violence is not sufficient reassurance; it only shows specificity relative to Boko Haram/state conflict, not specificity relative to non-herder communal violence.

**Why this matters:** The paper’s headline claim is about farmer-herder violence. The outcome does not isolate farmer-herder violence.

**Needed fix:** The main analysis should be redone, if possible, on actor-coded farmer-herder events or a validated subset of UCDP events identified through actor names/text coding/location filters. If that is not possible, the paper should be reframed as estimating effects on broader non-state violence in putatively pastoral areas, not farmer-herder violence per se.

### D. Endogenous adoption remains only partially addressed

The paper is right that simple state-level DiD is vulnerable to endogenous adoption. The DDD helps by absorbing state-level shocks with state-by-year FE. But this does not eliminate concerns about shocks targeted specifically at pastoral LGAs within adopting states.

For example, if adoption coincided with:
- area-specific deployments,
- local vigilante mobilization,
- changes in communal policing,
- targeted federal operations,
- or local political bargains in exposed LGAs,

then the DDD coefficient would capture these bundled responses, not the law itself. The paper says as much in passing, but the interpretation remains much stronger than warranted.

The SGF subsample is suggestive but not dispositive. It still depends on the same pastoral classification, the same broad outcome, and a small number of treated identifying states. Also, the claim that SGF adoption was “quasi-exogenous” is too strong without evidence showing that SGF adopters did not have differential within-state pastoral/non-pastoral trends before adoption.

**Needed fix:** Strengthen the pretrend evidence for the actual DDD estimand, not just state-level ATTs, and be much more careful in presenting SGF adoption as plausibly exogenous rather than quasi-exogenous.

## 2. Inference and statistical validity

### A. Inference is currently not convincing enough for publication

This is the paper’s most serious problem.

The preferred estimate in Table 1, col. 3 is significant with state-clustered SEs: \(-0.480\), SE \(0.153\), \(p=0.003\). But the paper also reports a **randomization-inference p-value of 0.183** (Section 5.4; Figure `ri`; Table `robustness`). That is a stark discrepancy.

The paper dismisses RI as “conservative due to structural centering,” but that is not an acceptable resolution. If the permutation distribution is not centered at zero because of the design, then the RI procedure is not appropriately matched to the null or the estimand. One cannot simply retain the conventional clustered p-value as “primary inference” and wave away the design-based result.

This matters especially because the effective treated identifying sample is very small. Although there are 37 state clusters nominally, the relevant treated identifying variation comes from only 6 treated mixed states. In such settings, standard CRVE can be badly misleading.

### B. The failure of WCB for the preferred specification is not a minor footnote

The paper says wild cluster bootstrap could not be implemented for the preferred specification because of singularity with high-dimensional FE, and reports WCB only for a simpler, non-preferred specification where the coefficient is insignificant. This does not help validate inference for the preferred design.

A paper at this outlet level needs a credible small-cluster inference strategy for the actual main specification.

**Needed fix:** The authors need to provide valid inference for the preferred model using methods suited to few treated clusters / high-dimensional FE, for example:
- cluster-robust bias-reduced linearization with Satterthwaite d.f. (CR2),
- randomization inference designed around the actual treatment assignment mechanism and estimand,
- score/bootstrap methods that can accommodate absorbed FE,
- or aggregation to the state-year × pastorality cell level with exact/permutation-based inference.

Without this, the main finding is statistically fragile.

### C. Event-study evidence is not strong enough

The paper presents both a Callaway-Sant’Anna state-level event study and a DDD event study. The state-level CS event study is not the right object for the key identifying assumption, which concerns the **pastoral-minus-nonpastoral gap** across treated and untreated states. The DDD event study is the relevant one, but it is discussed qualitatively only, without coefficient tables, joint lead tests, or a clear accounting of which cohorts identify which relative times.

Given the limited identifying sample, claims like “no evidence of pre-trends” are overstated. At most, the paper can say it does not detect clear pretrends with low power.

**Needed fix:** Present the DDD event-study coefficients in a table, report a joint test of leads if feasible, and discuss power honestly. If formal testing is infeasible, show the underlying cohort-time support and do not use the absence of significance as strong evidence of parallel trends.

### D. Sample-size reporting is coherent, but the effective-sample issue must be integrated into inference

The nominal sample size (11,625 LGA-years) is correctly reported. But the inferential problem is that this masks the much smaller number of independent treated identifying units. The paper deserves credit for surfacing this in Table 4, but it then underplays its implications.

## 3. Robustness and alternative explanations

### A. Robustness exercises are numerous, but the most important robustness fails conceptually

The paper includes many checks: leave-one-out, SGF subsample, log outcome, Poisson PML, placebos, spillovers, alternative treatment timing statement, etc. This is good in breadth. But many of these do not address the core threats:
- outcome misclassification,
- endogenous exposure classification,
- few treated identifying states,
- weak inference.

The robustness portfolio is therefore somewhat misallocated: many secondary checks, insufficient emphasis on the central vulnerabilities.

### B. Placebos are useful but limited

The null effects on state-based and one-sided violence are helpful. They suggest the result is not a general decline in all violence. But they do not establish that the measured reduction is specifically in farmer-herder clashes.

A much more compelling placebo/falsification design would examine:
- violence types or actors unlikely to involve herders within the same LGAs,
- crop-season timing interactions,
- effects in high-pastoral-exposure vs low-pastoral-exposure areas using independent exposure data,
- or event text coding.

### C. Spillover and displacement tests are underpowered and overinterpreted

The within-state displacement estimate is \(0.036\), \(p=0.24\). The cross-border spillover estimate is \(0.037\), \(p=0.75\). These are presented as evidence for deterrence rather than displacement. That is too strong.

Null estimates here may simply reflect low power, especially because the non-pastoral outcome means are very low. The paper does eventually note it cannot “prove” absence of displacement, but the rhetoric elsewhere goes beyond that.

**Needed fix:** Rephrase these as failing to detect displacement on tested margins. Avoid “consistent with deterrence rather than displacement” as a headline unless backed by confidence intervals showing economically meaningful displacement can be ruled out.

## 4. Contribution and literature positioning

The paper’s substantive contribution is potentially important: a causal evaluation of anti-open grazing laws in Nigeria would be valuable. The paper also makes a methodological point about DDD in spatially heterogeneous policy settings.

That said, the contribution is currently overstated relative to what the design can support. Given the outcome and exposure limitations, the paper does not yet convincingly deliver “the first causal estimate of anti-grazing legislation on farmer-herder violence.” It more plausibly offers suggestive evidence that anti-grazing laws are associated with reductions in broad non-state violence in a narrow set of “pastoral” LGAs in a subset of mixed states.

### Literature positioning gaps

The identification/method section should engage more directly with modern DDD/event-study practice, not only staggered DiD. In particular, the paper would benefit from discussing:
- Sun and Abraham (2021) on event-study contamination under heterogeneous treatment effects.
- Roth (2022, 2023) on low power of pretrend tests / parallel trends assessment.
- MacKinnon, Nielsen, and Webb on wild bootstrap and few-cluster inference.
- Athey and Imbens / design-based perspectives relevant for staggered adoption and randomization inference.

On the substantive side, the paper needs tighter connection to conflict-event measurement work and studies specifically distinguishing pastoral/farmer-herder violence from broader communal conflict.

Concrete additions:
- Sun, Liyang, and Sarah Abraham. 2021. “Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects.” *Journal of Econometrics.*
- Roth, Jonathan. 2022. “Pretest with Caution: Event-Study Estimates after Testing for Parallel Trends.” *AER: Insights.*
- Roth, Sant’Anna, Bilinski, and Poe. 2023. “What’s Trending in Difference-in-Differences?” *Journal of Econometrics.*
- MacKinnon and Webb papers on few-cluster inference / wild bootstrap.
These matter because the paper’s main inferential and pretrend claims rest precisely on these issues.

## 5. Results interpretation and claim calibration

This is another area where the paper needs substantial recalibration.

### A. The headline magnitude is too aggressively interpreted

The paper emphasizes a “79% decline” using the treated-pastoral pre-treatment mean of 0.609. Given the concerns about exposure classification, effective sample, and the broadness of the outcome, that interpretation is too strong. It also risks exaggeration because the mean is small and the estimate is a differential effect in a sparse-count setting.

### B. The paper repeatedly makes causal claims stronger than the evidence permits

Examples:
- “I find that anti-grazing laws reduce non-state violence…”
- “the laws appear to reduce farmer-herder violence…”
- “evidence favors deterrence”
- “formal law is associated with reduced communal violence even in weak institutional environments”

These are plausible interpretations, but not established cleanly enough here. Given the outcome measure and the inference issues, the paper should speak in terms of “suggestive evidence” or “estimated reductions in broad non-state violence in exposed areas,” unless the core issues are resolved.

### C. The paper does not sufficiently grapple with the contradiction between the state-level ATT and the DDD result

Section 5.7 explains why the Callaway-Sant’Anna ATT is positive and imprecise while the DDD is negative and significant. Some of that explanation is reasonable. But the contrast should raise more concern than the paper allows, especially because the state-level event study shows short-run positive coefficients and the main identifying states are not the high-conflict adopters. This does not invalidate the DDD design, but it should temper the confidence of the conclusions.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild the exposure measure (“pastoral” classification)
- **Issue:** The key interaction uses a classification partly defined by pre-treatment violence and partly by geography that often provides no identifying variation.
- **Why it matters:** This threatens identification and substantive interpretation.
- **Concrete fix:** Construct an independent, non-outcome-based pastoral exposure measure using historical grazing routes, livestock density, ecological suitability, pastoral settlements, or administrative grazing-reserve maps. Re-estimate the main design using that measure. If impossible, downgrade the causal claims substantially.

#### 2. Use an outcome that more directly measures farmer-herder violence
- **Issue:** UCDP Type 2 non-state violence is too broad.
- **Why it matters:** The paper’s main claim is about farmer-herder violence, but the outcome is not specific to that phenomenon.
- **Concrete fix:** Build an actor-coded/event-text-coded farmer-herder event series, or at minimum a validated subset of UCDP events plausibly linked to herders/farmers. Make that the primary outcome.

#### 3. Provide valid inference for the preferred specification
- **Issue:** Clustered SEs produce \(p=0.003\), but RI gives \(p=0.183\), and WCB is unavailable for the main model.
- **Why it matters:** The paper cannot pass with unresolved inference.
- **Concrete fix:** Implement a small-sample-valid inference approach for the preferred model (e.g., CR2/Satterthwaite, design-consistent RI, aggregated-cell inference, or another justified method), and make that the primary inference basis.

#### 4. Reframe the estimand and contribution around the actual effective sample
- **Issue:** The estimate is identified from only 6 treated mixed states, many with very few pastoral LGAs.
- **Why it matters:** Current framing overstates national relevance.
- **Concrete fix:** Rewrite the abstract/introduction/conclusion to reflect that the main estimate is local to mixed-composition states. Report treatment-effect decomposition by identifying state and by pastoral-LGA count.

### 2. High-value improvements

#### 5. Strengthen DDD pretrend diagnostics
- **Issue:** The state-level event study is not the correct test for the key identifying assumption, and the DDD event study is only informally discussed.
- **Why it matters:** Parallel trends is central to the design.
- **Concrete fix:** Report DDD lead coefficients in a table, show support by event time/cohort, and present any feasible joint lead test or power-aware discussion.

#### 6. Show robustness to alternative treatment timing conventions in full detail
- **Issue:** Annual coding of mid-year adoption is consequential and currently asserted rather than demonstrated.
- **Why it matters:** Timing choices could matter with sparse outcomes and short post windows.
- **Concrete fix:** Present full tables for alternative timing rules: adoption year treated, next-year treated, half-year weighting if possible.

#### 7. Address alternative bundled interventions
- **Issue:** The law may coincide with targeted enforcement or local security responses.
- **Why it matters:** The current estimate may capture a package, not legislation alone.
- **Concrete fix:** Add discussion and, if data exist, controls or narrative evidence on state security deployments, vigilante institutions, or livestock task forces around adoption.

#### 8. Recalibrate displacement claims
- **Issue:** Null spillover estimates are overinterpreted as supporting deterrence.
- **Why it matters:** Lack of evidence of displacement is not evidence of absence.
- **Concrete fix:** Report confidence intervals in substantive units and state explicitly what magnitudes can be ruled out.

### 3. Optional polish

#### 9. Tighten literature discussion around DDD and few-cluster inference
- **Issue:** Methodological positioning is incomplete.
- **Why it matters:** The paper’s identification and inference issues sit squarely in this literature.
- **Concrete fix:** Add discussion of Sun-Abraham, Roth, and MacKinnon/Webb.

#### 10. Clarify what “placebo” outcomes do and do not validate
- **Issue:** The placebo section currently implies more specificity than it establishes.
- **Why it matters:** Readers may infer the outcome is farmer-herder-specific when it is not.
- **Concrete fix:** Explicitly state that placebos rule out broad security shocks, not misclassification within non-state violence.

## 7. Overall assessment

### Key strengths
- Important policy question with high social relevance.
- Clear institutional motivation.
- Good instinct to exploit within-state heterogeneity rather than rely on naive staggered DiD.
- Commendable transparency in reporting effective sample and multiple robustness exercises.
- State-by-year fixed effects are a thoughtful design choice.

### Critical weaknesses
- The primary outcome does not specifically measure farmer-herder violence.
- The pastoral exposure measure is partly defined by pre-treatment violence and is not convincingly exogenous.
- The effective identifying sample is much smaller and more idiosyncratic than the paper’s framing suggests.
- Statistical inference is not currently credible enough: the RI result materially weakens confidence in the main finding, and no satisfactory small-sample inference for the preferred model is provided.
- The paper overclaims on deterrence, causality, and external validity.

### Publishability after revision
I think there is a potentially interesting paper here, but it requires substantial redesign or revalidation of the core empirical strategy before it would be competitive at the stated outlets. In particular, the paper needs a better outcome, a better exposure measure, and a defensible inference strategy. Without those, the current main result is too fragile for publication in a top field or general-interest journal.

DECISION: REJECT AND RESUBMIT