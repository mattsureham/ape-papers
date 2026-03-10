# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T01:42:32.481877
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 21269 in / 5823 out
**Response SHA256:** 5ba9d886a823f503

---

This paper asks an important and policy-relevant question: do discrete EPC/energy-label thresholds generate capitalization in housing prices, and does the MEES regulatory threshold at E/F create an additional price jump? The paper’s main contribution is to shift attention from cross-band hedonic comparisons to local comparisons at score thresholds, using a very large linked transactions–EPC dataset and a multi-cutoff RD framework. The central finding is a mostly precise null at the non-regulatory cutoffs, especially C/D, and no compelling evidence of a positive price discontinuity at E/F.

I found the paper interesting and potentially publishable in a strong field journal after substantial revision, but not yet ready for a top general-interest outlet in its current form. The main reasons are: (i) the identification at the headline E/F regulatory threshold is not credible as currently implemented because of clear manipulation/sorting; (ii) some key design/timing details remain underspecified; (iii) the inference for derived estimands (difference-in-discontinuities, decomposition) is not yet fully defensible; and (iv) the paper still overstates what it can conclude about regulation relative to what it can conclude about threshold effects more generally.

Below I focus on scientific substance and publication readiness.

---

## 1. Identification and empirical design

### A. What is credibly identified

The cleanest design-based contribution is at the **informational thresholds**, especially **C/D**. The paper is right to emphasize that C/D is the only cutoff that appears to pass the density test cleanly and has relatively limited balance-test issues (\S5.1, \S6.1, Appendix Table on balance). The null at C/D is therefore the most persuasive result in the paper.

That result supports a fairly specific claim:

- **crossing an informational EPC letter boundary does not produce a detectable discrete price jump**, at least locally around the clean cutoff and for this market/institutional context.

That is a meaningful contribution.

### B. The headline E/F regulatory claim is not causally identified

The paper’s title/abstract and parts of the introduction emphasize the E/F threshold because it is the regulatory cliff under MEES. But by the paper’s own evidence, **the sharp RD at E/F fails the core no-manipulation/sorting condition**. The McCrary/density rejection is strong (\S6.1; Table “McCrary Density Tests,” E/F \(p<0.001\)), and covariate balance also shows discontinuities at E/F (flat indicator, new-build status in Appendix balance table). This is not a minor caveat; it is central.

That means:

- the paper does **not** have a credible sharp-RD estimate of the causal effect of MEES at E/F;
- the E/F estimate is at best **suggestive descriptive evidence**;
- the “null” at E/F should not be used as if it were equally probative as the C/D null.

The manuscript often acknowledges this, but the framing still occasionally overreaches, especially in the abstract and conclusion. “A well-powered null” is fully justified for C/D and perhaps for the existence of **discrete threshold effects overall**, but it is not fully justified for **regulatory capitalization at E/F**, because the identifying design there is compromised.

### C. Manipulation is not only a nuisance; it may change the estimand

The paper argues that bunching at E/F likely biases the estimate downward because some lower-quality units are pushed from 38 to 39 (\S4.6; \S7.1). That direction is plausible, but the paper treats it as more certain than is warranted. With manipulation of the running variable by assessors/owners, local composition may change in multiple ways:

- “treated” units just above the cutoff may be negatively selected;
- strategic upgrading, selective listing, or sale timing may alter the composition of transacted units;
- if some units actually invest to cross the threshold, then observed sorting is not pure measurement manipulation.

In short, once manipulation is present, the observed discontinuity is not simply an attenuated version of a clean treatment effect. It is a conflation of treatment, sorting, and endogenous assessment/transaction behavior. The paper should be more careful not to assign a sign and interpretation too confidently.

### D. Treatment timing / data timing is insufficiently specified

A major design issue is that the paper never clearly states **which EPC certificate is assigned to each transaction and whether the EPC score is measured before the transaction** (\S3). This is crucial.

Questions that must be answered explicitly:

1. Is the linked EPC the **most recent certificate before sale**, the nearest in time, or any linked certificate?
2. Are certificates dated **after** the transaction excluded?
3. If not, then the running variable may be measured after the outcome, which is problematic.
4. How are multiple EPCs per property handled?
5. How are repeated sales of the same property handled?

This is not a cosmetic concern. If the EPC is measured after sale, the score could reflect post-sale renovations, reassessment, or administrative timing unrelated to the market information available to buyers at the time of transaction. That would undermine the design.

The fact that the paper reports “EPC recency” as a balance diagnostic suggests timing is available, but not the exact linking rule. This needs to be moved from appendix-level implication to main-text clarity.

### E. The use of a 500,000 random subsample is not satisfactory as the main analysis

The paper estimates the main RD on a 500,000 random subsample “for computational feasibility” (\S1, \S4.7), then later reports “full-sample validation” with a fixed bandwidth \(h=8\) (\S6.7). For a top journal, this is not enough.

Problems:

- the main reported results use one sample;
- the validation uses a different sample and a different bandwidth rule;
- the validation is therefore not a direct replication of the main specification;
- if the full sample is available, the preferred specification should be estimated on the full sample.

Given the paper’s emphasis on precision and ruling out economically meaningful effects, it is especially important that the main estimates use the full data wherever feasible. If software is limiting, the authors should either use more scalable implementations or redesign the computation. A random subsample is not a fatal flaw, but it is not acceptable as the principal specification in a paper whose value proposition is “well-powered null.”

### F. Difference-in-discontinuities around MEES is conceptually appealing but not yet convincing

The diff-in-disc exercise (\S4.5, \S5.4) is potentially valuable, but it inherits the E/F sorting problem and adds additional assumptions.

For the pre/post comparison at E/F to isolate MEES capitalization, one needs confidence that:

- the nature of score manipulation/composition around E/F did not itself change sharply in ways unrelated to price capitalization;
- other market changes did not differentially alter the local price-score relationship near E/F;
- the comparison boundary C/D is an appropriate control for local time-varying score-price curvature and housing composition.

These assumptions are plausible but not established. Since E/F is manipulated, changes in bunching or strategic transaction selection after 2018 could mechanically alter the local discontinuity estimate even if there is no treatment effect. The paper should discuss this much more explicitly and not present the diff-in-disc as a stronger causal test than it really is.

### G. Repeated observations and dependence structure

The paper clusters at local authority district (LAD) level (\S4.2). That may account for broad spatial correlation, but there are at least two unresolved dependence issues:

- multiple transactions for the same property over time;
- potential correlation induced by discrete score cells and local markets.

At minimum, the paper should report whether properties appear multiple times and whether results change when restricting to first observed sale per property, or when clustering at a finer market level / using property-level block bootstrap if repeated sales are common.

---

## 2. Inference and statistical validity

This paper takes inference seriously in many places, but some core aspects still need strengthening.

### A. Main RD inference is mostly appropriate, but some details need to be reported more fully

Using robust bias-corrected RD inference via `rdrobust` is appropriate (\S4.2). The manuscript also notes mass-point adjustment for integer SAP scores, which is important.

However, for publication readiness the paper should report, at least in an appendix table for all main specifications:

- left and right bandwidths;
- left and right effective sample sizes;
- polynomial order used;
- number of unique score support points within bandwidth;
- number of clusters used;
- whether bandwidths are common across with/without-covariate specifications.

This matters especially because the running variable is discrete and local support is limited at some cutoffs, notably A/B and post-crisis period splits.

### B. Inference for derived estimands is currently weak

The decomposition and difference-in-discontinuities rely on “propagation assuming independence” across boundaries/periods (\S4.4, \S5.3, \S5.4). That assumption is not credible:

- the same housing markets and time periods contribute to multiple estimates;
- errors are likely correlated across cutoffs and periods;
- some specifications may use overlapping sets of observations or market shocks.

The paper itself shows that bootstrap SEs differ materially from propagation SEs (\S6.8), which is effectively an admission that the reported table inference is not the preferred one.

This must be fixed. For the decomposition, diff-in-disc, and triple difference, the paper should present one coherent preferred inference approach, ideally:

- **cluster bootstrap at the relevant market level** with many more than 200 replications; or
- a re-estimation framework that computes the combined estimand directly rather than by ex post subtraction.

As written, the paper reports one set of p-values in the main tables and then says bootstrap gives different SEs later. That is not publication-ready.

### C. The bootstrap section raises its own questions

The bootstrap finding that SEs are about half the propagation SEs (\S6.8) could be reasonable, but it needs fuller explanation and implementation detail:

- Why only 200 replications?
- Why district resampling rather than another level?
- Is the bootstrap stable?
- Are the point estimates identical to the main tables, or recomputed under bootstrap?
- How does bootstrap handle RD bandwidth selection and mass-point adjustments?

For a top-journal empirical paper, 200 reps is thin. This should be increased substantially and integrated into the main inference presentation.

### D. Small-cell period/tenure analyses are underpowered and should be de-emphasized

Several period-specific and tenure-specific cells have tiny local effective samples (e.g., E/F post-crisis \(N_{\text{eff}}=315\); tenure splits in Appendix Table on tenure) and, with integer running variables, very little support. These estimates should not bear interpretive weight. The paper generally notes caution, but still draws some inferences from them. Better to frame them as exploratory only.

### E. Full-sample validation is not a substitute for proper main-sample inference

The fixed-\(h=8\) full-sample estimates are helpful, but they do not directly validate the exact main specification because:

- the bandwidth differs;
- perhaps the left/right sample composition differs;
- the inferential procedure is not fully described.

If the full sample can be estimated at all, then it should be used to estimate the same preferred RD design for the main tables.

---

## 3. Robustness and alternative explanations

### A. Robustness at C/D is fairly convincing

For the clean boundary, the paper does a useful set of checks:

- with/without covariates;
- bandwidth sensitivity;
- donut RD;
- placebo cutoffs;
- full-sample validation;
- a visual smooth score-price relationship.

These bolster the core “no threshold jump” interpretation at informational cutoffs.

### B. Robustness at E/F cannot rescue identification

The donut RD at E/F is sensible, but it does not restore a clean design. In fact, the widening SEs and sign instability across wider donuts suggest that the local design is fragile once the manipulated support near the threshold is excluded (\S6.4).

That is fine; the authors should simply say more directly:

- donut RD is a sensitivity analysis, not a repair of the violated RD assumptions;
- the paper cannot cleanly estimate a causal E/F effect from these data alone.

### C. Placebo tests are somewhat underdeveloped

The placebo-cutoff figure is directionally useful, but to be informative the paper should specify:

- how placebo cutoffs were chosen;
- whether they exclude regions near real cutoffs;
- whether bandwidth selection and inference were applied symmetrically;
- whether any multiple-testing adjustment is used for the placebo family.

Otherwise the placebo evidence is suggestive, not probative.

### D. Alternative explanation: smooth pricing of the continuous score

This is the paper’s most plausible interpretation, and one of its strongest features. The manuscript appropriately distinguishes the absence of threshold effects from the absence of valuation of energy efficiency overall (\S1, \S6.7, \S7.1, Conclusion).

That said, the smooth-pricing interpretation would be stronger if the paper estimated it more directly. At present, the “continuous score-price relationship” is shown visually (\S6.7) but not formally. Since the paper repeatedly uses this as the leading interpretation, it should present a simple and transparent complementary analysis:

- local/global semiparametric relationship between log price and continuous SAP score, with rich geographic-time controls;
- perhaps slope heterogeneity before vs. during the energy crisis;
- possibly first-difference or repeat-sales version if available.

This would not replace the RD but would sharpen the paper’s substantive message: no threshold effect, but perhaps a smooth score effect.

### E. Strategic selling and composition deserve more attention

The volume RD result at E/F (Appendix volume table) is potentially important. If transaction volume/composition changes discontinuously after MEES, the set of observed sales near E/F is endogenous. That has direct implications for interpreting price RD estimates.

Right now, the paper mentions strategic selling as an “alternative mechanism” but does not integrate it into the identification discussion. It should. If composition changes at E/F after MEES, then price comparisons among transacted units may fail to reveal capitalization even if asset values changed in the underlying stock.

A stronger version would examine whether observable characteristics of transacted units shift discontinuously after MEES near E/F, beyond the static balance tests.

---

## 4. Contribution and literature positioning

### A. The contribution is clear and potentially valuable

The paper’s best contribution is not “MEES had no effect” per se; it is:

1. a large-scale, threshold-based test of whether **discrete EPC labels** create local price jumps;
2. evidence that the **clean informational threshold** does not;
3. suggestive evidence that even the regulatory threshold does not show a positive jump in observed transaction prices.

That contribution is distinct from the hedonic capitalization literature.

### B. The paper should better position itself relative to RD with manipulated/discrete running variables

Given how central these issues are, the literature review should engage more directly with methodological work on:

- RD with **discrete running variables**;
- RD under **manipulation/sorting**;
- limits of donut designs as remedies.

The current citations include the core `rdrobust` papers, but the discussion remains too applied and not sufficiently tied to what the modern RD literature says about credibility when the density test fails. The paper should explicitly anchor its interpretation in that literature.

### C. The contrast with hedonic studies is useful but somewhat overstated

The manuscript often suggests that the RD null implies prior hedonic premia “likely reflect omitted variables” (\S7.2). That is too strong. The cleaner interpretation is:

- hedonic models estimate average cross-band or cross-score capitalization, which may combine smooth energy-efficiency pricing with many correlated characteristics;
- RD estimates local threshold effects;
- these are different estimands, so disagreement is not by itself evidence that the hedonic literature is wrong.

A more calibrated discussion would improve the paper.

### D. Concrete literature to add

I would encourage adding more explicit discussion/citation of work on:

1. **Discrete running variables in RD**
   - Kolesár and Rothe (2018), *Inference in regression discontinuity designs with a discrete running variable*.
   - Related discussions in Cattaneo et al. on local randomization / finite support concerns.

2. **Manipulation and sorting in RD**
   - McCrary (2008) as foundational.
   - Gerard, Rokkanen, and Rothe (2020), on bounds/identification under manipulation in RD.

3. **Multi-cutoff and extrapolation issues**
   - The paper cites Cattaneo et al. (2016), but should more clearly connect what is and is not identified when comparing different cutoffs with different local populations.

These additions matter because the paper’s central interpretation rests on RD credibility distinctions across cutoffs.

---

## 5. Results interpretation and claim calibration

### A. The C/D conclusion is appropriately precise

The paper’s language around C/D is generally well calibrated: the estimate is near zero and reasonably precise. This is the strongest result.

### B. The E/F conclusion should be weakened and reframed

The current framing still tends to imply: “MEES did not generate price capitalization.” That is stronger than the evidence supports. The evidence supports:

- no detectable positive discontinuity in observed transaction prices at E/F;
- but causal interpretation is limited by sorting/manipulation and possible endogenous transaction composition.

That distinction matters a great deal.

### C. “Ruling out effects larger than X%” should be made fully consistent with all reported CIs

The manuscript repeatedly says it rules out positive effects larger than 6–8 percent. Those statements should be synchronized with:

- the exact preferred sample/specification;
- full-sample versus subsample estimates;
- whether the CI is RBC and cluster-adjusted;
- whether E/F statements are conditional on ignoring sorting.

As written, these “ruled out” statements are somewhat too broad, especially for E/F.

### D. Policy implications are directionally interesting but a bit overextended

The policy discussion suggests that disclosure mandates and threshold designs may be ineffective, and that tightening MEES to C may not work without stronger enforcement (\S7.4). This is plausible, but the paper should be more proportional to the evidence:

- it has strong evidence against **discrete threshold capitalization**;
- weaker evidence about the broader effectiveness of disclosure;
- and compromised evidence about the capitalization of the MEES regulation itself.

A more measured policy takeaway would improve credibility.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Clarify and document transaction–EPC timing/linking
- **Issue:** The paper does not clearly state which EPC certificate is linked to each transaction or whether EPC scores are measured before sale.
- **Why it matters:** If the running variable is measured after the outcome, the design is fundamentally weakened.
- **Concrete fix:** Add a dedicated subsection in Data/Empirical Strategy specifying the exact matching rule (e.g., nearest prior EPC, latest prior EPC, window restrictions), report the distribution of assessment-to-sale timing, and re-estimate the main results restricting to EPCs dated on/before transaction date and within sensible pre-sale windows.

#### 2. Recompute the main RD results on the full sample using the preferred specification
- **Issue:** The headline results rely on a 500,000 random subsample, while full-sample results are only partial validation with a different bandwidth.
- **Why it matters:** The paper’s contribution relies on power and precision; top-journal publication requires the main specification on the full data if feasible.
- **Concrete fix:** Replace the main tables with full-sample estimates using the same preferred RD procedure, or provide a compelling computational reason plus exact replication of the main specification on the full sample.

#### 3. Reframe E/F as non-causal/suggestive unless a stronger identification strategy is developed
- **Issue:** The E/F threshold fails the density test and shows covariate imbalance.
- **Why it matters:** The paper cannot claim a clean causal estimate of regulatory capitalization at E/F.
- **Concrete fix:** Rewrite the abstract, introduction, results, and conclusion to clearly separate (i) credible null at clean informational threshold(s), and (ii) suggestive non-causal evidence at the manipulated regulatory threshold.

#### 4. Replace propagation-based inference for decomposition and diff-in-disc with a defensible preferred method
- **Issue:** Independence-based SE propagation is not credible for cross-period/cross-boundary contrasts.
- **Why it matters:** These are central secondary results.
- **Concrete fix:** Implement a cluster bootstrap with substantially more replications and make that the main inference throughout, or estimate the combined contrasts directly in a unified regression framework.

#### 5. Address endogenous composition of transacted units around E/F
- **Issue:** The volume RD suggests strategic sorting of transactions after MEES.
- **Why it matters:** Observed sale prices among transacted units may not identify capitalization in the housing stock.
- **Concrete fix:** Move the volume/composition discussion into the main identification section; examine whether observable sale composition shifts at E/F post-MEES; temper claims accordingly.

### 2. High-value improvements

#### 6. Add a more formal analysis of smooth continuous-score pricing
- **Issue:** The paper leans heavily on the “smooth pricing of SAP score” interpretation but shows it mostly graphically.
- **Why it matters:** This is the main substantive alternative to threshold effects and strengthens the paper’s positive contribution.
- **Concrete fix:** Estimate the continuous score-price relationship with flexible controls and report whether the slope steepens during the energy crisis.

#### 7. Strengthen reporting for RD implementation
- **Issue:** Key RD diagnostics/support details are not fully tabulated.
- **Why it matters:** Readers need to assess local support, finite-sample credibility, and comparability across specifications.
- **Concrete fix:** Report left/right bandwidths, left/right effective sample sizes, support points, clusters, and unique-score counts for all main estimates.

#### 8. Reassess clustering/dependence
- **Issue:** LAD clustering may not fully address repeated-property dependence or local serial correlation.
- **Why it matters:** Standard errors may be mismeasured.
- **Concrete fix:** Report the prevalence of repeated sales and run sensitivity checks: first-sale-only sample, alternative clustering, or block bootstrap.

#### 9. Integrate the manipulation problem more explicitly with modern RD guidance
- **Issue:** The paper notes bunching but still sometimes interprets E/F too causally.
- **Why it matters:** The credibility of the paper depends on properly aligning interpretation with RD assumptions.
- **Concrete fix:** Expand the methodology/literature discussion on manipulated and discrete running variables, and explicitly state what remains identified when density continuity fails.

### 3. Optional polish

#### 10. Tighten the contribution claim relative to the hedonic literature
- **Issue:** The paper sometimes implies prior hedonic findings are mostly omitted-variable bias.
- **Why it matters:** That claim is stronger than necessary and may be incorrect since estimands differ.
- **Concrete fix:** Recast as “the RD tests local threshold effects, not average smooth capitalization across the score distribution.”

#### 11. Make placebo-cutoff design more transparent
- **Issue:** Placebo construction is underspecified.
- **Why it matters:** The robustness value is limited without a clear protocol.
- **Concrete fix:** Add an appendix describing placebo selection, bandwidth/inference symmetry, and family-wise interpretation.

#### 12. De-emphasize very small-sample post-crisis and tenure cells
- **Issue:** Some subgroup estimates have minimal support.
- **Why it matters:** They can distract from the stronger core evidence.
- **Concrete fix:** Relegate exploratory cells to appendix or explicitly label them as underpowered.

---

## 7. Overall assessment

### Key strengths
- Important and timely policy question.
- Clever and substantively meaningful threshold-based design.
- Very large linked administrative dataset.
- Strongest result at C/D is potentially informative and publishable.
- The paper is admirably transparent about some limitations, especially manipulation at E/F.
- Robustness exercises are broad and generally thoughtful.

### Critical weaknesses
- The flagship regulatory threshold E/F is not credibly identified as a sharp RD because of clear manipulation/sorting.
- Main analysis on a random subsample is not adequate for a paper whose central contribution is precision.
- Timing/linking of EPC to transactions is insufficiently documented.
- Inference for decomposition and diff-in-disc is not yet publication-ready.
- Claims about MEES/regulatory capitalization remain stronger than the design warrants.

### Publishability after revision
I think the paper is **salvageable and potentially strong**, especially if reframed as a paper about the absence of **discrete threshold capitalization** rather than a definitive causal null on MEES. If the authors can (i) fully document timing/linkage, (ii) move the main RD to the full sample, (iii) clean up inference for derived estimands, and (iv) discipline the E/F interpretation, the paper could become a solid contribution. In its current form, however, the identification and inference issues are too substantial for acceptance.

DECISION: MAJOR REVISION