# Research Idea Ranking

**Generated:** 2026-03-05T11:53:17.697275
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Place-Based Policy Create or Reloca... | PURSUE (78) | PURSUE (84) | — |
| Does Losing Rural Revitalization Status ... | PURSUE (70) | SKIP (52) | — |
| Commune Nouvelle Mergers and Local Publi... | CONSIDER (60) | SKIP (45) | — |
| Business Tax Abolition and Firm Location... | CONSIDER (55) | CONSIDER (58) | — |
| Do Social Housing Mandates Lower Propert... | SKIP (45) | SKIP (35) | — |
| Idea 1: Does Place-Based Policy Create o... | — | — | PURSUE (82) |
| Idea 3: Does Losing Rural Revitalization... | — | — | PURSUE (70) |
| Idea 5: Business Tax Abolition and Firm ... | — | — | CONSIDER (65) |
| Idea 4: Commune Nouvelle Mergers and Loc... | — | — | CONSIDER (58) |
| Idea 2: Do Social Housing Mandates Lower... | — | — | SKIP (52) |

---

## GPT-5.2

**Tokens:** 6269

### Rankings

**#1: Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation**
- Score: 78/100
- Strengths: Rare chance to study the *removal* of place-based status at large scale with long-run, universe firm microdata and many treated neighborhoods. The “create vs relocate” displacement accounting can be framed as a mechanism/puzzle test, not just another zone ATE.
- Concerns: “Lost status” neighborhoods may be on systematically different trajectories because the redesignation is itself a re-targeting (not random removal), and spillovers across adjacent neighborhoods can blur interpretation. You’ll need a very clear first-stage (loss of funding/benefits/priority) and a spillover-aware design.
- Novelty Assessment: High—many papers on *gaining* place-based status, far fewer on *losing* it, and the QPV redesignation is an unusually large, plausibly policy-driven retargeting event.
- Top-Journal Potential: **Medium-High.** Could be AEJ:EP / JPubE very plausibly; top-5 is possible if the paper cleanly establishes displacement accounting and provides a welfare-relevant reinterpretation of place-based policy (e.g., bounded net creation vs pure reshuffling).
- Identification Concerns: Core threat is endogenous retargeting: the new grid-based poverty metric may correlate with differential pre-trends not captured by 2010–2014. Strongest version would add (i) border discontinuity / local comparisons near old ZUS boundaries, (ii) “dose” first stage via actual funding/benefit changes, and (iii) explicit spillover tests (rings/buffers).
- Recommendation: **PURSUE (conditional on: demonstrating a strong first-stage on policy resources/benefits; addressing spillovers and retargeting endogeneity with border/near-threshold designs or very tight local controls).**

---

**#2: Does Losing Rural Revitalization Status Deter Firm Creation? Evidence from France's 2017 ZRR Reclassification**
- Score: 70/100
- Strengths: Clean, policy-rule-driven reclassification with a conceptually sharp treatment (loss of tax exemptions) and long pre-periods in admin data. If you can show a strong “bite” on tax liability/eligibility and firm entry, it’s a tight shock→response story.
- Concerns: Rural firm creation is sparse—power and inference at the commune level are real risks, and measured “firm creation” may be lumpy/noisy. Also, reclassification criteria (income/density) may track underlying rural decline/recovery, so you need designs that leverage discontinuities in the formula if possible.
- Novelty Assessment: Medium-High—ZRR is much less saturated than urban zones, and “losing status” is under-studied; still, it sits in a broader enterprise-zone literature so novelty is not unlimited.
- Top-Journal Potential: **Medium.** Strong field-journal candidate if you can credibly bound effects (including meaningful nulls) and connect to a live mechanism (tax incentives vs spatial misallocation in low-density areas).
- Identification Concerns: DiD may struggle if the reclassification is effectively “predictable” from pre-trends in income/density; best upgrade is an RD/“donut RD” around eligibility cutoffs or a simulated-eligibility instrument using pre-determined components of the formula.
- Recommendation: **PURSUE (conditional on: confirming sufficient treated communes and event counts; exploring cutoff-based or near-threshold designs to strengthen exogeneity beyond DiD).**

---

**#3: Commune Nouvelle Mergers and Local Public Finance — Evidence from France's 2015 Municipal Consolidation Law**
- Score: 60/100
- Strengths: Big policy with lots of treated units and staggered timing, and outcomes (tax rates, spending, transfers) map directly into public finance questions with clear welfare stakes. Longer post windows than many recent reforms, and multiple outcomes allow a “mechanism map” (transfers → taxes/spending → property values).
- Concerns: Voluntary mergers are highly selected (politics, fiscal distress, local leadership), and propensity-score matching rarely convinces top journals on its own. Boundary/definition changes (pre/post aggregation) can create measurement artifacts that look like fiscal effects.
- Novelty Assessment: Medium—municipal mergers are a known topic internationally, but France’s voluntary, incentive-heavy design is less worked through in the econ canon (especially in English-language top outlets).
- Top-Journal Potential: **Low-Medium.** Could be a strong public economics field paper if it finds a surprising tradeoff (e.g., “bonuses buy mergers but worsen long-run fiscal discipline”), but a standard “mergers change spending” DiD is unlikely to clear a top-5 bar.
- Identification Concerns: Selection into treatment is the central threat; staggered DiD won’t fix it. Stronger designs would use quasi-exogenous incentive discontinuities (population brackets, eligibility rules, or administrative thresholds) as instruments, plus rigorous pre-trend and placebo batteries.
- Recommendation: **CONSIDER (only if you can replace matching with a threshold/IV design and clean boundary harmonization for outcomes).**

---

**#4: Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out**
- Score: 55/100
- Strengths: First-order policy stakes (large national business tax reform) and a natural “exposure” concept via local dependence on CVAE revenue. If credible, it speaks directly to tax competition, spatial allocation, and local public finance adjustment.
- Concerns: As proposed, identification is the weak link: exposure-based DiD is a shift-share style design where exposure correlates with industrial composition and local trends, and you only have a very short post period (2023–2025) with likely slow-moving location responses. The firm-level RDD at €500k turnover is probably infeasible without confidential turnover/tax microdata.
- Novelty Assessment: High (for France CVAE specifically), but the broader “business tax cuts and firm location” space is heavily populated—novelty hinges on what’s uniquely learnable from this reform.
- Top-Journal Potential: **Low-Medium.** Big-stakes reforms can place well, but top outlets will be skeptical with short panels and exposure designs unless you produce unusually compelling diagnostics/robustness and a tight causal chain (tax cut → local fiscal offset → firm relocation).
- Identification Concerns: Parallel trends for high- vs low-exposure places are unlikely without rich controls; composition-driven confounding is the default critique. Short-run post periods risk “no effect” that can’t distinguish sluggish adjustment from true nulls.
- Recommendation: **CONSIDER (conditional on: obtaining credible firm tax/turnover microdata for a sharper design, or a longer post window; otherwise this is likely to be attacked as under-identified).**

---

**#5: Do Social Housing Mandates Lower Property Values? Evidence from France's SRU Quota Increase**
- Score: 45/100
- Strengths: Policymakers care about capitalization and local opposition to social housing, and the 20%→25% change is a clear regulatory shock for a definable set of communes. Linking quotas to actual social-housing buildout (RPLS) is a natural first-stage.
- Concerns: Data feasibility is the binding constraint: DVF starting in 2014 means you miss clean pre-trends and announcement dynamics for a 2013 reform—exactly the seam that sinks many capitalization papers. Also, the idea is closer to a standard capitalization exercise with many confounds (local demand/supply shocks, enforcement heterogeneity) unless you can add a sharper design.
- Novelty Assessment: Low-Medium—while France-specific evidence may be thinner, “affordable/social housing and property values” is a saturated international literature, and SRU has already been studied on production/enforcement margins.
- Top-Journal Potential: **Low.** Without long pre-period transaction microdata and a design that convincingly isolates unexpected compliance risk, it will read as “important but empirically diffuse.”
- Identification Concerns: Missing pre-period transaction data prevents credible parallel-trends tests and makes anticipation impossible to rule out; treatment vs control communes differ structurally (urban pressure, politics, housing markets), creating baseline non-comparability.
- Recommendation: **SKIP (unless you can secure high-quality pre-2013 micro transaction data and a sharper quasi-experimental lever, e.g., close elections interacting with enforcement, or discontinuities in eligibility/penalty schedules).**

---

### Summary

This is a strong batch on French policy with unusually good administrative-data feasibility in several ideas. The clear front-runner is **Idea 1** because it pairs high novelty (status removal) with scalable data and an inherently interesting displacement/accounting question; **Idea 3** is next-best if you can secure power or exploit formula cutoffs. I would start with **Idea 1**, while simultaneously doing quick feasibility/power checks for **Idea 3** and exploring whether **Idea 4** can be redesigned around a genuine discontinuity/IV rather than matching.

---

## Gemini 3.1 Pro

**Tokens:** 8840

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in empirically observed editorial preferences at top economics journals.

### Rankings

**#1: Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation**
- **Score**: 84/100
- **Strengths**: This leverages a rare, large-scale *removal* of place-based policy to test a first-order mechanism (displacement vs. net creation). It uses "universe" administrative data with a long pre-treatment horizon, allowing for precise bounding of effects.
- **Concerns**: The redesignation was based on a new grid-based poverty metric, meaning the "lost status" neighborhoods might be on a fundamentally different economic trajectory (e.g., already gentrifying) than the "kept status" ones.
- **Novelty Assessment**: High. The literature on *gaining* enterprise zone status is completely saturated, but causal evidence on *losing* status is rare. Directly testing the displacement hypothesis flips a standard ATE paper into a novel mechanism paper.
- **Top-Journal Potential**: High. It fits the "trade-off discovery" and "boundary test" archetypes praised in top journals. By explicitly mapping the spatial substitution of firms, it provides a legible causal channel that changes how we interpret the efficiency of place-based policies.
- **Identification Concerns**: The primary threat is that neighborhoods losing ZUS status were already recovering faster than those transitioning to QPV, violating parallel trends. You must prove strict parallel trends in the 2010-2014 pre-period.
- **Recommendation**: PURSUE (conditional on: demonstrating strict parallel trends in the 2010-2014 pre-period; passing placebo tests on the new grid-based poverty threshold).

**#2: Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out**
- **Score**: 58/100
- **Strengths**: Addresses a massive, €8B first-order tax policy reform with clear welfare and local public finance implications. 
- **Concerns**: The phase-out is too recent (2023-2027), leaving an underpowered 1-2 year post-treatment window that top journals routinely reject.
- **Novelty Assessment**: High for this specific policy, though the general topic of local business taxes and firm mobility is well-trodden.
- **Top-Journal Potential**: Low (currently). The editorial appendix explicitly notes that "1-2 years post" windows routinely lose because they are underpowered or ambiguous. Furthermore, a standard DiD on firm creation reads as "competent but not exciting" without a deeper welfare or GE framework.
- **Identification Concerns**: The RDD at €500K is highly vulnerable to density manipulation (firms hiding revenue to stay under the threshold). The exposure DiD relies on shift-share designs that face severe credibility hurdles without exogenous shocks to local shares.
- **Recommendation**: CONSIDER (conditional on: waiting until 2026/2027 for sufficient post-treatment data; proving no density manipulation at the €500K threshold).

**#3: Does Losing Rural Revitalization Status Deter Firm Creation? Evidence from France's 2017 ZRR Reclassification**
- **Score**: 52/100
- **Strengths**: Uses a clean, formula-based reclassification to study the removal of rural tax incentives, reducing endogeneity concerns.
- **Concerns**: Rural communes have extremely low baseline rates of firm creation, making this highly susceptible to being an underpowered null result.
- **Novelty Assessment**: Medium. Rural enterprise zones are less studied than urban ones, but the fundamental question and approach are highly standard.
- **Top-Journal Potential**: Low. It falls squarely into the "technically competent but not exciting" bucket. It is a standard DiD with a narrow outcome, and will likely result in an underpowered null that cannot rule out plausible magnitudes.
- **Identification Concerns**: The primary threat is statistical power; with sparse firm creation events, the design will likely fail to produce the precisely bounded nulls required by top journals to make a non-result interesting.
- **Recommendation**: SKIP.

**#4: Commune Nouvelle Mergers and Local Public Finance — Evidence from France's 2015 Municipal Consolidation Law**
- **Score**: 45/100
- **Strengths**: Explores a major municipal consolidation wave with rich local public finance data to test economies of scale in local government.
- **Concerns**: The mergers were entirely voluntary and incentivized, meaning selection into treatment is driven by unobservable political alignment and fiscal desperation.
- **Novelty Assessment**: Medium. French municipal mergers are understudied in English, but the broader local government consolidation literature is established.
- **Top-Journal Potential**: Low. Top journals heavily penalize designs where the treatment is endogenous and relies merely on propensity score matching on observables. 
- **Identification Concerns**: Severe selection bias. Communes that choose to merge are fundamentally different in political willingness and fiscal trajectory than those that refuse, destroying the credibility of parallel trends.
- **Recommendation**: SKIP.

**#5: Do Social Housing Mandates Lower Property Values? Evidence from France's SRU Quota Increase**
- **Score**: 35/100
- **Strengths**: Targets a highly relevant housing policy with clear, escalating financial penalties for non-compliance.
- **Concerns**: The primary dataset for property values (DVF) only begins in 2014, a year *after* the 2013 reform, making pre-trends impossible to test for the main outcome.
- **Novelty Assessment**: Low. There are already three recent papers (Maaoui, Chapelle et al., Pedrotti) studying this exact social housing quota increase.
- **Top-Journal Potential**: Low. The topic is saturated, and the lack of pre-treatment data is a fatal flaw explicitly called out in editorial patterns ("Data window starts after announcement/implementation").
- **Identification Concerns**: Without pre-2013 DVF data, the paper cannot test for anticipation effects or parallel trends in property values, rendering any effect (or null) completely uninterpretable.
- **Recommendation**: SKIP.

### Summary

This batch contains one outstanding idea and four that suffer from fatal flaws in either data timing, statistical power, or endogeneity. **Idea 1 (ZUS to QPV Redesignation)** is the only proposal I recommend pursuing immediately; it brilliantly flips a saturated literature on its head by testing policy removal and spatial displacement, utilizing a clean shock and excellent historical data. The remaining ideas read as "competent but not exciting" at best, or fundamentally flawed at worst, and should be discarded or shelved until more data becomes available (in the case of Idea 5).

---

## Grok 4.1 Fast

**Tokens:** 6036

### Rankings

**#1: Idea 1: Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation**
- Score: 82/100
- Strengths: Exceptionally novel test of status *loss* in place-based policy using a clean natural experiment with pre-treated controls and long pre-trends; universe-scale SIRENE firm data enables precise displacement testing (gains in new QPV vs. losses in ex-ZUS), directly challenging prior lit's 2/3 displacement finding with a compelling causal chain.
- Concerns: Secondary property data requires some archival work pre-2020; ZFU tax exemptions need careful exclusion to avoid confound.
- Novelty Assessment: Highly novel—no causal studies of priority status removal exist; builds uniquely on gaining-status papers (e.g., Gobillon et al., Mayer et al.) by flipping the experiment.
- Top-Journal Potential: High (AER/QJE-level). This uncovers a substitution/offset (create vs. relocate) in a saturated place-based lit, with universe data scale, long horizons (1973+), and a policy-belief pivot (net activity?), matching winners like trade-off discoveries and opponent-killer designs (transitioner placebo).
- Identification Concerns: Parallel trends credible with 5+ pre-years and shared pre-treatment, but spatial spillovers to adjacent non-QPV areas need border placebo tests; sufficient treated units (~300) for cluster-robust inference.
- Recommendation: PURSUE (conditional on: spatial placebo for spillovers; ZFU sensitivity analysis)

**#2: Idea 3: Does Losing Rural Revitalization Status Deter Firm Creation? Evidence from France's 2017 ZRR Reclassification**
- Score: 70/100
- Strengths: Novel loss-of-status experiment in thin rural enterprise zone lit, with formulaic reclassification providing exogenous variation and solid pre-trends (2012-2016); SIRENE enables firm-level granularity.
- Concerns: Rural setting means sparse firm events, risking underpowered nulls; secondary employment data at commune level may dilute precision.
- Novelty Assessment: Very novel—no causal ZRR studies; rural EZ lit far thinner than urban (e.g., vs. Idea 1's ZUS/QPV).
- Top-Journal Potential: Medium (AEJ:EP potential). Clean loss test as a boundary for EZ lit, but firm creation outcome feels standard without strong mechanism/welfare pivot; lacks the relocation substitution punch of urban peers.
- Identification Concerns: Formula-based shift reduces endogeneity, but unobserved rural shocks (e.g., agriculture trends) could violate trends; power hinges on # of losers (needs 100s for reliability).
- Recommendation: PURSUE (conditional on: verifying 200+ losers and pre-trend diagnostics; power calculations for MDE)

**#3: Idea 5: Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out**
- Score: 65/100
- Strengths: Timely on €8B reform with no prior causal work; dual ID options (exposure DiD, firm RDD) and rich SIRENE/DGCL data for location/fiscal response.
- Concerns: Very short post-period (2023-2025) limits horizons and power; national policy forces exposure design vulnerable to shift-share critiques.
- Novelty Assessment: Highly novel—ongoing phase-out unstudied; fills gap in business tax location lit.
- Top-Journal Potential: Medium. Large stakes but reads as competent ATE on firm location without legible channel or long-run scale; short window echoes appendix losses on underpowered post-data.
- Identification Concerns: Exposure DiD faces aggregate shocks confounding shares; RDD at €500K threshold risks bunching/manipulation without density tests; anticipation from announced schedule untestable with late data start.
- Recommendation: CONSIDER (if post-2027 data emerges for longer horizon)

**#4: Idea 4: Commune Nouvelle Mergers and Local Public Finance — Evidence from France's 2015 Municipal Consolidation Law**
- Score: 58/100
- Strengths: Staggered mergers offer event-study potential on understudied French context; multiple outcomes (finances, property, firms) with available data.
- Concerns: Strong self-selection into voluntary mergers threatens parallel trends despite matching; broad outcomes risk "diffuse" framing without tight channel.
- Novelty Assessment: Moderately novel—French mergers unstudied in econ, but builds on Nordic/Japanese lit; not a first-of-kind.
- Top-Journal Potential: Low. Competent DiD/matching on mergers reads as "technical but unsurprising" per appendix (self-selection pitfalls common); lacks belief-changing pivot or substitution discovery.
- Identification Concerns: Propensity matching can't fully address fiscal incentive × politics selection; staggered DiD needs CW/CS checks for heterogenous effects.
- Recommendation: CONSIDER

**#5: Idea 2: Do Social Housing Mandates Lower Property Values? Evidence from France's SRU Quota Increase**
- Score: 52/100
- Strengths: Addresses quota capitalization gap; decent treatment contrast (~400 communes) with RPLS for construction first-stage.
- Concerns: Critical pre-2013 DVF data unavailable (starts 2014), crippling pre-trends and anticipation tests; related papers reduce novelty.
- Novelty Assessment: Low-moderate—builds on 3 papers (Maaoui, Chapelle et al., Pedrotti) on production/enforcement; price effects incremental at best.
- Top-Journal Potential: Low. Standard capitalization DiD on housing policy without novel stakes or channel; data seam echoes appendix losses (missing announcement/pre-data).
- Identification Concerns: No pre-treatment property data means untested trends and anticipation; compliance penalties may induce strategic responses beyond quota shock.
- Recommendation: SKIP

### Summary
This is a strong batch overall, with two genuinely promising ideas (1 and 3) leveraging clean loss-of-status experiments in place-based policy—rare and high-value for the field. I'd recommend pursuing Idea 1 first for its top-journal excitement and displacement test, followed by Idea 3 if power checks out; the rest are competent but hampered by data/selection issues and lack punch.

