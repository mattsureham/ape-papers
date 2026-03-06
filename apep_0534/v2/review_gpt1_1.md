# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T13:13:32.614268
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 17637 in / 4735 out
**Response SHA256:** d48e00a43dff2fb6

---

This paper asks an important question: whether marginal patent grants in green technologies hinder or stimulate cumulative innovation. The paper’s most credible contribution is to show, using application-level PatEx data with grants and abandonments, that examiner leniency strongly predicts grant outcomes in a large sample of green-technology applications. That is useful and potentially publishable as part of a broader design contribution. However, the paper’s stated causal question is about downstream cumulative innovation, and on that central question the empirical design is not publication-ready.

The manuscript is unusually candid about its own limitations, which I appreciate. In fact, many of the core problems are correctly diagnosed by the author. But for a top general-interest journal or AEJ: Economic Policy, acknowledgment of a design failure is not enough; the paper needs a design that can actually identify the object of interest with valid inference. At present, the downstream analysis does not do so.

## 1. Identification and empirical design

### Main identification claim

The paper’s intended identification strategy is quasi-random examiner assignment within art-unit-by-filing-year cells, using examiner-specific grant propensity as an instrument or reduced-form treatment intensity. This is credible for the **first-stage question**: does assignment to a more lenient examiner affect whether an application is granted? The answer appears to be yes, strongly.

But the central causal claim in the title and framing concerns **cumulative green innovation**. For that question, the design breaks down because the main downstream outcome is not observed at the level of randomization or treatment.

### Core design mismatch: treatment at application level, outcome at subclass-year level

This is the paper’s central problem, and the author recognizes it in Sections 4–7, especially “Threats to Validity” and “Aggregation Analysis.” The follow-on outcome varies only at the CPC subclass × filing-year level (96 cells). Yet examiner assignment is quasi-random only within art-unit × filing-year cells. Therefore:

- the application-level reduced form is pseudo-replicated;
- the subclass-year collapsed regression does **not** inherit the random assignment that motivates the examiner design;
- the art-unit-year collapse is closer to the assignment mechanism, but then the outcome is too aggregated/misaligned to capture the hypothesized within-subclass blocking channel.

This is not a minor inference issue; it is a **fundamental identification failure** for the downstream claim.

The paper is right to say that the subclass-year result may be confounded by composition. But that means the main negative finding is not causally interpretable. The art-unit-year null is also not dispositive, because it may average away the relevant margin. The correct conclusion is stronger than the paper currently states: the current data do not support a causal downstream estimate.

### Assumptions are partly explicit, but not adequately validated

The paper clearly states relevance, independence, and exclusion assumptions in Section 5. That is a strength. However:

- **Independence / random assignment** is only weakly validated. The balance tests are on grants only, which conditions on treatment, and therefore are not informative in the needed way.
- The claims variable shows statistically significant imbalance even in that problematic grants-only sample (Table 3 / balance table). This is not fatal by itself, but it weakens confidence in the assignment design.
- The paper says small entity status has no within-cell variation; that is surprising and should be documented carefully. It raises concern either about sample construction or variable extraction. If true, the paper needs more comprehensive pre-treatment covariates from PatEx or linked sources.
- For the downstream analysis, even perfect random assignment within art-unit-year would not solve the key problem, because the outcome is measured at subclass-year, not application or art-unit-year in a way consistent with assignment.

### Exclusion restriction for IV is not credible as implemented

The paper is appropriately cautious about IV interpretation and mostly backs away from it. That is good. Still, the IV estimates are presented in the main table, and the text sometimes refers to “marginal grant” effects. Given examiner heterogeneity in:

- prosecution duration,
- claim narrowing,
- continuation practice,
- office actions,
- amendments and scope,

the exclusion restriction is not believable without much richer evidence. This is especially true in light of the paper’s own citation to Frakes and related work. For a paper centered on cumulative innovation, the reduced form may be policy-relevant as “examiner leniency bundle,” but then the title, framing, and causal interpretation need to match that narrower estimand.

### Treatment timing is only partially coherent

The paper defines follow-on windows from **filing date**, not grant date, because abandonments lack grant dates. That choice is understandable, but it changes the estimand. For 3-year windows especially, much of the outcome may occur before the patent decision. The paper acknowledges this, but the implication is deeper: the estimated reduced form is not an effect of patent grant on subsequent innovation; it is an ITT effect of assignment to a more lenient examiner from filing onward, combining publication, prosecution, and grant effects.

That may still be interesting, but it is a different question than the paper’s headline one.

### Sample definition for “green applications” introduces substantial measurement error and possible selection

The Y02 sample is built by identifying “Y02 art units” from granted patents and then including all applications in those art units, with subclass imputation for abandonments using modal subclass among grants in the art unit.

This is a very consequential choice and creates several risks:

1. **Population misclassification**: many non-green applications may be included simply because they were filed in an art unit with >10% Y02 grants.
2. **Outcome mismeasurement**: abandoned applications are assigned a subclass by art-unit mode, even though art units contain multiple subclasses.
3. **Differential composition**: if stricter examiners disproportionately abandon applications from particular subclasses within an art unit, the modal-imputation procedure could systematically distort measured exposure to follow-on counts.

The paper argues this is conservative, but that is not demonstrated. The direction of bias is ambiguous. This is especially problematic because the main outcome is subclass-specific.

## 2. Inference and statistical validity

### First-stage inference appears strong, but some reporting needs tightening

The first stage is clearly strong. The leave-one-out examiner grant rate predicts grant probability with very large F-statistics. This part of the paper is convincing and valuable.

However, a few points need clarification:

- The exact first-stage specification should be fully aligned across the standalone first stage and IV table. Right now, the manuscript explains why F differs, but the presentation remains potentially confusing.
- The instrument is constructed within examiner × art-unit × filing-year cells. The paper should report the distribution of cell sizes and the share of observations with very small leave-one-out denominators. Small-sample noise in leniency measures can matter even with large overall N.
- Since many examiners are observed across years, the paper should discuss jackknife/leave-cell-out or many-IV concerns more fully if any 2SLS results remain in the paper.

### Downstream inference is not valid in the application-level regressions

This is the most serious statistical problem.

The application-level regressions treat 640,845 observations as if they carry independent outcome information, but there are only 96 unique subclass-year values for the main follow-on measure. Even clustering at subclass × year does not really rescue this setup, because:

- the effective number of outcome clusters is tiny;
- regressor variation is at the application level, but outcome variation is almost entirely at a much coarser level;
- with only 96 outcome cells, asymptotic clustered inference is fragile;
- examiner-level clustering is plainly inappropriate for the main downstream uncertainty if the outcome is shared within subclass-year cells.

The manuscript acknowledges overstatement of precision, but still devotes substantial space to application-level p-values and robustness checks built on them. Those results should not be treated as confirmatory evidence.

### Collapsed regressions are closer to correct inference, but identification is lost

Once the data are collapsed:

- at **subclass × year**, the outcome is correctly represented, but assignment is no longer quasi-random at that level;
- at **art-unit × year**, assignment is more appropriate, but the outcome is too coarse/misaligned.

Thus the paper never simultaneously has credible identification and validly measured outcome variation.

### Clustering table highlights fragility rather than robustness

Table “Inference Under Alternative Clustering” is useful and honest. The coefficient remains negative, but significance disappears under more conservative clustering. Two concerns:

1. The two-way clustering choice “Exam x CPC” is not clearly defined in standard terms. If it means two-way clustering by examiner and CPC subclass, that is one thing; if it means an interaction cluster, that is another. This needs precise definition.
2. With only 8 subclasses × 12 years = 96 outcome cells, cluster-robust inference at that level may itself be unstable. Wild cluster bootstrap or randomization inference at the collapsed-cell level would be more appropriate if the design were otherwise valid.

### Permutation inference does not solve the core issue

The permutation exercise preserves the application-level pseudo-replicated structure, as the paper notes. Therefore it does not validate the downstream inference. At most it shows that the observed correlation is unusual under reshuffling of examiner leniency within art-unit-year cells. It does not show that the subclass-year association is causally identified.

## 3. Robustness and alternative explanations

### Existing robustness checks do not address the main threat

The paper presents Poisson, large-cell, winsorization, experienced-examiner, alternative horizons, and grants-only robustness checks. These are secondary. They do not address the first-order concern: mismatch between level of treatment randomization and level of outcome variation.

A result can be robust across functional forms and still be unidentified.

### Placebo/falsification test is not strongly informative

The “other subclass” placebo is not a compelling placebo because, as the paper itself says, own-subclass and other-subclass counts are mechanically linked within filing-year totals. That test cannot be interpreted as a true falsification. A stronger placebo would need to exploit dimensions that should be unaffected by the focal application’s grant but are measured comparably.

### Mechanism claims are appropriately restrained, but some language still overreaches

The paper is fairly careful in distinguishing:

- blocking,
- cross-subclass redirection,
- irrelevance at the margin.

That is commendable. Still, some passages imply more than the evidence warrants, e.g. suggesting consistency with blocking based on the subclass-year collapse. Since that result is not causally identified, the paper should avoid mechanism language suggesting even tentative support unless clearly labeled as descriptive correlation.

### External validity is discussed sensibly

The paper appropriately notes the local nature of the estimand and the 2001–2012 sample. This is a strength.

## 4. Contribution and literature positioning

### Contribution is partly clear, but narrower than the current framing

The paper’s true contribution is not yet a convincing answer to whether examiner leniency affects cumulative green innovation. Rather, it is:

1. a useful demonstration that application-level PatEx data solve a selection problem in examiner leniency first stages; and
2. an illustration of how downstream analyses can fail when the outcome is too aggregated relative to assignment.

That is potentially interesting, but narrower and more methodological than the current title and introduction suggest.

### Literature coverage is decent, but several key references should be added

The manuscript cites important examiner-IV and patent/cumulative-innovation papers, but it should engage more directly with modern econometric work on staggered/shared outcomes, shift-share-like aggregation issues, and randomization/inference with few clusters. Concrete additions:

- **Borusyak, Hull, and Jaravel (2022, QJE)** on quasi-experimental shift-share designs.  
  Why: the subclass-year average leniency design has a compositional/aggregate-treatment flavor, and the paper needs to frame why aggregation can break micro identification.

- **Abadie, Athey, Imbens, and Wooldridge (2023, JEL)** on sampling-based versus design-based uncertainty.  
  Why: useful for clarifying why pseudo-replication is not fixed by standard clustering.

- **MacKinnon, Nielsen, and Webb** papers on wild bootstrap and cluster-robust inference with few clusters.  
  Why: relevant for 96-cell or other limited-cluster settings.

- If the paper retains any DiD-style or grouped comparisons over time, some discussion of **Athey and Imbens (2022)** or related design-based approaches to panel event studies would help, though this is less central.

- On patent examination and examiner behavior, the paper could engage more with work by **Frakes and Wasserman** beyond the single citation, especially on how examiner incentives affect prosecution outcomes other than grant.

- On patent scope and cumulative innovation, additional discussion of **Boldrin and Levine** or more recent empirical patent-thicket work may help situate the blocking mechanism.

The paper also should more directly compare itself to **Sampat and Williams** not only on results but on outcome measurement. Their downstream measures are much more proximate to the relevant unit than the subclass-year counts used here.

## 5. Results interpretation and claim calibration

### The paper is more calibrated than most, but still not fully aligned with the evidence

A major positive is that the paper does not oversell the downstream findings. It repeatedly says the evidence is mixed and fragile. That is scientifically responsible.

Still, several calibrations need tightening:

1. **Title and abstract**: The title asks a causal downstream question, but the abstract’s main substantive conclusion is effectively “we cannot credibly answer this with the available follow-on outcome.” That mismatch should be resolved.
2. **Negative subclass-year estimate**: The paper should not present this as evidence “associated with” less follow-on and then discuss it as if it helps answer the causal question. It is descriptive once collapsed at subclass-year.
3. **Policy implications**: The conclusion that “forces shaping green innovation trajectories appear to dominate the marginal examiner decision” is too strong given the design failure on downstream outcomes. A more accurate statement is that this paper does not find robust evidence that the marginal examiner decision materially affects the coarse follow-on measure available here.
4. **Power claims**: Section 4’s power discussion is not meaningful given the pseudo-replication issue. The confidence interval from the application-level regression should not be used to infer ability to rule out economically important effects.

### Contradiction between “null” and “negative” evidence should be framed as non-identification, not mixed causal evidence

The subclass-year negative and art-unit-year null are not two equally credible causal estimates. They are estimates from two different aggregations, each violating a different requirement. The proper interpretation is not “evidence is mixed”; it is “the available outcome cannot be used to credibly identify the downstream causal effect.”

That distinction matters for publication readiness.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Replace or fundamentally redesign the downstream outcome
- **Issue:** Main outcome varies at subclass × year, while treatment is assigned quasi-randomly at application level within art-unit × year.
- **Why it matters:** This breaks causal identification for the paper’s central question.
- **Concrete fix:** Obtain downstream outcomes at the application/patent level or at least at a level nested within the assignment mechanism. Examples: subsequent citations to the application/publication, text-similarity-weighted follow-on patents, family-level continuations/divisionals, or technologically proximate future patents linked to the focal application using citation/text/network methods. If such an outcome cannot be built, the paper should be reframed around the first stage and methodological lesson rather than a causal claim about cumulative innovation.

#### 2. Remove or sharply demote application-level downstream regressions as main evidence
- **Issue:** Application-level regressions with 96 unique outcome values produce invalid precision and misleadingly large effective sample size.
- **Why it matters:** The current core tables overstate evidence.
- **Concrete fix:** Move application-level downstream regressions to an appendix or relabel them explicitly as descriptive pseudo-replicated regressions. Main inference should come only from designs where both identification and outcome variation are coherent.

#### 3. Rebuild the green-sample classification and subclass assignment for abandonments
- **Issue:** Identifying green applications via Y02-heavy art units and imputing abandoned applications to modal subclass risks serious misclassification.
- **Why it matters:** The main outcome is subclass-specific, so misclassification directly contaminates treatment–outcome mapping.
- **Concrete fix:** Either (i) link abandoned applications to pre-grant/publication classifications if available, (ii) use text-based classification into Y02 subclasses, or (iii) restrict analysis to granted applications for downstream descriptive exercises while being explicit that causal leverage is lost. At minimum, provide validation of the imputation against held-out granted applications.

#### 4. Eliminate causal interpretation of IV estimates unless exclusion is defended with evidence
- **Issue:** Examiner leniency likely affects many prosecution margins beyond grant/deny.
- **Why it matters:** IV estimates are not interpretable as grant effects.
- **Concrete fix:** Remove IV columns from the main table, or provide a separate analysis documenting whether lenient examiners differ systematically in pendency, claim amendments, continuations, and scope. Without that, keep IV purely as exploratory appendix material.

### 2. High-value improvements

#### 5. Strengthen random-assignment validation using genuine pre-treatment covariates
- **Issue:** Balance tests are mostly on post-treatment-conditioned samples.
- **Why it matters:** The credibility of the first stage and any reduced form depends on assignment being as-good-as-random.
- **Concrete fix:** Extract and report all pre-treatment covariates available at filing: applicant type, continuation status, PCT status, inventor count, assignee country, small/micro entity if available, application length, art-unit queues, etc. Show within-art-unit × year balance and preferably randomization/permutation diagnostics.

#### 6. Validate the art-unit assignment mechanism more directly
- **Issue:** The institutional argument is plausible but under-documented for this sample.
- **Why it matters:** Examiner assignment may vary with workload, specialization, or application characteristics in ways that matter.
- **Concrete fix:** Show examiner caseload rotation patterns, within-cell assignment shares, and whether observables predict examiner assignment. If possible, exploit narrower routing cells than art-unit × year.

#### 7. Rethink inference at collapsed levels
- **Issue:** Collapsed regressions use very small numbers of cells/clusters and conventional robust SEs.
- **Why it matters:** Inference may be unreliable even in descriptive analyses.
- **Concrete fix:** Use randomization inference or wild bootstrap at the collapsed-cell level, clearly specifying the assignment mechanism being approximated. But note this only helps if the estimand is otherwise identified.

#### 8. Remove the power analysis based on pseudo-replicated regressions
- **Issue:** The reported MDE and CI are not meaningful under the shared-outcome problem.
- **Why it matters:** It overstates what the study can rule out.
- **Concrete fix:** Replace with power calculations at the effective outcome-cell level or omit entirely.

#### 9. Reframe the contribution around what the paper actually establishes
- **Issue:** Current framing promises an answer to a substantive policy question that the design cannot deliver.
- **Why it matters:** Publication standards require alignment between question, design, and contribution.
- **Concrete fix:** Recast as a methodological paper on examiner-IV implementation with PatEx and the dangers of outcome aggregation in cumulative-innovation studies, unless a better downstream outcome can be built.

### 3. Optional polish

#### 10. Clarify cluster definitions and effective sample sizes
- **Issue:** Some clustering choices are ambiguous; the effective number of independent outcome units is obscured.
- **Why it matters:** Readers need to understand what variation identifies each estimate.
- **Concrete fix:** For every main result, report the level of outcome variation, treatment variation, FE structure, cluster count, and effective number of cells.

#### 11. Add validation of subclass imputation
- **Issue:** The paper asserts imputation is conservative without evidence.
- **Why it matters:** Readers need to know the extent of misclassification.
- **Concrete fix:** For granted applications, hide true subclass and impute using modal art-unit subclass; report accuracy and misclassification structure.

#### 12. Tighten interpretation of placebo and heterogeneity analyses
- **Issue:** These exercises are not very informative given the main design problems.
- **Why it matters:** They may distract from the core identification issue.
- **Concrete fix:** Shorten or move to appendix unless a redesigned outcome makes them meaningful.

## 7. Overall assessment

### Key strengths
- Important and policy-relevant question.
- Strong and credible first stage using application-level data with grants and abandonments.
- Honest treatment of limitations; the paper is more transparent than many submissions.
- Useful warning about pseudo-replication when outcomes are shared across many micro observations.
- Generally careful distinction between reduced form and IV, even if not fully carried through.

### Critical weaknesses
- The central downstream causal question is not credibly identified.
- Main outcome is measured at a level incompatible with the assignment mechanism.
- Application-level downstream inference is invalid due to severe shared-outcome pseudo-replication.
- Collapsed regressions either lose identification (subclass-year) or the relevant outcome granularity (art-unit-year).
- Green classification and subclass imputation for abandoned applications are too noisy for the subclass-based outcome.
- IV estimates lack a credible exclusion restriction.

### Publishability after revision
In its current form, I do not think this is publishable in a top field or general-interest journal as a substantive causal paper on cumulative green innovation. However, the paper could become publishable if the author either:

1. **builds a downstream outcome at the application/patent level that aligns with the examiner assignment design**, or  
2. **substantially reframes the paper** as a methodological/data paper about examiner-IV first stages with PatEx and the failure of aggregated follow-on outcomes to support downstream causal claims.

As written, the paper’s strongest result is the first stage, while the main substantive question remains unanswered.

DECISION: REJECT AND RESUBMIT