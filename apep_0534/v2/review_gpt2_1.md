# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T13:13:32.618087
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 17637 in / 4721 out
**Response SHA256:** c83688c27e23226d

---

Referee Report on “Does Examiner Leniency Affect Cumulative Green Innovation? Evidence from USPTO Application-Level Data”

## Summary

This paper asks whether assignment to a more lenient USPTO examiner affects cumulative green innovation. The paper’s strongest component is the application-level first stage using PatEx data with both grants and abandonments. That is a meaningful data contribution relative to grants-only examiner-IV implementations. The paper also has the virtue of candor: the author repeatedly acknowledges that the downstream outcome is measured at a far more aggregated level than treatment assignment, and that the strongest causal interpretation therefore breaks down.

That honesty is welcome, but it also reveals the central problem: in its current form, the paper does not deliver a publishable causal estimate of the effect of patent grants on cumulative green innovation. The main follow-on outcome varies only at the CPC subclass × filing-year level (96 cells), while the identifying variation is examiner assignment within art-unit × filing-year cells. The application-level regressions are pseudo-replicated; the subclass-year collapse does not preserve the quasi-random assignment argument; and the art-unit-year collapse, which is closer to the assignment design, yields a null. The paper’s own best evidence therefore undermines the headline question rather than answering it.

For a top general-interest journal or AEJ:EP, this is not publication-ready. The paper could become a useful methodological or measurement note, or a redesigned paper with a downstream outcome measured at the application/patent level. But in its current form, the scientific substance is not yet strong enough.

## 1. Identification and empirical design

### A. First-stage design: credible and potentially useful

The paper’s cleanest contribution is the use of PatEx application-level data including abandonments. That avoids a major selection problem in grants-only designs and allows a proper first-stage relationship between examiner leniency and grant probability. The first-stage magnitude is large and precisely estimated (\Cref{tab:firststage}). This part of the design is coherent and, on its own terms, credible.

That said, even here the design would benefit from clearer validation of quasi-random assignment within art-unit × filing-year cells. The paper relies heavily on institutional arguments, but the empirical balance evidence is thin and partly post-treatment (grants-only balance tests in \Cref{tab:balance}). For a top journal, the assignment-as-good-as-random claim needs stronger direct support using pre-determined observables, queue features, examiner workload measures, or timing-based diagnostics.

### B. Main causal design for cumulative innovation: not credible as stated

The central identification problem is severe and, in my view, dispositive.

The downstream outcome—follow-on Y02 patenting in the same CPC subclass within 3/5/10 years—varies only at subclass × filing-year level, with 96 unique values total (8 subclasses × 12 years; see Introduction, Empirical Strategy, and Aggregation Analysis). The examiner assignment variation is quasi-random within art-unit × filing-year cells. These are not the same level of variation.

That mismatch generates three related failures:

1. **Application-level regressions do not identify the causal effect of examiner assignment on follow-on innovation.**  
   Every application in a given subclass-year shares the same outcome. Running 640,845 application-level regressions with 96 unique outcomes does not recover micro-level treatment effects; it mechanically overweights cells with many applications and treats shared outcomes as if they were individual outcomes.

2. **The subclass × year collapse does not inherit the random assignment assumption.**  
   The paper explicitly acknowledges this, correctly. Random examiner assignment is within art-unit × filing-year, not subclass × filing-year. Once collapsing to subclass-year means, composition of art units within subclass-year cells can vary systematically, and average examiner leniency may correlate with technology mix, art-unit composition, or the grant/abandonment composition induced by the Y02 assignment procedure. Hence the negative coefficient in the 96-cell collapsed regression is not causally identified from the examiner assignment design.

3. **The art-unit × year collapse is the only collapse aligned with assignment, and it yields a null.**  
   This is an important result, but it cuts against the paper’s motivating claim. If the design-congruent aggregation shows no effect, while the design-incongruent aggregation shows a negative effect, the appropriate conclusion is that the paper does not identify the causal effect of patent grant propensity on cumulative innovation using the available follow-on measure.

The manuscript does eventually reach a version of this conclusion, but that means the current paper is more a demonstration of design failure than a persuasive answer to the substantive question. That can still be publishable in some outlets if the methodological lesson is novel and tightly executed; here, however, the downstream design problem is too fundamental.

### C. Y02 sample definition and subclass imputation are potentially consequential threats

The paper defines “green” applications by identifying Y02-heavy art units from granted patents and then including all applications in those art units, including abandonments. It then imputes subclass for abandoned applications using the modal subclass of granted patents in the art unit (Data section; Sample Construction).

This is a major measurement choice, not a minor convenience. It creates at least three threats:

- **Selection via grants-only mapping of Y02 art units.** Art units are labeled “green” using the CPC composition of grants only. If more lenient examiners are associated with different grant composition, the sample definition itself may depend on grant outcomes.
- **Systematic misclassification of abandonments.** Assigning all abandonments in an art unit to the modal granted subclass may substantially distort subclass-year counts and exposure measures, especially because the main outcome is subclass-specific.
- **Mechanical attenuation or spurious composition effects.** The paper suggests this is “conservative” and biases toward zero, but that is not established. Misclassification need not be classical here; it may be correlated with examiner behavior, art-unit composition, or abandonment propensity.

Given that the main reduced-form outcome is already only observed at subclass-year level, this imputation problem becomes central. It could easily drive differences between subclass-year and art-unit-year collapses.

### D. Treatment timing and estimand need sharper articulation

The paper uses filing date as the start of the follow-on window because abandonments lack grant dates. That means the outcome includes innovation realized before final disposition, especially in the 3-year window and likely part of the 5-year window. The paper acknowledges this and interprets estimates as ITT from filing onward, not post-grant effects. That is reasonable, but then claims about whether “patent grants block cumulative innovation” must be calibrated accordingly. The design does not isolate the post-grant legal-right channel.

### E. Exclusion restriction for IV is not credible

The paper is right not to lean on the IV results. Examiner leniency likely affects prosecution duration, claim scope, amendment intensity, continuation behavior, and the breadth/clarity of allowed claims. Those are not incidental concerns; they directly undermine the exclusion restriction. The IV estimates should not play a substantive role in the paper’s contribution. At present they are presented cautiously, which is good, but for a top-journal paper I would either remove them from the main results or relegate them fully to an appendix.

## 2. Inference and statistical validity

This is the most serious problem after identification.

### A. Main application-level inference is not valid for the substantive claim

The paper itself recognizes pseudo-replication, but the extent of the problem is such that the headline application-level p-values should not be used as evidence. With only 96 unique follow-on outcome values, application-level clustering at examiner, art unit, or even subclass × year does not solve the deeper issue that the estimand is effectively aggregate while the regression treats it as micro-level.

The manuscript repeatedly reports highly precise application-level coefficients (e.g., \Cref{tab:main}, \Cref{tab:cluster}), but these do not have a straightforward causal interpretation. In particular, clustering at subclass × year when there are only 96 outcome cells is not enough to validate the design. Nor is the permutation exercise persuasive, since it preserves the same pseudo-replicated structure.

### B. Collapsed-regression inference is also underdeveloped

For the collapsed subclass × year regressions with 96 observations (\Cref{tab:robust}, Panel C), the paper appears to use heteroskedasticity-robust standard errors. With only 96 cells—and more importantly with serial and cross-sectional dependence likely present in innovation counts—this is weak. At minimum, inference should be re-done using approaches appropriate for few aggregated cells and potential dependence: wild bootstrap, randomization/permutation at the relevant assignment level, or block/bootstrap methods justified by the data structure.

Even more importantly, because the subclass-year collapse does not preserve quasi-random assignment, stronger inference does not rescue identification.

### C. Two-way clustering is not correctly motivated

\Cref{tab:cluster} reports “Two-way (Exam x CPC)” clustering, but the paper does not explain why this is the relevant asymptotic framework. Since the outcome varies at subclass × year, clustering by examiner and CPC subclass omits the time dimension that is central to the shared-outcome problem. More generally, presenting a menu of clustering choices without a clear justification risks looking like specification searching.

### D. Sample sizes are coherent, but effective sample size is not transparently treated

The paper reports the nominal sample size consistently. However, for the follow-on regressions the effective sample size is much closer to 96 or, at best, to the number of assignment-consistent aggregate cells. That distinction needs to be front-and-center, not mainly a caveat.

### E. Power discussion is misleading in current form

The Statistical Power subsection uses application-level standard errors to argue the paper is highly powered to detect small effects. The paper later concedes this precision is overstated. I think the power calculation should be dropped unless re-done using the actual effective sample size under the aggregate outcome design. As written, it overstates inferential strength.

## 3. Robustness and alternative explanations

### A. Robustness checks do not address the core identification problem

Most robustness exercises in \Cref{tab:robust} vary functional form or sample restrictions at the application level. These are not very informative once the main problem is that the outcome is shared at a far more aggregate level than the treatment assignment. A Poisson regression, winsorization, or “experienced examiners” sample does not address the design mismatch.

### B. The placebo is not a meaningful falsification test

The placebo outcome—follow-on in other CPC subclasses—is not a clean placebo. The paper itself notes that within-year totals and own-subclass/other-subclass decomposition mechanically induce dependence. I agree. As a result, this test provides little information about causal validity.

A useful falsification would need an outcome that should not plausibly respond to examiner leniency and that is measured at the same level as the treatment variation. The current placebo does neither.

### C. Forward-citation analysis is mechanically contaminated

The paper is admirably clear that forward citations are mechanically affected because abandoned applications cannot be cited as patents. That makes the forward-citation results largely uninformative about knowledge spillovers or cumulative innovation. Since the domain heterogeneity analysis is based only on this contaminated outcome (\Cref{tab:hetero}), that section adds little scientific value in its current form.

### D. Mechanism claims are mostly appropriately restrained

The discussion distinguishes reduced-form effects from mechanisms, which is good. However, some passages still flirt with substantive interpretations such as “blocking” or “cross-subclass redirection” that are not identified. Given the fragility of the downstream design, those mechanisms should be framed more explicitly as conjectures rather than evidence-backed interpretations.

### E. External validity is discussed reasonably

The paper is careful about the local nature of the estimand, the 2001–2012 sample period, and the difference between marginal grant effects and broader IP regime effects. This is a strength.

## 4. Contribution and literature positioning

### A. Contribution is currently overstated relative to what is identified

The paper’s real contribution is narrower than the title and framing suggest. It is not persuasive evidence that examiner leniency affects cumulative green innovation. Rather, it is evidence that:

1. application-level PatEx data improve the first-stage design relative to grants-only studies; and
2. with currently available coarse downstream outcomes, the examiner-IV design cannot credibly answer the cumulative green innovation question.

That is a potentially useful contribution, but it is methodological/measurement-oriented, not a substantive answer to the policy question posed in the title.

### B. Literature coverage is generally solid, but some additional references would help

The paper already cites much of the right substantive literature. I would still encourage adding or more directly engaging with the following strands:

- **Judge/examiner IV methodology and cautionary interpretation** beyond the cited Chyn et al. framework, especially work emphasizing exclusion, treatment heterogeneity, and leave-one-out issues.
- **Patent examination and examiner behavior**: more on how examiners affect claim scope, pendency, amendments, and continuations, not only grant rates. This matters directly for why IV is hard to interpret.
- **Green patent measurement / Y02 classification validity**: the paper should cite work discussing the construction and limitations of Y02 as a green innovation measure, because the empirical design depends heavily on Y02 subclass assignment.

Concrete additions to consider:
- Hall, Jaffe, and Trajtenberg on patent citations and measurement issues.
- Frakes and Wasserman on patent examination and examiner incentives/behavior.
- de Rassenfosse and coauthors on patent data construction and patent examination outcomes.
- OECD/EPO work on Y02/CPC green technology classification and its limits.

These additions would help the paper better position its measurement choices and inference limits.

## 5. Results interpretation and claim calibration

### A. The paper is more calibrated than most, but still not fully calibrated

To the paper’s credit, the abstract and conclusion already retreat from strong causal claims and emphasize the fragility of the downstream evidence. That is appropriate.

Still, several places continue to summarize the subclass-year negative estimate as if it is substantive evidence of less follow-on innovation, when the paper itself shows that this estimate is not identified by quasi-random examiner assignment. The text should not oscillate between “negative estimate” and “not causal.” The latter should dominate.

### B. Effect sizes are small in application-level reduced forms and unstable across aggregation

The main application-level reduced form is economically tiny (-0.0067 log points per 1 SD leniency), while the collapsed subclass-year estimate is large (-0.193) and the art-unit-year estimate is near zero. This instability is the central empirical result. The paper should foreground that the effect size is not just uncertain statistically—it is not stable across conceptually relevant aggregations.

### C. Policy implications should be toned down further

The manuscript concludes that patent-office decisions do not appear to be binding constraints on cumulative green innovation. That claim is still stronger than the evidence warrants. The design does not permit that inference because the main outcome is too coarse and misaligned with treatment assignment. The safer conclusion is: with the available aggregate follow-on outcome, the paper cannot credibly detect a robust causal effect of examiner leniency on cumulative green innovation.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild the downstream outcome so it varies at the application/patent level
- **Issue:** The current follow-on outcome is measured at subclass × filing-year level (96 cells), which breaks the examiner-assignment identification design.
- **Why it matters:** Without outcome variation at or near the assignment level, the paper cannot support its core causal claim.
- **Concrete fix:** Construct a downstream outcome tied to the focal application/patent: e.g., future patents citing the focal patent/application (if application publication data can be used), text-similarity-based follow-on patenting in proximate technology space, same-assignee or rival follow-on innovation around the focal application, or application-publication-based measures that include abandoned applications. If such an outcome cannot be built, the paper should be reframed as a methodological cautionary note rather than a causal study of cumulative innovation.

#### 2. Remove application-level follow-on regressions as headline evidence
- **Issue:** The current main tables report pseudo-replicated application-level regressions with misleading nominal precision.
- **Why it matters:** Invalid or weakly justified inference disqualifies the paper in its current form.
- **Concrete fix:** Either drop these estimates from the main text or explicitly demote them to descriptive evidence with no inferential weight. The main empirical design must rely on an assignment-consistent outcome structure.

#### 3. Address Y02 sample construction and subclass imputation much more rigorously
- **Issue:** Green status and subclass for abandonments are inferred indirectly from grants and art-unit modal subclass.
- **Why it matters:** This could generate nonclassical measurement error and compositional bias in exactly the variables driving the main results.
- **Concrete fix:** Provide validation of art-unit-to-Y02 mapping against alternative thresholds and external concordances; show how many art units are nearly mixed; quantify imputation error using granted patents as a holdout exercise; and re-estimate results under alternative subclass assignments or without subclass-specific analyses for abandonments.

#### 4. Redo inference using the actual effective unit of variation
- **Issue:** Current standard errors and power claims are based on nominal rather than effective sample size.
- **Why it matters:** Statistical significance is not credible under the present inferential framework.
- **Concrete fix:** If aggregate outcomes remain, use aggregate-cell regressions only, justify the identifying variation at that level, and use inference appropriate for few clustered/serially dependent cells. Remove power calculations based on application-level SEs.

### 2. High-value improvements

#### 5. Strengthen random-assignment validation
- **Issue:** Balance tests are weak and partly post-treatment.
- **Why it matters:** The first-stage design is only as credible as the quasi-random examiner assignment assumption.
- **Concrete fix:** Expand PatEx extraction to include pre-treatment observables if available: continuation status, applicant type, inventor count, foreign priority, assignee status, application type, queue timing, etc. Show within-art-unit × year balance and perhaps examiner-switch or workload-based tests.

#### 6. Reframe the paper’s contribution around what is actually learned
- **Issue:** The title and framing promise a causal answer on cumulative green innovation that the paper does not deliver.
- **Why it matters:** Top-journal publication requires tight alignment between question, design, and contribution.
- **Concrete fix:** Recast the paper as: (i) a clean first-stage application-level examiner-IV contribution using PatEx; and (ii) evidence that existing green follow-on measures are too coarse to support causal downstream claims. That contribution is narrower but more credible.

#### 7. Move IV and forward-citation analyses out of the main contribution
- **Issue:** Both are structurally compromised: IV by exclusion failures, forward citations by mechanical contamination.
- **Why it matters:** They distract from the one genuinely useful contribution.
- **Concrete fix:** Relegate these to appendix or brief robustness discussion, and make clear they are not part of the paper’s core evidence.

### 3. Optional polish

#### 8. Clarify effective sample sizes in all tables
- **Issue:** Tables list large N even when outcome support is tiny.
- **Why it matters:** Readers need to understand the true information content.
- **Concrete fix:** Add a row for “unique outcome cells” or “effective outcome units” wherever relevant.

#### 9. Tighten interpretation of placebo and robustness sections
- **Issue:** Some exercises are not valid falsifications of the causal design.
- **Why it matters:** Weak tests can create false confidence.
- **Concrete fix:** Label them explicitly as descriptive sensitivity checks, not falsification tests.

#### 10. Expand discussion of what data would be needed to answer the question convincingly
- **Issue:** The conclusion points in this direction but could be more concrete.
- **Why it matters:** This would improve the paper’s value even if the main substantive question remains unanswered.
- **Concrete fix:** Lay out a roadmap using application publications, text-based nearest-neighbor inventions, or claim-level proximity measures.

## 7. Overall assessment

### Key strengths
- Strong and useful application-level first stage using grants plus abandonments.
- Honest discussion of the main design limitations.
- Careful distinction between reduced form and IV assumptions.
- Policy and external-validity claims are more restrained than in many papers.

### Critical weaknesses
- The main downstream outcome is fundamentally mismatched to the assignment design.
- Application-level inference for follow-on innovation is not credible.
- The subclass-year collapsed specification does not preserve identification.
- The art-unit-year specification aligned with assignment yields a null.
- Y02 sample construction and subclass imputation for abandonments introduce serious measurement concerns.
- Several reported analyses (IV, forward citations, placebo) are not informative about the core causal question.

### Publishability after revision
In its current form, I do not think the paper is publishable in a top general-interest journal or AEJ:EP. The core issue is not a missing robustness check but a mismatch between the available downstream outcome and the identifying design. If the author can construct a downstream outcome at the application/patent level, the paper could become a serious contribution. Without that redesign, the best version of the paper is likely a narrower methodological note showing that application-level PatEx data solve the first-stage selection problem but that currently available aggregate follow-on green outcomes do not support credible causal inference.

DECISION: REJECT AND RESUBMIT