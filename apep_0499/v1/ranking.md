# Research Idea Ranking

**Generated:** 2026-03-04T10:00:32.888891
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Public Investment Revitalize Declin... | PURSUE (76) | PURSUE (72) | PURSUE (78) |
| Anticipating the Ban — Energy Performanc... | CONSIDER (67) | CONSIDER (62) | CONSIDER (68) |
| Tax Incentives in the French Countryside... | CONSIDER (56) | SKIP (55) | SKIP (62) |
| Vacant Homes and Housing Markets — Franc... | SKIP (44) | SKIP (45) | SKIP (52) |

---

## GPT-5.2

**Tokens:** 5899

### Rankings

**#1: Does Public Investment Revitalize Declining City Centers? Evidence from France's Action Cœur de Ville**
- **Score: 76/100**
- **Strengths:** Big, first-order French place-based program with (apparently) no credible causal evaluation yet, and unusually rich parcel-level transactions that make a center-vs-periphery within-commune design feasible. The DDD structure is well-matched to the key confound (COVID-era revaluation of mid-sized cities) and supports a mechanism chain (commercial vacancy/firms → amenities → prices).
- **Concerns:** “Treated cities” were selected non-randomly, so even with matching + DDD you’ll need very strong pre-trend evidence and falsification tests (e.g., pre-2018 “effects” within centers) to be credible. Implementation is likely heterogeneous and lagged—if you cannot measure actual spending/project timing, estimates risk becoming an “intention-to-treat with unknown dose,” which can look noisy/underpowered even with lots of transactions.
- **Novelty Assessment:** **High (in this exact setting/policy).** Place-based policies are heavily studied, but ACV specifically looks under-evaluated; the Cour des Comptes critique suggests real value-add if you can credibly isolate the program.
- **Top-Journal Potential: Medium-High.** Not conceptually new (place-based revitalization), but could become a top field-journal paper (AEJ:EP/JUE) if the design convincingly separates ACV from COVID and traces mechanisms; top-5 potential depends on whether you deliver a belief-changing mechanism (e.g., “public-space/housing rehab capitalizes but does/doesn’t revive local commerce”).
- **Identification Concerns:** Main threats are differential pre-trends in “city centers” of treated cities, spillovers from center projects to periphery, and treatment timing/dose mismeasurement (designation vs convention signing vs project completion). You’ll want event studies by signing year, robustness to alternative center definitions, and “planned-but-not-yet-spent” timing checks.
- **Recommendation:** **PURSUE (conditional on: convincing center/periphery parallel trends pre-2018; credible measurement of implementation timing/dose—at least convention signing + project rollout proxies; strong placebo battery including outcomes unlikely to move quickly).**

---

**#2: Anticipating the Ban — Energy Performance Labels and Property Values in France's "Passoire Thermique" Policy**
- **Score: 67/100**
- **Strengths:** Clear, policy-relevant forward-looking shock (rental feasibility being removed by rating) with a natural placebo (owner-occupied) and potentially sharp contrasts (G vs D) that map to theory of capitalization under anticipated regulation. If executed well, the paper can go beyond “labels matter” to “future rental constraints get priced immediately,” which is more interesting.
- **Concerns:** The biggest practical risk is data/linkage: ADEME DPE coverage starts mid-2021 and property-level matching to DVF can be error-prone and selectively missing, which can generate composition bias that looks like capitalization. The design may also be confounded by simultaneous energy-price shocks, renovation subsidies/credit conditions, and changing salience of energy costs—hard to separate from “ban anticipation” without a very careful design.
- **Novelty Assessment:** **Medium.** There is already a sizeable EPC/DPE capitalization literature (esp. UK/Europe). The French rental-ban schedule is a genuine twist, but reviewers will treat it as “another EPC paper” unless you cleanly isolate the regulation/anticipation channel and quantify it.
- **Top-Journal Potential: Medium.** Could hit a strong field journal if you credibly separate information vs regulation vs energy-price salience and show heterogeneity by rental share/landlord exposure; top-5 is possible but only if the design is unusually clean (e.g., convincing multi-cutoff/RD-style comparisons with manipulation checks and a tight causal chain).
- **Identification Concerns:** Limited pre-period (post-2021 DPE) weakens DiD; boundary designs risk manipulation/sorting around thresholds and non-classical measurement error in ratings. Owner-occupier “placebo” helps, but you still need evidence that treated/control homes follow similar pre-trends in prices *within the short window* and that DPE availability itself isn’t endogenous.
- **Recommendation:** **CONSIDER (conditional on: high-quality DVF×ADEME linkage with missingness analysis; design anchored in multi-cutoff/RD logic with manipulation tests; explicit separation of energy-price shock vs policy timing using plausibly exogenous timing variation like the Jan-2023 freeze / Jan-2025 ban milestone).**

---

**#3: Tax Incentives in the French Countryside — The ZRR Redesign and Rural Firm Dynamics**
- **Score: 56/100**
- **Strengths:** The 2015 redesign plausibly creates quasi-experimental status changes (gainers vs losers) and Sirene is strong universe data for firm demography. Policy relevance is real (persistent rural decline; ongoing 2024 reform), and the “gain/loss” structure can be informative if trends are stable.
- **Concerns:** The redesign criteria (density, income) are exactly the variables driving outcomes, making parallel trends questionable; gainers/losers may be on different trajectories even absent treatment. Also, “firm creation/destruction in rural communes” is a common/low-excitement outcome in the zone-policy literature unless you add sharp mechanisms (composition, productivity, relocation vs net new, fiscal incidence).
- **Novelty Assessment:** **Medium-High (for ZRR specifically), but low in the broader ‘enterprise zone/tax incentive’ space.** Reviewers may see it as a cousin of ZFU/enterprise-zone work unless the redesign yields unusually clean identification (e.g., discontinuities at thresholds).
- **Top-Journal Potential: Low-Medium.** Most likely a competent regional/place-based evaluation unless you (i) exploit a discontinuity-based design, (ii) show an unexpected margin (e.g., relocation crowd-out dominates, or long-run demographic effects), and (iii) tie to welfare/cost-effectiveness.
- **Identification Concerns:** DiD on gainers vs losers is vulnerable to endogenous reclassification and differential shocks to rural areas; treatment likely correlated with unobserved decline/recovery. A threshold/RD (if administratively strict) or synthetic control at fine geographic level might be needed to convince.
- **Recommendation:** **CONSIDER (conditional on: finding a credible discontinuity/threshold-based design or other quasi-random assignment feature in the 2015 decree; expanding beyond firm counts to relocation vs net entry, sectoral shifts, and (ideally) employment/wage effects).**

---

**#4: Vacant Homes and Housing Markets — France's Expanding Vacancy Tax**
- **Score: 44/100**
- **Strengths:** The policy is important and globally under-studied; the 2023/2024 expansion is huge (thousands of communes), which is attractive for precision once enough time passes. If you can measure vacancy and show clear first-stage behavior (re-occupancy/letting), it could eventually become a definitive paper on vacancy taxation.
- **Concerns:** Right now the post-period is extremely short for outcomes like vacancy rates, rents, and construction/renovation responses—nulls would be hard to interpret and positives may reflect short-run compositional/anticipation effects. Assignment to TLV is policy-driven by tight markets (non-random), and credible annual vacancy measurement at commune level is not guaranteed.
- **Novelty Assessment:** **High conceptually, medium empirically (because “vacancy tax” evidence is thin, but short-run evaluations are common and often inconclusive).** The setting is promising but immature.
- **Top-Journal Potential: Low (for now).** Top outlets will likely view this as underpowered-by-time and too exposed to selection unless you reframe explicitly as “short-run immediate responses” with strong first-stage and very high-frequency outcomes.
- **Identification Concerns:** Endogenous targeting (tight markets chosen for TLV), anticipation effects in late 2023, and short horizon with slow-moving outcomes. Without strong pre-trends and a compelling comparison set (or an instrument/threshold rule), DiD will look fragile.
- **Recommendation:** **SKIP (for now) / REVISIT later (when ≥3–5 years post is available, or if you can secure high-frequency vacancy/advertisement data and show an immediate first stage).**

---

### Summary

This is a solid batch with one clearly fundable project now (**ACV**, Idea 1), one potentially excellent but execution-risky project (**passoire thermique**, Idea 2), and two that are either likely to read as “competent but not exciting” (Idea 3) or are prematurely timed given the short post window (Idea 4). If you start one immediately, start with **Idea 1**, and develop **Idea 2** in parallel only if you can de-risk the data linkage and design (multi-cutoff + manipulation/missingness diagnostics).

---

## Gemini 3.1 Pro

**Tokens:** 8391

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in observed editorial preferences and the realities of empirical identification.

### Rankings

**#1: Does Public Investment Revitalize Declining City Centers? Evidence from France's Action Cœur de Ville**
- **Score**: 72/100
- **Strengths**: The DDD design elegantly solves the major COVID-19 urban exodus confounder that plagues recent spatial evaluations. It leverages high-quality, universe-level administrative data with sufficient clusters for reliable inference.
- **Concerns**: Place-based policies are a heavily saturated literature. Without a novel mechanism, this risks reading as a standard, albeit well-executed, program evaluation.
- **Novelty Assessment**: Moderate. While ACV itself lacks a rigorous causal evaluation, the broader literature on place-based interventions (Enterprise Zones, Opportunity Zones) is massive and mature. 
- **Top-Journal Potential**: Medium. The identification is clean, but to hit a Top 5, it needs to challenge conventional wisdom (e.g., showing spatial sorting vs. actual new growth) rather than just estimating an ATE. It is a very solid fit for *AEJ: Economic Policy* or *Journal of Urban Economics*.
- **Identification Concerns**: Spillovers from the treated city center to the control periphery within the same commune could violate SUTVA, potentially attenuating the DDD estimates. 
- **Recommendation**: PURSUE (conditional on: mapping a clear mechanism chain beyond the ATE; ensuring center/periphery spillovers can be bounded).

**#2: Anticipating the Ban — Energy Performance Labels and Property Values in France's "Passoire Thermique" Policy**
- **Score**: 62/100
- **Strengths**: The anticipation of a hard regulatory ban on rentals is a fantastic, first-order economic shock, and the owner-occupied placebo provides a structurally rigorous defense.
- **Concerns**: The lack of systematic DPE data pre-2021 is a near-fatal flaw for a standard DiD, making pre-trends impossible to verify cleanly.
- **Novelty Assessment**: High. Moving from "energy labels as information" to "energy labels as a binding constraint on capital yield" is a significant step forward in the climate/housing literature.
- **Top-Journal Potential**: High (conceptually) but Low (empirically). The question and mechanism are Top-5 material, but the data constraints will likely result in a rejected paper due to "admitted identification failure" on pre-trends.
- **Identification Concerns**: Without pre-2021 DPE ratings, you cannot establish parallel trends. Furthermore, address matching between DVF and ADEME is notoriously lossy and could create endogenous sample selection.
- **Recommendation**: CONSIDER (conditional on: finding a historical DPE dataset to establish pre-trends, or pivoting to a pure cross-sectional RDD at the implementation dates).

**#3: Tax Incentives in the French Countryside — The ZRR Redesign and Rural Firm Dynamics**
- **Score**: 55/100
- **Strengths**: The 2015 redesign provides clean, bidirectional variation (communes gaining and losing status simultaneously) to test the symmetry of tax incentives.
- **Concerns**: This is the textbook definition of "competent but not exciting," applying a standard DiD to a standard place-based tax incentive.
- **Novelty Assessment**: Low. The literature on enterprise zones and place-based tax incentives is saturated, and rural zones do not offer a fundamentally different economic mechanism.
- **Top-Journal Potential**: Low. As noted in the editorial patterns, standard DiDs with unsurprising signs on narrow outcomes (firm registrations) without a belief-changing pivot do not win top-journal space.
- **Identification Concerns**: Communes that gained/lost status in 2015 likely did so because of underlying demographic/economic trends (crossing population/income thresholds), which directly threatens the parallel trends assumption.
- **Recommendation**: SKIP

**#4: Vacant Homes and Housing Markets — France's Expanding Vacancy Tax**
- **Score**: 45/100
- **Strengths**: Vacancy taxes are a highly relevant, understudied policy tool with massive public interest and clear welfare implications.
- **Concerns**: The post-period (Jan 2024) is far too short to measure housing market capitalization or structural vacancy changes.
- **Novelty Assessment**: Moderate. Vacancy taxes are understudied globally, but the empirical setup here is premature.
- **Top-Journal Potential**: Low. The editorial appendix explicitly flags "recent policies with short post-periods" as losers because they are uninterpretably underpowered, especially in slow-moving real estate markets.
- **Identification Concerns**: A 1.5-year post-period captures mostly noise, transaction delays, and short-run frictions rather than the new equilibrium, making any null result uninterpretable.
- **Recommendation**: SKIP (revisit in 2027 when sufficient post-treatment data exists).

### Summary

This batch presents a mix of standard evaluations and promising but flawed designs. Idea 1 is the most viable and professionally executable, offering a clean identification strategy for a major policy, though it will need a compelling mechanism analysis to elevate it above a standard field-journal piece. Idea 2 has the highest theoretical ceiling due to its focus on anticipation and regulation, but its data constraints make it highly risky; I recommend pursuing Idea 1 first while investigating the data feasibility of Idea 2.

---

## Grok 4.1 Fast

**Tokens:** 5560

### Rankings

**#1: Does Public Investment Revitalize Declining City Centers? Evidence from France's Action Cœur de Ville**
- Score: 78/100
- Strengths: Strong novelty as the first causal evaluation of France's largest urban revitalization program, with a clean triple-difference design leveraging geocoded data for within-city center-periphery variation that credibly isolates policy effects from COVID trends; clear mechanism chain (investments → commercial activity → housing prices) using universe administrative data positions it well for place-based policy literature.
- Concerns: Matching non-ACV controls must be robust to unobserved city heterogeneity; firm outcomes may dilute if ACV's multi-axis nature blurs firm-level channels.
- Novelty Assessment: Highly novel—no known rigorous causal papers; official audits confirm lack of credible evaluations, distinguishing it from broader place-based lit.
- Top-Journal Potential: High. Challenges place-based skepticism (e.g., Neumark lit) with a counterintuitive DDD addressing COVID confounds, first-order urban decline stakes, and a full causal chain with universe data—fits winners like Gaubert/Hanson/Neumark by delivering definitive mechanisms on revitalization.
- Identification Concerns: Parallel trends in center-periphery pre-2018 must hold despite potential anticipation; limited treated units per sector could weaken firm dynamics inference despite 244 clusters.
- Recommendation: PURSUE (conditional on: strong pre-trends/event-study visuals; mechanism decomposition with intermediate firm/vacancy outcomes)

**#2: Anticipating the Ban — Energy Performance Labels and Property Values in France's "Passoire Thermique" Policy**
- Score: 68/100
- Strengths: Novel anticipation capitalization from phased bans offers a clean forward-looking test absent in French lit, with built-in owner-occupied placebo and multi-cutoff potential aligning outcomes directly to policy bite on 4.8M homes.
- Concerns: Data merging (DVF × ADEME) risks attenuation from imperfect address matches; short pre-period post-2021 DPE availability limits trend tests.
- Novelty Assessment: Moderately novel—builds directly on UK EPC paper but first for French regulation/anticipation channel; no prior causal French DPE evaluations.
- Top-Journal Potential: Medium. Exciting information-vs-regulation decomposition with owner placebo echoes UK EPC winner, but feels like a "competent extension" without field-pivoting scale or surprise (e.g., no universe coverage or welfare bounds), risking "technically sound but unsurprising ATE" rejection.
- Identification Concerns: DiD intensity may confound label information shocks with ban expectations; D-rated controls could trend differently if future bans alter behavior pre-emptively.
- Recommendation: CONSIDER (if RDD/multi-cutoff yields sharp discontinuities and merge success >90%)

**#3: Tax Incentives in the French Countryside — The ZRR Redesign and Rural Firm Dynamics**
- Score: 62/100
- Strengths: Gain/lose/unchanged DiD exploits a clean 2015 natural experiment in understudied rural zones, with accessible universe firm/property data for standard outcomes.
- Concerns: Rural sparsity means thin DVF samples and noisy firm rates; overlaps with urban ZFU lit may frame it as incremental.
- Novelty Assessment: Moderately studied—rural ZRR less than urban ZFU (e.g., Mayer et al. 2017), but 2015 redesign unexamined causally.
- Top-Journal Potential: Low. Standard firm dynamics ATE on place-based taxes reads as "competent but not exciting" without mechanism chain, surprise, or first-order stakes—echoes appendix losses on narrow employment nulls vs. urban benchmarks.
- Identification Concerns: Staggered adoption risks heterogeneous trends; unchanged-status controls may proxy poorly if national shocks hit rural areas unevenly.
- Recommendation: SKIP

**#4: Vacant Homes and Housing Markets — France's Expanding Vacancy Tax**
- Score: 52/100
- Strengths: Globally understudied vacancy taxes with massive 2023 expansion (3,690 communes) and prior 2013 placebo.
- Concerns: Extremely short post-period (~1.5 years) underpowers inference; vacancy data may lack frequency/granularity for credible trends.
- Novelty Assessment: Highly novel—scarce global causal evals of vacancy taxes, French expansion unprecedented in scale.
- Top-Journal Potential: Low. Recent policy with thin post-data fits appendix "short-run underpowered" losses; no mechanism chain or bite verification makes it a non-starter for top journals despite policy angle.
- Identification Concerns: Short window precludes event studies/pre-trends; macro housing trends (e.g., post-COVID) confound without longer horizon.
- Recommendation: SKIP

### Summary
This is a solid batch with one standout (Idea 1) leveraging excellent identification and novelty to address timely place-based questions, while others suffer from data hurdles, saturation, or fatal short post-periods. Pursue Idea 1 first for its top-journal promise; Idea 2 warrants a feasibility pilot but ranks lower due to execution risks.

