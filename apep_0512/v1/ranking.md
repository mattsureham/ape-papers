# Research Idea Ranking

**Generated:** 2026-03-05T10:02:43.099861
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Eliminating the Housing Tax Capital... | PURSUE (72) | — | — |
| Place-Based Tax Incentives and Rural Fir... | PURSUE (68) | — | — |
| The Fiscal Displacement Effect: Do Commu... | PURSUE (63) | — | — |
| Do Renovation Tax Incentives Revitalize ... | CONSIDER (58) | — | — |
| Does City-Center Revitalization Work? Ca... | SKIP (52) | — | — |
| Idea 5: The Fiscal Displacement Effect (... | — | PURSUE (85) | — |
| Idea 1: Taxe d'Habitation Capitalization | — | PURSUE (72) | — |
| Idea 4: Denormandie Renovation Tax Incen... | — | SKIP (58) | — |
| Idea 3: ZRR Reform (Rural Firm Creation) | — | CONSIDER (52) | — |
| Idea 2: Action Coeur de Ville (ACV) Revi... | — | SKIP (45) | — |
| Idea 1: Does Eliminating the Housing Tax... | — | — | PURSUE (82) |
| Idea 5: The Fiscal Displacement Effect: ... | — | — | PURSUE (72) |
| Idea 3: Place-Based Tax Incentives and R... | — | — | CONSIDER (65) |
| Idea 4: Do Renovation Tax Incentives Rev... | — | — | CONSIDER (58) |
| Idea 2: Does City-Center Revitalization ... | — | — | SKIP (52) |

---

## GPT-5.2

**Tokens:** 6854

### Rankings

**#1: Does Eliminating the Housing Tax Capitalize into Property Prices? Evidence from France's Taxe d'Habitation Reform**
- Score: **72/100**
- Strengths: Very large, salient fiscal shock with “universe” transaction data and unusually rich placebo structure (secondary residences; commercial property; phase-in). Clear welfare object (tax incidence/capitalization) with an interpretable benchmark (ΔP ≈ ΔTax/r).
- Concerns: Cross-commune tax rates are deeply correlated with amenities, local public goods, and long-run growth; continuous-intensity DiD can still load on differential trends even with FE. Anticipation is a serious risk (2017 campaign/legislation) and could shift effects into the pre-period, biasing post estimates toward zero.
- Novelty Assessment: **Medium.** Tax capitalization is heavily studied, but this specific reform at this scale with DVF microdata is plausibly new and could add credible external validity.
- Top-Journal Potential: **Medium-High.** Could hit a top field journal (AEJ:EP) and has some top-5 upside if framed as a decisive incidence test with strong “opponent-killer” placebos and an explicit capitalization bound (how much of the tax cut is captured by owners vs renters).
- Identification Concerns: Main threat is **non-parallel trends by baseline tax rate** (rates proxy for unobserved local dynamics) and **anticipation**; phase-in and property-type placebos help, but you’ll need pre-trend/event-study diagnostics that are truly flat and perhaps designs beyond a single intensity DiD (e.g., exploiting the 2018 vs 2021 phase-in by household composition).
- Recommendation: **PURSUE (conditional on: (i) explicit anticipation tests around 2017–2018; (ii) robustness to flexible commune trends / reweighting / border-pair designs; (iii) a clean mapping from statutory rate → household-level expected tax savings).**

---

**#2: Place-Based Tax Incentives and Rural Firm Creation: Evidence from France's ZRR Reform**
- Score: **68/100**
- Strengths: The reform’s **mechanical eligibility rule** (density and income thresholds) offers a path to much cleaner identification than typical place-based policies; Sirene provides near-universe firm entry measurement. Potential to speak to a live policy question: do tax exemptions create new activity or reshuffle it?
- Concerns: The proposed DiD (“gainers vs losers”) risks being less credible than the setting allows—you likely want a **threshold/RD or border discontinuity** design at the EPCI assignment frontier. Effective sample size may be the number of EPCIs near the cutoff (clustered inference), not the number of communes.
- Novelty Assessment: **Medium-High.** Enterprise/zone policies are saturated, but this particular French reform with quasi-mechanical reassignment is less worked-over than US-style zones; novelty hinges on using the reform’s threshold structure well.
- Top-Journal Potential: **Medium.** Could land well in a top field journal if you (i) deliver a tight causal design and (ii) go beyond an entry ATE to show displacement (within-EPCI vs across-border), sectoral composition, and medium-run survival/employment.
- Identification Concerns: **Sorting/manipulation** is less likely (criteria are slow-moving), but **differential trends correlated with rural decline** remain; strongest version is RD/border-based with tight bandwidths and pre-trend balance.
- Recommendation: **PURSUE (conditional on: pivot to RD/border discontinuity around EPCI eligibility thresholds; show displacement vs net creation; ensure inference is at the EPCI/threshold-running-variable level).**

---

**#3: The Fiscal Displacement Effect: Do Communes Shift Tax Burden to Property Owners After Housing Tax Elimination?**
- Score: **63/100**
- Strengths: Conceptually sharp “offset/substitution” question (does a tenant tax cut get undone by owner tax hikes?) with direct policy relevance for local public finance design. Feasible with administrative fiscal data; can be paired with house-price evidence as an incidence package.
- Concerns: “Fiscal stress” exposure (TH share) is endogenous to local preferences, housing market structure, and long-run municipal trajectories; compensation rules may mechanically break the link between exposure and pressure. Rate-setting responds to many simultaneous shocks (service costs, politics), so attributing changes to the reform is hard.
- Novelty Assessment: **Medium.** Tax shifting across local tax instruments is studied, but this specific French episode is less canonized; still, it risks reading as an unsurprising “rates went up where they relied on TH.”
- Top-Journal Potential: **Medium-Low.** More likely a solid field-journal/public finance outlet unless you can (i) isolate a quasi-mechanical component of the compensation gap and (ii) tie it to a clear incidence decomposition (how much capitalization is net of offsetting taxe foncière).
- Identification Concerns: Key threat is **endogenous exposure** (TH dependence correlates with unobservables) plus **policy simultaneity** in local budgets; a stronger design would use **predicted uncompensated loss** from statutory formulas as an instrument for pressure.
- Recommendation: **CONSIDER (upgrade to PURSUE if you can construct an exogenous “compensation shortfall” measure and validate it with first-stage budget accounting).**

---

**#4: Do Renovation Tax Incentives Revitalize Declining Housing Markets? Evidence from the Dispositif Denormandie**
- Score: **58/100**
- Strengths: Renovation incentives are policy-relevant and comparatively less evaluated with transaction microdata; the “old vs new” within-commune contrast points toward a credible triple-diff style design.
- Concerns: The biggest risk is **no observable first stage**: DVF won’t tell you whether a purchase used Denormandie or whether renovations occurred, so interpretation becomes indirect. Overlap with ACV/ORT place-based investments creates severe confounding unless you have timing of ORT signatures and/or take-up intensity.
- Novelty Assessment: **Medium-High.** Less saturated than generic enterprise zones, but prior work on housing tax incentives broadly exists; novelty depends on demonstrating actual renovation/take-up and isolating the mechanism.
- Top-Journal Potential: **Low-Medium.** Could become interesting if you can document a causal chain (incentive → renovation activity/proxy → quality/price/occupancy), but without take-up/renovation measurement it risks being “competent DiD with ambiguous mechanism.”
- Identification Concerns: **Concurrent policies** (ACV, ORT, other housing measures) and **selection into ORT**; triple-diff helps, but only if “new housing” is a valid control trend for “old housing” absent the policy.
- Recommendation: **CONSIDER (conditional on: obtaining Denormandie take-up or credible renovation proxies—e.g., tax filings/permit/energy retrofit data—and using staggered ORT adoption timing rather than a single post-2019 dummy).**

---

**#5: Does City-Center Revitalization Work? Causal Evidence from France's Action Coeur de Ville Program**
- Score: **52/100**
- Strengths: First-order policy stakes (€5B) and enough treated cities for meaningful estimation; multi-dataset linkage (DVF + Sirene + INSEE) is feasible and policy-facing.
- Concerns: Selection is explicitly on decline and the intervention bundle is diffuse (infrastructure + housing + commerce), making the estimand hard to interpret and the DiD vulnerable to **mean reversion** and **non-parallel trends** even after matching. Likely to devolve into “many outcomes, noisy effects, contested identification.”
- Novelty Assessment: **Medium-Low.** Place-based revitalization programs are extensively studied internationally; the French setting is new, but the design (matched DiD on selected cities) is not.
- Top-Journal Potential: **Low.** Without a sharper assignment mechanism or a tight causal channel, this reads like the kind of broad place-based evaluation that top outlets often view as important-but-diffuse.
- Identification Concerns: **Endogenous selection + differential pre-trends** are central; matching rarely fixes dynamic selection. A more credible angle would need quasi-exogenous funding rules, discontinuities, or project-level timing variation with strong diagnostics.
- Recommendation: **SKIP (unless you can uncover a quasi-experimental assignment/threshold or a sharply timed, measurable sub-component).**

---

### Summary

This is a strong batch in terms of data access (DVF/Sirene/REI) and policy salience, but only two ideas currently have a clear path to *high-credibility causal inference*: **(1) taxe d’habitation capitalization** and **(3) ZRR reform leveraging thresholds** (ideally via RD/border designs). I would start with **Idea 1** (big shock + universe outcomes + strong placebo battery) while simultaneously scoping whether **Idea 3** can be upgraded from DiD to a threshold-based design that would materially raise its publication ceiling.

---

## Gemini 3.1 Pro

**Tokens:** 8220

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in empirically observed editorial preferences for top economics journals.

### Rankings

**#1: Idea 5: The Fiscal Displacement Effect (Taxe d'Habitation)**
- **Score**: 85/100
- **Strengths**: This perfectly captures the "trade-off discovery" that top journals love by revealing a substitution effect that changes the interpretation of a massive, familiar policy lever (a tax cut). It links a clean, continuous shock (pre-reform TH dependence) to a concrete political economy and public finance mechanism.
- **Concerns**: The state compensation mechanism might have been too perfectly calibrated, resulting in a lack of "bite" (first stage) if communes felt no actual fiscal stress. 
- **Novelty Assessment**: High. While tax competition and fiscal federalism are old topics, empirically proving that a national tenant tax cut was stealthily converted into a local property tax hike using modern micro-data is highly novel and policy-relevant.
- **Top-Journal Potential**: High. A top-5 journal would find this exciting because it challenges the conventional wisdom of the policy's incidence. It provides a legible causal chain (Shock → lost revenue → fiscal response → incidence) rather than just a standalone ATE.
- **Identification Concerns**: The main threat is if pre-reform TH dependence is correlated with other local economic trends (e.g., declining communes relied more on TH). Controlling for baseline commune characteristics and testing pre-trends in *taxe foncière* rates will be critical.
- **Recommendation**: PURSUE (conditional on: merging with Idea 1. Showing the fiscal displacement *and* how it offsets the property price capitalization would make this an absolute blockbuster paper).

**#2: Idea 1: Taxe d'Habitation Capitalization**
- **Score**: 72/100
- **Strengths**: Leverages "universe" admin data (24M+ transactions) and features an excellent built-in placebo battery (secondary residences, commercial properties) to serve as opponent-killers. The continuous-treatment DiD design is highly credible.
- **Concerns**: Tax capitalization is a very mature literature; without a new mechanism, this risks falling into the "competent but not exciting" bucket. Furthermore, the reform was a major campaign promise in 2017, meaning anticipation effects might contaminate the late pre-period.
- **Novelty Assessment**: Medium. The setting and scale are unprecedented for France, but the theoretical question (do housing taxes capitalize into prices?) has been studied exhaustively since Oates (1969). 
- **Top-Journal Potential**: Medium. It is a guaranteed top field journal (AEJ: Policy) due to the scale and clean design, but likely misses the top-5 without a belief-changing pivot or welfare deliverable. 
- **Identification Concerns**: Anticipation effects in 2017 (Macron's election) could violate parallel trends right before implementation. The researcher must carefully map the announcement timeline against transaction dates.
- **Recommendation**: PURSUE (conditional on: combining with Idea 5 to show the net welfare effect and fiscal offset, elevating it from a standard capitalization paper to a general equilibrium public finance paper).

**#3: Idea 4: Denormandie Renovation Tax Incentives**
- **Score**: 58/100
- **Strengths**: The within-commune placebo design (comparing eligible old housing to ineligible new housing) is a highly effective storytelling device that isolates the policy from broader city-level shocks. 
- **Concerns**: The 2019 start date is a fatal flaw regarding the data window. The entire post-period is dominated by the COVID-19 pandemic, which fundamentally rewired housing demand (the "race for space" and home-office renovations).
- **Novelty Assessment**: Medium. Renovation incentives are under-evaluated compared to new-build incentives, but the core mechanics are standard.
- **Top-Journal Potential**: Low. This reads as a standard DiD with a narrow outcome. Furthermore, referees will immediately flag that the results are likely driven by COVID-19 confounds, which is a modal reason for rejection.
- **Identification Concerns**: The COVID-19 shock is perfectly collinear with the treatment rollout. Disentangling the Denormandie incentive from the pandemic-induced urban exodus to medium-sized cities will be nearly impossible.
- **Recommendation**: SKIP (unless the researcher can find a highly specific boundary-discontinuity design that perfectly neutralizes the COVID macro-shock).

**#4: Idea 3: ZRR Reform (Rural Firm Creation)**
- **Score**: 52/100
- **Strengths**: The mechanical EPCI-level criteria (density and income thresholds) provide a plausibly exogenous, quasi-random shock for communes near the cutoff.
- **Concerns**: This is the quintessential "competent but not exciting" paper: a standard DiD on a saturated topic (place-based policies) using a narrow outcome (firm creation) without a broader welfare or counterfactual deliverable.
- **Novelty Assessment**: Low. The literature on enterprise zones and place-based tax incentives is incredibly crowded (Busso et al., Briant et al., etc.). This offers a new French reform but no new economic insight.
- **Top-Journal Potential**: Low. Top journals routinely reject standard place-based policy evaluations unless they uncover a radically new mechanism or utilize a structural model to estimate spatial equilibrium welfare effects.
- **Identification Concerns**: Because treatment is assigned at the EPCI (inter-communal) level, standard errors must be clustered at this level, drastically reducing the effective N. The "nulls" might end up severely underpowered.
- **Recommendation**: CONSIDER (only if repositioned as a spatial regression discontinuity (RDD) at the EPCI borders, and only if aimed at a lower-tier field journal).

**#5: Idea 2: Action Coeur de Ville (ACV) Revitalization**
- **Score**: 45/100
- **Strengths**: Addresses a highly visible, €5 billion first-order policy question that policymakers actively want evaluated.
- **Concerns**: The identification strategy is fundamentally broken. Cities were explicitly selected *because* they were declining, making matching on pre-trends highly susceptible to Ashenfelter's dip (mean reversion). 
- **Novelty Assessment**: Low. Broad, multi-pronged urban revitalization programs are evaluated constantly, and the "broad rollout → many outcomes" framing usually gets discounted by editors unless the causal channel is incredibly tight.
- **Top-Journal Potential**: Low. The combination of endogenous selection, a "kitchen sink" policy intervention (making mechanisms impossible to isolate), and massive COVID-19 confounding makes this unpublishable in top outlets.
- **Identification Concerns**: Fatal flaws abound. Beyond the endogenous selection on negative trajectories, the 2018-2024 window means the treatment effect is entirely confounded by the post-2020 urban exodus, where households naturally fled Paris for the exact medium-sized cities targeted by ACV.
- **Recommendation**: SKIP.

### Summary

This batch features a stark divide between high-potential public finance questions and fatally confounded urban policy evaluations. Ideas 2, 3, and 4 suffer from the classic pitfalls of applied microeconomics: they are either "competent but unexciting" standard DiDs on saturated topics, or they are fatally confounded by the 2020 COVID-19 shock. I strongly recommend pursuing **Idea 5 and Idea 1 as a single, unified project**. By combining the massive scale and clean identification of the housing tax capitalization (Idea 1) with the counter-intuitive "trade-off discovery" of the fiscal displacement effect (Idea 5), the institute could produce a top-5 journal publication that fundamentally changes how economists and policymakers view the incidence of local tax eliminations.

---

## Grok 4.1 Fast

**Tokens:** 6213

### Rankings

**#1: Idea 1: Does Eliminating the Housing Tax Capitalize into Property Prices? Evidence from France's Taxe d'Habitation Reform**
- **Score**: 82/100
- **Strengths**: Universe-scale DVF data (24M transactions) with long pre/post periods enables precise tests of tax capitalization theory on a massive (€26B/year) reform; built-in placebos (secondary residences, commercial properties, phase-in) and continuous intensity provide opponent-killer diagnostics for a tight causal channel (tax cut → price appreciation).
- **Concerns**: General tax capitalization literature is voluminous, so results must reveal a counterintuitive degree/speed of capitalization or bounds to stand out; COVID housing boom (2020-2022) could confound post trends despite controls.
- **Novelty Assessment**: Tax capitalization is a saturated field (hundreds of papers since Oates 1969), but this specific reform—the largest modern French housing tax change—lacks micro-transaction evaluations, making it a fresh boundary test.
- **Top-Journal Potential**: High. Fits editorial winners: first-order stakes (who bears tenant tax incidence?), legible causal chain with universe data and long horizons, substitution test via placebos; could pivot field views on cap speed in owner-occupied markets like AER/QJE tax papers.
- **Identification Concerns**: Continuous-treatment DiD assumes parallel trends across pre-reform rates (testable with 4 pre-years), but unobserved commune heterogeneity correlated with rates could bias if not fully absorbed by FE; phase-in helps but requires modeling timing.
- **Recommendation**: PURSUE (conditional on: event-study specs ruling out anticipation/pre-trends; old vs new property controls as extra placebo)

**#2: Idea 5: The Fiscal Displacement Effect: Do Communes Shift Tax Burden to Property Owners After Housing Tax Elimination?**
- **Score**: 72/100
- **Strengths**: Complements demand-side capitalization (e.g., pairs naturally with Idea 1) by tracing supply response (TH elimination → TF rate hikes), using fiscal dependence as clean intensity; REI/DGCL data feasible for welfare incidence calculation.
- **Concerns**: Aggregate commune rates may lack power for precise incidence bounds; state compensation could mute variation, yielding underpowered null uninterpretable without MDE framing.
- **Novelty Assessment**: Fiscal displacement in tax reforms is studied (e.g., US prop 13 responses), but supply-side to France's TH elimination is untouched, offering a novel Tiebout-style offset to demand papers.
- **Top-Journal Potential**: Medium-High. Trade-off discovery (occupant relief offset by owner burden?) with policy counterfactuals could excite if chained to price effects, akin to corruption-wage violence papers; top-5 potential if scaled to full incidence but risks "competent ATE" desk rejection.
- **Identification Concerns**: Tax rate changes are endogenous policy choices, so dependence × post DiD needs commune/year FE + controls to proxy fiscal stress; unmodeled inter-commune competition or state grants could confound.
- **Recommendation**: PURSUE (conditional on: pairing with Idea 1 for joint incidence; robustness to compensation formula)

**#3: Idea 3: Place-Based Tax Incentives and Rural Firm Creation: Evidence from France's ZRR Reform**
- **Score**: 65/100
- **Strengths**: Mechanical EPCI criteria enable clean gainer/loser DiD on firm microdata (Sirene), addressing a gap in French place-based evals; ~500 switchers provide decent N.
- **Concerns**: Firm creation is a saturated, low-excitement outcome (many nulls in lit); EPCI clustering reduces effective variation, risking underpowered RI.
- **Novelty Assessment**: Place-based policies heavily studied (e.g., US EZ, French ZFU), but 2015 ZRR reform's EPCI shift lacks causal firm-level work, so incremental novelty.
- **Top-Journal Potential**: Medium. Mechanical variation is credible, but firm ATE without mechanism/welfare pivot reads as "another place-based null," per appendix losses on employment outcomes; field journal (AEJ:App Econ Pol) more likely than top-5.
- **Identification Concerns**: Within-EPCI treatment spills over (all communes treated together), biasing via GE; mechanical thresholds need density tests, and pre-trends across switchers unmentioned.
- **Recommendation**: CONSIDER

**#4: Idea 4: Do Renovation Tax Incentives Revitalize Declining Housing Markets? Evidence from the Dispositif Denormandie**
- **Score**: 58/100
- **Strengths**: Within-commune old vs new housing placebo tightens design; DVF/Sirene feasible for multi-outcomes.
- **Concerns**: Temporal/spatial overlap with ACV muddies attribution (hard to disentangle); small eligible set (~222+ ORT) limits power.
- **Novelty Assessment**: Renovation incentives underexplored vs new-build (Pinel), no causal DVF work, but overlaps prior French revitalization studies.
- **Top-Journal Potential**: Low-Medium. Diffuse outcomes without clear channel (prices/volumes/firms) risks "broad rollout → many outcomes" discount; within-old placebo helps but no belief-changing stakes.
- **Identification Concerns**: DiD confounds from ACV (same cities/time); eligibility non-random, so matching needed but pre-trends risky in declining areas.
- **Recommendation**: CONSIDER (conditional on: stacking with non-ACV ORT for cleaner variation)

**#5: Idea 2: Does City-Center Revitalization Work? Causal Evidence from France's Action Coeur de Ville Program**
- **Score**: 52/100
- **Strengths**: Multi-outcome on big (€5B) program with public data; 222 treated exceeds N threshold.
- **Concerns**: Selection on decline guarantees divergent pre-trends, undermining matching DiD; no mechanical variation, just "similar controls."
- **Novelty Assessment**: Place-based revitalization causal evals exist (e.g., US, prior French), Cour des Comptes gap noted but descriptive barometers abound.
- **Top-Journal Potential**: Low. Selection bias + diffuse outcomes (prices/firms/pop) fits "important but diffuse" losses; lacks tight channel or substitution, unlikely top-5/field excitement.
- **Identification Concerns**: Non-random selection (decline indicators) biases trends; matching/CEM unproven without binned pre-trends or internal replication.
- **Recommendation**: SKIP

### Summary
This batch is solid for a policy institute (strong French admin data, policy stakes), but only Ideas 1-2 rise above competent DiD territory via clean shocks, scale, and trade-offs—prioritize Idea 1 for its top-journal shot and universe precision. Ideas 3-4 are feasible increments on place-based themes but risk nulls on saturated margins; skip Idea 2 due to fatal selection flaws. Pursue 1 and 5 jointly for a capitalization-incidence package.

