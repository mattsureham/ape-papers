# Research Idea Ranking

**Generated:** 2026-03-04T13:40:41.313818
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Naming Work? Mandatory Food Hygiene... | PURSUE (74) | — | — |
| The Fiscal Externalities of Poverty: Cou... | PURSUE (68) | — | — |
| Planning Deregulation and the Office-to-... | CONSIDER (62) | — | — |
| The Great Revaluation: Business Rates Sh... | SKIP (57) | — | — |
| Idea 1: Does Naming Work? Mandatory Food... | — | PURSUE (82) | PURSUE (75) |
| Idea 3: The Fiscal Externalities of Pove... | — | CONSIDER (65) | CONSIDER (62) |
| Idea 4: Planning Deregulation and the Of... | — | SKIP (45) | SKIP (55) |
| Idea 2: The Great Revaluation: Business ... | — | SKIP (25) | PURSUE (70) |

---

## GPT-5.2

**Tokens:** 6597

### Rankings

**#1: Does Naming Work? Mandatory Food Hygiene Rating Display and Restaurant Market Discipline**
- **Score: 74/100**
- **Strengths:** Clean, policy-relevant information disclosure shock with two implementation cohorts (Wales 2013, NI 2016) and a large, transparent administrative outcome (FSA universe) that lets you show a full “distributional” response (cleanup at the bottom vs. mean shifts). Border and non-food placebos make it easy to build an “opponent-killer” diagnostic battery.
- **Concerns:** The key economic outcomes you propose (entry/exit) are *not* well-measured by Companies House for this sector (many restaurants are sole proprietors), risking attenuation/selection that could dominate the headline results. Also, “restaurant grades” are a classic topic (e.g., NYC/LA grading), so you must clearly articulate what the UK mandatory-display setting uniquely identifies beyond the existing disclosure literature.
- **Novelty Assessment:** **Medium.** “Hygiene/grades disclosure → demand/quality” is heavily studied in the US, but **mandatory display with modern DiD + UK-wide universe administrative data** is much less studied and plausibly novel in economics.
- **Top-Journal Potential: Medium-High.** Could be AEJ:EP / top field if framed as a boundary test: when does disclosure *reallocate market share/exit* vs. just shift reported quality? To get top-5 interest, you likely need a sharper welfare/channel chain (e.g., disclosure → reallocation/quality upgrading → health externalities or local amenities) rather than just firm dynamics.
- **Identification Concerns:** Country differences and contemporaneous devolved policies are the core threat; you’ll want (i) stacked event studies by cohort, (ii) border-only comparisons, and (iii) strong pre-trend evidence on *FSA-measured outcomes* (ratings distribution) rather than relying on Companies House.
- **Recommendation:** **PURSUE (conditional on: validating entry/exit measurement—ideally using FSA “new/closed” establishment flags or local inspection histories rather than Companies House alone; delivering a tight mechanism chain with “bite” checks such as compliance/display evidence and consumer salience proxies).**

---

**#2: The Fiscal Externalities of Poverty: Council Tax Support Cuts and Neighborhood Spillovers**
- **Score: 68/100**
- **Strengths:** Big policy with rich cross-sectional variation (326 LAs; intensity 0–40%) and a compelling, potentially belief-changing framing (“savings” offset by crime, arrears enforcement, neighborhood decline). The pensioner protection creates a natural placebo/exposure dimension for triple-diff.
- **Concerns:** Scheme generosity is highly endogenous (fiscal stress, local politics, deprivation trends), so a straight intensity DiD risks “cuts are a symptom” rather than a cause. Crime and property values are also heavily confounded by 2014–2021 national shocks (austerity policing, COVID-era crime changes), so results can look fragile unless the design isolates pre-2020 dynamics convincingly.
- **Novelty Assessment:** **Medium-High.** The core reform is known and has policy reports and some empirical work, but **neighborhood spillovers and fiscal externalities** are much less saturated in the published econ literature.
- **Top-Journal Potential: Medium.** Stronger than a typical “local tax benefit cut → employment” paper if you can show an offsetting-cost mechanism (e.g., higher arrears/enforcement + crime + capitalization) and translate it into a net fiscal/welfare counterfactual. Without a clean instrument or quasi-random driver of scheme severity, it risks being judged “important but diffuse.”
- **Identification Concerns:** Policy endogeneity is first-order; you likely need an IV or quasi-exogenous shifter (e.g., pre-policy CTS claimant composition interacted with the centrally-imposed funding cut formula; or tight controls for contemporaneous grant cuts and local austerity intensity), plus very transparent event-study diagnostics excluding/postponing the COVID period.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you can secure a plausibly exogenous instrument for scheme severity and pre-specify a pre-2020 primary window with robust pre-trend performance).**

---

**#3: Planning Deregulation and the Office-to-Residential Conversion Shock**
- **Score: 62/100**
- **Strengths:** First-order housing/planning policy with a clear economic mechanism (planning deregulation → office stock → agglomeration/productivity/firm survival) and the kind of topic top journals like *if* the design is sharp. The Article 4 carve-outs offer an intuitive comparison and allow multiple internal replications (different exemption timings/renewals).
- **Concerns:** Article 4 exemptions are non-random and concentrated in exceptional places (central London, high-price/dense business districts), making vanilla DiD comparisons hard to defend. Measuring the commercial-side “office hollowing out” credibly is also nontrivial: Companies House addresses are imperfect proxies for operational location and sector exposure; and you need reliable conversion/intensity measurement (not just “policy on/off”).
- **Novelty Assessment:** **Medium.** PDR has been studied (especially on housing quantity/quality), but the **commercial/agglomeration side** is less developed—still, not a blank slate.
- **Top-Journal Potential: Medium.** Could become high if you can credibly show an “office death spiral” mechanism that changes how we think about deregulation trade-offs (housing supply vs. productivity). As currently sketched, it risks being viewed as selection-driven and measurement-limited.
- **Identification Concerns:** The main threat is exemption selection and differential trends in London vs. elsewhere; a more credible route is a **border/discontinuity design** around exempt vs. non-exempt boundaries (or an intensity design tightly tied to pre-policy office micro-geography) combined with direct measures of conversions/office stock changes.
- **Recommendation:** **CONSIDER (conditional on: a defensible design beyond treated-vs-exempt DiD—ideally border-based or using renewal timing; and obtaining a strong first-stage measure of office-to-resi conversion intensity at fine geography).**

---

**#4: The Great Revaluation: Business Rates Shocks and Commercial Vitality in England**
- **Score: 57/100**
- **Strengths:** Big, salient tax shock with excellent administrative tax-base data (VOA lists) and obvious policy relevance. The SBRR placebo idea is conceptually strong and could be an “opponent-killer” if exposure can be measured cleanly.
- **Concerns:** The intensity of the revaluation is mechanically tied to *pre-existing* commercial rent/price growth (especially London), making parallel trends and exogeneity very hard to defend—exactly the setting where event studies often “discover” pre-trends. Also, the revaluation was anticipated and phased in via transitional relief, so the effective tax shock timing/size at the firm level is blurred unless you can reconstruct bills or relief schedules credibly.
- **Novelty Assessment:** **Medium.** Surprisingly under-published as a causal paper, but the broader “property taxes/business taxes and local activity” space is crowded, and intensity designs tied to local price growth are well-known to be fragile.
- **Top-Journal Potential: Low-Medium.** Without a sharper quasi-random driver of tax changes (beyond “places with booming rents got bigger hikes”), this reads like a competent reduced-form exercise that top journals often discount as confounded—even if the estimates are precise.
- **Identification Concerns:** Treatment intensity is endogenous to local economic trajectories; SBRR placebo is only convincing if you can classify firms/properties by relief eligibility using pre-policy RV and link that to outcomes (hard with Companies House alone). Anticipation (announcement years) and transitional relief complicate interpretation of “post-2017.”
- **Recommendation:** **SKIP (unless you can: link VOA assessments to actual liability/bills or relief eligibility at property level; and develop an identification strategy less mechanically correlated with local growth—e.g., discontinuities around relief thresholds or administrative reassessment rules that generate quasi-random reassignment).**

---

### Summary

This is a strong batch in terms of administrative data ambition and policy relevance, but only **Idea 1** currently combines (i) a fairly defensible quasi-experiment, (ii) large-universe outcomes, and (iii) a clean “market discipline from disclosure” mechanism. I’d start with **Idea 1** while simultaneously stress-testing feasibility for **Idea 3** (needs a sharper design) and **Idea 4** (needs a non-endogenous source of tax shock variation).

---

## Gemini 3.1 Pro

**Tokens:** 10506

Here is my evaluation of the research proposals, ranked from most to least promising, applying the editorial patterns and criteria provided.

### Rankings

**#1: Idea 1: Does Naming Work? Mandatory Food Hygiene Rating Display and Restaurant Market Discipline**
- **Score**: 82/100
- **Strengths**: Exceptionally clean identification with multiple built-in placebos (non-food, B2B) and a border design. It leverages universe-level administrative data to test a fundamental mechanism (extensive margin market discipline) of a classic policy.
- **Concerns**: The core concept of hygiene disclosure is well-trodden, so the paper risks being seen as a mere replication unless the market structure/firm survival mechanism is front-and-center.
- **Novelty Assessment**: Moderate-High. While hygiene disclosure is a classic topic (e.g., Jin & Leslie 2003), using universe-level firm dynamics to decompose the extensive (exit/entry) vs. intensive (cleaning up) margins at a national scale is a novel twist that elevates the literature.
- **Top-Journal Potential**: Medium-High. To avoid the "competent but not exciting" trap, the paper must frame the contribution around information economics and market structure, rather than just "does the policy work." The use of "universe admin data paired with precise bounds" and a multi-margin design fits top-journal editorial preferences perfectly.
- **Identification Concerns**: Very minor. The combination of a staggered rollout, a border design, and a triple-diff (food vs. non-food) provides a formidable defense against regional macro-confounding.
- **Recommendation**: PURSUE

**#2: Idea 3: The Fiscal Externalities of Poverty: Council Tax Support Cuts and Neighborhood Spillovers**
- **Score**: 65/100
- **Strengths**: Brilliant "trade-off discovery" framing that perfectly aligns with editorial preferences for showing how a policy lever has hidden substitution effects. It addresses a first-order policy question with clear welfare implications.
- **Concerns**: Local authorities designed their own schemes, meaning the treatment intensity is highly endogenous to local fiscal health and political preferences.
- **Novelty Assessment**: High. While welfare cuts are widely studied, the specific angle of "fiscal externalities" (welfare cuts causing offsetting local state costs like crime and debt collection) is a fresh and highly relevant framing.
- **Top-Journal Potential**: Medium. The narrative arc is exactly what top journals want—uncovering an offset that changes the interpretation of a familiar policy lever. However, it will only survive peer review if the endogeneity of LA scheme design is convincingly addressed.
- **Identification Concerns**: Severe selection bias. LAs that implemented harsh cuts likely had worse pre-existing fiscal trajectories or different political trends. A naive continuous DiD will fail; this requires an instrumental variable (e.g., pre-shock political control or a simulated instrument).
- **Recommendation**: CONSIDER (conditional on: developing a robust identification strategy for endogenous LA scheme adoption, such as a simulated instrument or political IV)

**#3: Idea 4: Planning Deregulation and the Office-to-Residential Conversion Shock**
- **Score**: 45/100
- **Strengths**: Addresses a highly topical issue (commercial vs. residential land use) with an interesting "office death spiral" agglomeration mechanism.
- **Concerns**: The control group (Article 4 LAs) is explicitly composed of areas with the highest pre-existing office demand, making parallel trends highly unlikely.
- **Novelty Assessment**: Medium-High. The commercial hollowing-out effect of residential deregulation is an understudied and interesting angle compared to standard housing supply papers.
- **Top-Journal Potential**: Low. While the mechanism is interesting, the paper would likely lose because the skeptic's best counterstory (that Article 4 areas are just fundamentally different prime real estate markets) cannot be easily defeated with the proposed DiD.
- **Identification Concerns**: Fatal selection bias in the proposed DiD. Article 4 exemptions were granted specifically to areas where office-to-residential conversion would be most disruptive (e.g., Central London). A standard DiD will just capture the divergent trends of prime vs. non-prime office markets.
- **Recommendation**: SKIP (unless a strict boundary-discontinuity design across Article 4 borders can be proven to have balanced pre-treatment covariates)

**#4: Idea 2: The Great Revaluation: Business Rates Shocks and Commercial Vitality in England**
- **Score**: 25/100
- **Strengths**: Uses a massive, highly salient policy shock with excellent universe-level data coverage.
- **Concerns**: The treatment variable is mechanically driven by the area's economic growth over the preceding 7 years, creating a fatal endogeneity problem.
- **Novelty Assessment**: Medium. Business rates are understudied relative to their size, but the question of property tax incidence is standard.
- **Top-Journal Potential**: Low. This paper would suffer a fatal flaw rejection. As noted in the editorial patterns, papers lose when "identification breaks in the paper's own diagnostics"—here, the treatment guarantees failed pre-trends.
- **Identification Concerns**: Fatal endogeneity. The 2017 revaluation updates tax liabilities based on property value growth since 2010. Areas with tax hikes are areas that boomed; areas with tax cuts declined. Any post-2017 DiD will be hopelessly confounded by mean reversion or the continuation of these divergent economic trends.
- **Recommendation**: SKIP

### Summary

This batch contains one highly promising empirical design (Idea 1) and one conceptually brilliant framing that needs methodological work (Idea 3). I strongly recommend pursuing Idea 1 immediately due to its bulletproof identification and feasibility, while Idea 3 should be kept in the pipeline if a valid instrument for local authority scheme adoption can be found. Ideas 2 and 4 suffer from severe selection and endogeneity flaws that make them unviable in their current forms.

---

## Grok 4.1 Fast

**Tokens:** 5846

### Rankings

**#1: Idea 1: Does Naming Work? Mandatory Food Hygiene Rating Display and Restaurant Market Discipline**
- **Score**: 75/100
- **Strengths**: Exceptionally clean staggered DiD with never-treated controls, triple differences, border robustness, and multiple placebos (non-food businesses), paired with universe-scale admin data and a long pre/post horizon; tests a core information economics question across multiple margins (exit/entry/quality spillovers) with high policy stakes for disclosure regimes.
- **Concerns**: Multi-margin outcomes risk diluting the core story unless a tight causal chain emerges; property value spillovers may be underpowered if low-rated establishments are sparse.
- **Novelty Assessment**: Highly novel—no top-journal causal studies using modern DiD on this exact UK policy, despite US analogs (e.g., NYC restaurant grades); existing work is descriptive FSA reports or non-econ journals.
- **Top-Journal Potential**: High. Fits editorial winners: legible causal channel (disclosure → market discipline → quality/structure) with universe data scale, substitution testing (entry/exit/upgrade), and potential trade-off discovery (e.g., if disclosure deters low-quality entry but slows overall dynamism); could pivot field views on disclosure efficacy beyond health outcomes.
- **Identification Concerns**: Staggered cohorts risk recentering bias, though two-cohort structure and long pre-trends (5+ years) mitigate; triple-diff and placebos strongly address spillovers or LA confounders.
- **Recommendation**: PURSUE (conditional on: prioritizing core exit/quality margins over spillovers; running Callaway-Sant'Anna atten for staggered robustness)

**#2: Idea 2: The Great Revaluation: Business Rates Shocks and Commercial Vitality in England**
- **Score**: 70/100
- **Strengths**: Massive tax shock with continuous LA-level intensity variation, powerful small-business placebo (zero rates unaffected), event-study diagnostics, and universe Companies House data testing real activity vs. capitalization—a classic unresolved incidence question.
- **Concerns**: All-England treatment lacks never-treated controls, relying fully on intensity and placebo; transitional relief phase-in could muddy short-run effects despite long horizon.
- **Novelty Assessment**: Novel for causal DiD—no rigorous econ papers, only IFS descriptives; property tax-firm dynamics studied elsewhere (e.g., US), but this scale/setting unique.
- **Top-Journal Potential**: High. Aligns with "first-order stakes + channel" (tax shock → vitality or cap?) and scale as content (5M firms); powerful placebo kills capitalization counterstory, with potential for welfare counterfactuals on tax design.
- **Identification Concerns**: Intensity correlated with regional growth (e.g., London upticks), though pre-trends/event studies and quartile cohorts help; relief phase-in requires careful stacking.
- **Recommendation**: PURSUE (conditional on: stacking relief phases in event study; quantifying MDE for nulls on employment)

**#3: Idea 3: The Fiscal Externalities of Poverty: Council Tax Support Cuts and Neighborhood Spillovers**
- **Score**: 62/100
- **Strengths**: Novel spillover framing with continuous intensity (min payment %) across 326 LAs, triple-diff by claimant exposure, and placebos (pensioners); links to fiscal externalities with multiple outcomes (crime/values/fiscal stress).
- **Concerns**: Data for treatment intensity (scheme details) requires manual scraping/processing, risking errors; broad outcomes (crime/property/fiscal) may read as diffuse without a tight mechanism.
- **Novelty Assessment**: Moderately novel—IFS covered claimant effects, but spillovers unstudied in econ; fiscal externality angle fresh, though poverty policy spillovers have US parallels (e.g., EITC neighborhood effects).
- **Top-Journal Potential**: Medium. "Fiscal externalities" could excite if trade-offs emerge (savings offset by crime?), but risks "broad rollout → many outcomes" discount without single causal chain; lacks universe-scale bite.
- **Identification Concerns**: Intensity endogenous to LA poverty/politics, though triple-diff and never-treated LAs (full support) address; claimant share pre-trends critical for exposure.
- **Recommendation**: CONSIDER (if treatment data cleanly constructed; focus on one spillover like crime)

**#4: Idea 4: Planning Deregulation and the Office-to-Residential Conversion Shock**
- **Score**: 55/100
- **Strengths**: Timely "office death spiral" question with triple-diff/Bartik intensity on office stock; built-in placebos (non-office sectors) and policy relevance for housing vs. agglomeration trade-offs.
- **Concerns**: Only ~28 control LAs are highly selected (dense/London), threatening parallels despite matching/border fixes; data on exemptions/timing incomplete, and commercial outcomes secondary to prior housing descriptives.
- **Novelty Assessment**: Somewhat novel—housing quality studied descriptively (MHCLG), commercial/agglomeration side open, but planning deregulation has growing lit (e.g., UK zoning papers).
- **Top-Journal Potential**: Low-Medium. Agglomeration framing intriguing as boundary test, but selection flaws and non-universe N risk "competent but not exciting"; lacks opponent-killer for LA differences.
- **Identification Concerns**: Exempt LAs non-random (high-value/dense), violating parallels even with triple-diff; staggered expirations add complexity without clean cohorts.
- **Recommendation**: SKIP (unless border RDD viable with granular office data; too many ID fixes needed)

### Summary
This is a strong batch overall, with two genuinely promising ideas leveraging UK admin data for clean policy shocks—far better than typical proposals lacking scale or novelty. Prioritize Idea 1 for its pristine identification and info-econ punch, followed closely by Idea 2 for tax incidence stakes; skip Idea 4 due to endemic selection issues, and consider Idea 3 only after data piloting.

