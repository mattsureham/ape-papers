# Research Idea Ranking

**Generated:** 2026-03-04T10:10:35.459756
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Petro-Federalism and Local Economic Acti... | PURSUE (74) | — | PURSUE (70) |
| Legislating Peace? Anti-Open Grazing Law... | PURSUE (68) | — | PURSUE (72) |
| Cash and Conflict: Did Nigeria's 2023 Na... | CONSIDER (63) | — | SKIP (52) |
| Conflict Contagion: Spatial Spillovers o... | CONSIDER (59) | — | CONSIDER (62) |
| The Economic Shadow of Insecurity: Confl... | SKIP (54) | — | CONSIDER (58) |
| Idea 5: Conflict Contagion: Spatial Spil... | — | PURSUE (85) | — |
| Idea 2: Legislating Peace? Anti-Open Gra... | — | CONSIDER (68) | — |
| Idea 4: Cash and Conflict: Did Nigeria's... | — | SKIP (58) | — |
| Idea 1: Petro-Federalism and Local Econo... | — | SKIP (52) | — |
| Idea 3: The Economic Shadow of Insecurit... | — | SKIP (45) | — |

---

## GPT-5.2

**Tokens:** 6867

### Rankings

**#1: Petro-Federalism and Local Economic Activity: Oil Price Shocks and Nigeria's Revenue Sharing**
- **Score: 74/100**
- **Strengths:** Clear, policy-relevant fiscal channel with plausibly exogenous global oil-price shifts and rich monthly panel outcomes (VIIRS) that match the timing of transfer flows. The design has many units (all states) and multiple large shocks, enabling tight event-study diagnostics and heterogeneity (derivation states vs others).
- **Concerns:** “Share” (baseline FAAC/oil dependence) is likely correlated with differential trends (governance, urbanization, electrification), so shift-share credibility will hinge on strong pre-trends, alternative baselines, and leave-one-out / placebo shift tests. Nightlights can move due to electrification/fuel shortages rather than real activity, so mechanism validation is needed.
- **Novelty Assessment:** **Medium-high.** Oil shocks and Nigeria’s political economy are studied, but **this exact fiscal-transfer channel with high-frequency FAAC allocations + monthly VIIRS** is much less saturated than generic “resource curse” papers.
- **Top-Journal Potential:** **Medium.** Best shot is a top field journal (AEJ:EP/JDE) unless you can (i) cleanly separate “fiscal transfer” from “oil-production” channels and (ii) deliver a welfare-relevant mechanism chain (transfers → state spending composition/arrears → local activity).
- **Identification Concerns:** Shift-share assumptions (shares predetermined and not proxying for differential trends); potential coincident macro shocks (exchange rate crises, subsidy regimes) that differentially affect high-FAAC states.
- **Recommendation:** **PURSUE (conditional on: strong pre-trend/event-study evidence; explicit separation of derivation vs non-derivation and oil-producing vs non-producing states; at least one validated mechanism measure such as state spending, wage arrears, or procurement).**

---

**#2: Legislating Peace? Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria**
- **Score: 68/100**
- **Strengths:** First-order, life-and-death policy with ambiguous sign (deterrence vs backlash), which is exactly where credible evidence can change beliefs. Good built-in placebos (other violence types) and a natural push toward mechanism (enforcement, displacement, seasonal patterns).
- **Concerns:** Adoption is very likely endogenous to rising conflict and political pressure; with only ~14 adopters, staggered DiD at the state level is fragile and inference is tricky. “Law on the books” may not equal enforcement—nulls could be uninterpretable without a first-stage on actual grazing behavior/enforcement intensity.
- **Novelty Assessment:** **High.** There is extensive work on farmer–herder conflict, but **causal evaluation of anti-open-grazing statutes specifically** is not a heavily mined topic in economics.
- **Top-Journal Potential:** **Medium-high.** Could be AEJ:EP/QJE-level *if* you convincingly handle endogeneity and show a mechanism chain (law → enforcement/displacement → violence composition/locations).
- **Identification Concerns:** Pre-trends (conflict already rising), anticipatory effects, and contemporaneous security/political changes; small number of treated states and clustered inference.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you can: move to LGA/event-level with “pastoral suitability” or transhumance-route exposure for DDD; document enforcement intensity; run strong pre-trend and randomization-inference designs).**

---

**#3: Cash and Conflict: Did Nigeria's 2023 Naira Redesign Trigger Violence?**
- **Score: 63/100**
- **Strengths:** Very novel “macro/monetary administrative failure → social unrest/violence” channel with a sharp time shock and clear short-run narrative. If you can build a credible scarcity index, the design could be tight and the result would be intrinsically interesting.
- **Concerns:** The key regressor (cash scarcity) is currently the weak link—media-based measures risk circularity and bias. The window overlaps major confounds (2023 election cycle, fuel scarcity, general inflation/stress), and the acute period is short, creating power and specification-mining risks.
- **Novelty Assessment:** **High.** There is work on cash shortages and protests globally, but **Nigeria’s 2023 episode + cross-state scarcity intensity + UCDP violence** is not an over-studied pairing.
- **Top-Journal Potential:** **Medium.** A top field journal is plausible if you (i) nail measurement, (ii) pre-register/specify, and (iii) show a causal chain (scarcity → protests/crime types → broader violence).
- **Identification Concerns:** Differential trends correlated with banking penetration/urbanization; simultaneity with election violence; measurement error in scarcity attenuating effects and inviting post-hoc tuning.
- **Recommendation:** **CONSIDER (conditional on: obtaining administrative proxies—CBN currency shipments by state, bank branch/ATM density, POS transaction collapses, or mobile-money substitution—to construct an ex ante scarcity index; explicit controls/negative controls for election-related violence).**

---

**#4: Conflict Contagion: Spatial Spillovers of Organized Violence Across Nigerian States**
- **Score: 59/100**
- **Strengths:** The “security balloon” hypothesis is policy-critical and, if credibly identified, would be highly publishable because it speaks directly to optimal security allocation. Nigeria’s multiple simultaneous conflict theaters offer unusual variation to test displacement vs redeployment mechanisms.
- **Concerns:** Spatial spillovers are notoriously hard: correlated shocks, simultaneity, and reflection problems can easily masquerade as contagion. The proposed instruments (distant conflicts, military operations) are promising in words but often weak in practice without detailed data on deployments and operational intensity.
- **Novelty Assessment:** **Medium.** Spillovers/balloon effects are studied in crime/insurgency contexts, but Nigeria’s multi-theater setting could still add a distinctive contribution—novelty depends on executing a design others haven’t.
- **Top-Journal Potential:** **Medium (upside), Low (baseline).** Upside is real if you can produce a compelling “operations → redeployment → vulnerability window → spillover violence” chain with strong falsification; otherwise it will read as suggestive spatial correlation.
- **Identification Concerns:** National shocks (arms flows, elections, macro crises) simultaneously affecting many states; border exposure correlating with trade routes and policing capacity; endogenous timing of operations.
- **Recommendation:** **CONSIDER (conditional on: obtaining credible exogenous shocks such as clearly dated, externally triggered military redeployments; pre-specified spatial exposure measures; and strong falsification—non-adjacent placebo borders, directionality tests, and timing tests around operations).**

---

**#5: The Economic Shadow of Insecurity: Conflict Types and Local Economic Activity in Nigeria**
- **Score: 54/100**
- **Strengths:** Useful descriptive mapping and “type decomposition” could be valuable for policy prioritization, and the data are feasible at scale (UCDP + VIIRS). Recovery dynamics is a potentially interesting descriptive object.
- **Concerns:** The causal identification is weak: conflict onset is endogenous to local economic conditions and governance, and threshold-based “treatment” definitions are easily contestable. Without a strong instrument or quasi-random source of variation, this risks being a well-executed correlation study in a very crowded literature.
- **Novelty Assessment:** **Low-medium.** There is a large literature on conflict and economic activity using nightlights; “different conflict types” is incremental unless paired with a truly new identification angle.
- **Top-Journal Potential:** **Low.** Absent a standout design or new measurement object, top outlets will view this as “competent but not belief-changing.”
- **Identification Concerns:** Reverse causality (economic decline → conflict), omitted variables (state capacity), overlapping/confounded conflict types, and arbitrary treatment thresholds.
- **Recommendation:** **SKIP (unless you can secure a strong exogenous design—e.g., plausibly random security-force reallocations, weather shocks affecting pastoral routes interacted with pre-existing exposure, or other shocks that differentially shift specific conflict types).**

---

### Summary

This is a strong batch on policy importance, with two genuinely promising directions. **Idea 1** is the best “publishable-with-credible-ID” project given the clean exogenous oil-price shift and high-frequency fiscal/outcome data; I would start there. **Ideas 2 and 4** have higher stakes/novelty but need serious work to defeat endogeneity and measurement concerns before they’re institute-ready causal evaluations.

---

## Gemini 3.1 Pro

**Tokens:** 9802

Here is my evaluation of the research proposals, ranked from most to least promising based on the criteria provided. 

### Rankings

**#1: Idea 5: Conflict Contagion: Spatial Spillovers of Organized Violence Across Nigerian States**
- **Score**: 85/100
- **Strengths**: The proposed instrumental variable strategy—using distant military operations as an exogenous shock to local security capacity via troop redeployment—is a brilliant, top-tier identification strategy. It tests a profound mechanism about state capacity constraints and the opportunity cost of security provision.
- **Concerns**: Measuring actual troop movements might be empirically impossible; the paper will likely have to infer them from the timing of named military operations, which requires strong assumptions.
- **Novelty Assessment**: High. While spatial spillovers of conflict are studied, isolating the "security balloon" effect via endogenous state resource reallocation is a highly novel mechanism for economics.
- **Top-Journal Potential**: High. This fits the "Puzzle → Design → Mechanism" arc perfectly. It shows a surprising tradeoff (fighting here causes deaths there) that challenges how policymakers think about localized security operations, elevating it from a standard ATE to a paper about state capacity.
- **Identification Concerns**: The author needs to rigorously prove that distant military operations don't affect the local state through other channels (e.g., national political shocks, trade disruptions, or general equilibrium effects).
- **Recommendation**: PURSUE

**#2: Idea 2: Legislating Peace? Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria**
- **Score**: 68/100
- **Strengths**: This addresses a life-and-death policy with a clear, actionable binary treatment. The proposed DDD design (pastoral vs. non-pastoral LGAs within adopting states) provides a credible path to isolating the policy's effect from general state-level trends.
- **Concerns**: There is a severe risk of reverse causality—states pass these laws *because* violence is spiking, making parallel pre-trends highly unlikely.
- **Novelty Assessment**: Medium-High. The specific policy (anti-grazing laws) is understudied in economics, though the broader topic of farmer-herder conflict is gaining attention.
- **Top-Journal Potential**: Medium. If the DDD convincingly overcomes the endogenous timing, it's a great paper with high policy stakes ("first-order stakes"). However, if pre-trends fail (Ashenfelter's dip), it will be rejected as fatally flawed.
- **Identification Concerns**: Endogenous adoption timing is the primary threat. The surge in violence preceding the law's passage will likely violate the parallel trends assumption, requiring an IV for adoption timing (e.g., political alignment with the Southern Governors' Forum).
- **Recommendation**: CONSIDER (conditional on: passing strict pre-trend tests; finding an IV for adoption timing).

**#3: Idea 4: Cash and Conflict: Did Nigeria's 2023 Naira Redesign Trigger Violence?**
- **Score**: 58/100
- **Strengths**: The premise is fascinating—a technocratic monetary policy causing deadly riots—which perfectly fits the editorial preference for surprising substitutions and unintended tradeoffs.
- **Concerns**: The January-March 2023 window perfectly overlaps with the highly contested February 2023 Nigerian Presidential Election, introducing a massive, likely fatal confounder.
- **Novelty Assessment**: High for the question, but the empirical setting is too messy to cleanly isolate the monetary shock from the political shock.
- **Top-Journal Potential**: Low-Medium. The election confounder will kill this at top journals unless the author can perfectly partial out election violence, which is empirically very difficult. 
- **Identification Concerns**: Severe omitted variable bias from the 2023 elections. Additionally, banking infrastructure (which dictates cash scarcity) correlates heavily with state wealth, urbanization, and baseline institutional capacity.
- **Recommendation**: SKIP (unless the outcome is restricted strictly to bank-vandalism events, rather than general violence, to bypass the election confounder).

**#4: Idea 1: Petro-Federalism and Local Economic Activity: Oil Price Shocks and Nigeria's Revenue Sharing**
- **Score**: 52/100
- **Strengths**: Good use of high-resolution satellite data and a clear attempt to use a modern shift-share framework to answer a macroeconomic question.
- **Concerns**: There is a fatal violation of the exclusion restriction. Global oil prices directly affect the local economies of oil-producing states (via oil industry employment and local spillovers), not just through the FAAC fiscal transfer channel.
- **Novelty Assessment**: Low-Medium. Oil price shocks and nightlights have been studied extensively. The attempt to isolate the "fiscal channel" is interesting but empirically confounded by the direct channel.
- **Top-Journal Potential**: Low. Reviewers will immediately spot the direct vs. fiscal channel confounding. It will be viewed as a standard ATE paper with a flawed identification strategy.
- **Identification Concerns**: The "shift" (oil prices) affects the outcome through channels other than the "share" (fiscal transfers). You cannot easily separate the loss of federal revenue from the loss of direct oil extraction activity in the Niger Delta.
- **Recommendation**: SKIP

**#5: Idea 3: The Economic Shadow of Insecurity: Conflict Types and Local Economic Activity in Nigeria**
- **Score**: 45/100
- **Strengths**: The type decomposition of violence (Boko Haram vs. banditry vs. farmer-herder) is a nice descriptive exercise that adds nuance to the conflict literature.
- **Concerns**: The treatment (conflict onset) is highly endogenous, and standard DiD on conflict and nightlights is a very tired literature.
- **Novelty Assessment**: Low. The core finding that "conflict reduces economic activity" is a well-established stylized fact. This reads exactly as "competent but not exciting."
- **Top-Journal Potential**: Low. It lacks a surprising mechanism, a clean exogenous shock, or a counter-intuitive finding, which are required for top-5 or top field journals. 
- **Identification Concerns**: Conflict onset is endogenous to local economic trends (poorer areas attract conflict). State fixed effects do not solve dynamic unobservables, and the proposed "distant conflict" instrument is too vague to evaluate.
- **Recommendation**: SKIP

### Summary

This batch contains one genuinely standout proposal (Idea 5) that leverages a clever identification strategy to answer a deep, first-order question about state capacity and security tradeoffs. Idea 2 is highly policy-relevant but faces steep identification hurdles regarding endogenous law adoption. The remaining ideas suffer from fatal confounders (Idea 4's election overlap, Idea 1's exclusion restriction violation) or lack the novelty required for top-tier economics journals (Idea 3). I strongly recommend pursuing Idea 5 first, as it has the clearest path to a top-tier publication and offers a compelling "causal chain" narrative.

---

## Grok 4.1 Fast

**Tokens:** 7175

### Rankings

**#1: Legislating Peace? Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria**
- Score: 72/100
- Strengths: Tackles a first-order life-and-death policy question (~2,800 deaths in 5 years) with no prior causal evidence and uncertain effect direction (reduction vs. enforcement backlash), enabling a compelling mechanism chain; high policy urgency given the 2025 national ban.
- Concerns: Only 14 treated states falls below the ≥20 DiD threshold, risking underpowered estimates despite mitigations; state-year aggregation may mask LGA-level heterogeneity.
- Novelty Assessment: Highly novel—no existing causal studies on anti-grazing laws' effects, only descriptive analyses of farmer-herder conflict.
- Top-Journal Potential: High—top-5 journals reward high-stakes violence policies with uncertain tradeoffs (e.g., politician wages reducing corruption but increasing violence) and clear welfare implications, especially with DDD placebos isolating the grazing channel.
- Identification Concerns: Staggered timing risks anticipation effects or non-parallel trends (e.g., early adopters like Benue may differ systematically); reliance on wild bootstrap for small N treated units could invite skepticism without extensive pre-trends validation.
- Recommendation: PURSUE (conditional on: LGA-level DDD execution; pre-trends passing HonestDiD or equivalent; placebo validation on non-pastoral outcomes)

**#2: Petro-Federalism and Local Economic Activity: Oil Price Shocks and Nigeria's Revenue Sharing**
- Score: 70/100
- Strengths: Exceptionally clean shift-share design with global oil prices as exogenous shift, large N (37 states, 5k+ obs), and multiple shocks enabling robust inference; novel fiscal transfer channel distinct from direct resource curse.
- Concerns: Nightlights proxy, while validated, may understate informal economy responses; baseline shares could embed pre-existing trends if oil-dependent states grow differently.
- Novelty Assessment: Moderately novel—resource curse extensively studied, but subnational fiscal derivation impacts via transfers underexplored, especially with monthly satellite data.
- Top-Journal Potential: Medium—offers a causal chain (oil shocks → differential transfers → activity) with policy bite for federalism design, but oil volatility effects feel familiar without a major belief pivot.
- Identification Concerns: Share instrument plausibly exogenous but may correlate with state trends (e.g., oil states' IGR weakness); needs leave-one-out IV checks per Borusyak et al. to rule out bias.
- Recommendation: PURSUE

**#3: Conflict Contagion: Spatial Spillovers of Organized Violence Across Nigerian States**
- Score: 62/100
- Strengths: Tests "security balloon" hypothesis with multi-mechanism decomposition in a multi-insurgency lab setting, leveraging georeferenced data for precise exposure measures.
- Concerns: Spatial identification chronically prone to omitted correlated shocks; instruments (distant violence, ops) require heroic assumptions on resource reallocation.
- Novelty Assessment: Fairly novel—spatial spillovers studied elsewhere (e.g., Colombia), but Nigeria's decentralized security and multi-type conflicts offer fresh natural experiment.
- Top-Journal Potential: Medium—counterintuitive policy implication (localized ops backfire) could excite if mechanisms cleanly traced, akin to substitution tradeoffs, but niche without universe-scale data.
- Identification Concerns: Hard to disentangle true contagion from national confounders (e.g., fiscal shocks); IV exclusion restrictions vulnerable to diffuse mechanisms like arms flow.
- Recommendation: CONSIDER (conditional on: multiple falsification batteries succeeding; clear MDE bounds)

**#4: The Economic Shadow of Insecurity: Conflict Types and Local Economic Activity in Nigeria**
- Score: 58/100
- Strengths: Type decomposition and recovery dynamics add nuance to conflict-econ link using granular UCDP and nightlights data.
- Concerns: Violence onset highly endogenous (poor areas attract conflict); staggered design vulnerable to heterogeneous effects without strong controls.
- Novelty Assessment: Low to moderate—conflict impacts on nightlights/growth heavily studied (e.g., post-2009 Nigeria papers), though type-specific footprints less common.
- Top-Journal Potential: Low—reads as competent descriptive decomposition without challenging wisdom or novel chain; many similar papers lack top-5 traction absent tighter ID.
- Identification Concerns: Treatment (violence threshold crossing) not exogenous—reverse causality and selection bias dominate despite FEs/trends; distant shocks IV weak for local effects.
- Recommendation: CONSIDER

**#5: Cash and Conflict: Did Nigeria's 2023 Naira Redesign Trigger Violence?**
- Score: 52/100
- Strengths: Surprising mechanism (monetary shock → scarcity → violence chain) on a unique recent event with daily data precision.
- Concerns: Very short acute window (Jan-Apr 2023) underpowers estimates; cash scarcity index construction subjective and media-reliant.
- Novelty Assessment: Highly novel—brand-new event with no prior studies.
- Top-Journal Potential: Low—short-run event studies on thin post-periods repeatedly lose (per appendix); lacks scale or chain depth to compete beyond policy note.
- Identification Concerns: Cross-state variation in scarcity likely endogenous to politics/banking (e.g., southern bias); no pre-trends possible for hyper-acute shock.
- Recommendation: SKIP

### Summary
This is a solid batch with two genuinely promising ideas (2 and 1) blending clean Nigeria policy variation and high stakes, but most suffer ID hurdles or familiarity that cap top-journal odds. Prioritize Idea 2 for its violence stakes and urgency, then Idea 1 for ID strength—others risk "competent but unexciting" rejection without major fixes.

