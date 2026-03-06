# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T03:44:17.890787
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 18474 in / 4727 out
**Response SHA256:** 17462e43be8e35ac

---

This paper asks an important policy question: whether examiner-level variation in patent grant output affects subsequent green innovation. The topic is potentially of broad interest, and the paper is commendably transparent that, given grants-only data, it estimates a reduced-form effect of assignment to a “higher-output” examiner rather than the causal effect of grant versus denial. The null result could be valuable if supported by a design that cleanly identifies the relevant estimand and delivers valid inference.

In its current form, however, the paper is not publication-ready for a top field or general-interest journal. The core concerns are not cosmetic; they are about whether the variation used is plausibly exogenous for the stated claim, and whether the uncertainty estimates are valid given the highly aggregated/shared outcome. The main result may still survive after substantial redesign, but at present the paper does not support its headline causal interpretation.

## 1. IDENTIFICATION AND EMPIRICAL DESIGN

### 1.1 The treatment is not clearly identified as examiner “grant propensity”
The central regressor is a leave-one-out examiner grant share within art-unit-by-grant-year cells, constructed from **granted patents only** (Data, “Examiner Grant Share Construction”; Empirical Strategy, “Data Limitation: Grants Only”). This creates a fundamental identification problem.

The paper interprets cross-examiner variation in share of granted patents within a cell as a proxy for examiner permissiveness. But with grants-only data, that share conflates at least three things:

1. **Examiner grant propensity**  
2. **Examiner assignment volume/workload within the cell**  
3. **Differences in grant timing / prosecution speed**

Because the numerator is the number of granted patents handled by the examiner, a high share can arise because the examiner:
- receives more applications,
- processes them faster,
- has lower abandonment,
- is more permissive,
- or some combination.

The paper acknowledges this in places, but still repeatedly frames the design as exploiting quasi-random variation in examiner grant behavior and draws conclusions about whether “granting a green patent, at the margin, promotes or hinders follow-on innovation” (Abstract; Introduction; Conclusion). That is not justified by the current measure.

This is especially problematic because assignment is plausibly quasi-random at **filing**, while the main treatment is defined in **grant-year** cells. A patent’s eventual grant year is itself downstream of examiner behavior and case processing. Conditioning treatment construction on grant-year output creates scope for endogenous timing/composition, even if initial assignment was random.

### 1.2 Conditioning on granted patents only changes the estimand in a severe way
The sample includes only granted Y02 patents. This is not just a limitation to note; it is central to interpretation.

If the question is whether the patent system hinders or promotes follow-on innovation, the relevant margin is typically the effect of **granting versus not granting** or broader IP protection intensity. But the paper estimates, among patents that were eventually granted, whether being assigned to an examiner with a higher share of grants in the cell predicts future subclass patenting.

That estimand could be zero even if the causal effect of grant versus denial is large, because:
- compliers/marginal cases are not observed as such,
- selection into the granted sample may differ by examiner type,
- examiner “high output” may mostly shift timing rather than grant incidence,
- the sample omits exactly the denied/abandoned applications needed to interpret examiner heterogeneity structurally.

The manuscript is transparent about not estimating a LATE, but the substantive claims remain too close to “marginal green patent grants do not matter.” That is overstated relative to the evidence.

### 1.3 The use of grant-year cells is conceptually and causally awkward
The instrument/treatment is built in **art-unit × grant-year** cells, while fixed effects are **art-unit × filing-year** (Data; Empirical Strategy). The paper says results are robust to using art-unit-by-grant-year FE, but that does not solve the underlying problem.

Why this matters:
- Grant year is partially determined by examiner behavior.
- Faster examiners may accumulate larger grant shares in certain years.
- Technology and subclass-specific innovation conditions may shift between filing and grant.
- A treatment measured using realized grant-year outcomes may reflect examiner speed/composition rather than a stable predisposition known at assignment.

In the standard examiner design, one wants a leave-one-out examiner leniency measure based on application outcomes in a comparison set defined as close as possible to the randomization environment and independent of the focal case. Here, the current variable is not a clean analog.

### 1.4 Random assignment is asserted more than demonstrated
The paper relies heavily on prior literature and institutional description (“functionally random” assignment within art units; Institutional Background), but the paper’s own balance evidence is not fully reassuring.

The balance regressions (Table “Balance Test”) show statistically significant relationships between examiner grant share and predetermined patent characteristics. The paper dismisses these as “economically negligible,” but for a design resting on quasi-random assignment, significance and sign consistency should prompt deeper examination rather than a brief reassurance. Moreover:
- only two balance variables are shown;
- no placebo outcomes or richer predetermined features are used;
- no examiner-cell randomization tests/permutation diagnostics are reported;
- no direct evidence is shown that examiner workloads within art unit-year are orthogonal to observables.

Given that the treatment may partly capture workload/throughput, stronger assignment diagnostics are essential.

### 1.5 Outcome definition raises a serious reflection/shared-outcome problem
The main outcome is the number of Y02 patents in the same CPC subclass filed within 3 or 5 years after the focal patent’s grant date. This is an aggregate technology-class outcome with mean around 26,600 at five years (Summary Statistics).

Multiple focal patents in the same subclass and nearby dates will share nearly identical outcomes. The paper notes this, but does not address its full implications. This is not a standard patent-level follow-on measure like future citations to the focal patent or matched third-party applications. Instead, it is a highly aggregated subclass-time count replicated across many patent observations.

That makes the interpretation difficult:
- It is not obvious how one focal patent’s examiner assignment should measurably move the total subclass count among tens of thousands of later patents.
- The design effectively regresses a largely shared group-time outcome on individual assignment variation.
- The estimand becomes a diluted exposure mapping rather than an individual treatment effect.

A null under such aggregation may simply reflect attenuation from extreme aggregation, not substantive irrelevance of patents for follow-on innovation.

### 1.6 Reflection/general equilibrium concerns are not adequately handled
If many patents in the same subclass and period are exposed to different examiner assignments, then later subclass-level patenting is the joint product of many contemporaneous patents, not the consequence of one focal patent’s treatment. This creates interference/exposure problems:
- The outcome for patent i depends on treatments of many other patents in the subclass.
- The paper treats the outcome as if patent i’s examiner assignment independently shifts subclass innovation.

A more coherent design would aggregate treatment at the subclass-cohort level and estimate whether cohorts with higher exposure to lenient/high-output examiners experience different subsequent innovation. At the patent level, SUTVA/interference is implausible.

## 2. INFERENCE AND STATISTICAL VALIDITY

This is the paper’s most serious issue.

### 2.1 Main standard errors are likely invalid because the outcome is shared at a higher level than the clustering
The paper clusters at the examiner level throughout (Empirical Strategy; main tables). But the main dependent variable is a subclass-level aggregate over future filing windows. Many observations share essentially the same outcome because they belong to the same CPC subclass and similar grant dates/cohorts.

This raises a classic **Moulton/shared-outcome problem**: individual-level regressors with group-level residual correlation require clustering at the level of residual dependence, not merely treatment assignment. Examiner clustering accounts for correlation across cases handled by the same examiner; it does **not** account for:
- shared errors within CPC subclass,
- shared errors within grant-date/cohort windows,
- overlapping future windows,
- serial correlation in subclass innovation.

The fact that alternative clustering at art unit or art-unit × year yields even smaller standard errors is not reassuring; if anything, it suggests the paper has not clustered at the level where residual dependence actually lives.

At minimum, inference should be redone with clustering or resampling schemes that reflect the outcome structure, e.g.:
- subclass × grant-year or subclass × filing-year clustering,
- two-way clustering (examiner and subclass-time),
- block bootstrap over subclass-time units,
- or redesign at the subclass-cohort level.

Without this, the “precisely estimated null” language is not credible.

### 2.2 The regression sample size is misleading for effective power
The paper repeatedly emphasizes 484k observations and tiny standard errors, claiming power to rule out effects above ±0.5% (Statistical Power section). But because the outcome is highly shared and overlapping across patents, the effective number of independent outcome units is far smaller than 484k.

This undermines:
- the precision claims,
- the power calculations,
- the interpretation of tight confidence intervals.

The paper should not present patent-level N as if each observation contributes independent information about the outcome.

### 2.3 The null is not as “precise” as claimed until inference is corrected
Given the likely residual dependence structure, the key substantive claim—ruling out even small effects—cannot be sustained. A null result can be valuable, but only if the standard errors are credible. Right now, the paper’s strongest rhetorical point is also its weakest statistical point.

### 2.4 The IV exercise on claims is not credible as causal evidence
The “Patent Scope IV” section uses examiner grant share as an instrument for log claims. This is not convincing for two reasons:
1. The exclusion restriction is especially implausible: examiner output likely affects outcomes through channels other than claims.
2. The first stage (F = 38.2) is explicitly acknowledged as weak relative to the recommended threshold in the cited framework.

Given the paper’s already reduced-form orientation, this IV analysis adds little and may distract from the main result. I would recommend dropping it unless substantially strengthened.

## 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS

### 3.1 Existing robustness checks do not probe the main identification threats
The current robustness set—Poisson, cell size restriction, alternative clustering, winsorization, experienced examiners—is useful but mostly mechanical. It does not address the central concerns:
- whether grant share reflects workload rather than leniency,
- whether grant-year construction is endogenous,
- whether outcome aggregation masks meaningful effects,
- whether interference invalidates patent-level interpretation.

The paper needs robustness that speaks directly to identification.

### 3.2 Balance tests are too limited
Only claims and backward citations are used. For a paper relying on quasi-random assignment, I would expect a much richer set:
- assignee type,
- inventor count,
- domestic/foreign applicant,
- continuation status if available,
- art unit subclass composition,
- pre-existing assignee patent stock,
- technological breadth measures,
- filing month/quarter,
- pre-treatment subclass innovation trends.

And these should be shown as a coherent omnibus assessment, not only two regressions.

### 3.3 Placebo/falsification exercises are missing or underdeveloped
The paper would benefit from falsification tests such as:
- outcomes in unrelated CPC subclasses,
- pre-grant “future” outcomes that should not respond,
- examiner grant share predicting prior subclass innovation,
- random/permuted examiner assignment within art-unit-year cells.

These are particularly important because the treatment measure is unusual and may capture latent throughput differences.

### 3.4 Mechanism discussion overreaches relative to evidence
The paper interprets the citation effect plus follow-on null as evidence that “patents are read and cited but do not alter the trajectory of inventive activity.” This is suggestive, but not established. Forward citations are themselves an equilibrium outcome influenced by examiner practices, applicant behavior, patent visibility, and citation-generation conventions. Without separating applicant-added and examiner-added citations (if possible), or considering citation truncation/composition, the mechanism story should remain modest.

### 3.5 Right-censoring/truncation is discussed but not fully integrated
The paper acknowledges truncation for recent cohorts and says the 2001–2014 restriction gives similar results. That is useful. But the logic around complete observability should be presented more carefully because both:
- focal patent grant timing,
- and follow-on grant observability
matter under grants-only data.

This is not a fatal flaw, but the current treatment is somewhat informal for a paper making strong precision claims.

## 4. CONTRIBUTION AND LITERATURE POSITIONING

### 4.1 The topic is important and potentially publishable
The question—how patent-office discretion affects cumulative green innovation—is important and relevant for current climate/IP policy debates. The connection to examiner/judge designs is also natural.

### 4.2 But the contribution relative to Sampat-type designs is currently limited by data/design constraints
The paper presents itself as extending Sampat et al.-style examiner designs to green patents. The problem is that those designs rely on application-level variation that permits a genuine leniency/grant-propensity measure and, often, a first stage for grant. Here, the paper lacks denied applications and replaces grant propensity with grant share among grants. That is a materially weaker design.

As a result, the contribution is currently more modest than framed: it is evidence that, among granted Y02 patents, assignment to an examiner with higher within-cell grant output is not strongly associated with later subclass-level granted patent counts. That can still be interesting, but it is not yet at the level implied by the framing.

### 4.3 Literature coverage is mostly adequate, but some method references on modern causal inference/inference are missing
The paper cites Chyn et al. on judge/examiner designs, but should also engage more directly with methodological work relevant to the paper’s actual problems:
- group-level/shared-outcome inference and Moulton-style issues,
- spillovers/interference in patent and innovation settings,
- modern examiner-leniency construction using application-level data.

Concrete additions that would strengthen the paper:
- **Moulton (1990)** on group effects and underestimated standard errors.
- **Bertrand, Duflo, and Mullainathan (2004)** for serial correlation / policy-style persistence logic, relevant by analogy to overlapping windows and shared outcomes.
- **Abadie et al.** work on clustering and causal inference if the paper keeps unusual outcome aggregation/clustering choices.
- More direct discussion of the exact leniency construction in **Farre-Mensa, Hegde, and Ljungqvist (2020)** and **Sampat and Williams (2019)** relative to the current grants-only substitute.

## 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION

### 5.1 The headline claim is too strong for the design
Statements such as:
- “marginal green patent neither blocks competitors from building on disclosed knowledge nor stimulates additional inventive activity” (Conclusion),
- “patents are not blocking it” (Discussion/Policy Implications),
- “the patent system is a sideshow” (Conclusion),

go well beyond what the paper identifies.

The actual evidence is much narrower:
- among eventually granted Y02 patents,
- using an examiner grant-output proxy measured from granted patents only,
- with subclass-level future granted patent counts,
- and potentially problematic inference.

This can support, at best, a far more cautious statement.

### 5.2 The policy implications are overstated
The paper uses its result to speak to TRIPS waivers, compulsory licensing, and strengthening/weakening green patent protection. Those are broad institutional interventions. The paper does not identify the effect of those policies, nor the effect of patent grant versus denial in general equilibrium. Even if the reduced form were solid, policy discussion should be much more restrained.

### 5.3 The positive citation effect should be interpreted cautiously
Because examiner behavior can affect citation practices and patent visibility directly, the citation result is not clean evidence of a disclosure/attention channel. It is an interesting reduced-form association, but the mechanism interpretation should be toned down.

## 6. ACTIONABLE REVISION REQUESTS

### 1. Must-fix issues before acceptance

#### 1. Rebuild the empirical design around a defensible treatment
- **Issue:** Examiner grant share among granted patents is not a credible proxy for leniency without application-level data.
- **Why it matters:** This is the central identification problem; without fixing it, the causal claim is not supported.
- **Concrete fix:** Obtain application-level data including denied/abandoned applications (e.g., PatEx or equivalent USPTO prosecution data) and construct a standard leave-one-out examiner grant-rate leniency measure within the true assignment cell. Estimate the first stage for grant and then either a reduced form and/or IV. If this is infeasible, radically narrow the paper’s claim and redesign it as descriptive reduced-form evidence on examiner throughput, not grant propensity.

#### 2. Redo inference to match the outcome’s dependence structure
- **Issue:** Examiner clustering is not sufficient when the dependent variable is a heavily shared subclass-time aggregate.
- **Why it matters:** The paper’s precision claims are currently unreliable.
- **Concrete fix:** Re-estimate using a design with the outcome aggregated to the subclass-cohort level, or at minimum use clustering/bootstrapping that accounts for subclass-time residual dependence. Report how many effectively distinct subclass-time outcome cells drive the analysis.

#### 3. Address interference/reflection by changing the unit of analysis
- **Issue:** Patent-level assignment is linked to a subclass-level future outcome jointly determined by many patents’ treatments.
- **Why it matters:** Patent-level causal interpretation is not coherent under likely spillovers.
- **Concrete fix:** Aggregate treatment exposure to subclass × cohort (or subclass × art-unit × cohort) and estimate whether cohorts more exposed to high-leniency examiners have different subsequent innovation. Alternatively, use patent-specific outcomes that are not shared across many observations (e.g., future third-party citations, future related applications tied to the focal patent).

#### 4. Recalibrate claims throughout
- **Issue:** The manuscript overstates what the current design shows.
- **Why it matters:** Even a revised paper needs claims aligned to evidence.
- **Concrete fix:** Replace claims about “marginal patent grants” and “patents are not blocking green innovation” with narrower language unless a true grant-propensity design is implemented.

### 2. High-value improvements

#### 5. Strengthen assignment diagnostics substantially
- **Issue:** Current balance tests are too limited.
- **Why it matters:** Quasi-random assignment is the foundation of the design.
- **Concrete fix:** Add a richer balance table, joint tests, and permutation/randomization checks within assignment cells. Show that examiner workload and case mix are not predictably related to observables.

#### 6. Probe whether the treatment captures workload/speed rather than leniency
- **Issue:** Grant share may reflect throughput.
- **Why it matters:** This changes the estimand fundamentally.
- **Concrete fix:** Test whether grant share predicts prosecution duration, examiner caseload, or other throughput measures. If it does, reinterpret accordingly or redesign.

#### 7. Reconsider the outcome measure
- **Issue:** Same-subclass future patent counts are very aggregated and likely too coarse.
- **Why it matters:** A null at this level may be uninformative.
- **Concrete fix:** Consider more focal outcomes: third-party forward citations, related patenting by non-self assignees, textual/semantic-neighbor innovation, or subclass-originating application flows excluding the focal assignee.

#### 8. Drop or substantially qualify the patent-scope IV
- **Issue:** Weak first stage and implausible exclusion.
- **Why it matters:** The IV result is not persuasive and could undermine confidence.
- **Concrete fix:** Remove from main text or recast explicitly as exploratory.

### 3. Optional polish

#### 9. Clarify the estimand repeatedly and consistently
- **Issue:** The paper alternates between careful reduced-form language and stronger causal phrasing.
- **Why it matters:** Readers need a stable interpretation.
- **Concrete fix:** State clearly in Abstract, Introduction, and Conclusion what is and is not identified.

#### 10. Improve literature positioning on inference and spillovers
- **Issue:** Methodological positioning is incomplete.
- **Why it matters:** Helps justify redesign choices and interpret nulls properly.
- **Concrete fix:** Add references/discussion on clustered/shared outcomes, interference, and patent spillovers.

## 7. OVERALL ASSESSMENT

### Key strengths
- Important and policy-relevant question.
- Large-scale data assembly on green patents.
- Clear acknowledgment of some data limitations.
- Potentially interesting null result if supported by a stronger design.
- Constructive effort to situate the paper in the examiner-design literature.

### Critical weaknesses
- Core regressor is not a clean leniency measure; with grants-only data it conflates permissiveness, workload, and timing.
- Sample conditioning on granted patents severely limits causal interpretation.
- Main outcome is a highly shared aggregate, making patent-level analysis and examiner-level clustering problematic.
- Precision claims are likely overstated because inference does not match the residual dependence structure.
- Conclusions and policy implications go well beyond what the design can support.

### Publishability after revision
In its current form, I do not think this is close to acceptance at a top journal or AEJ: Economic Policy. However, the paper could become publishable if the authors undertake a substantial redesign—ideally using application-level data to construct a proper examiner-leniency measure and adopting an outcome/inference strategy consistent with the spillover structure. If such data are unavailable, the manuscript would need to be reframed much more modestly as descriptive reduced-form evidence, likely with a different target journal.

DECISION: REJECT AND RESUBMIT