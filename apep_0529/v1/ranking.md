# Research Idea Ranking

**Generated:** 2026-03-05T17:07:06.478879
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Scale Mismatch — National Consensus vs L... | PURSUE (73) | — | PURSUE (76) |
| Does the Green Backlash Travel Upward? L... | PURSUE (62) | — | CONSIDER (64) |
| Car Restrictions and the Rise of Anti-Gr... | SKIP (54) | — | SKIP (55) |
| Idea 1: Scale Mismatch — National Consen... | — | PURSUE (85) | — |
| Idea 2: Does the Green Backlash Travel U... | — | CONSIDER (58) | — |
| Idea 3: Car Restrictions and the Rise of... | — | SKIP (42) | — |

---

## GPT-5.2

**Tokens:** 5183

### Rankings

**#1: Scale Mismatch — National Consensus vs Local Conflict on French Low-Emission Zones (ZFE)**
- Score: 73/100
- Strengths: Unusually novel “two-level” political economy design: the same nationally legislated policy generates locally salient costs, allowing a tight test of when/where climate policy becomes politically divisive. The combination of (i) nationally comparable roll-call + speech measures and (ii) fine local election outcomes is a strong measurement contribution that can be packaged as a coherent causal chain (local exposure → local electoral shifts → national legislative behavior/polarization).
- Concerns: The identification story is doing a lot: ZFE mandate/timing is tied to pre-trends in pollution and urban structure (dense, left-leaning, higher-income metros), which are also directly related to polarization and party dynamics. The design risks reading as “many outcomes + staggered DiD” unless you clearly prioritize one main estimand and pre-specify a small set of mechanism tests.
- Novelty Assessment: **High.** There is broad literature on environmental regulation and voting, and some on LEZ/congestion charges, but the explicit *scale-mismatch* hypothesis with harmonized polarization indices at national vs local levels (plus text-based rhetoric) is much less saturated—especially in the French ZFE setting.
- Top-Journal Potential: **Medium–High.** Top outlets could like this if framed as a boundary test of a first-order puzzle (“why is climate policy nationally popular yet locally explosive?”) with a clean causal narrative and a small number of headline results. It drops to medium if it becomes a descriptive omnibus of polarization metrics without a design that convincingly rules out differential urban political trends.
- Identification Concerns: The key threat is **policy endogeneity and correlated trends**: pre-2019 pollution-driven mandates select big metros with distinct political trajectories, and local implementation details/timing may respond to local politics. You’ll need design elements beyond vanilla staggered DiD—e.g., exploiting **sharp regulatory thresholds/classifications**, very rich pre-trends/event studies, and “opponent-killer” placebos (other non-transport votes; placebo geographies; outcomes that should not move).
- Recommendation: **PURSUE (conditional on: a threshold-based or otherwise quasi-exogenous treatment assignment argument that survives pre-trend tests; a clearly prioritized main outcome + mechanism sequence rather than many parallel indices; credible handling of spillovers/commuting zones and heterogeneous implementation strictness).**

---

**#2: Does the Green Backlash Travel Upward? Local ZFE Exposure and National Climate Votes**
- Score: 62/100
- Strengths: A more legible causal chain than Idea 1: local exposure → MP behavior on national votes. If it works, it speaks directly to how geographically concentrated policy costs reshape national policymaking, which is a field-level political economy mechanism.
- Concerns: France has strong party discipline; deviations on roll-calls may be rare (limited signal), and the number of clearly “ZFE-relevant” roll-calls may be small—raising power and measurement issues. Also, within-MP changes in “exposure” may coincide with other constituency shocks (fuel prices/protests, local elections, COVID-era urban policy) that are hard to net out with MP×vote FE alone.
- Novelty Assessment: **Medium.** “Constituency exposure affects legislator voting” is a known idea; applying it to ZFEs is fresh, but the conceptual move is not new. The novelty hinges on showing that ZFE exposure creates *unexpected* cross-pressures within parties (not just left MPs vote green, right MPs don’t).
- Top-Journal Potential: **Medium.** Could place well if you show a sharp, surprising pattern (e.g., backlash among otherwise pro-climate parties; heterogeneous effects by car dependence/Crit’Air composition) and can tightly rule out confounds. If the result is small/unsurprising or underpowered, it risks “competent but not exciting.”
- Identification Concerns: Main threats are **time-varying constituency confounders** correlated with ZFE rollout/anticipation and **limited within-unit treatment variation** (many constituencies are always/never exposed; exposure changes may be gradual and endogenous to local implementation). You likely need an instrument (e.g., pre-period pollution classification thresholds) or a design focusing on “mandated-by-rule” timing to bolster exogeneity.
- Recommendation: **CONSIDER (best as a focused chapter/companion to Idea 1, or pursue standalone only if you can document enough roll-calls, meaningful variance in exposure over time, and a strong first-stage/“deviation” rate).**

---

**#3: Car Restrictions and the Rise of Anti-Green Voting — Evidence from French ZFEs**
- Score: 54/100
- Strengths: Clear policy relevance and an intuitively interpretable outcome (RN/Reconquête vs Greens), with feasible administrative election data and precise geo-matching of ZFE perimeters. If you can credibly isolate a local treatment effect, the headline is communicable to policymakers.
- Concerns: The proposed “inside vs just outside boundary” comparison is highly vulnerable to **sorting and structural discontinuities**: ZFE borders often coincide with city limits and sharp urban–suburban differences (income, density, immigrant share, car dependence), which drive voting trends irrespective of ZFEs. With only a few election waves (and national political shocks), parallel trends is a major risk, and the design could be reinterpreted as descriptive geography rather than causal.
- Novelty Assessment: **Medium–Low.** “Environmental/transport restrictions produce populist backlash” is an active area, and spatial DiD around policy boundaries is common; the French ZFE angle is incremental unless you add a stronger design (e.g., quasi-random eligibility thresholds, or compelling within-metro border discontinuities with extensive balance/continuity checks).
- Top-Journal Potential: **Low–Medium.** Without a sharper identification strategy, this is likely to be seen as another backlash DiD with predictable signs. It could still be publishable in a good field journal if the design is strengthened and you add mechanism/heterogeneity (car dependence, fleet composition, transit substitutes), but top-5 odds are modest.
- Identification Concerns: **Endogenous borders + differential trends** are the core threats; “near the boundary” does not guarantee comparability when the boundary is an administrative/urban form break. Spillovers (drivers living outside but commuting inside; media salience region-wide) further blur treatment/control.
- Recommendation: **SKIP (unless you can redesign around a quasi-experimental assignment—e.g., regulatory thresholds for ZFE mandates/strictness, or a credible within-agglomeration border discontinuity with strong continuity tests and rich controls).**

---

### Summary

This is a coherent batch centered on a timely policy with unusually good public data. The most promising path is **Idea 1**, because it offers a relatively novel, potentially top-journal framing (multi-level political conflict from a uniform national climate policy) *if* you can make the assignment/timing argument genuinely credible and keep the narrative tight. **Idea 2** is a useful, cleaner companion mechanism test but may be underpowered; **Idea 3** is the most standard and the most exposed to boundary endogeneity.

---

## Gemini 3.1 Pro

**Tokens:** 6881

Here is my evaluation of the research proposals, ranked from most to least promising, applying the criteria and editorial patterns provided.

### Rankings

**#1: Idea 1: Scale Mismatch — National Consensus vs Local Conflict on French Low-Emission Zones (ZFE)**
- **Score**: 85/100
- **Strengths**: Brilliant framing of a first-order policy puzzle (scale mismatch) that connects local implementation costs to national political polarization. The combination of text analysis (debate transcripts) and electoral data provides a compelling, multi-layered causal narrative.
- **Concerns**: The staggered DiD relies on air-quality exceedance rules, meaning early-adopter cities (e.g., Paris, Lyon) are systematically larger and more polluted than late-adopters, which likely correlates with divergent baseline political trends.
- **Novelty Assessment**: High. While the "green backlash" is widely discussed, quantifying the divergence between national consensus and local conflict using linked micro-data across governance levels is highly novel and pushes the frontier of environmental political economy.
- **Top-Journal Potential**: High. This fits the "First-order stakes + one legible causal channel" winning pattern perfectly. It elevates a standard policy evaluation into a broader, belief-changing contribution about the spatial distribution of transition costs and political friction.
- **Identification Concerns**: Parallel trends are a major threat because treatment timing is driven by air quality, which correlates with city size and demographics. You must demonstrate that the mandate threshold provides quasi-random variation (perhaps via an RDD around the exceedance cutoff) or use a robust synthetic control approach.
- **Recommendation**: PURSUE (conditional on: establishing robust pre-trends; addressing the endogeneity of the air-quality mandate timing).

**#2: Idea 2: Does the Green Backlash Travel Upward? Local ZFE Exposure and National Climate Votes**
- **Score**: 58/100
- **Strengths**: Offers a very clean, specific mechanism test (spillback to national legislators) with a tight identification strategy utilizing within-MP variation over time.
- **Concerns**: French parliamentary groups enforce notoriously strict party discipline; the actual variation in roll-call deviations may be too small to detect, leading to an underpowered null result.
- **Novelty Assessment**: Moderate. The upward spillback channel is under-theorized empirically, but as a standalone paper, it is essentially just one mechanism extracted from Idea 1.
- **Top-Journal Potential**: Medium to Low. While the identification is tighter, it risks falling exactly into the "competent but not exciting" category. Without the broader local-vs-national contrast of Idea 1, it reads as a narrow ATE on a niche outcome.
- **Identification Concerns**: The main threat is statistical power (a "thin tail" of variation) rather than endogeneity, given the MP fixed effects. Additionally, MPs might anticipate the ZFE backlash and change their behavior before the formal implementation date, muddying the event-study timing.
- **Recommendation**: CONSIDER (as a secondary paper or, ideally, merge it back into Idea 1 as the mechanism chapter).

**#3: Idea 3: Car Restrictions and the Rise of Anti-Green Voting — Evidence from French ZFEs**
- **Score**: 42/100
- **Strengths**: Focuses on a highly salient, easily understood local outcome with excellent, granular spatial data availability.
- **Concerns**: The proposed spatial DiD contains a fatal SUTVA violation: communes just outside the ZFE boundary are heavily treated because their car-dependent residents commute into the ZFE, making them an invalid control group.
- **Novelty Assessment**: Low. The "green backlash" literature is growing rapidly, and a standard spatial DiD on voting patterns is becoming a crowded, predictable space.
- **Top-Journal Potential**: Low. This reads exactly like the "modal loss" described in the appendix: a standard DiD with a predictable outcome, lacking a surprising mechanism, welfare counterfactual, or broader theoretical pivot.
- **Identification Concerns**: Severe SUTVA violations. The spatial DiD design is fundamentally flawed because the "control" units (peri-urban commuters) bear the brunt of the policy costs without receiving the local air quality benefits. 
- **Recommendation**: SKIP (unless completely reframed to explicitly exploit the commuter spillovers as the primary treatment effect, turning the SUTVA violation into the core mechanism).

### Summary

This batch contains one standout proposal (Idea 1) that brilliantly frames a standard policy evaluation as a broader political economy puzzle, giving it genuine top-5 potential. Idea 1 should be pursued immediately, provided the identification hurdles regarding endogenous treatment timing can be cleared. Idea 2 is a competent but narrow slice of Idea 1 that lacks standalone narrative ambition, while Idea 3 suffers from a fatal flaw in its proposed control group and should be discarded.

---

## Grok 4.1 Fast

**Tokens:** 4828

### Rankings

**#1: Scale Mismatch — National Consensus vs Local Conflict on French Low-Emission Zones (ZFE)**
- **Score**: 76/100
- **Strengths**: Tests a compelling scale-mismatch hypothesis (national consensus turning locally divisive) with matched indices across governance levels, paired with a clean staggered DiD and spillback mechanism test that forms a clear causal chain (local costs → electoral shifts → national vote deviations). Exceptional data feasibility across universe-level political, election, and air-quality sources enables precise measurement and long pre/post periods.
- **Concerns**: Multiple outcomes across levels risk diluting the core story into a descriptive kitchen-sink; national rhetoric analysis may be noisier and harder to causally link than vote-based measures.
- **Novelty Assessment**: Highly novel—scale-mismatch in climate policy is discussed anecdotally (e.g., in EU transport policy reviews), but no quantitative papers match national/local indices with staggered French ZFE variation; closest are cross-country or US energy backlash studies.
- **Top-Journal Potential**: High. Aligns with editorial wins on "first-order stakes + legible causal channel" (local backlash → national spillback) and mechanism surprise (consensus policy backfiring upward), with a puzzle-driven arc that challenges pol-econ wisdom on multi-level governance; could package as "rules out national polarization, pins it on local salience" with welfare implications for EU climate rollouts.
- **Identification Concerns**: Staggered DiD risks recentering bias if early/late ZFEs differ systematically beyond air quality (e.g., urban political leanings), though pre-trends and spillback placebo mitigate; national outcomes may confound with broader climate debates unrelated to ZFE.
- **Recommendation**: PURSUE (conditional on: prioritizing spillback as core mechanism and demoting rhetoric to appendix; validating parallel trends across all ZFE waves)

**#2: Does the Green Backlash Travel Upward? Local ZFE Exposure and National Climate Votes**
- **Score**: 64/100
- **Strengths**: Narrow, credible test of a specific upward spillback prediction using within-MP variation, leveraging the same rich French ZFE data for fast execution and precise constituency exposure measures.
- **Concerns**: Very narrow scope limits broader contribution, reading as a "standalone ATE" without local electoral intermediaries; limited votes/MPs with timing variation may underpower event studies.
- **Novelty Assessment**: Moderately novel—spillback mechanisms appear in pol-econ (e.g., US fracking representation), but ZFE-specific local-to-national link in Europe is unstudied; builds on Idea 1 but lacks scale-mismatch breadth.
- **Top-Journal Potential**: Medium. Solid mechanism test but risks "competent but not exciting" per appendix patterns, as it's a single channel without full causal chain or counterintuitive pivot; top field (AEJ:App) more likely than top-5 unless paired with welfare counterfactual on climate bill passage.
- **Identification Concerns**: Within-MP design assumes no concurrent shocks to constituency representation, but MP turnover or national events could confound; few treated MPs/votes threaten power, echoing appendix warnings on thin tails.
- **Recommendation**: CONSIDER (as a module within Idea 1 or standalone if power checks out)

**#3: Car Restrictions and the Rise of Anti-Green Voting — Evidence from French ZFEs**
- **Score**: 55/100
- **Strengths**: Clean spatial setup with granular bureau-level elections and GeoJSON boundaries for precise treatment; timely on vehicle-specific green backlash.
- **Concerns**: Boundary DiD invites endogenous sorting (ZFEs placed in high-pollution/political cities), yielding "cautionary tale" rather than causal contribution; lacks mechanism depth beyond ATE on vote shares.
- **Novelty Assessment**: Low to moderate—green backlash well-studied (e.g., German coal, US clean power plans), with vehicle restrictions getting some qualitative attention but few causal papers; spatial RDD/DiD variants exist in transport pol-econ.
- **Top-Journal Potential**: Low. Fits "modal loss" of unsurprising local ATE without mechanism decomposition, substitution insight, or policy counterfactual; competent for field journal at best, dismissed as "another backlash" without scale or surprise.
- **Identification Concerns**: Boundaries proxy deep urban/rural divides (appendix fatal flaw on endogenous BDD sorting); no pre-periods in some ZFEs and spillovers across boundaries undermine parallel trends.
- **Recommendation**: SKIP

### Summary
This is a strong batch overall, with Idea 1 standing out as genuinely promising due to its novel multi-level puzzle, tight identification, and top-journal arc on climate pol-econ spillbacks—worth pursuing as the anchor project. Ideas 2 and 3 are feasible add-ons or alternatives but lack the breadth and excitement to compete independently, risking rejection as narrow or flawed. Prioritize Idea 1 with its conditions to maximize impact.

