# Research Idea Ranking

**Generated:** 2026-03-04T16:02:31.831751
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Taxing Vacancy — Council Tax Empty Homes... | PURSUE (72) | — | PURSUE (75) |
| The Hidden Costs of Devolved Austerity —... | PURSUE (68) | — | PURSUE (82) |
| Licensing Landlords — Selective Licensin... | PURSUE (57) | — | SKIP (58) |
| The Rent Squeeze — Local Housing Allowan... | SKIP (54) | — | CONSIDER (68) |
| Idea 1: The Hidden Costs of Devolved Aus... | — | PURSUE (85) | — |
| Idea 2: Taxing Vacancy — Council Tax Emp... | — | CONSIDER (68) | — |
| Idea 3: The Rent Squeeze — Local Housing... | — | SKIP (58) | — |
| Idea 4: Licensing Landlords — Selective ... | — | SKIP (52) | — |

---

## GPT-5.2

**Tokens:** 7162

### Rankings

**#1: Taxing Vacancy — Council Tax Empty Homes Premiums and Housing Supply**
- **Score:** 72/100  
- **Strengths:** Very high novelty in a first-order policy area (housing supply/under-occupancy) with a clear, legible channel: premium → vacancy/returns to holding empty property → re-occupation/sales/new supply. Multiple national “step” changes (2019–2024) create repeated opportunities for internal replication if you can credibly leverage differential exposure/adoption.  
- **Concerns:** Adoption and escalation are likely endogenous to local housing pressure/politics, so naïve staggered DiD risks selection-on-trends (places with worsening shortages both raise premiums and see vacancy fall/rents rise). Key outcomes (empty counts) are administratively measured and may respond via reclassification/avoidance rather than true occupancy changes.  
- **Novelty Assessment:** **Very high.** I’m not aware of a serious causal economics paper on England’s empty homes premium; closest analogs are other-country vacancy taxes (e.g., France), which helps framing without saturating the topic.  
- **Top-Journal Potential:** **Medium.** Could hit **AEJ:EP / JPubE** strongly if you show a tight causal chain (premium → vacancy duration/transactions → supply) and quantify welfare/fiscal implications; top-5 is plausible only if you deliver a belief-changing mechanism (e.g., “mostly reclassification,” or “large supply response at low efficiency cost”) with very strong diagnostics.  
- **Identification Concerns:** Biggest threats are (i) endogenous adoption/tiering and (ii) heterogeneous local shocks (housing demand, second-home demand, tourism/Airbnb, COVID-era moves) correlated with premium decisions. You’ll likely need an “exposure” design (pre-period long-term empties share × national tier changes), or very convincing pre-trend/negative-control evidence, not just CS-DiD on adopter vs later-adopter.  
- **Recommendation:** **PURSUE (conditional on: a design that directly addresses endogenous adoption—e.g., exposure-to-national-tier-changes or tight political/institutional instruments; validation that “empty” measurement isn’t mechanically reclassified in treated LAs).**

---

**#2: The Hidden Costs of Devolved Austerity — Council Tax Support Localization and Household Distress**
- **Score:** 68/100  
- **Strengths:** Compelling policy setting with large affected population and unusually sharp institutional features (national pre-period + pensioner protection) that can support strong diagnostics and at least one credible placebo. The administrative outcomes on council tax collection/arrears are tightly linked to the policy margin (liability for low-income working-age households).  
- **Concerns:** The core treatment (how much each LA cut generosity) is a choice that likely loads on broader austerity severity, local politics, and underlying economic distress—exactly the same forces that move crime and even housing prices. The “multi-outcome welfare” pitch can read diffuse unless you commit to a tight primary estimand and a causal chain.  
- **Novelty Assessment:** **High (but not pristine).** There are IFS and policy analyses; I don’t recall a widely-cited, modern-design journal paper that cleanly nails this reform, but it’s also not “untouched” the way Idea 2 is.  
- **Top-Journal Potential:** **Medium-Low.** Strong potential for **AEJ:EP / EJ / JPubE** if you (i) lead with arrears/collections as the main outcome and (ii) use pensioner protections + additional negative controls to convincingly separate CTS from general austerity. Top-5 odds fall if the paper becomes “austerity correlates with bad things.”  
- **Identification Concerns:** “Parallel trends by construction” is overstated: entitlements were uniform pre-2013, but outcomes (arrears, crime, prices) were not, and *scheme choice* post-2013 is plausibly correlated with differential trends. The pensioner placebo is powerful for outcomes observed separately by age (liability/arrears), but much weaker for crime and house prices where you can’t isolate treated households.  
- **Recommendation:** **PURSUE (conditional on: prioritizing outcomes tightly linked to CTS first-stage; building an explicit strategy for confounding by broader LA austerity—e.g., controls/stacked reforms, negative-control revenues, or designs exploiting statutory constraints/minimum-payment discontinuities if available).**

---

**#3: Licensing Landlords — Selective Licensing and Housing Market Outcomes**
- **Score:** 57/100  
- **Strengths:** Policy-relevant and scalable, with a plausible mechanism (licensing raises compliance/quality costs → rent/exit/quality changes). If you can get micro-geographic treatment boundaries, this could become a strong spatial quasi-experiment (treated wards vs adjacent wards).  
- **Concerns:** As written (LA-level staggered DiD), identification is weak because licensing is targeted to problem neighborhoods and often covers small areas—LA averages will dilute first stages and amplify selection bias. Treatment measurement is nontrivial (timing, coverage, renewals, enforcement intensity), and “adoption” is not the same as bite.  
- **Novelty Assessment:** **Medium.** Selective licensing has some existing evaluation work (at least in health, and some housing policy commentary). A national housing-market evaluation would be new-ish, but the policy is not a blank slate.  
- **Top-Journal Potential:** **Low-Medium (as proposed); Medium if redesigned.** A top field journal could be interested if you deliver a clean boundary design plus a mechanism chain (licensing → landlord composition/quality proxies → rents/tenant outcomes). Without micro treatment definition and a strong first-stage, it risks “competent DiD on endogenous rollout.”  
- **Identification Concerns:** Endogenous targeting (areas chosen because of rising crime/anti-social behavior/poor conditions), time-varying local shocks, and treatment heterogeneity by geography/enforcement. Owner-occupier placebo helps only if you can measure outcomes at a granularity where treated vs untreated stock is meaningfully separable.  
- **Recommendation:** **CONSIDER (upgrade to PURSUE only if: you can assemble ward/property-level licensing polygons over time and show strong first-stage on affected segments; otherwise skip LA-level design).**

---

**#4: The Rent Squeeze — Local Housing Allowance Freezes and Tenant Welfare**
- **Score:** 54/100  
- **Strengths:** Extremely policy-relevant with clear stakes; the freeze/reset/refreeze sequence is attractive on paper as an “internal replication” narrative. If executed cleanly, it could speak directly to current LHA uprating debates.  
- **Concerns:** Identification is fundamentally hard because the treatment intensity is driven by local rent growth—i.e., local demand shocks that also directly affect homelessness and evictions—so “dose-response DiD” risks being demand-shock DiD. The 2020 reset coincides with major COVID confounds (eviction moratoria, emergency housing policies, mobility shifts), contaminating the cleanest reversal test.  
- **Novelty Assessment:** **Medium-Low.** While this exact freeze episode may be less studied than earlier UK HB/LHA reforms, the broader literature on housing allowances, rent pass-through, and benefit caps is sizable; referees may view it as part of a well-trodden family unless the design is exceptionally sharp.  
- **Top-Journal Potential:** **Low-Medium.** The question is important, but top outlets will be skeptical that you can separate LHA generosity from coincident local rent shocks and COVID policy bundles; without a very strong design twist (e.g., quasi-random BRMA boundary comparisons, or instruments for rent growth), it likely lands as “important but empirically muddy.”  
- **Identification Concerns:** Endogeneity of rent growth; concurrent UK welfare reforms (benefit cap, UC rollout, local homelessness duties) and COVID-era court/homelessness interventions; and geographic mismatch (BRMA treatment vs LA outcomes) creating measurement error and attenuation.  
- **Recommendation:** **SKIP (unless you can: build a boundary-based design around BRMA discontinuities or a credible instrument for differential rent growth that is orthogonal to homelessness/evictions, and credibly isolate/omit the COVID period without losing the core identifying variation).**

---

### Summary

This is a strong batch on policy relevance and data availability, but only Ideas **2** and **1** look like realistic “publishable causal policy” projects under tight execution. I would start with **Empty Homes Premiums (Idea 2)** for its combination of novelty + clear mechanism, while simultaneously scoping **CTS localization (Idea 1)** with a narrower, first-stage-led outcome strategy to avoid “diffuse austerity” critiques.

---

## Gemini 3.1 Pro

**Tokens:** 9311

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in the empirical realities of top-journal editorial preferences rather than theoretical ideals.

### Rankings

**#1: Idea 1: The Hidden Costs of Devolved Austerity — Council Tax Support Localization**
- **Score**: 85/100
- **Strengths**: This proposal brilliantly combines a massive, understudied policy shock with a compelling "trade-off discovery" narrative (local fiscal savings vs. downstream social/enforcement costs). The built-in pensioner placebo is an "opponent-killer" design feature that elegantly addresses unobserved local shocks.
- **Concerns**: Local Authorities endogenously chose their cut intensity, meaning the treatment dose is likely correlated with local political economy or fiscal distress. The continuous treatment will require careful handling to ensure effects aren't driven by a few extreme LAs.
- **Novelty Assessment**: High. It is genuinely surprising that a 2013 reform affecting 2.4 million households has escaped modern causal inference evaluation in the peer-reviewed literature. 
- **Top-Journal Potential**: High. This has all the hallmarks of a top-5 or *AEJ: Policy* paper. It addresses first-order stakes, reveals a counter-intuitive mechanism (austerity shifting costs rather than eliminating them), and uses a sharp placebo group to defend the design. It perfectly fits the winning "welfare/counterfactual deliverable" archetype.
- **Identification Concerns**: The primary threat is policy endogeneity—LAs that chose harsher cuts might have been experiencing worse parallel economic trends. The pensioner placebo is crucial here, but you must rigorously prove that pensioners and working-age populations follow parallel trends in the pre-period.
- **Recommendation**: PURSUE

**#2: Idea 2: Taxing Vacancy — Council Tax Empty Homes Premiums**
- **Score**: 68/100
- **Strengths**: Addresses a highly salient policy debate (housing shortages) with a clear, staggered policy rollout. The potential to distinguish between actual housing supply increases and mere tax reclassification offers a nice mechanism decomposition.
- **Concerns**: The primary outcome (empty homes) is derived from the very tax base being manipulated, creating massive incentives for evasion/reclassification (Goodhart's Law in action). 
- **Novelty Assessment**: Moderate to High. While vacancy taxes have been studied elsewhere (e.g., France), the UK context with its escalating tiers is unstudied causally.
- **Top-Journal Potential**: Medium. To elevate this beyond a standard field journal, the paper must convincingly separate real housing supply effects from administrative reclassification. If it just shows "taxing empty homes reduces registered empty homes," referees will dismiss it as a mechanical reporting effect.
- **Identification Concerns**: LAs adopt premiums endogenously, likely in response to local housing crises or budget shortfalls. Furthermore, staggered DiD with continuous/escalating treatments is econometrically complex and highly prone to negative weighting issues.
- **Recommendation**: CONSIDER (conditional on: proving the ability to measure actual housing supply/occupancy independent of the tax registry data)

**#3: Idea 3: The Rent Squeeze — Local Housing Allowance Freezes**
- **Score**: 58/100
- **Strengths**: Focuses on a highly relevant welfare policy with a direct link to severe outcomes like homelessness. The "double shock" (freeze-relief-refreeze) initially looks like a clever storytelling device for internal replication.
- **Concerns**: The 2020 "relief" period perfectly coincides with the COVID-19 pandemic, eviction bans, and the "Everyone In" homelessness policy, fatally confounding the internal replication.
- **Novelty Assessment**: Moderate. The policy is heavily discussed in UK think-tank circles, though lacking a formal DiD evaluation in the peer-reviewed literature.
- **Top-Journal Potential**: Low. This proposal falls directly into the "results collapse when excluding COVID period" trap noted in the editorial appendix. Without the 2020 relief period, it is a standard dose-response DiD where the "dose" is just local rent inflation, which is not a clean shock.
- **Identification Concerns**: Treatment intensity is mechanically driven by local market rent growth. Areas with fast-growing rents (high treatment) are on fundamentally different economic trajectories than stagnant areas (low treatment), severely threatening the parallel trends assumption.
- **Recommendation**: SKIP (or pivot to a purely pre-COVID 2016-2019 analysis, though this significantly weakens the narrative and statistical power)

**#4: Idea 4: Licensing Landlords — Selective Licensing**
- **Score**: 52/100
- **Strengths**: Uses a built-in placebo (owner-occupied properties) to control for neighborhood-level shocks, which is a smart way to isolate the rental market.
- **Concerns**: This is a classic "competent but not exciting" setup. The data collection for treatment timing sounds tedious, and the expected findings are highly predictable.
- **Novelty Assessment**: Low to Moderate. Selective licensing has been studied for health outcomes, and while the housing market impacts are unstudied nationally, they do not promise a paradigm-shifting discovery.
- **Top-Journal Potential**: Low. This reads as a standard staggered DiD with an unsurprising sign (licensing increases rents and pushes out marginal landlords). It lacks the "first-order stakes" or "trade-off discovery" needed to excite top-tier editors.
- **Identification Concerns**: Extreme selection bias in treatment assignment. By law, LAs can only implement selective licensing in areas suffering from low housing demand, poor property conditions, or high anti-social behavior. Treated areas are fundamentally incomparable to never-treated areas, making the never-treated control group highly suspect.
- **Recommendation**: SKIP

### Summary

This batch contains one outstanding proposal (**Idea 1**) that perfectly aligns with what top journals are currently publishing: a large-scale, unstudied shock with a clean placebo and a compelling welfare trade-off. I strongly recommend putting your institute's resources behind it. **Idea 2** is a viable backup if the researchers can prove they have data to distinguish real housing supply from tax evasion. Ideas 3 and 4 suffer from fatal identification flaws (COVID confounding and extreme selection bias, respectively) and read as standard, unexciting evaluations; they should be discarded.

---

## Grok 4.1 Fast

**Tokens:** 6261

### Rankings

**#1: The Hidden Costs of Devolved Austerity — Council Tax Support Localization and Household Distress**
- **Score**: 82/100
- **Strengths**: Exceptional identification via near-exogenous continuous treatment variation (pre-reform national uniformity ensures parallel trends) and built-in pensioner placebo, paired with a compelling multi-outcome welfare narrative (fiscal savings vs. household distress, crime, and property effects) over 11 post years. High novelty on an understudied reform with first-order stakes affecting 2.4M households, using universe admin data for scale.
- **Concerns**: Multi-outcome kitchen sink risks diluting the core story unless tightly linked via mechanisms; property price effects might be confounded by broader housing trends post-2013.
- **Novelty Assessment**: Highly novel—no peer-reviewed causal economics papers; closest is outdated IFS descriptive work without modern DiD robustness.
- **Top-Journal Potential**: High. Fits editorial winners: trade-off discovery (austerity savings offset by social costs), opponent-killer pensioner placebo, long-horizon multi-margin welfare chain (A: cuts → B: arrears/crime → C: property distress), and universe-scale data that could reframe devolution policy consensus.
- **Identification Concerns**: Minimal threats—pre-period uniformity and pensioner placebo address trends/spillovers; continuous treatment with 326 units supports reliable inference, though LA heterogeneity in unobservables could bias if correlated with outcomes.
- **Recommendation**: PURSUE (conditional on: prioritizing pensioner placebo and fiscal-social cost trade-off in framing; validating parallel trends across multiple pre-years)

**#2: Taxing Vacancy — Council Tax Empty Homes Premiums and Housing Supply**
- **Score**: 75/100
- **Strengths**: Zero prior causal work on a clean staggered policy with multiple shocks, enabling modern event-study DiD and direct comparison to French vacancy tax literature; strong potential for substitution discovery (supply increase vs. reclassification) using public LA-level data on empties and housing supply.
- **Concerns**: LA adoption timing likely endogenous to local vacancy/housing pressures, risking heterogeneous trends; short pre-periods (~3 years) limit trend tests, and recent 2024 changes may introduce underpowered late shocks.
- **Novelty Assessment**: Extremely novel—zero academic causal evaluations; only policy descriptions exist.
- **Top-Journal Potential**: High. Could excite via niche boundary test (vacancy tax mechanism puzzle, framed against French results) with legible channel (premiums → empties → supply/prices) and policy counterfactuals, especially if uncovering offsets like reclassification.
- **Identification Concerns**: Staggered timing invites policy endogeneity and heterogeneous effects; Callaway-Sant'Anna needed but never-treated controls may be non-random (high-vacancy LAs adopt first).
- **Recommendation**: PURSUE (conditional on: robust staggered DiD diagnostics and mechanism tests for reclassification vs. true supply)

**#3: The Rent Squeeze — Local Housing Allowance Freezes and Tenant Welfare**
- **Score**: 68/100
- **Strengths**: Double-shock structure (freeze-relief-refreeze) offers internal replication for storytelling; relevant multi-outcomes (homelessness, evictions) on a live policy lever, with adequate ~150 BRMAs for dose-response variation.
- **Concerns**: Treatment intensity (rent-LHA gap) partly endogenous to local market dynamics, complicating exogeneity; eviction data at county level may mismatch BRMA geography, risking aggregation bias.
- **Novelty Assessment**: Moderately novel—no peer-reviewed causal DiD evaluations; policy reports and advocacy dominate.
- **Top-Journal Potential**: Medium. Good replication arc and welfare margins, but lacks trade-off pivot or scale; reads more as solid policy ATE than belief-changing mechanism (e.g., no clear substitution channel).
- **Identification Concerns**: Rent growth as "dose" may reflect BRMA-specific shocks (e.g., demand booms), violating exogeneity; relief placebo helps but short freeze windows limit power.
- **Recommendation**: CONSIDER

**#4: Licensing Landlords — Selective Licensing and Housing Market Outcomes**
- **Score**: 58/100
- **Strengths**: Staggered adoption with owner-occupier placebo targets quality-rent trade-off; national expansion fills gap beyond prior health-focused studies.
- **Concerns**: Treatment dates require manual collection (FOI risk), delaying feasibility; adoption highly endogenous to local problems (e.g., poor housing areas license first), threatening parallel trends.
- **Novelty Assessment**: Moderately studied—health outcomes evaluated (e.g., LSHTM 2022), but national housing markets (rents/prices) unstudied.
- **Top-Journal Potential**: Low. Competent DiD on niche regulation without first-order stakes or counterintuitive channel; prior London work makes it incremental, risking "technically sound but unsurprising" rejection.
- **Identification Concerns**: Endogenous rollout (problematic LAs adopt) biases staggered DiD; placebo helps but EPC quality data may lack granularity for clean mechanisms.
- **Recommendation**: SKIP

### Summary
This is a strong batch overall, with three ideas leveraging recent UK housing reforms for cleanish DiD designs and public data—far better than typical proposals lacking novelty or ID rigor. Prioritize Idea 1 for its top-tier identification, trade-off narrative, and journal potential; Idea 2 as a close second for purest novelty if staggered threats are contained.

