# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T15:29:35.792308
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 19542 in / 5941 out
**Response SHA256:** 91b4ad0053b788b4

---

This paper studies whether Erasmus+ outflows reduce sending regions’ human capital, framing the question as a potential conflict between EU mobility subsidies and Cohesion Policy. The paper is ambitious, uses novel bilateral Erasmus flow data at NUTS3, and is commendably transparent about several design limitations. The most important positive feature is that the author does not hide unfavorable diagnostics: the NUTS2 panel effect disappears with country-by-year fixed effects, the NUTS3 long-difference estimate is weakly identified and imprecise, and randomization inference does not support strong quasi-experimental interpretation. That transparency is valuable.

However, in its current form, the paper is not publication-ready for a top general-interest journal or AEJ: Economic Policy. The central causal claim is not convincingly identified. The preferred NUTS2 result relies materially on cross-country variation; the more credible within-country specification loses the effect. The shift-share design does not survive the paper’s own strongest exogeneity diagnostic. The paper then leans heavily on heterogeneity and placebo patterns that are interesting but cannot rescue the core identification problem. As written, the evidence supports at most a suggestive correlation pattern consistent with regional brain drain, not a credible causal estimate of Erasmus on regional human capital.

Below I organize comments by the requested dimensions.

---

## 1. Identification and empirical design

### 1.1 Main identification claim is not credible in the preferred specification

The paper’s main quantitative result is the NUTS2 panel 2SLS estimate of about -0.39 percentage points on tertiary share (Section 5.3; Table 4 / `tab:nuts2_panel`). But this result is not robust to the specification that most directly addresses the core confound—country-specific shocks and national policies varying by year. Once country-by-year fixed effects are added, the estimate becomes essentially zero (`0.0324`, SE `0.1381`).

That is not a minor robustness issue. It directly undermines the causal interpretation of the preferred panel estimate. If the identifying variation disappears when comparing regions within the same country-year, then the design is relying importantly on cross-country differences in Erasmus exposure and human-capital dynamics. Those differences are exactly where omitted variables are most severe: education policy, migration policy, macro conditions, EU accession timing, language, labor-market structure, and differential COVID disruptions.

The paper acknowledges this in the abstract, introduction, Section 5.3, and Section 8.1/8.2, but the paper’s framing still overstates what has been learned causally. At present, the cleanest reading is: cross-country and between-country-time variation line up with a negative relationship, but within-country identification at the level where the human-capital outcome is observed does not.

### 1.2 The paper’s own randomization inference rejects a strong shift-share causal interpretation

Section 7.1 is the most damaging evidence for the current design. Randomization inference yields p-values around 0.49 (NUTS3) and 0.44 (NUTS2 panel). By the paper’s own description, the observed estimates sit well inside the permutation distribution. That means the design does not isolate shock variation in a way that convincingly separates the shifter from endogenous exposure shares.

For a shift-share design, this is central, not peripheral. The paper correctly cites Borusyak-Hull-Jaravel and Goldsmith-Pinkham-Sorkin-Swift, but the practical implication here is stark: the design appears to be identified partly or largely by shares. Since shares are plausibly endogenous to regional university quality, language ties, migration networks, and labor-market orientation, the causal claim is weakened substantially.

The manuscript sometimes interprets the RI failure as “a limitation” while still speaking of “effects” and “brain drain” in the conclusion and policy discussion. That is too strong. If the shifter-based quasi-randomness is not supported, the paper must either:
- sharply downgrade its causal language throughout, or
- redesign the empirical strategy around a different source of exogenous variation.

### 1.3 The “go/no-go diagnostic” is informative but insufficient

Section 4.4 shows that the NUTS3 Bartik has substantial within-country variation and a strong first stage even with country-by-year fixed effects. This is useful, but it is only a relevance diagnostic. It does not establish exogeneity of the shifters, nor does it solve the problem that the outcome with credible within-country identification at NUTS3 is a noisy proxy (youth population share), not human capital.

In other words, the paper demonstrates that the instrument varies within country; it does not demonstrate that this within-country variation is valid for identifying human-capital effects.

### 1.4 The NUTS3 long-difference outcome is not tightly connected to the main claim

The NUTS3 long-difference outcome is change in the share of 25–34-year-olds in total population (Section 4.1, Eq. 1; Section 5.2). This is at best an indirect proxy for “regional human capital.” It conflates:
- age structure,
- fertility and mortality,
- non-Erasmus migration,
- internal migration within countries,
- differential student/housing markets,
- and macro regional growth.

A decline in youth share is not a clean measure of tertiary human capital depletion. Since this is the only level where the instrument retains strong within-country relevance, the paper’s substantive claim ends up hanging on an outcome that is too indirect for the policy argument being made.

### 1.5 The NUTS2 long-difference result cuts against the main story and is under-integrated into the design

Section 5.2 reports a positive NUTS2 long-difference IV coefficient (`3.836`, p = 0.09), opposite in sign to the main panel result. The paper interprets this as possible medium-run “brain circulation.” That is possible, but the current treatment is too ad hoc. Opposite signs across major specifications can reflect:
- model misspecification,
- non-comparable estimands,
- timing mismatch,
- weak instrument issues,
- or instability due to different identifying variation.

Given that one main specification is negative, one is weak and insignificant, and one is positive, the paper needs a much more disciplined discussion of what parameter each design identifies and under what assumptions. As is, the evidence reads as unstable rather than horizon-specific.

### 1.6 Treatment timing is not fully coherent with the claimed mechanism

The paper notes that Erasmus participation occurs at ages roughly 20–24 while the main outcome is tertiary share among 25–34-year-olds (Section 4.3 and 5.4). That is a real timing issue. The distributed lag exercise is not fully persuasive because:
- it simply replaces contemporaneous treatment with lags, rather than modeling a cumulative stock-flow relationship;
- sample sizes fall sharply across lags;
- the lagged estimates attenuate toward zero, which the paper describes as “surprising” but does not resolve.

Conceptually, a stock outcome like tertiary share should depend on cumulated inflows/outflows and return migration, not just a single-year flow rate. A panel in yearly flow rates may be misspecified relative to the mechanism. This likely contributes to the sign/magnitude instability across panel and long-difference designs.

### 1.7 Exclusion restriction concerns are serious and not adequately addressed

The shifters are destination-specific growth in Erasmus inflows. But destination attractiveness can change for reasons that also affect origin-region outcomes through channels other than Erasmus:
- broader migration opportunities,
- labor-market demand in destination countries,
- common macro shocks,
- accession/integration effects,
- changes in English-language education demand,
- and university network expansion.

These channels could affect sending-region human-capital trajectories directly via migration expectations, labor-market sorting, or other educational choices. The paper discusses “correlated shocks” in Section 4.3, but the empirical responses are limited. The placebo on older cohorts is not sufficient to support the exclusion restriction.

---

## 2. Inference and statistical validity

### 2.1 Standard errors are generally reported, but the main inferential basis is weaker than presented

The paper does report standard errors, p-values, and first-stage statistics throughout. That is good. But for publication in a top journal, the issue is not merely whether standard errors are printed; it is whether the inferential procedure matches the design.

The headline problem is that the strongest causal interpretation depends on a shift-share design, yet the key exogeneity/inference diagnostic (randomization inference) fails. A paper “cannot pass without valid statistical inference,” and here the paper’s own RI procedure indicates that conventional significance in the NUTS2 baseline is not a reliable guide to causal significance.

### 2.2 Weak instrument concerns are material in the NUTS3 long-difference specification

In Table `tab:main_nuts3`, the reported first-stage F for the NUTS3 2SLS long-difference is `6.53`. The text acknowledges weak-instrument concerns. That should make this specification non-decisive. Yet the paper still uses sign reversal from OLS to IV in this specification as substantive support for the brain-drain interpretation. That is too much weight on a weakly identified estimate.

For this specification, the paper should report weak-IV robust confidence intervals (e.g., Anderson-Rubin / CLR), not just conventional 2SLS inference. Without that, the estimate is not reliable enough to inform the sign of the effect.

### 2.3 The AKM exercise is not a convincing implementation of AKM inference

Section 7.2 says the author “approximates AKM-type standard errors by assigning each region to its primary (modal) destination and clustering at the destination level.” That is not an adequate implementation of Adão-Kolesár-Morales. AKM inference is not equivalent to clustering units by modal exposure. The whole point is to account for correlation induced by many shared shocks with heterogeneous exposure weights; modal-destination clustering is a very rough heuristic and can be misleading.

This matters because the paper uses the AKM result to reassure the reader that inference is conservative. That reassurance is not warranted from the reported procedure.

### 2.4 Sample sizes are mostly reported, but some coherence issues remain

The paper generally reports sample sizes clearly and explains some differences between OLS and IV samples. That is a strength. Still, a few issues need attention:

- NUTS3 counts vary: the introduction says “approximately 970 NUTS3 and 330 NUTS2” while the data section mentions roughly 1,300 regions and 1,220 distinct NUTS3 origins; then the main NUTS3 analysis uses 969. This is explainable, but a sharper accounting table is needed.
- The first-stage and second-stage N’s differ in ways attributed to instrument availability and fixed effects; this should be fully documented in an appendix sample-flow table.
- For the heterogeneity table, observations drop from 2,796 baseline to 2,526 pooled heterogeneity and to 1,251/1,275 by subgroup. The reason seems to be missing GDP for the peripheral/core split, but this should be stated directly.

### 2.5 Two-way clustering with only 9 years should be interpreted cautiously

The paper notes this briefly in Section 5.3. With only 9 year clusters, two-way clustered standard errors by region and year are fragile. The fact that significance weakens materially under two-way clustering is informative, but the paper should avoid leaning heavily on the p-value from that specification. Wild bootstrap approaches for the small number of time clusters may be more appropriate if this specification is retained.

---

## 3. Robustness and alternative explanations

### 3.1 Robustness exercises are extensive but do not address the central identification failure

The paper has many robustness checks: placebo cohort, leave-one-country-out, no-COVID sample, distributed lags, heterogeneity, RI, AKM proxy, pre-trend. This is substantial effort. However, most of these exercises probe the stability of the baseline correlation/IV estimate; they do not solve the core problem that the preferred estimate disappears with country-by-year FE and fails RI.

This distinction is important. A battery of secondary checks cannot compensate for a failure of the main design under the most relevant identifying restriction.

### 3.2 The placebo is suggestive, not decisive

The 25–64 placebo in Table `tab:placebo` is directionally reasonable. If Erasmus mainly affects recent cohorts, the effect should be diluted in the broader 25–64 group. But this is not a strong falsification test:
- the 25–64 outcome still contains the treated 25–34 group;
- mechanical dilution can produce smaller coefficients even if broader omitted regional trends drive the result;
- older-cohort stability does not validate the exclusion restriction.

So this is supportive but limited.

### 3.3 The “pre-trend” test is not a strong test of pre-trends

Section 7.4 describes a pre-trend test regressing tertiary share on predicted outflow rate using 2014–2019. But that is not obviously a pre-trend test in the DiD/event-study sense, because the treatment is continuous, persistent, and already present during that period. Also, Erasmus is not “untreated” before the 2021 budget expansion; the program is active throughout the sample. A null relationship in 2014–2019 does not establish that the post-2019 or full-sample relationship is causal.

If the paper wants a trend-based diagnostic, it should examine whether pre-period changes in tertiary share are predicted by baseline exposure shares or predicted outflows before the outcome window used in the long differences, not simply estimate the main relationship on an earlier subsample.

### 3.4 Heterogeneity is interesting but cannot bear the paper’s policy claims without stronger identification

The peripheral/core split is substantively plausible and one of the most interesting findings in the paper. But because it is estimated within the same baseline panel framework that fails under country-by-year FE, it should be interpreted cautiously. It may reflect differential omitted trends across poorer vs richer regions.

At minimum, the paper should show whether the heterogeneity survives the stricter country-by-year specification, or explain why that specification is infeasible or too low-powered. Without that, the strongest policy claim—that Erasmus undermines cohesion precisely in poorer regions—is not securely identified.

### 3.5 Receiver-side analysis is underdeveloped and not comparable

The receiver-side analysis is OLS only, whereas the sender-side claim is based on IV. That makes the asymmetry hard to interpret. A null OLS relationship for receivers cannot be contrasted meaningfully with an IV sender estimate. The asymmetry may be real, but current evidence does not establish it.

### 3.6 Mechanism vs reduced form is not always cleanly separated

The paper often moves from reduced-form regional composition effects to a mechanism of non-return / permanent relocation of Erasmus participants. That mechanism is plausible and grounded in prior literature, but the current data do not directly observe return migration or post-study location choices. The paper should more clearly distinguish:
- estimated regional composition effects,
- inferred migration/retention mechanisms,
- and normative implications for Cohesion Policy.

---

## 4. Contribution and literature positioning

### 4.1 The question is important and potentially publishable

The paper addresses a genuinely important policy question: whether subsidized educational mobility and place-based redistribution may work at cross-purposes. That framing is novel and attractive for a broad audience, especially given EU policy salience.

The use of bilateral Erasmus flows at NUTS3 is also potentially a real contribution, especially if it can support a design that cleanly isolates within-country variation.

### 4.2 Current contribution relative to prior work is overstated given the identification limits

The paper positions itself as advancing from individual returns to regional equilibrium effects and from NUTS2 to finer geography. That is fair in principle. But because the outcome with substantive content is observed at NUTS2 and the within-country identification is strongest only at NUTS3 with an indirect outcome, the practical contribution is less clear than advertised.

The “central methodological finding” is said to be that the NUTS3 Bartik has genuine within-country power. That is a useful diagnostic result, but on its own it is not enough for a top-journal contribution unless paired with a convincing causal estimate on an outcome tightly tied to the paper’s question.

### 4.3 Literature coverage is decent, but some adjacent literatures could be integrated more sharply

The paper cites the key shift-share methodological papers and major brain-drain references. I would encourage stronger engagement with adjacent literatures on:
- internal migration and regional human capital sorting,
- place-based policies and mobility responses,
- return migration / brain circulation,
- and exposure-share identification critiques.

Concrete additions that would likely strengthen positioning:
1. **Bound, Jaeger, and Baker (1995)** — classic critique of shift-share/Bartik style IV relevance/exogeneity logic.
2. **Jaeger, Ruist, and Stuhler (2018)** — for dynamic migration responses and treatment timing concerns in migration settings.
3. **Moretti (2012, The New Geography of Jobs)** or related urban human-capital sorting work — to connect regional composition changes to broader local equilibrium mechanisms.
4. Depending on exact scope, more of the **place-based policy with mobility response** literature (e.g., Kline and Moretti-related work) could help calibrate how unusual it is for subsidies to induce spatial re-sorting.

These citations are not missing in a fatal sense, but they would help situate the paper’s empirical challenge and policy interpretation more rigorously.

---

## 5. Results interpretation and claim calibration

### 5.1 Claims are stronger than the evidence supports

The title, abstract, introduction, and conclusion all lean toward a substantive causal claim that Erasmus “drains” human capital from peripheral regions and creates a “fundamental tension” with Cohesion Policy. That goes beyond the evidence currently established.

Given:
- failure of RI,
- zero effect under country-by-year FE in the main panel,
- weak IV in NUTS3,
- and opposite sign in NUTS2 long-difference,

the appropriate calibration is something like:
> the paper documents patterns consistent with Erasmus-associated regional human-capital redistribution, especially across poorer regions, but causal attribution remains unresolved.

Anything stronger is over-claiming.

### 5.2 Magnitude interpretation is often too mechanical

Section 6.3 and 6.4 convert coefficients into sizable policy-relevant losses, including comparisons to Moretti-style wage externalities and statements that Erasmus-induced brain drain could explain a “substantial fraction” of the education gap. These magnitudes are too speculative given the identification uncertainty and the instability across specifications.

In particular:
- multiplying the peripheral coefficient by a high outflow percentile to infer 5 pp tertiary-share losses is aggressive when the estimate comes from a panel design that does not survive stricter fixed effects;
- mapping that into wage losses using U.S. city externality estimates compounds uncertainty substantially.

These exercises should be framed, if retained, as back-of-the-envelope illustrations under strong assumptions, not policy conclusions.

### 5.3 Contradictions across results need tighter synthesis

The paper has:
- weak, imprecise negative NUTS3 long-difference,
- significant negative NUTS2 panel,
- zero with country-by-year FE,
- positive NUTS2 long-difference,
- and null receiver-side OLS.

These can perhaps be reconciled, but the current synthesis is too quick. A top-journal paper needs a much clearer statement of which estimate is preferred and why, and what parameter each specification targets.

At present the reader is left with a menu of conflicting estimates and a narrative that emphasizes whichever result best supports the overarching claim.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Re-center the paper around a design with credible identification, or sharply downgrade causal claims
- **Issue:** The preferred NUTS2 effect vanishes with country-by-year FE and the shift-share design fails randomization inference.
- **Why it matters:** This is the core scientific obstacle. Without credible identification, the paper cannot support its headline causal claims.
- **Concrete fix:** Either:
  - redesign around a more plausibly exogenous source of variation (e.g., institutional rule changes, eligibility discontinuities, bilateral agreement shocks, program expansions with clear differential exposure and pre-trend validation), or
  - rewrite the paper as a suggestive/descriptive analysis and strip causal language from title, abstract, introduction, results, conclusion, and policy sections.

#### 2. Provide weak-IV robust inference for all specifications with borderline first-stage strength
- **Issue:** The NUTS3 long-difference has first-stage F around 6.5–9.4 depending on implementation.
- **Why it matters:** Conventional 2SLS t-tests are unreliable under weak instruments.
- **Concrete fix:** Report Anderson-Rubin and CLR confidence sets/p-values for the NUTS3 long-difference and any other weak-IV specification. Refrain from interpreting sign reversals as evidence if weak-IV robust inference is uninformative.

#### 3. Replace the AKM proxy with a valid shift-share inference procedure
- **Issue:** “Modal destination clustering” is not AKM inference.
- **Why it matters:** Inference in shift-share designs is a first-order issue.
- **Concrete fix:** Implement a proper AKM/AKM0-style procedure, or remove the current claim that AKM inference strengthens confidence. If computationally difficult, clearly label the current exercise as heuristic and do not use it to validate inference.

#### 4. Clarify what estimand each specification targets and why signs differ
- **Issue:** Panel, long-difference, and NUTS3 proxy outcome estimates differ sharply in sign and significance.
- **Why it matters:** Without a coherent estimand discussion, results appear unstable rather than informative.
- **Concrete fix:** Add a subsection explicitly contrasting the causal objects: annual contemporaneous composition effect, medium-run net stock effect, and demographic-composition proxy effect. State which one is primary and why.

#### 5. Substantially recalibrate conclusion and policy claims
- **Issue:** Policy implications are stronger than the evidence warrants.
- **Why it matters:** Overclaiming reduces credibility.
- **Concrete fix:** Remove language implying established causal “drain” unless the design is strengthened. Present policy discussion as contingent and exploratory.

### 2. High-value improvements

#### 6. Show whether heterogeneity survives more credible within-country controls
- **Issue:** The peripheral/core result is striking but estimated in the same design whose baseline fails with country-by-year FE.
- **Why it matters:** This heterogeneity currently bears too much interpretive weight.
- **Concrete fix:** Estimate the heterogeneity specification with country-by-year FE, or at least show reduced forms/first stages within that stricter design. If precision collapses, say so clearly.

#### 7. Improve timing/modeling of stock outcomes
- **Issue:** A yearly flow rate is used to explain a stock outcome, and lag specifications are ad hoc.
- **Why it matters:** Misspecification may explain unstable signs and magnitudes.
- **Concrete fix:** Construct cumulative or distributed exposure measures more tightly aligned with the stock nature of tertiary share, or model changes in tertiary share as a function of cumulated predicted outflows over relevant prior years.

#### 8. Strengthen falsification tests
- **Issue:** Current placebo and pre-trend exercises are suggestive but weak.
- **Why it matters:** Better falsifications can sharpen interpretation even if they do not fully solve identification.
- **Concrete fix:** Test whether baseline exposure predicts pre-2014 changes where available, or outcomes less plausibly affected by Erasmus (e.g., older cohort composition changes, non-tertiary age groups, or outcomes unrelated to educational migration).

#### 9. Provide a transparent sample construction appendix
- **Issue:** Region counts and sample restrictions are somewhat difficult to track.
- **Why it matters:** Sample selection could matter materially when the IV sample excludes zero-flow regions.
- **Concrete fix:** Add a sample flow chart/table documenting how many regions are dropped at each step, especially due to missing pre-period shares and GDP.

#### 10. Address selection into the IV sample
- **Issue:** Regions with zero pre-period Erasmus participation are excluded from IV analysis.
- **Why it matters:** This may change the estimand toward already internationally connected regions.
- **Concrete fix:** Characterize excluded regions and discuss external validity. Consider alternative share construction or regularization methods allowing inclusion of zero-share regions if feasible.

### 3. Optional polish

#### 11. Tighten the receiver-side analysis or drop it
- **Issue:** OLS-only receiver analysis is not comparable to IV sender analysis.
- **Why it matters:** The current asymmetry claim is under-supported.
- **Concrete fix:** Either develop a comparable identification strategy for inflows or relegate the receiver-side discussion to a brief descriptive aside.

#### 12. Moderate the “go/no-go” framing
- **Issue:** The diagnostic is useful but rhetorically stronger than what it establishes.
- **Why it matters:** It may mislead readers into conflating relevance with validity.
- **Concrete fix:** Present it as a relevance/variation diagnostic rather than a decisive identification test.

#### 13. Add a table mapping each claim to its supporting specification
- **Issue:** The paper makes several layered claims with mixed evidence.
- **Why it matters:** This would help readers assess which conclusions are strongly vs weakly supported.
- **Concrete fix:** Summarize for each claim: preferred specification, identifying variation, main threat, and whether country-by-year FE / RI support it.

---

## 7. Overall assessment

### Key strengths
- Important policy question with broad appeal.
- Novel Erasmus bilateral flow data at NUTS3 resolution.
- Serious effort to engage modern shift-share concerns.
- Unusually transparent reporting of unfavorable diagnostics.
- Interesting heterogeneity by peripheral vs core regions.

### Critical weaknesses
- Main causal estimate does not survive country-by-year fixed effects.
- Randomization inference fails to support shock-based identification.
- NUTS3 specification is weakly identified and uses an indirect outcome.
- Opposite-signed long-difference estimate is not fully reconciled.
- Some inference claims (especially AKM) are not methodologically adequate.
- Policy conclusions are materially stronger than the evidence supports.

### Publishability after revision
There is a potentially interesting paper here, but not yet a publishable top-journal paper in its current empirical form. To become publishable, the paper likely needs either:
1. a substantially stronger research design that can credibly identify within-country causal variation in human-capital outcomes, or
2. a major reframing away from definitive causal claims toward carefully bounded, suggestive evidence.

Given the current state, this is beyond a “major revision” in the usual sense because the central identification architecture does not presently support the headline claim. The paper needs a fundamental redesign or reframing.

DECISION: REJECT AND RESUBMIT