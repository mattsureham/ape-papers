# Research Idea Ranking

**Generated:** 2026-03-05T10:06:22.237422
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| The Price of Pork — France's Dual-Mandat... | PURSUE (78) | — | PURSUE (82) |
| Forced Together — Loi NOTRe, EPCI Merger... | PURSUE (68) | — | CONSIDER (68) |
| Losing the Tax Lever — Taxe d'Habitation... | CONSIDER (60) | — | CONSIDER (62) |
| Does Scale Save? Evidence from France's ... | CONSIDER (55) | — | SKIP (58) |
| The Métropole Effect — Urban Governance ... | SKIP (42) | — | SKIP (45) |
| Idea 1: The Price of Pork — France's Dua... | — | PURSUE (88) | — |
| Idea 2: Losing the Tax Lever — Taxe d'Ha... | — | CONSIDER (65) | — |
| Idea 4: Forced Together — Loi NOTRe and ... | — | SKIP (55) | — |
| Idea 3: Does Scale Save? Evidence from V... | — | SKIP (45) | — |
| Idea 5: The Métropole Effect — Urban Gov... | — | SKIP (30) | — |

---

## GPT-5.2

**Tokens:** 6467

### Rankings

**#1: The Price of Pork — France's Dual-Mandate Ban and the Fiscal Cost of Local–National Connections**
- **Score: 78/100**
- **Strengths:** Large, sharp national reform with a very high pre-reform treatment rate and rich administrative outcomes (budgets + 24M DVF transactions) makes it feasible to map a full causal chain from political connection → fiscal flows/spending → capitalization. The question is tightly tied to constitutional design and has a built-in “trade-off discovery” angle (pork vs. local public goods/representation).
- **Concerns:** “Treated vs control” is not random: cumulards were systematically different (often rural, politically entrenched), so parallel trends is the make-or-break diagnostic. The reform is nationwide in 2017, so the counterfactual relies on a relatively small and atypical control group (never-cumul constituencies) and could be contaminated by compositional changes in candidates/parties in 2017.
- **Novelty Assessment:** **High.** I’m not aware of economics papers cleanly estimating the fiscal/pork implications of banning dual mandates; most related work is political science and/or on different institutional margins (legislator pay, term limits, part-time legislatures).
- **Top-Journal Potential:** **High (top field / possible top-5).** If you can show a clear first stage (loss of access to specific grants/transfers), strong pre-trends, and a mechanism-to-welfare narrative (misallocation vs valued local goods), this is “first-order stakes + legible channel,” with unusually strong data scale.
- **Identification Concerns:** Main threat is **differential trends correlated with being a cumulard constituency** (rural decline, shifting national party system in 2017, local political competition differences). You’ll want aggressive event-studies, reweighting/matching on pre-paths, and possibly designs exploiting within-party/within-region variation in cumul prevalence to strengthen credibility.
- **Recommendation:** **PURSUE (conditional on: (i) clean event-study pre-trends on key fiscal outcomes; (ii) demonstrated “bite” on the specific channels dual mandates plausibly affect—e.g., earmarked investment grants; (iii) robustness to reweighting/matched controls and excluding major urban areas/outliers).**

---

**#2: Forced Together — Loi NOTRe, EPCI Mergers, and Intermunicipal Governance**
- **Score: 68/100**
- **Strengths:** Policy-induced consolidation with a population threshold creates plausibly exogenous pressure to merge—substantially cleaner than voluntary municipal mergers—and outcomes (tax harmonization, inter-municipal budgets) are tightly aligned with what the reform changed. Large number of EPCIs gives statistical power.
- **Concerns:** The assignment is **fuzzy** due to derogations (mountain/island/low-density) and political discretion in implementation; “below 15k” is not equivalent to “forced.” NOTRe coincided with other territorial reforms/competence reallocations, creating confounding unless you isolate margins directly tied to the merger requirement.
- **Novelty Assessment:** **Medium-High.** There’s intermunicipal cooperation literature, but France’s NOTRe-driven EPCI restructuring at this scale is less saturated than classic municipal amalgamation settings (Denmark/Germany/Japan).
- **Top-Journal Potential:** **Medium.** Could become top-field if framed around a sharp mechanism (forced consolidation → tax-base sharing and tax-rate convergence → distributional winners/losers, efficiency vs representation) and if you exploit the threshold in a compelling way (e.g., fuzzy RD / RD-DD around 15k).
- **Identification Concerns:** A simple DiD “below vs above” risks violation of parallel trends because population size strongly correlates with trajectories. The most credible path is **running-variable designs around 15,000 (donut/fuzzy RD)** plus DiD/event-study and explicit tests for manipulation/derogation-driven selection.
- **Recommendation:** **PURSUE (conditional on: redesign around a fuzzy RD (or RD-DD) near 15k; show strong first stage: merger probability jumps; and provide an “opponent-killer” on derogations/political discretion—e.g., excluding/stratifying exempt zones).**

---

**#3: Losing the Tax Lever — Taxe d'Habitation Abolition and Local Fiscal Autonomy**
- **Score: 60/100**
- **Strengths:** First-order policy importance (major local tax abolition) with universe commune finance data and a clear fiscal-federalism question: what happens when a salient tax instrument disappears even with compensation? Exposure variation (pre TH reliance) is abundant and continuous, enabling heterogeneity and tight precision.
- **Concerns:** Identification is vulnerable because TH reliance is highly correlated with commune type (urbanization, housing stock, income, rental share), which also drives trends in spending and property markets. COVID overlaps critical years, and compensation mechanisms may attenuate the “bite,” making nulls hard to interpret without a clearly demonstrated first stage.
- **Novelty Assessment:** **Medium.** The exact French reform is not heavily mined in economics yet, but “local tax shocks and fiscal responses/capitalization” is a well-trodden genre; novelty depends on a distinctive mechanism and institutional detail (compensation design, loss of rate-setting autonomy).
- **Top-Journal Potential:** **Medium-Low.** Likely an AEJ:Policy/field-journal paper if you can show (i) a clean autonomy mechanism (rate-setting constraints, tax mix changes) and (ii) a welfare-relevant counterfactual (e.g., deadweight loss vs accountability). Without that, it risks reading as “competent DiD on a big reform.”
- **Identification Concerns:** Main threats are **differential pre-trends by TH share**, **anticipation** (announcement in 2017), and **COVID-era fiscal shocks** correlated with commune characteristics. You’ll need strong pre-period event studies, designs emphasizing 2018–2019, and a demonstrated mapping from TH share to an actual policy-induced change in marginal incentives (not just accounting swaps).
- **Recommendation:** **CONSIDER (conditional on: strong first-stage evidence on autonomy loss—e.g., changes in tax-rate setting behavior/dispersion; and a design that is not driven by 2020–2021).**

---

**#4: Does Scale Save? Evidence from France's Voluntary Municipal Mergers**
- **Score: 55/100**
- **Strengths:** Important and policy-relevant; France is a major new setting with many treated communes and staggered timing, so implementation is feasible and powered. Potential to study political economy (turnout/representation) alongside budgets and property markets.
- **Concerns:** Voluntary mergers are **selection-heavy**: financial stress, leadership quality, pre-existing cooperation, and local growth prospects drive adoption and outcomes. Cross-country merger effects are already a mature literature; without a quasi-exogenous instrument or compelling discontinuity, the paper risks “yet another amalgamation DiD with selection.”
- **Novelty Assessment:** **Medium-Low.** France is new, but municipal merger impacts have many existing studies; novelty must come from a uniquely French institutional margin or a new mechanism (e.g., how voluntary vs forced consolidation changes accountability and tax competition).
- **Top-Journal Potential:** **Low-Medium.** Could land in solid field outlets if identification is strengthened (IV/RD-like pressure) and if you deliver a sharp mechanism and welfare takeaway. Absent that, it will be seen as incremental relative to Denmark/Germany/Japan evidence.
- **Identification Concerns:** Staggered DiD does not solve endogenous timing. You likely need **an IV for merger pressure** (statutory incentives, boundary constraints, discontinuities in grant formulas) or a design comparing “near-eligible” vs “near-ineligible” incentive exposure.
- **Recommendation:** **CONSIDER (only if you can credibly instrument or find a discontinuity that predicts mergers but not outcomes).**

---

**#5: The Métropole Effect — Urban Governance Consolidation and Local Economies**
- **Score: 42/100**
- **Strengths:** The question is inherently interesting (urban governance scale and agglomeration) and outcomes like firm creation/property prices are salient. Institutional change is consequential in a few major areas (Grand Paris, Lyon).
- **Concerns:** **Too few treated units (≈14)** for credible DiD inference at the policy level, and selection is extreme (largest, fastest-changing cities). Even with synthetic control, results will be fragile and hard to generalize; many concurrent urban shocks (housing constraints, transport investments, local political shifts) confound interpretation.
- **Novelty Assessment:** **Medium.** “Metropolitan governance and growth” is studied in various forms internationally; France’s métropoles are a distinct institution, but the empirical leverage here is the bottleneck.
- **Top-Journal Potential:** **Low.** Top journals are skeptical of small-N policy evaluations unless the design is exceptionally sharp (clear discontinuity or repeated trials) and the mechanism is uniquely identified.
- **Identification Concerns:** Small number of treated clusters + high heterogeneity + contemporaneous place-specific shocks makes causal attribution very difficult; standard errors and specification sensitivity will dominate.
- **Recommendation:** **SKIP (unless you can reframe into a sharper within-métropole discontinuity or competence-transfer boundary design with many more treated units).**

---

### Summary

This is a strong batch on French territorial/public-finance reforms, with one standout: **Idea 1** combines unusually high novelty, scale, and a clean reform shock that can be packaged into a top-journal-style causal chain. **Idea 4** is the next best because the threshold invites a much more credible design than typical consolidation papers, while **Ideas 2–3** are feasible but risk “competent but not exciting/clean” unless you solve the bite/selection problems.

---

## Gemini 3.1 Pro

**Tokens:** 8014

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in the empirical realities of top-tier economics publishing. 

### Rankings

**#1: Idea 1: The Price of Pork — France's Dual-Mandate Ban**
- **Score**: 88/100
- **Strengths**: This proposal perfectly aligns with the "first-order stakes + legible causal channel" archetype that wins at top journals, leveraging a sharp, national constitutional reform. It promises a compelling "trade-off discovery" (national efficiency vs. local public goods) rather than a simple ATE, backed by universe-level administrative data.
- **Concerns**: The primary risk is that the "cumulard" vs. "non-cumulard" constituencies might have fundamentally different political economies that drive divergent pre-trends, though the 9-year pre-period allows for rigorous testing of this. 
- **Novelty Assessment**: Highly novel. While political scientists have discussed this qualitatively, the economics of politician multi-tasking and the fiscal cost of dual mandates lack clean, large-scale causal estimates. 
- **Top-Journal Potential**: High. A top-5 journal would find this exciting because it addresses a fundamental question of constitutional design and political economy using a massive, clean shock. The ability to trace the causal chain from political mandate $\rightarrow$ fiscal transfers $\rightarrow$ local public goods $\rightarrow$ real estate capitalization is exactly the kind of narrative architecture editors reward.
- **Identification Concerns**: The main threat is whether the 101 "non-cumulard" constituencies are a valid counterfactual, as politicians who choose *not* to hold dual mandates might be systematically different. The proposed placebo tests (private-sector outcomes, fake 2012 ban) are essential to defend the design.
- **Recommendation**: PURSUE (conditional on: verifying parallel trends in the 2008-2016 pre-period immediately; ensuring the 101 control constituencies provide sufficient common support).

**#2: Idea 2: Losing the Tax Lever — Taxe d'Habitation Abolition**
- **Score**: 65/100
- **Strengths**: This evaluates the most significant French local tax reform in decades, speaking directly to the Tiebout and fiscal federalism literatures. The continuous treatment intensity design across 35,000+ communes provides excellent statistical power.
- **Concerns**: The state compensated communes for the lost revenue, meaning the net fiscal shock might be close to zero, resulting in an underpowered null. Furthermore, the phase-out perfectly overlaps with the 2020-2021 COVID-19 pandemic, which drastically altered local budgets.
- **Novelty Assessment**: Medium. The specific reform is unstudied causally, but the broader literature on property tax limits and local fiscal autonomy is quite mature (e.g., US property tax caps).
- **Top-Journal Potential**: Medium. To avoid the "technically competent but not exciting" bin, the paper must prove a strong first-stage "bite" (showing the compensation didn't perfectly smooth the shock) and uncover a surprising behavioral response from mayors. If it just yields a null effect on spending, it will struggle.
- **Identification Concerns**: The COVID confound is a near-fatal flaw if not handled perfectly; pandemic-related spending or revenue drops will correlate with the 2020 phase-out. The design must isolate the 2018-2019 period or find a highly credible way to partial out pandemic shocks.
- **Recommendation**: CONSIDER (conditional on: proving a definitive first-stage fiscal shock despite state compensation; developing a robust strategy to strip out COVID-19 confounds).

**#3: Idea 4: Forced Together — Loi NOTRe and EPCI Mergers**
- **Score**: 55/100
- **Strengths**: The 15,000-inhabitant threshold provides a much cleaner, forced assignment mechanism than voluntary mergers, reducing selection bias. It addresses a highly relevant policy question about the efficiency of intermunicipal cooperation.
- **Concerns**: The 2015-2017 period was flooded with concurrent territorial reforms (e.g., merging of regions, transfer of competences), making it difficult to isolate the EPCI merger effect. The threshold also had numerous geographic derogations, making the treatment fuzzy.
- **Novelty Assessment**: Medium. Intermunicipal cooperation is a known literature, though causal evidence on forced consolidation of this magnitude is relatively scarce.
- **Top-Journal Potential**: Low to Medium. This reads as a solid field-journal paper (e.g., *Journal of Urban Economics* or *Regional Science and Urban Economics*). It lacks the broad, belief-changing pivot required for a top-5, and the concurrent reforms muddy the "legible causal channel."
- **Identification Concerns**: Concurrent regional reforms are a major threat to the exclusion restriction. Additionally, if the threshold derogations were granted based on political connections or economic distress, the threshold is no longer exogenous.
- **Recommendation**: SKIP (unless the threshold can be cleanly exploited as a fuzzy RDD with a tightly bounded bandwidth, rather than a broad DiD).

**#4: Idea 3: Does Scale Save? Evidence from Voluntary Municipal Mergers**
- **Score**: 45/100
- **Strengths**: The staggered rollout across four waves allows for modern heterogeneous DiD estimators (Callaway-Sant'Anna), and the data is highly accessible.
- **Concerns**: The treatment is entirely voluntary, meaning communes that chose to merge were likely on different financial or demographic trajectories than those that didn't. The proposed IV (proximity to EPCI threshold) is weak and likely violates the exclusion restriction.
- **Novelty Assessment**: Low. The municipal merger literature is heavily saturated with papers from Northern Europe and Japan. 
- **Top-Journal Potential**: Low. This is the modal "technically competent but not exciting" paper. A standard DiD on a saturated topic with severe endogeneity issues will not survive top-tier peer review.
- **Identification Concerns**: Massive selection bias. Communes often merge precisely because they anticipate future fiscal distress or because they have highly aligned, proactive mayors—both of which directly determine the fiscal outcomes being measured.
- **Recommendation**: SKIP.

**#5: Idea 5: The Métropole Effect — Urban Governance Consolidation**
- **Score**: 30/100
- **Strengths**: Addresses a genuinely interesting question about the "optimal city size" and the economic impacts of scaling up urban governance.
- **Concerns**: With only 14 treated units that are systematically the largest and most economically dynamic cities in the country, finding a valid control group is practically impossible. 
- **Novelty Assessment**: Medium. The agglomeration literature is vast, though institutional scale-ups are slightly less common.
- **Top-Journal Potential**: Low. This proposal suffers from a fatal flaw explicitly cited in editorial rejections: it is severely underpowered with too few treated clusters. Any results would be highly sensitive to the specific control group chosen.
- **Identification Concerns**: Extreme selection on observables and unobservables. The 14 métropoles are on entirely different secular growth trends compared to smaller agglomerations. A DiD here will almost certainly fail parallel trends, and synthetic control methods will struggle with such a small donor pool of comparable cities.
- **Recommendation**: SKIP.

***

### Summary

The overall quality of this batch is highly skewed, with one outstanding proposal and several that suffer from classic empirical pitfalls (endogeneity, underpowered clusters, saturated literatures). **Idea 1 (The Price of Pork)** is the only proposal I recommend pursuing immediately; it has the rare combination of a massive, clean exogenous shock, universe-level data, and a narrative that speaks to first-order questions in political economy. **Idea 2** is worth keeping in the pipeline as a backup, provided the researchers can prove the policy actually had "bite" despite state compensation and can navigate the COVID-19 confound. The remaining ideas should be discarded, as they will likely hit hard ceilings at lower-tier journals due to fundamental identification flaws.

---

## Grok 4.1 Fast

**Tokens:** 6269

### Rankings

**#1: The Price of Pork — France's Dual-Mandate Ban and the Fiscal Cost of Local–National Connections**
- **Score**: 82/100
- **Strengths**: Exceptionally clean national shock with 476 treated units, long balanced panel (9 pre, 6+ post), rich admin data for mechanisms (grants vs. spending), and built-in placebos/trade-offs that map to pork-barrel politics and constitutional design tensions. Uncovers a novel causal estimate on politician multitasking with clear welfare stakes (national efficiency vs. local goods).
- **Concerns**: Aggregation to constituency level might mask commune heterogeneity; post-2017 period includes some COVID years, though long pre-trends and placebos mitigate.
- **Novelty Assessment**: Highly novel—no causal economics papers exist (zero on Google Scholar/NBER), only descriptive pol sci; dual-mandate costs are a gaping hole in politician allocation literature despite global relevance.
- **Top-Journal Potential**: High. Fits editorial winners: trade-off discovery (pork reduction vs. local goods loss), legible causal chain (ban → mandate choice → fiscal flows), universe-scale French admin data (24M+ DVF), and challenges conventional wisdom on multi-tasking incentives in a first-order constitutional question.
- **Identification Concerns**: Parallel trends highly testable with 9 pre-years and placebos (private outcomes, never-cumulard); minor risk of anticipation if deputies adjusted pre-2017, but placebo 2012 ban tests this.
- **Recommendation**: PURSUE (conditional on: robust pre-trend diagnostics and mechanism decomposition; COVID robustness checks)

**#2: Forced Together — Loi NOTRe, EPCI Mergers, and Intermunicipal Governance**
- **Score**: 68/100
- **Strengths**: Threshold-based forced mergers provide cleaner identification than voluntary cases, with large N (~40% treated EPCIs) and accessible EPCI budgets for tax harmonization/service outcomes; speaks to intermunicipal cooperation with reduced selection bias.
- **Concerns**: Derogations (mountain/island areas) blur treatment sharpness; concurrent reforms (region mergers, competence shifts) risk confounding the 2017 shock.
- **Novelty Assessment**: Moderately novel—first causal evidence for France's EPCI wave, but builds on international intermunicipal lit (e.g., US metro areas).
- **Top-Journal Potential**: Medium. Solid scale/efficiency question with threshold design, but lacks a crisp trade-off or belief-changing pivot; reads more as "competent policy eval" than mechanism-revealing chain unless heterogeneity uncovers offsets.
- **Identification Concerns**: Single-period DiD vulnerable if pre-trends differ by size; derogations require careful coding or exclusion, potentially shrinking N.
- **Recommendation**: CONSIDER (conditional on: IV for derogations or matching on observables)

**#3: Losing the Tax Lever — Taxe d'Habitation Abolition and Local Fiscal Autonomy**
- **Score**: 62/100
- **Strengths**: Continuous exposure DiD leverages 35k+ communes for power, with long panel and direct fiscal data to trace Tiebout responses; timely reform with property price capitalization as bonus outcome.
- **Concerns**: Compensation via taxe foncière transfers likely mutes net shock, yielding small effects; heavy COVID overlap (2020-23) confounds post-phase.
- **Novelty Assessment**: Somewhat novel for this exact reform, but property/local tax responses well-studied elsewhere (e.g., Lutz 2015 caps/rates).
- **Top-Journal Potential**: Medium. Fiscal federalism angle is solid but risks "broad rollout → many outcomes" discount without tight channel; COVID makes short-run nulls hard to interpret credibly.
- **Identification Concerns**: Continuous treatment needs binned or nonlinear specs for clean ATE; anticipation from 2017 announcement untestable without earlier data.
- **Recommendation**: CONSIDER

**#4: Does Scale Save? Evidence from France's Voluntary Municipal Mergers**
- **Score**: 58/100
- **Strengths**: Staggered DiD with 2,500+ treated across 4 waves enables CS estimator and heterogeneity (e.g., by merger motive); ties to global scale-efficiency debate with service indicators.
- **Concerns**: Voluntary selection creates severe endogeneity—merging communes likely already efficient/motivated; needs untested IV (EPCI proximity).
- **Novelty Assessment**: Low to moderate—municipal mergers causal lit exists for Denmark/Germany/Japan; France adds voluntary twist but not a field-changer.
- **Top-Journal Potential**: Low. Standard scale ATE on saturated topic (local gov efficiency) without guaranteed trade-off; voluntary bias risks "endogeneity fatal flaw" per appendix.
- **Identification Concerns**: Staggered adoption demands event-study robustness to heterogenous trends; matching/IV essential but feasibility unproven.
- **Recommendation**: SKIP

**#5: The Métropole Effect — Urban Governance Consolidation and Local Economies**
- **Score**: 45/100
- **Strengths**: Interesting agglomeration/institutions link with firm/employment outcomes from Sirene; policy of enhanced urban powers has real stakes.
- **Concerns**: Tiny treated N (14 métropoles) underpowers DiD (fails ≥20-unit gate), with selection (largest cities) hard to match; clustered errors unreliable.
- **Novelty Assessment**: Moderate—urban scale lit abundant (e.g., city size), métropoles as test is niche but not boundary-pushing.
- **Top-Journal Potential**: Low. Underpowered with few clusters reads as "tiny N null" per appendix; lacks causal bite for top-5 excitement despite agglomeration tie-in.
- **Identification Concerns**: Extreme selection on unobservables (top metros vs. agglos); wild bootstrap may not salvage noisy estimates.
- **Recommendation**: SKIP

### Summary
This is a strong batch overall, with Idea 1 standing out as genuinely top-journal caliber due to its novelty, clean ID, and trade-off discovery—pursue it first as a potential field-changer on pork-barrel politics. Ideas 2 and 4 are competent policy evals worth considering if diagnostics hold, but the rest suffer fatal flaws like endogeneity or power. Prioritize designs with ≥20 treated units, long horizons, and mechanism maps to align with editorial patterns.

