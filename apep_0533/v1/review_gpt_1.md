# GPT-5.4 Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T20:34:09.011813
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 17076 in / 5164 out
**Response SHA256:** f06b35f2388300f3

---

This paper asks an important policy question and uses a potentially powerful data source: whether state salary-history bans narrowed the gender earnings gap at hire. The central empirical idea—using QWI measures that distinguish new hires from continuing workers and then comparing the gender gap across these two margins—is creative and, in principle, well matched to the hypothesized mechanism. The paper’s main finding is a null: no detectable effect on aggregate gender earnings gaps.

I think the paper is promising, but in its current form it is not yet publication-ready for a top general-interest journal or AEJ: Economic Policy. The main reasons are not about prose; they are about identification, estimand clarity, and especially inference/validation of the stacked DDD and staggered-adoption analyses. The paper is plausibly salvageable, but it needs substantial redesign and tightening of the empirical case before the null can be viewed as decisively established.

## 1. Identification and empirical design

### A. Core idea is sensible, but the identifying assumptions need sharper justification

The paper’s main contribution is the DDD comparing new hires to continuing workers within state-quarter cells (Section 4.3). That is conceptually appealing because salary-history bans should operate at hiring, not on incumbent wages. However, the paper overstates how much this design “absorbs” confounding policy or macro shocks.

The key identifying assumption is not merely that statewide shocks hit both groups similarly. It is that, absent treatment, the **difference between the new-hire and continuing-worker gender gaps** would have evolved similarly in treated and untreated states. That is a substantially stronger and more specific assumption than the paper sometimes suggests (Sections 1, 4.3, 4.4). Many policies or shocks can differentially affect new hires relative to incumbents:

- pay transparency rules may bind more strongly for new hires than incumbents;
- minimum wage increases, occupational demand shifts, or changes in recruiting technology can affect entry wages more than incumbent pay;
- pandemic-era labor market churn plausibly affected new-hire wages differently from continuing-worker wages, with heterogeneous timing across states.

So the statement that the DDD “absorbs any policy that affects all workers, not just new hires” is fine, but the paper repeatedly implies that concurrent reforms are thereby largely neutralized. That is too strong. Any policy bundled with salary-history bans that differentially affects hiring-stage wage setting remains a first-order threat.

### B. Continuing workers are not a clean placebo/control group

The paper acknowledges contamination of the continuing-worker group as post-ban cohorts age into incumbent status (Section 4.3), but the implications are understated. This issue matters for both interpretation and identification:

1. **Mechanical contamination over time** means the DDD estimand is mainly short-run.  
2. **General-equilibrium spillovers** may affect internal equity adjustments, retention wages, or bargaining norms for incumbents.  
3. **QWI outcome definitions differ in ways not only about treatment exposure**: `EarnHirNS` is for new hires who become stable, while `EarnS` is for stable full-quarter workers. These are not symmetric populations.

This last point is especially important. The new-hire outcome is not “all hires”; it is earnings for hires who achieve stable employment. If the ban changes who remains employed long enough to enter `EarnHirNS`, the measured “new-hire wage” can change even absent any effect on initial offers. That is a nontrivial selection issue, and the current composition checks using female hire share (Section 5.3) do not address it. The relevant margin is stability/retention among hires, by sex, not just overall hiring counts.

### C. The paper does not adequately address local-law contamination

Treatment is coded at the state level (Section 3.3 and Appendix A), but salary-history bans were also adopted in many cities/counties before or outside statewide adoption. If untreated states contain major local bans, then the control group is partially treated; likewise, pre-periods in eventually treated states may already include local restrictions. This would bias estimates toward zero and is directly relevant for a paper whose main conclusion is a null.

Given the institutional setting, this is not a minor issue. A top-field or general-interest version of this paper needs either:

- a systematic accounting of sub-state policies and an assessment of likely exposure using population/employment shares, or
- a restricted sample excluding states/metropolitan areas with major pre-state local bans, or
- a treatment-intensity approach reflecting covered employment.

As written, the null may partly reflect treatment misclassification.

### D. Treatment timing and partial-quarter exposure are handled too casually

The paper codes treatment in the quarter the law becomes effective, even if only part of that quarter is exposed (Section 3.3). The paper says this is “conservative,” but that is only true under monotone immediate treatment effects. In practice, partial-quarter coding plus lags in employer compliance may create noisy event-time alignment and attenuate dynamic effects. Given the heavy emphasis on event-study flatness, more disciplined timing choices are needed:

- first full quarter treated;
- effective-date quarter coded by exposure share;
- lagged treatment onset for compliance/implementation.

These should be shown explicitly, not just mentioned as “available upon request” in the appendix.

### E. Staggered-adoption concerns are partly recognized, but the implementation is incomplete

The paper appropriately notes that naive TWFE can be problematic under staggered adoption (Section 4.2). However, because the main text still leans heavily on TWFE and the preferred alternative estimators are either incomplete or not fully validated, the identification argument is not yet convincing enough.

Most problematic is that the Callaway-Sant’Anna analysis is described as using an ad hoc standard-error approximation due to software issues (Section 5.2). That is not acceptable as a main robustness pillar in a paper whose central claim is a precisely estimated null.

## 2. Inference and statistical validity

This is the most serious weakness of the paper.

### A. Main uncertainty reporting is present, but some of the key inference is not publication-standard

The TWFE and DDD tables report clustered SEs at the state level (Tables 2, 3, 5), which is necessary. With 51 clusters, state clustering can be reasonable. But for a null-result paper in staggered adoption, that is not sufficient by itself. Several additional concerns need to be addressed:

1. **Finite-sample inference with 20 treated clusters**: cluster-robust asymptotics may still be imperfect when treatment is concentrated in a subset of states.  
2. **Serial correlation / highly persistent treatment**: standard Bertrand-Duflo-Mullainathan concerns apply.  
3. **Generated dependent variables** based on aggregate ratios likely produce heteroskedasticity tied to state size.  
4. **Stacked DDD inference** may require care because each state-quarter appears twice (new hire, continuing), and error correlation structure is not discussed.

Wild cluster bootstrap or randomization/permutation methods tailored to the actual assignment mechanism would substantially improve credibility.

### B. The Callaway-Sant’Anna inference is not valid as presented

This is a major problem. Section 5.2 states that standard aggregation “could not be used due to a software compatibility issue,” so SEs are “computed as the root-mean-square of the group-time cell-level bootstrap SEs,” which “does not account for correlations across cells.”

That means the reported CS estimates are not inferentially valid. For this journal tier, one cannot present such SEs as substantive robustness evidence. Either the estimator needs to be correctly implemented, or it should be removed. A software issue is not a scientific justification.

### C. The randomization inference design is not fully convincing

The RI exercise is useful in spirit, but the implementation details raise concerns (Section 5.5):

- Treatment timing is drawn “with replacement” from actual adoption dates, which does not preserve the actual staggered-adoption structure.
- The procedure appears not to condition on covariates/political determinants of adoption.
- It is unclear whether the RI statistic is studentized.
- RI is applied only to the TWFE estimate, not the DDD estimand that the paper emphasizes as the cleanest design.

A stronger design would randomize or re-assign adoption timing in a way that preserves the number of treated states and cohort structure, and would apply RI or placebo inference to the DDD coefficient as well.

### D. Power calculations are not persuasive as currently done

Section 4.5 presents back-of-the-envelope MDE calculations, but they are too stylized for the design actually used. They do not appear to account for:

- serial correlation,
- staggered treatment timing,
- cluster-level assignment,
- weighting/state size,
- the stacked DDD structure.

Moreover, the paper uses these calculations to support the claim of a “precisely estimated zero.” That claim is too strong without design-consistent power or minimum-detectable-effect calculations.

### E. Weighting is under-discussed and could materially affect inference and estimands

The regressions appear unweighted. This means Wyoming contributes equally to California in state-quarter cells despite enormous differences in employment counts and precision of QWI aggregates. That choice may be defensible if the estimand is an average state effect, but the paper interprets results as aggregate policy effects for the U.S. labor market.

At minimum, the paper needs:

- a clear statement of the estimand under unweighted OLS,
- weighted estimates using employment or hire counts,
- discussion of whether the null is for the average state, the average worker, or the average hire.

A null in equal-weighted state panels is not the same as a null for the average worker.

## 3. Robustness and alternative explanations

### A. Composition checks are too weak relative to the aggregation problem

The paper is commendably aware of composition concerns (Sections 4.4, 6.1, 6.3), but the empirical response is too limited. Showing that the female share of hires is unchanged does not address several important channels:

- changes in age/education/industry composition within sex,
- changes in full-quarter stability among new hires,
- changes in occupation or firm-type composition,
- shifts in hours/full-time status if reflected in monthly earnings.

Because QWI public data allow stratification by sex × age × education × industry, the paper should do more. Even if suppression prevents a fully saturated design, one could construct and compare within-state-quarter compositional distributions and reweight outcomes, or estimate effects within major demographic/industry cells and aggregate them.

At present, the paper’s interpretation of the null as absence of wage effects rather than offsetting composition changes is not sufficiently supported.

### B. Event studies need fuller presentation and more cautious interpretation

The event-study figure is central, but the textual claim “pre-trends are flat” based on a p-value of 0.99 is overconfident (Sections 1, 4.4, 5.5). A very high p-value is not proof of parallel trends; it can reflect low power, noisy lead coefficients, or over-aggregation. The paper should avoid using the pre-trend test as near-confirmation.

Also, because the DDD is the main design, the paper should show an event-study for the **DDD interaction** itself, not only separate event studies for new hires and continuing workers. The identifying assumption concerns the relative trend between these groups.

### C. Robustness to bundled policies is not yet sufficient

Excluding Colorado, California, and Washington is a start (Sections 2.2, 5.4), but probably insufficient. Other states had equal-pay reforms, disclosure laws, or related labor-market policies around adoption. The paper should assemble a broader policy-control set or at least test sensitivity to excluding additional bundled-reform states.

Also, some concurrent policies likely affect new hires more than incumbents, which the DDD will not purge. This point should be treated directly, not just via a few state exclusions.

### D. Industry heterogeneity analysis is informative but not fully convincing

The industry analysis is directionally useful, but it is still based on coarse 2-digit sectors and appears to use separate TWFE regressions rather than a unified interaction framework. Claims that the mechanism “should be strongest” in certain sectors are plausible, but the current evidence is descriptive and underpowered for sharp conclusions. Also, the paper does not clearly state whether industry-specific outcomes are suppressed differentially across states and time, which could itself introduce selection.

### E. Mechanism claims should be toned down

The paper is generally careful, but some passages go beyond the evidence. For example, the Discussion argues that the laws may be “too porous,” “too narrow,” or “too weakly enforced.” Those are plausible explanations, but the paper does not directly measure compliance, employer knowledge, or enforcement intensity. These are hypotheses consistent with the null, not demonstrated mechanisms.

## 4. Contribution and literature positioning

### A. Contribution is potentially meaningful

A careful, well-powered null result on salary-history bans using administrative data would be a useful contribution. The paper’s use of QWI new-hire versus continuing-worker outcomes is novel and has real promise. The paper also correctly engages the modern staggered-DiD literature and tries to move beyond CPS-based evidence.

### B. But the literature positioning overstates “first” and “more rigorous” claims

The paper repeatedly presents itself as the “first evaluation” using these data and suggests earlier findings may not survive rigorous design. That may ultimately be true, but the current empirical implementation is not yet strong enough to justify such framing. In particular, because the paper’s alternative staggered-adoption inference is incomplete and the aggregation/composition issues remain unresolved, the contrast with prior studies should be more measured.

### C. Likely missing or underdeveloped literatures

The paper would benefit from more engagement with:

1. **Local and sub-state policy diffusion** in labor regulation, given the treatment-classification issue.  
2. **QWI/LEHD measurement papers**, especially on how new-hire and stable-employee earnings are defined and what selection those definitions induce.  
3. **Null-result and policy-evaluation interpretation** in settings with low treatment intensity/compliance.  
4. **Pay transparency and wage-posting literatures**, beyond a few bundled-state mentions, because these are close substitutes and potential confounds.

I would encourage adding and engaging the following kinds of references:
- LEHD/QWI technical documentation and papers using QWI earnings measures for causal designs;
- papers on local pay transparency/salary posting laws;
- papers on treatment misclassification and policy spillovers in state-policy DiD settings;
- inference references for wild cluster bootstrap / permutation inference in staggered DiD.

## 5. Results interpretation and calibration of claims

### A. “Precisely estimated zero” is too strong

The abstract and introduction lean heavily on the phrase “precisely estimated zeros.” I do not think the evidence currently supports that characterization. The TWFE new-hire estimate of -0.008 (SE 0.008) is informative, but the DDD estimate and the staggered-adoption robustness exercises are not yet established with sufficiently strong inference. More importantly, several identification frictions—local-law contamination, composition/selection in `EarnHirNS`, weighting, bundled policies—could attenuate effects.

A better calibration would be: the paper finds no evidence of economically large aggregate effects in state-level QWI averages.

### B. Policy implications should be more restrained

The conclusion that “banning the question, as currently implemented, is not sufficient to change aggregate outcomes” is plausible, but the paper should more clearly distinguish:
- failure of statutory bans as implemented,
- failure of compliance/enforcement,
- treatment misclassification/partial spillovers,
- inability of aggregate cell means to detect distributional effects.

At present the paper sometimes slips from “no detectable effect in these aggregate data” toward “policy ineffective.” That is too strong.

### C. Some textual interpretations do not track the reported uncertainty

For example, the paper interprets the null female hire-share result as “ruling out” composition effects (Abstract; Sections 4.4 and 5.3). That is not warranted. It rules out one simple composition margin, not broader composition or selection changes.

Likewise, the male/female decomposition is described as showing both genders had modest earnings growth, but neither estimate is significant and their difference is not tested. The paper should not over-interpret those coefficients.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Valid staggered-adoption inference
- **Issue:** The Callaway-Sant’Anna SEs are ad hoc and not valid.
- **Why it matters:** A paper making a null causal claim must have defensible inference; invalid SEs undermine the main robustness architecture.
- **Concrete fix:** Re-run CS or another modern staggered estimator correctly, with proper aggregation and simultaneous/pointwise uncertainty. If software is the obstacle, change software/workflow; do not report ad hoc SEs.

#### 2. Address local-policy contamination and treatment misclassification
- **Issue:** State-level treatment ignores city/county salary-history bans and earlier public-sector/local reforms.
- **Why it matters:** Misclassification likely biases effects toward zero, directly threatening the paper’s main conclusion.
- **Concrete fix:** Build a comprehensive database of sub-state salary-history restrictions; construct treatment intensity based on covered employment/population where possible; show sensitivity excluding states with major local pre-treatment bans or control states with substantial local exposure.

#### 3. Clarify and address selection in `EarnHirNS`
- **Issue:** The main new-hire wage outcome applies to hires who become stable, not all hires.
- **Why it matters:** Treatment could affect who survives into the measured outcome, confounding wage interpretation.
- **Concrete fix:** Analyze effects on hire stability/retention by sex using available QWI counts; compare `EarnHirNS` to alternative hire earnings measures if available (`EarnHirAS` or related measures); discuss selection formally and, if possible, bound its implications.

#### 4. Rework the DDD validation
- **Issue:** The main identifying assumption concerns the differential trend between new hires and incumbents, but the paper mainly shows separate event studies.
- **Why it matters:** The preferred design needs direct validation.
- **Concrete fix:** Estimate and plot a DDD event study (dynamic `Ban × NewHire` effects), with appropriate inference, and test pre-treatment leads of the interaction.

#### 5. Strengthen inference for main estimates
- **Issue:** State-clustered CRSE alone may be insufficient for a null-result staggered policy design.
- **Why it matters:** Under- or over-rejection directly affects the claim of precise null effects.
- **Concrete fix:** Add wild-cluster-bootstrap p-values/CIs for TWFE and DDD; implement RI/placebo inference for DDD, preserving the actual adoption structure as closely as possible.

### 2. High-value improvements

#### 6. Report weighted and unweighted estimates
- **Issue:** Equal weighting of states may not match the paper’s substantive interpretation.
- **Why it matters:** The null for the average state may differ from the null for the average worker/hire.
- **Concrete fix:** Report estimates weighted by state employment, hires, or inverse-variance proxies alongside unweighted results; explicitly define the estimand.

#### 7. Expand composition analysis
- **Issue:** Female hire share is too narrow a composition check.
- **Why it matters:** Aggregate cell means can hide meaningful within-cell shifts.
- **Concrete fix:** Use QWI stratification by age/education/industry to test whether post-ban composition changes within sex account for the null; consider reweighting treated observations to pre-treatment composition.

#### 8. Explore alternative treatment timing definitions
- **Issue:** Coding partial-quarter effective dates as fully treated may blur dynamics.
- **Why it matters:** Misaligned timing can attenuate true effects and flatten event studies.
- **Concrete fix:** Re-estimate using first full quarter treated, exposure-share treatment, and lagged implementation specifications.

#### 9. Broaden concurrent-policy controls/sensitivity analyses
- **Issue:** Excluding only CO/CA/WA is limited.
- **Why it matters:** Other bundled reforms may confound treatment.
- **Concrete fix:** Add a richer policy-control matrix and/or leave-one-state-out and leave-one-cohort-out analyses; report whether results are driven by particular cohorts.

#### 10. Recalibrate claims about “precisely estimated zero”
- **Issue:** Current wording overstates what the design establishes.
- **Why it matters:** Strong claims require stronger inferential and identification support than currently provided.
- **Concrete fix:** Rewrite abstract/introduction/conclusion to emphasize “no evidence of economically large effects in aggregate state-level QWI outcomes,” unless stronger validation is added.

### 3. Optional polish

#### 11. Add a unified estimand discussion
- **Issue:** The paper moves between aggregate policy effect, average state effect, and mechanism test.
- **Why it matters:** Readers need to know exactly what quantity is being estimated.
- **Concrete fix:** Include a short subsection clarifying estimands for TWFE, weighted TWFE, DDD, and any worker-weighted interpretation.

#### 12. Test heterogeneity by enforcement strength or statutory strictness
- **Issue:** Discussion emphasizes heterogeneous enforcement but does not test it.
- **Why it matters:** Even a null average effect could mask effects in stronger-law states.
- **Concrete fix:** Code private right of action, penalties, voluntary-disclosure loopholes, employer-size thresholds, and estimate heterogeneity or dose-response patterns.

#### 13. Tighten mechanism interpretation
- **Issue:** Some explanations in the Discussion are speculative.
- **Why it matters:** The paper is strongest as a careful reduced-form null.
- **Concrete fix:** Label compliance, porosity, and signal substitution explicitly as hypotheses, not findings.

## 7. Overall assessment

### Key strengths
- Important policy question with high external relevance.
- Creative use of QWI to isolate the hiring margin.
- Thoughtful attempt to use a within-state comparison via DDD.
- Broad state-by-quarter panel with staggered policy variation.
- The paper treats a null result seriously rather than burying it.

### Critical weaknesses
- Invalid/incomplete inference for key staggered-adoption robustness results.
- Main DDD design not directly validated with the appropriate event-study interaction.
- Treatment misclassification from local laws is a serious unaddressed threat.
- Selection/composition concerns from the `EarnHirNS` definition are under-addressed.
- Claims of “precisely estimated zeros” and strong policy conclusions are overstated relative to the design as currently implemented.

### Publishability after revision
I do not think the paper is currently ready for acceptance or minor revision. But I do think there is a potentially publishable paper here if the author substantially strengthens identification and inference. In particular, if the paper can (i) correctly implement modern staggered-adoption inference, (ii) deal seriously with local-policy contamination, (iii) validate the DDD directly, and (iv) address the selection inherent in the QWI new-hire measure, then the null finding would become much more persuasive and potentially important.

DECISION: MAJOR REVISION