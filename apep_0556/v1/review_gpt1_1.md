# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T17:11:41.405945
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 22827 in / 5258 out
**Response SHA256:** bd06ef1055531d66

---

This paper studies the effect of India’s NRHM on institutional delivery using state-level NFHS/DHS aggregates and a difference-in-differences design that compares “high-focus” states to later/lower-intensity states. The paper’s core empirical finding—a sizable differential increase in institutional delivery, especially in the EAG states—is plausible and policy-relevant. The paper is also admirably transparent about several limitations, especially the partial treatment of the comparison group and the weak mortality evidence.

That said, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ:EP. The main reason is not that the topic lacks importance, but that the identification and inferential foundations remain too weak relative to the strength of the causal claims. The paper has the bones of a potentially useful quasi-experimental study, but the current design relies on a very coarse state-by-round panel, an only partially informative pre-trend test, and a comparison group that is itself treated relatively quickly. These features do not kill the project, but they do mean the paper needs a substantial redesign or major strengthening before it can support the current claims.

## 1. Identification and empirical design

### A. What the design identifies is narrower than the paper often suggests

The paper is explicit in several places that the design compares early/high-intensity NRHM exposure to later/lower-intensity NRHM exposure, rather than NRHM versus no NRHM (Sections 4.1, 4.4, 8, 9). This is correct and important. However, the framing in the abstract, introduction, title, and conclusion still often reads as if the paper estimates “the effect of NRHM” more generally. That is too broad.

With NFHS-3 as “baseline” and NFHS-4/5 as post, the design is effectively asking whether high-focus states experienced larger long-run changes than lower-priority states after both groups had already been exposed for years. This is a meaningful estimand, but it is not the total program effect, and not even cleanly the “early vs late” effect in an event-time sense because the outcome windows are long recall aggregates.

This matters because many of the strongest policy interpretations (“NRHM moved 4 million births per year into facilities”) are stated in a way that sounds like national program impact rather than differential effect of priority designation.

**Bottom line:** the estimand must be narrowed and consistently described throughout as the long-run differential effect of being an early/high-intensity NRHM state relative to later/lower-intensity states.

### B. The baseline is contaminated in a way that is more serious than the paper allows

Section 3.3 and Section 4.4 acknowledge that NFHS-3 (2005–06) contains births from the prior five years and therefore includes some births exposed to NRHM after April 2005. This is treated as likely attenuation. I do not think the paper can simply wave this away.

The problem is deeper:

- NFHS-3 is not a clean pre-period.
- The amount of contamination likely varies by state depending on survey timing and implementation intensity.
- Because treatment began earlier and more intensively in the treated states, contamination is differential, not merely classical noise.
- With only one “baseline” round in the main design, this contamination directly affects the estimated DiD contrast.

It may attenuate, but the direction is not guaranteed, as the paper briefly notes. More importantly, if the main 3-round design is the paper’s preferred specification, then the lack of a clean pre-treatment baseline is a first-order identification problem, not a minor caveat.

A top-journal version of this paper would need a design that uses actual birth-year data or at least narrower windows that isolate clearly pre- and post-program births. With DHS/NFHS microdata, the author could construct birth-cohort-by-state outcomes and estimate effects by birth year relative to rollout. Using API-level five-year aggregates is too blunt for the policy timing at issue.

### C. Parallel trends evidence is far too limited for the preferred specification

The central identification assumption is parallel trends. The paper’s formal pre-trend test for the preferred EAG-only specification uses only 2 of the 8 treated EAG states (Odisha and Rajasthan; Sections 4.3, 6.1, Appendix B). This is not enough to validate parallel trends for the preferred treated group.

The paper is honest about this limitation, but the substantive implication is underplayed. A null pre-trend among 2 treated states does not do much to reassure me about the remaining 6 treated EAG states, especially given:

- treatment assignment was based on poor baseline health conditions,
- institutional delivery is a bounded variable with strong convergence/ceiling dynamics,
- untreated comparisons started at much higher baseline levels (Table 1),
- the outcome rose sharply nationwide over the period.

In other words, the biggest threat here is not level differences per se; it is differential nonlinear convergence. The treated states started much lower, and the controls were already close to high institutional-delivery levels by NFHS-3. A large absolute catch-up in low-baseline states is exactly what one would expect even absent treatment under bounded diffusion or broader development convergence.

The paper has a “low baseline × post” heterogeneity exercise (Section 6.4), but that is not an adequate response. What is needed is a design that explicitly addresses differential baseline trends/convergence, for example:
- matched or reweighted controls,
- synthetic control / synthetic DiD at the state-group level,
- inclusion of flexible controls for baseline outcome levels,
- or, best of all, microdata-based cohort/event-study designs.

### D. The state composition / boundary issue undermines the long-panel evidence

The paper repeatedly notes that pre-2000 rounds report undivided parent states while post-2000 rounds report successor states separately (Sections 3.2–3.3, 4.2–4.3, 5.3, Appendix A). This means the five-round event-study and full-panel specification do not track comparable geographic units over time.

The paper appropriately downgrades those results to “supplementary,” but then still uses them visually and rhetorically as supportive evidence. I would advise treating these as descriptive only and not as identification-relevant evidence.

### E. Excluding NE states is understandable substantively, but the preferred specification becomes selective

The decision to prefer the EAG-only treated sample is intuitively sensible, and Appendix D shows treatment heterogeneity. But the paper’s strongest estimate comes from a specification chosen after observing that the northeast behaves differently. This may be substantively justified, but it raises a risk of specification search. At minimum, the preferred sample selection needs to be defended ex ante and linked to a stronger comparability strategy, not simply larger estimated effects.

### F. Threats from concurrent policies are not convincingly addressed

Section 4.4 discusses concurrent programs but does not do much empirically. Over 2005–2020, there were many national and state-specific changes in maternal and child health, roads, sanitation, and female education. In a 3-round state panel with no covariates and a treated group chosen for low development, this is a serious concern.

State and year fixed effects do not solve this if treated and comparison states were on different trajectories because of these other changes. A top-field paper would need either richer controls, a stronger within-state timing design, or individual microdata allowing finer timing.

## 2. Inference and statistical validity

This is the area where the paper is better, but still not fully convincing.

### A. Standard errors are reported, but inference remains incomplete

The main tables report clustered SEs, which is necessary. The paper also adds randomization inference (RI), which is a useful supplement given the small number of treated clusters. That is a strength.

However:

1. **Wild cluster bootstrap** would be more standard and informative here than or in addition to RI.
2. The RI procedure needs stronger justification. The treatment was not randomly assigned; permutation tests are only compelling if the assignment mechanism under the null is plausible or if RI is presented as a sensitivity check rather than quasi-exact inference.
3. With such a small number of treated clusters in the preferred specification (8 EAG states), finite-sample reliability should be assessed more systematically.

### B. The “continuous treatment” specification is not an independent robustness test

Column 3 of Table 2 is presented as a continuous-treatment check using JSY intensity. But in the implementation described, JSY intensity takes only two values: 1.4 for treated states and 0.8 for comparison states. This is just an affine transformation of the same binary treatment. Therefore it does not provide independent identifying variation.

The paper’s claim that this “internal consistency strengthens confidence” overstates what this specification adds. It is mathematically equivalent to the binary contrast up to scaling. It should be presented as a rescaling exercise, not a separate robustness result.

### C. Sample sizes are reported, but the effective information content is much smaller than N suggests

The paper reports observation counts like 72, 96, and 138. But the effective number of independent units is the number of states, and in the preferred specification it is quite small. This should be emphasized more clearly when interpreting precision and power.

### D. Outcome measurement error / unequal precision is ignored

This is an underappreciated but important issue. The dependent variables are state-level DHS/NFHS estimates obtained from STATcompiler, each with its own survey SE. Some state-round means are estimated far more precisely than others, especially small states/UTs. The regressions treat them all equally and ignore first-stage sampling uncertainty in the dependent variable.

This does not necessarily bias OLS coefficients, but it affects efficiency and potentially inference if measurement error differs systematically by state size/treatment status. At minimum the paper should:
- report the distribution of DHS sampling SEs,
- consider precision-weighted estimation,
- and show that results are not driven by small, noisy state/UT estimates.

The current unweighted “mean-state” estimand may be acceptable as one estimand, but for publication in a top outlet the paper should also report population- or births-weighted estimates.

## 3. Robustness and alternative explanations

### A. Current robustness checks are too narrow relative to the main threats

The robustness section focuses on:
- pre-trends,
- RI,
- leave-one-out,
- baseline heterogeneity,
- “continuous” treatment.

These are useful, but they do not address the main alternative explanation: differential convergence from low baseline levels under a bounded outcome.

The key missing robustness exercises are:

1. **Population- or births-weighted regressions.**
2. **Dropping union territories and very small units** whose estimates are noisy and substantively atypical.
3. **Controls or matching on baseline level** of institutional delivery and other state characteristics.
4. **Alternative functional forms** for bounded outcomes (logit transform or fractional response at the state aggregate level).
5. **A specification using only larger, more comparable states** and perhaps only rural births if the policy was rural-focused.
6. **Microdata-based birth-year analysis** as the decisive robustness/redesign.

### B. Placebo/falsification evidence is weak

The paper mentions anemia as a placebo-type outcome in summary statistics (Section 3.4), but does not actually present a placebo regression. Even if it did, anemia among women 15–49 is not an especially sharp placebo for NRHM exposure, given broad changes in nutrition and public health.

More compelling falsifications would be:
- pre-program outcomes using actual birth-year microdata,
- outcomes that should not react in the short run to NRHM intensity,
- or placebo treatment dates.

### C. Mechanism claims are still too strong

The paper is generally careful to say the treatment is the bundle of ASHAs, JSY, and facility upgrades. That is appropriate. But some passages infer that the stronger effect on delivery than ANC suggests financial incentives/logistics were the operative mechanisms (Sections 5.1, 7.3). This is plausible but still speculative because the paper does not separately identify components.

Mechanism language should remain explicitly suggestive.

### D. Mortality discussion is substantially overextended

This is my second-largest concern after identification.

The paper repeatedly foregrounds the question “But did newborns actually survive?” and develops a “facility quality paradox” around national neonatal mortality trends plus prior literature. But the paper does not estimate mortality effects causally, and the national mortality figure is not a credible test of whether NRHM’s differential treatment changed neonatal mortality.

A smooth national trend does not imply no differential effect in treated states. It could easily coexist with meaningful but heterogeneous impacts. The discussion section acknowledges this, but the introduction, abstract, and conclusion still leverage the mortality angle heavily.

This should be scaled back materially unless the paper adds a state-level mortality analysis using birth histories from NFHS microdata. Without that, the mortality angle is closer to motivation than finding.

## 4. Contribution and literature positioning

The contribution is potentially meaningful: a long-run evaluation of India’s NRHM using nationally representative data and modern DiD awareness. The topic is important and broad-interest.

But the paper currently oversells novelty in two ways:

1. **Methodological novelty.** The paper suggests it “resolves” earlier disagreement because it brings a longer panel and a pre-trend test. Given the very limited pre-trend coverage and contaminated baseline, that claim is too strong.
2. **Substantive reconciliation on mortality.** The paper does not really reconcile the literature so much as document utilization effects and speculate about mortality.

I would encourage stronger engagement with:
- the broader JSY/NRHM evaluation literature beyond the three focal papers,
- studies using NFHS or DLHS microdata on institutional delivery and maternal-child outcomes,
- and the literature on diffusion/convergence in maternal health service use in India.

On methods, the paper cites Goodman-Bacon, Callaway-Sant’Anna, Sun-Abraham, and Roth. That is good. But the key design challenge here is not standard staggered-adoption bias so much as weak comparability and outcome timing. The methods discussion would be more credible if it spent less time defending against staggered-TWFE critiques and more time confronting convergence and aggregate-outcome limitations.

## 5. Results interpretation and claim calibration

### A. Main institutional-delivery result: plausible, but should be more cautiously framed

The core result—a differential increase in institutional delivery in high-focus states—is plausible and likely directionally correct. But the current language at times exceeds what the design can support.

In particular, the implied calculation of “4.1 million additional facility-based deliveries per year” (Section 5.2) is too strong given:
- the estimand is differential, not total,
- the analysis is unweighted,
- the preferred estimate comes from the EAG-only specification,
- and the identification assumptions are not yet secure enough for national aggregate scaling.

This kind of back-of-the-envelope policy extrapolation is better omitted or heavily qualified.

### B. ANC results are weak and should be treated as secondary

The ANC effect is marginally significant and less stable. That is fine, but mechanism interpretation should not lean heavily on it.

### C. Mortality and facility quality conclusions are not supported by reported estimates

The paper repeatedly suggests that large delivery gains did not translate into proportionate survival gains. This is not established by the reported evidence. At most, the paper shows:
- differential increases in institutional delivery,
- and separately, a descriptive national decline in mortality.

Those facts do not identify the marginal mortality effect of NRHM. The paper should clearly separate:
1. what it estimates,
2. what prior work estimates,
3. and what it speculates.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Redesign the empirical analysis using individual-level birth histories or narrower birth-cohort cells
- **Issue:** The current API-based state-round panel uses 5-year recall aggregates, creating a contaminated baseline and very coarse timing.
- **Why it matters:** This is the central identification weakness. Without a cleaner pre/post structure, the main DiD is hard to interpret causally.
- **Concrete fix:** Use NFHS microdata to construct birth-level or state-by-birth-year outcomes, then estimate event-time effects around 2005 and 2008–10 rollout, ideally separating clean pre, transition, and post periods.

#### 2. Address the parallel-trends/convergence problem directly
- **Issue:** The preferred pre-trend test covers only 2 of 8 treated EAG states, while treated states start much lower on a bounded outcome.
- **Why it matters:** Differential catch-up could explain a substantial share of the estimated effect.
- **Concrete fix:** Implement matched/reweighted controls, synthetic DiD/synthetic control, or explicit controls for baseline outcome level and nonlinear convergence. Show results are robust.

#### 3. Reframe the estimand consistently as differential treatment intensity/timing
- **Issue:** The paper often slides from “differential effect of early/high-intensity NRHM” to “effect of NRHM.”
- **Why it matters:** Overstating the estimand distorts contribution and policy implications.
- **Concrete fix:** Rewrite abstract, introduction, results, and conclusion so that every causal claim is consistently about priority-state differential exposure.

#### 4. Remove or sharply scale back mortality claims unless new analysis is added
- **Issue:** National mortality trends do not support causal claims about NRHM’s mortality effects.
- **Why it matters:** This is currently the paper’s main overclaim.
- **Concrete fix:** Either add a state-level or birth-level mortality analysis using NFHS birth histories, or reposition the mortality discussion strictly as motivation/future work.

#### 5. Strengthen inference
- **Issue:** Clustered SEs with few treated clusters and ad hoc RI are not fully sufficient.
- **Why it matters:** A paper cannot pass without credible inference.
- **Concrete fix:** Add wild-cluster-bootstrap p-values/CIs, clarify the RI assignment mechanism, and report inference robustness across methods.

### 2. High-value improvements

#### 6. Report weighted estimates
- **Issue:** Current regressions are unweighted and answer a “mean state” question.
- **Why it matters:** Policy relevance in India depends heavily on population/birth weighting.
- **Concrete fix:** Report population- or births-weighted specifications alongside unweighted results and discuss estimand differences.

#### 7. Show robustness to excluding small UTs and atypical units
- **Issue:** Small UTs may contribute noise and are substantively unlike states.
- **Why it matters:** Comparability and precision.
- **Concrete fix:** Re-estimate after dropping UTs and very small states.

#### 8. Stop presenting the JSY-intensity model as an independent robustness check
- **Issue:** With only two intensity values, it is just a rescaling of the binary treatment.
- **Why it matters:** Current presentation overstates evidentiary breadth.
- **Concrete fix:** Recast it as interpretive rescaling, or replace with truly continuous within-state/state-year exposure if available.

#### 9. Incorporate survey precision of dependent variables
- **Issue:** DHS state estimates have unequal sampling precision.
- **Why it matters:** Efficiency and possibly inference.
- **Concrete fix:** Report precision-weighted regressions or sensitivity to inverse-variance weights.

#### 10. Expand engagement with the India-specific policy literature
- **Issue:** Literature review is too selective for such a heavily studied policy area.
- **Why it matters:** Contribution must be situated against the broader JSY/NRHM evidence base.
- **Concrete fix:** Add a fuller review of NRHM/JSY studies using DLHS/NFHS and administrative data, especially those addressing utilization versus health outcomes.

### 3. Optional polish

#### 11. Clarify sample construction and control composition in one transparent table
- **Issue:** The state composition across rounds/specifications is hard to follow.
- **Why it matters:** Replicability and interpretation.
- **Concrete fix:** Add a table listing all units, treatment status, availability by round, and whether included in each specification.

#### 12. Tone down “resolving the literature” language
- **Issue:** The current evidence is suggestive, not definitive.
- **Why it matters:** Claim calibration.
- **Concrete fix:** Present the paper as adding evidence on utilization effects rather than settling the broader debate.

## 7. Overall assessment

### Key strengths
- Important policy question with broad interest.
- Clear statement that the treatment is a bundle, not a single component.
- Good transparency about several limitations.
- Main utilization result is plausible and substantively interesting.
- Sensible attention to finite-sample inference via RI and to heterogeneity across EAG vs northeast.

### Critical weaknesses
- Main design lacks a clean pre-treatment baseline because NFHS-3 is contaminated.
- Preferred pre-trend evidence is too weak to validate parallel trends for the treated sample actually used.
- Differential convergence/ceiling effects are not adequately addressed.
- State-level API aggregates are too coarse for the timing of the intervention.
- Mortality discussion materially overreaches the evidence.
- Some robustness checks are weaker than advertised, especially the “continuous treatment” model.

### Publishability after revision
In my view, this is not a minor-revision paper. The topic is promising, but publication in a top field or general-interest journal would require substantial empirical strengthening—most likely a redesign around microdata and cleaner timing. If the author can implement that redesign, the project could become publishable. In its current form, however, the causal claims are ahead of the design.

DECISION: REJECT AND RESUBMIT