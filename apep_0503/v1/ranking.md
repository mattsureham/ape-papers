# Research Idea Ranking

**Generated:** 2026-03-04T11:59:10.427197
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Banned from the Market — Energy Labels, ... | PURSUE (78) | PURSUE (88) | PURSUE (88) |
| What’s a Mayor Worth? Politician Compens... | CONSIDER (62) | — | — |
| Drawing the Line — Flood Risk Zone Desig... | SKIP (52) | SKIP (42) | SKIP (52) |
| What's a Mayor Worth? Politician Compens... | — | PURSUE (55) | CONSIDER (68) |

---

## GPT-5.2

**Tokens:** 6651

### Rankings

**#1: Banned from the Market — Energy Labels, Rental Prohibitions, and Property Price Capitalization in France**
- **Score: 78/100**
- **Strengths:** Unusually sharp and policy-salient treatment: an energy label cutoff that *removes the right to rent* is a much bigger “bite” than the standard EPC salience setting, and the phased schedule allows a clean anticipation/horizon angle. Massive administrative samples + multi-cutoff structure naturally support “internal replication” and mechanism separation (info vs. regulation vs. anticipation).
- **Concerns:** The main fragility is manipulation/selection around DPE scores (strategic audits, renovations timed to just clear a cutoff, heaping/rounding) and selection into having a DPE in the first place (triggered by sale/rent). Linking ADEME DPE to DVF at scale without differential match error near cutoffs is also nontrivial, and the true post-ban window is still short (2023–2025) for equilibrium adjustment.
- **Novelty Assessment:** **High-medium.** Energy label capitalization is heavily studied, but *rental prohibitions tied to labels* with multiple horizons and a double-seuil rule is much less mined and plausibly first/early in the literature.
- **Top-Journal Potential: High.** This can be framed as a belief-changing test of whether climate housing policy works via renovation vs. market reallocation (sales/vacancy/rental supply), with repeated trials across cutoffs and a built-in owner-occupier placebo; that’s top-field/top-5 shaped if the diagnostics are clean and the “bite” is demonstrated.
- **Identification Concerns:** Density/bunching at thresholds; sorting into (or timing of) DPE measurement; and multidimensional assignment under the double-seuil (energy vs CO₂) could undermine a simple sharp RDD. You’ll want McCrary + covariate balance, donut RDDs, heaping-robust checks, and a clearly pre-registered way to handle the bivariate rule.
- **Recommendation:** **PURSUE (conditional on: (i) strong no-manipulation evidence or a defensible donut strategy; (ii) a convincing “first-stage” showing the ban changes rental-market feasibility/behavior—not just labels; (iii) validated DPE↔DVF linkage quality with robustness to match error).**

---

**#2: What’s a Mayor Worth? Politician Compensation, Governance Quality, and the Compound Treatment Problem in French Communes**
- **Score: 62/100**
- **Strengths:** First-order policy question (politician pay → selection/governance) with clear welfare stakes, and France offers many thresholds plus council-size-only placebos that could be used to directly attack the “compound treatment” critique. The 2025 Gatel Law creates an additional quasi-experimental layer if implementation is sharp and timing is clean.
- **Concerns:** The compound-treatment problem is not just “council size”: French population thresholds often bundle multiple institutional changes (staffing, reporting requirements, transfers/formulas, inter-municipal constraints), and those co-movements can swamp the salary channel. External validity across thresholds is also tricky (different communes, different regimes), and “candidate quality” via profession codes is noisy and may not move even if true quality does.
- **Novelty Assessment:** **Medium.** Politician compensation RDDs are a known genre (Italy and others), but France is underexploited largely *because* the thresholds are messy; the novelty would come from credibly solving (or bounding) the compound-treatment issue.
- **Top-Journal Potential: Medium.** If you can convincingly isolate compensation (or produce tight bounds showing compensation doesn’t matter despite a strong first stage), it’s exciting; without that, it risks reading as “competent multi-threshold RDD with ambiguous treatment.”
- **Identification Concerns:** Non-salary institutional discontinuities at the same thresholds are the central threat; “differential dosage” helps but doesn’t guarantee exclusion. Also watch for limited effective N at larger thresholds and for specification searching across many cutoffs (you’ll need a disciplined, pooled/multi-cutoff design and an inference plan).
- **Recommendation:** **CONSIDER (conditional on: (i) a comprehensive “what else changes at each threshold” audit; (ii) a pooled design that pre-commits to a small set of thresholds with high effective N; (iii) at least one outcome with a tight theoretical link to mayor effort/competence and a demonstrable first stage).**

---

**#3: Drawing the Line — Flood Risk Zone Designations and Property Value Capitalization in France**
- **Score: 52/100**
- **Strengths:** High policy relevance (adaptation, disclosure, land-use regulation) and DVF-scale transactions could deliver precise estimates; staggered PPRI adoption opens the door to an RDD × event-study design rather than a single cross-section.
- **Concerns:** Spatial RDD at risk-map boundaries is notoriously vulnerable because boundaries follow geography (rivers, elevation, amenities) and thus can violate local randomization; even if perfectly executed, interpretation often collapses into “risk changes at the boundary” rather than “regulation/disclosure changes.” Data engineering risk is also substantial (high-quality geocoding, harmonizing changing PPRI polygons over time, and dealing with map revisions).
- **Novelty Assessment:** **Low-medium.** The French setting is less studied, but “flood zone designation → house prices” and spatial boundary designs are a crowded international literature; novelty would need to come from a distinctive French institutional feature (e.g., enforcement intensity, disclosure regime) or new measurement of map error/reclassification.
- **Top-Journal Potential: Low-Medium.** Absent a uniquely French mechanism or a new measurement/diagnostic contribution (e.g., map misclassification, enforcement heterogeneity, disclosure salience), top outlets may view it as another capitalization paper in a well-trodden area.
- **Identification Concerns:** Sorting and unobserved geographic gradients at boundaries; endogeneity of PPRI adoption timing (often after floods); and boundary placement reflecting continuous risk. You’d likely need strong pre-trend/event-time evidence, boundary “within-neighborhood” fixed effects, and possibly instruments/controls for modeled flood risk to defend a regulatory/disclosure interpretation.
- **Recommendation:** **SKIP (unless you can: (i) obtain high-confidence parcel geocodes + time-stamped polygon vintages; and (ii) convincingly separate “designation/disclosure” from “underlying risk” using pre-period transactions and/or independent risk models).**

---

### Summary

This is a strong batch in terms of policy importance and administrative data access, but only **Idea 1** currently combines high novelty with a plausibly clean design and a top-journal style mechanism map. **Idea 2** is potentially important but must overcome a severe bundled-institutions problem to avoid interpretability issues. **Idea 3** is policy-relevant but sits in a saturated literature with harder identification, so I would prioritize (and staff) Idea 1 first.

---

## Gemini 3.1 Pro

**Tokens:** 7161

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, heavily weighting identification credibility and the editorial preferences of top economics journals.

### Rankings

**#1: Banned from the Market — Energy Labels, Rental Prohibitions, and Property Price Capitalization in France**
- **Score**: 88/100
- **Strengths**: This proposal perfectly aligns with what top journals want: a first-order policy shock (climate transition in housing) evaluated through a highly legible causal design (multi-cutoff RDD). The ability to decompose pure information effects from active and anticipated regulatory bans using the phased rollout is exceptionally clever.
- **Concerns**: The primary risk is density manipulation (bunching) at the cutoffs, as assessors might face pressure to bump a "G" property to an "F" to avoid the ban. The *double-seuil* (two-dimensional running variable) also complicates the standard RDD estimation.
- **Novelty Assessment**: High. While energy label capitalization is a saturated literature, almost all existing papers study *informational* labels (like the UK EPC). Studying a hard regulatory *prohibition* with phased anticipation horizons is genuinely novel and pushes the frontier of environmental/urban economics.
- **Top-Journal Potential**: High. This has clear Top-5 or AEJ: Policy potential. It hits multiple empirically observed winning patterns: it features "internal replication" (multiple cutoffs), tests a "trade-off discovery" (renovation vs. market displacement), and most importantly, includes an "opponent-killer" placebo (owner-occupied properties). 
- **Identification Concerns**: The design is theoretically pristine, but its empirical survival hinges entirely on the McCrary density test. If landlords successfully bribe DPE assessors to manipulate scores just over the threshold, the RDD assumption of smooth potential outcomes is violated.
- **Recommendation**: PURSUE (conditional on: passing McCrary density tests for manipulation at the DPE cutoffs; successfully mapping the *double-seuil* dimensionality into a clean running variable).

**#2: What's a Mayor Worth? Politician Compensation, Governance Quality, and the Compound Treatment Problem in French Communes**
- **Score**: 55/100
- **Strengths**: The dataset is comprehensive, and the question of politician compensation and selection remains relevant in political economy. The attempt to use "differential dosage" to untangle the compound treatment is a creative econometric workaround.
- **Concerns**: The compound treatment problem (salary + council size changing simultaneously) is a massive liability. Top journals rarely accept "workarounds" for messy identification when cleaner natural experiments (like Italy's pure salary thresholds) already exist in the literature.
- **Novelty Assessment**: Low to Medium. The core question was famously answered by Gagliarducci & Nannicini (2013) in a much cleaner Italian setting. While applying this to France with a focus on fiscal outcomes is a new application, it reads as an incremental extension rather than a paradigm shift.
- **Top-Journal Potential**: Low. This falls squarely into the "competent but not exciting" category. Because the identification requires complex dosage arguments rather than a clean, isolated shock, referees will constantly question whether the effects are driven by council size rather than mayoral pay. It lacks the "legible causal channel" required for top general-interest journals.
- **Identification Concerns**: The differential dosage strategy assumes that the effect of council size is linear or easily partialled out. If moving from 35 to 37 councilors has a fundamentally different dynamic than moving from 23 to 27, the dosage comparison collapses. Furthermore, Eggers et al. (2018) explicitly warns against using French population thresholds due to sorting and compound policies.
- **Recommendation**: SKIP. (The identification hurdles are too high for a question that has already been cleanly answered in other contexts. If pursued, target a solid field journal like *Public Choice* or *European Economic Review*, not a Top-5).

**#3: Drawing the Line — Flood Risk Zone Designations and Property Value Capitalization in France**
- **Score**: 42/100
- **Strengths**: The combination of spatial RDD and staggered DiD provides a multi-layered approach to a highly relevant climate adaptation policy. The DVF dataset provides excellent statistical power.
- **Concerns**: The identification strategy suffers from a classic, often fatal, spatial RDD flaw: PPRI boundaries are not drawn randomly; they follow natural topography (rivers, elevation, flood plains) which independently determine property values. 
- **Novelty Assessment**: Low. Flood risk capitalization is a heavily saturated topic in environmental and urban economics. Without a radically new mechanism or a massive scale that changes what can be ruled out, this is just another ATE on a well-trodden topic.
- **Top-Journal Potential**: Low. The proposal violates the editorial preference against "another ATE on a saturated topic." Furthermore, the spatial RDD design is highly vulnerable to the "fatal flaw" of unobservables jumping at the boundary. 
- **Identification Concerns**: The spatial RDD is fundamentally compromised because the boundary is endogenous to geographic features. Properties inside the PPRI are likely at a lower elevation or closer to water than those just outside. Controlling for "distance to boundary" does not fix the discrete jump in unobservable geographic amenities/disamenities at the boundary line itself.
- **Recommendation**: SKIP. 

### Summary

This batch presents a stark contrast in quality, with one clear standout. **Idea 1 (Banned from the Market)** is an exceptional proposal that leverages a unique institutional feature (a phased rental ban) to answer a first-order policy question with a highly credible, placebo-backed design; it should be resourced and pursued immediately. Ideas 2 and 3 suffer from fatal identification flaws (compound treatments and endogenous spatial boundaries, respectively) and target literatures that are already heavily saturated, making them poor investments for a top-tier policy research institute.

---

## Grok 4.1 Fast

**Tokens:** 5527

### Rankings

**#1: Banned from the Market — Energy Labels, Rental Prohibitions, and Property Price Capitalization in France**
- Score: 88/100
- Strengths: Exceptional multi-cutoff RDD with owner-occupied placebo cleanly decomposes information, current regulatory, and anticipation effects in a high-stakes climate policy; massive universe-scale data (14M+ DPE, DVF transactions) enables precise inference and trade-off discovery (renovation vs. rental-to-sale displacement).
- Concerns: Double-seuil running variable adds complexity (though mitigable by focusing on energy-bound cases); potential bunching at cutoffs requires density tests.
- Novelty Assessment: Highly novel—first causal evidence on actual rental bans (vs. prior UK/France info-only papers), phased anticipation horizons, and double-seuil heterogeneity; no direct analogs.
- Top-Journal Potential: High. Fits editorial winners: legible causal chain (info → reg → antic), opponent-killing placebo, substitution trade-off reframing climate policy, universe data for precise bounds, multi-cutoff internal replication—could challenge EPC literature and package as belief-changing pivot on regulatory capitalization.
- Identification Concerns: Running variable continuity and parallel trends testable with pre-2021 data and non-regulatory cutoffs; owner-occupied placebo directly validates regulatory channel over confounders.
- Recommendation: PURSUE (conditional on: confirming no major bunching via McCrary; prioritizing energy-only subsample for clean RDD)

**#2: What's a Mayor Worth? Politician Compensation, Governance Quality, and the Compound Treatment Problem in French Communes**
- Score: 68/100
- Strengths: Clever differential dosage exploits compound treatment (salary vs. council size) with placebo thresholds, extending Gagliarducci-Nannicini to messy French setting; timely Gatel Law reform adds pre/post layer for fiscal/candidate outcomes.
- Concerns: Small effective N near thresholds (~35K communes total) risks underpowered estimates; compound design, while innovative, invites skepticism per Eggers (2018) warnings on French pop cutoffs.
- Novelty Assessment: Moderately novel—builds on Italian salary threshold literature but first French application with compound-treatment solution; no priors on fiscal/governance effects.
- Top-Journal Potential: Medium. Interesting mechanism map (salary dosage → fiscal discipline/candidate quality) in niche setting, but lacks universe-scale precision or first-order stakes; reads as "competent extension" without clear welfare pivot or trade-off surprise to excite top-5 editors.
- Identification Concerns: Council size confounds all salary jumps, relying on dosage/placebo differences; pre-trends and small bandwidth N could fail diagnostics, echoing editorial losses on underpowered RDDs.
- Recommendation: CONSIDER

**#3: Drawing the Line — Flood Risk Zone Designations and Property Value Capitalization in France**
- Score: 52/100
- Strengths: Spatial RDD + staggered DiD leverages accessible DVF data for French PPRI boundaries, separating disclosure from risk effects.
- Concerns: GIS-heavy matching untested; boundaries likely endogenous (drawn along rivers/floodplains), biasing capitalization estimates.
- Novelty Assessment: Low to moderate—flood zone capitalization well-studied (e.g., US FEMA papers); French PPRI application incremental, not transformative.
- Top-Journal Potential: Low. Standard spatial RDD on saturated topic without mechanism decomposition, trade-off discovery, or clean exogeneity; boundaries along natural features scream confounding, per editorial pitfalls, yielding "technically competent but unsurprising" ATE.
- Identification Concerns: Endogenous boundary placement (rivers correlate with values/flood risk) violates RDD continuity; sorting/disclosure anticipation unaddressed without strong pre/post or placebo.
- Recommendation: SKIP

### Summary
This is a strong batch with Idea 1 standing out as genuinely top-journal caliber due to its clean identification, novelty, and editorial sweet spots (trade-offs, placebos, scale). Pursue Idea 1 immediately as the clear leader; Idea 2 warrants a pilot for power checks, but Idea 3 lacks excitement and faces fatal ID threats. Overall quality tilts promising but typical of proposals—only one breaks 70.

