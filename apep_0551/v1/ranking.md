# Research Idea Ranking

**Generated:** 2026-03-09T09:42:37.258505
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Disaster Salience and Regulatory Acceler... | PURSUE (69) | CONSIDER (64) | PURSUE (73) |
| Do Low-Emission Zones Gentrify? Vehicle ... | PURSUE (65) | PURSUE (72) | PURSUE (66) |
| The Metro Before the Metro: Construction... | SKIP (47) | SKIP (52) | SKIP (48) |

---

## GPT-5.4 (A)

**Tokens:** 8078

### Rankings

**#1: Disaster Salience and Regulatory Acceleration: The AZF Toulouse Explosion and French Industrial Risk Enforcement**
- **Score:** 69/100
- **Strengths:** This is the most novel idea in the batch and has a compelling causal chain: a salient disaster led to regulatory expansion, which may have changed enforcement and industrial safety. The long pre-period and administrative accident universe are real assets.
- **Concerns:** The main risk is that more inspectors increased reporting rather than reduced true accidents, which could mechanically bias the headline outcome. Also, baseline Seveso density is only a convincing treatment-intensity measure if you can document that enforcement really expanded more in those departments.
- **Novelty Assessment:** **Very high.** I know of substantial engineering/legal discussion of AZF and Seveso regulation, but essentially no prominent economics paper causally evaluating the 2003 French industrial-risk regime with ARIA-type panel data.
- **Top-Journal Potential:** **Medium.** This could make a strong AEJ: Economic Policy / JPubE-style paper. For a top-5, the paper would need to become a broader statement about salience-driven state capacity and show effects on severe accidents/fatalities rather than just recorded incidents.
- **Identification Concerns:** Continuous-treatment DiD is plausible but not clean enough on its own; industrial structure and reporting intensity are major threats. I would want severe/fatal accidents, targeted Seveso-related outcomes, and ideally direct department-level inspection/PPRT intensity data.
- **Recommendation:** **PURSUE (conditional on: showing ARIA reporting changes are not driving results; obtaining direct enforcement-intensity measures if possible; focusing on severe and policy-targeted accident outcomes)**

**#2: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities**
- **Score:** 65/100
- **Strengths:** This is highly policy-relevant and uses hard, economically legible outcomes. The staggered rollout plus boundary-based comparison is potentially strong, and the welfare tradeoff—cleaner air versus reduced car access—is important.
- **Concerns:** This is a moderately crowded topic cluster, so the paper could easily read as “another LEZ capitalization study.” Also, “gentrification” is a stronger claim than the proposed data currently support unless you add household composition or displacement measures.
- **Novelty Assessment:** **Medium.** French ZFE + DVF is new, but LEZs have already been studied in Europe on air quality, traffic, and in some cases housing outcomes. The setting is fresh; the question is not.
- **Top-Journal Potential:** **Medium.** There is a plausible top field-journal paper here, especially if you can show a surprising distributional mechanism. A pure house-price capitalization result is publishable, but not especially exciting for top-5 outlets.
- **Identification Concerns:** ZFE boundaries are not random and may line up with pre-existing neighborhood differences, municipal borders, or other policies; you need a very local difference-in-discontinuities style design. Pollution spillovers across the boundary and coarse pollution data also weaken the design unless handled carefully.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if: you can add resident-sorting/displacement outcomes; implement a tight local-boundary design; and use better pollution data than Open-Meteo)**

**#3: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion**
- **Score:** 47/100
- **Strengths:** The data are excellent and the outcome is standard, interpretable, and policy-relevant. The construction-versus-opening distinction is the most interesting part of the concept.
- **Concerns:** This is a very crowded literature, and the core identification is weak because station placement was endogenous and the project was anticipated long before the sample window. By 2020-2025, a large share of capitalization may already have happened.
- **Novelty Assessment:** **Low to medium.** Grand Paris Express is a new setting, but transit capitalization is one of the most heavily studied urban topics, and this version does not yet offer a genuinely new identification angle.
- **Top-Journal Potential:** **Low.** As written, this looks like a competent application in a famous setting, not a paper that would change how the field thinks about transit or urban investment. It would need unexpected delays, route surprises, or some quasi-random service variation to become much more interesting.
- **Identification Concerns:** Near-versus-far station comparisons are highly vulnerable to endogenous station siting and anticipation effects. “Future-opening stations” are not a convincing placebo if buyers already knew those stations were coming.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea strikes me as clearly worth pushing hard right now. I would pursue **Idea 1 first**, because it is by far the most novel and has a plausible policy-to-enforcement-to-safety narrative, though it absolutely needs reporting-bias validation. **Idea 2** is a solid backup if you can sharpen the design and add actual distributional outcomes; **Idea 3** is too crowded and too weakly identified as currently framed.

---

## Gemini 3.1 Pro

**Tokens:** 10496

Here is the evaluation and ranking of the research proposals, applying the criteria and the empirical editorial patterns provided.

### Rankings

**#1: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities**
- **Rank**: 1
- **Score**: 72/100
- **Strengths**: Combines a highly credible identification strategy (staggered boundary DiD) with universe-scale administrative data to address a first-order policy debate (climate policy inequality). The gentrification/displacement mechanism elevates this beyond a standard capitalization paper into a compelling equilibrium story.
- **Concerns**: The core relationship (air quality/LEZs and housing prices) is already well-studied in other contexts, so the paper's contribution relies entirely on successfully proving the distributional/gentrification framing.
- **Novelty Assessment**: Moderate. LEZ capitalization is not new, but using administrative transaction data to prove a gentrification/displacement channel (rather than just a WTP for air quality) is a fresh and highly relevant angle.
- **Top-Journal Potential**: Medium-High. A top-5 journal might find the pure capitalization angle too incremental, but if the paper convincingly demonstrates a "climate policy causes displacement" causal chain, it fits the "surprising mechanism" and "first-order stakes" criteria perfectly. It is a guaranteed top field journal (e.g., AEJ: Policy) paper if executed well.
- **Identification Concerns**: 1) Endogenous boundaries: LEZ boundaries often follow major ring roads (like the *Périphérique*) which act as structural divides between fundamentally different housing markets. 2) Spillovers: Banned vehicles might park or drive just outside the boundary, worsening air quality in the control group and violating SUTVA.
- **Recommendation**: PURSUE (conditional on: focusing heavily on the gentrification/displacement mechanism rather than just average price effects; verifying LEZ boundaries don't perfectly overlap with structural neighborhood divides).

**#2: Disaster Salience and Regulatory Acceleration: The AZF Toulouse Explosion and French Industrial Risk Enforcement**
- **Rank**: 2
- **Score**: 64/100
- **Strengths**: Extremely high novelty—both the AZF shock and the ARIA database are virtually untouched by economists. It addresses a major gap in the empirical regulation literature regarding industrial risk enforcement with a hard, economically legible outcome.
- **Concerns**: The proposed identification is severely flawed. A jump in recorded accidents after doubling the inspectorate is almost certainly driven by reporting bias, not a true increase in accidents.
- **Novelty Assessment**: High. This is a genuinely unstudied policy and dataset in economics. A well-executed paper here would be a first-mover in this specific institutional context.
- **Top-Journal Potential**: Medium. Top journals love novel administrative data and unstudied major policies, but they will instantly reject a paper that confuses a reporting effect with a real effect. If the author can isolate severe accidents and use plant-level data, it could be a major paper.
- **Identification Concerns**: 1) Fatal reporting bias: the 42% jump in 2003 is likely an artifact of having twice as many inspectors logging minor incidents. 2) Department-level continuous DiD (N=96) is too aggregated; high-Seveso departments are heavily industrial and likely have different secular deindustrialization trends (e.g., the China shock) than low-density departments, violating parallel trends.
- **Recommendation**: CONSIDER (conditional on: restricting the outcome to fatal/severe accidents which do not suffer from reporting bias; moving the analysis to the commune or plant level rather than the department level).

**#3: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion**
- **Rank**: 3
- **Score**: 52/100
- **Strengths**: Uses excellent, granular data (DVF) to evaluate a massive, €36 billion infrastructure project with clear staggered rollout phases.
- **Concerns**: Transit capitalization is one of the most saturated literatures in urban economics. The "construction phase" angle is just a re-branding of standard anticipation effects, confounded by construction nuisance.
- **Novelty Assessment**: Low. We already have hundreds of papers showing that housing markets price in future transit access. 
- **Top-Journal Potential**: Low. This is the textbook definition of "technically competent but not exciting." It estimates a standard ATE for a standard policy using a standard design, which the Editorial Pattern Appendix explicitly flags as a losing formula. It lacks a surprising mechanism or a resolution to an active literature confusion.
- **Identification Concerns**: 1) Confounding anticipation with nuisance: The price effect will be a net of positive anticipation and negative construction nuisance (noise, dust, traffic), making it hard to interpret. 2) Endogenous station placement: Stations are placed in areas targeted for broader urban renewal, meaning prices might rise due to concurrent neighborhood redevelopment, not just the transit line.
- **Recommendation**: SKIP.

### Summary
This batch presents a classic tradeoff between novelty and execution. Idea 2 is the strongest overall, taking a known literature (LEZs) but applying a sharp distributional lens (gentrification) with excellent data, making it the most viable candidate for immediate pursuit. Idea 1 has the highest raw novelty and could be a breakout paper, but its current empirical design suffers from fatal reporting bias and aggregation issues that must be fixed before it is viable. Idea 3 is technically sound but fundamentally unexciting, representing a saturated literature that is highly unlikely to yield high-impact publications.

---

## GPT-5.4 (B)

**Tokens:** 7899

### Rankings

**#1: Disaster Salience and Regulatory Acceleration: The AZF Toulouse Explosion and French Industrial Risk Enforcement**
- **Score:** 73/100
- **Strengths:** This is the most novel idea in the batch by a clear margin: a major national regulatory response with no obvious economics literature already occupying the space. The design also has real bite—nationwide policy, differential treatment intensity, and a long pre-period—plus a plausible causal chain from disaster salience to enforcement capacity to safety outcomes.
- **Concerns:** The biggest problem is that the main outcome may be contaminated by reporting and detection: more inspectors can mechanically generate more recorded incidents even if underlying safety improves. Seveso density also proxies for industrial structure, so differential post-2003 trends could reflect sectoral change rather than enforcement.
- **Novelty Assessment:** **High.** AZF and the 2003 law are well known in engineering/regulatory circles, but I am not aware of a substantial economics causal paper on this exact policy using ARIA.
- **Top-Journal Potential:** **Medium.** This could become a strong AEJ: Economic Policy / top field-journal paper if framed as “salient disasters reshape regulatory enforcement, but measured incident counts confound detection and true risk.” For top-5, it would need a sharper general lesson and especially convincing evidence on severe accidents rather than raw reports.
- **Identification Concerns:** The post-2003 jump in ARIA records is itself evidence that reporting changed, so raw accident counts are not credible on their own. To persuade, the paper needs less-reportable outcomes (fatal/major accidents, off-site harms), strong pre-trend evidence, and controls or heterogeneity tests by industrial composition.
- **Recommendation:** **PURSUE (conditional on: solving the reporting-bias problem with severity-based outcomes; showing robustness to industrial-composition trends; ideally obtaining more direct department-level inspection intensity data)**

**#2: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities**
- **Score:** 66/100
- **Strengths:** This is highly policy-relevant and uses a hard, economically legible outcome—transaction prices—with excellent administrative coverage. The French ZFE setting is newer than the classic German LEZ literature, and the distributional angle could make it more than just another environmental capitalization paper.
- **Concerns:** As written, it is stronger on capitalization than on “gentrification”: DVF gives prices, not displacement or household composition. The inside/outside-boundary comparison is also vulnerable because ZFE borders often line up with city-suburb boundaries and other place-based differences, not quasi-random treatment variation.
- **Novelty Assessment:** **Moderate.** LEZ/ULEZ effects and housing capitalization are both studied topics, though the French administrative-transaction setting and explicit distributional framing are less saturated.
- **Top-Journal Potential:** **Medium.** This could be a good top field-journal paper if it cleanly shows a chain like vehicle restrictions → cleaner air / changed accessibility → housing-price shifts and sorting. It is less likely to be top-5 because “environmental amenity capitalization” is already a crowded genre unless the paper delivers a genuinely new distributional fact.
- **Identification Concerns:** Boundary DiD is only persuasive if the boundary is locally comparable; in many cities that is doubtful. I would trust designs based on within-city tightening phases, sharp boundary discontinuities with segment fixed effects, or expansions of coverage more than simple citywide adoption contrasts.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if: you add direct distributional/displacement data; rely on tightening/expansion margins rather than only initial boundaries; and use better air-quality data than coarse modeled series)**

**#3: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion**
- **Score:** 48/100
- **Strengths:** The data are excellent, the project is economically important, and there is obvious public interest in who gains from the Grand Paris Express. The construction-phase vs. opening-phase distinction is the one genuinely interesting wrinkle here.
- **Concerns:** This is a very crowded literature, and the key information about future stations was revealed years before the proposed sample window. That means much of the capitalization likely predates the observed treatment, leaving the design to recover little more than residual trends around endogenous station locations.
- **Novelty Assessment:** **Low.** Grand Paris itself is new, but transit capitalization is one of the most heavily studied topics in urban economics, including anticipation effects.
- **Top-Journal Potential:** **Low.** Without an unexpected timing shock, route revision, cancellation, or some other quasi-experimental twist, this reads as a competent local application in a saturated area. Even with good execution, it is hard to see this changing how the field thinks.
- **Identification Concerns:** Station placement is endogenous, construction timing is not plausibly exogenous, and treatment began long before 2020 in expectation terms. A simple near-station vs. far-away DiD will be very hard to interpret causally.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea strikes me as clearly worth leading with. **Idea 1** is the best bet because it is genuinely under-studied and could tell a broader story about disaster salience and regulatory capacity, though it lives or dies on separating reporting from real safety changes. **Idea 2** is worth keeping alive as a second-tier project if the team can strengthen the identification and add real distributional evidence; **Idea 3** is too crowded and too anticipation-contaminated to prioritize.

