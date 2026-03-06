# Research Idea Ranking

**Generated:** 2026-03-06T17:37:46.923868
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| When the Train Doesn't Come: The Propert... | PURSUE (75) | PURSUE (88) | PURSUE (73) |
| Speed Kills Less at 20mph: The Welsh Def... | CONSIDER (67) | CONSIDER (58) | CONSIDER (68) |
| Does Regulating Private Landlords Raise ... | None (55) | SKIP (45) | SKIP (55) |

---

## GPT-5.4 (A)

**Tokens:** 10646

### Rankings

**#1: When the Train Doesn't Come: The Property Value Destruction of HS2's Northern Cancellation**
- **Score:** 75/100
- **Strengths:** This is the most novel idea in the batch: a rare chance to study the *reversal* of anticipated infrastructure benefits rather than the usual construction/opening effects. The Land Registry universe data, same-project Phase 1 comparison, and distance-gradient design give it a stronger empirical backbone than a standard transit-capitalization paper.
- **Concerns:** The key empirical risk is that the cancellation was not fully a surprise after years of HS2 political uncertainty, so much of the repricing may have happened before October 2023. Also, the sign is not mechanically negative everywhere: cancellation removes expected access gains near stations but may also remove route blight/noise/acquisition risk.
- **Novelty Assessment:** **High.** I know a large literature on transport capitalization, but much less on infrastructure *cancellation* and expectation destruction; I do not know of a well-known economics paper on this exact shock.
- **Top-Journal Potential:** **Medium.** This could be a strong AEJ: Economic Policy / top field-journal paper if framed as a paper on infrastructure credibility and capitalized expectations, not just “house prices near stations fell.” For a top-5, it would need a broader conceptual punch—e.g., separating lost accessibility premiums from relief from corridor blight, and speaking to how markets price government promises.
- **Identification Concerns:** You need to convincingly show limited anticipation and rule out earlier repricing using long event-time diagnostics and contemporaneous news evidence. Inference also needs to respect the small number of treated geographies and spatial correlation; repeat-sales or rich hedonic controls are important because transaction composition can shift.
- **Recommendation:** **PURSUE** *(conditional on: documenting the surprise/limited anticipation of the October 2023 announcement; separating station-access effects from corridor-blight effects; using spatially robust inference and repeat-sales or rich hedonic specifications)*

---

**#2: Speed Kills Less at 20mph: The Welsh Default Speed Limit and Road Casualties**
- **Score:** 67/100
- **Strengths:** This has a first-order outcome—road casualties—and good administrative data. The proposal is smart to triangulate across border DiD, border RDD, and within-Wales variation rather than relying on a single design.
- **Concerns:** The short post period is a real limitation, especially for fatal and serious crashes where power will be weak. Treatment is also messier than the headline policy suggests because exemptions, enforcement, and compliance differ across roads and places.
- **Novelty Assessment:** **Medium.** I do not know of a peer-reviewed economics paper on the Welsh 20mph reform itself, but speed-limit effects on traffic safety are already a very crowded literature.
- **Top-Journal Potential:** **Medium.** A clean, well-powered estimate showing either surprisingly small effects or substantial gains could be publishable in AEJ:EP or a strong field journal. But for a top-5, this likely looks too much like another speed-limit evaluation unless it uncovers a broader mechanism about compliance, enforcement, or policy salience.
- **Identification Concerns:** The border designs are the credible core, but only if you can precisely identify roads actually affected by the default change and handle cross-border spillovers. The within-Wales dose-response piece is much weaker because implementation intensity is partly chosen, not exogenous.
- **Recommendation:** **CONSIDER**

---

**#3: Does Regulating Private Landlords Raise Property Values? Selective Licensing in England**
- **Score:** 55/100
- **Strengths:** The policy is relevant and under-studied in mainstream economics, and the number of adoptions creates a potentially useful panel. There is a plausible mechanism story if one can separate neighborhood amenity improvements from landlord-cost capitalization.
- **Concerns:** As written, the treatment definition is too coarse: many selective licensing schemes are neighborhood-targeted, so LA-level DiD likely creates serious mismeasurement. Adoption is also highly endogenous to neighborhood decline, anti-social behaviour, and housing problems, which makes the proposed design hard to believe.
- **Novelty Assessment:** **Medium.** The exact English selective licensing regime is not heavily studied in economics, but adjacent literatures on landlord regulation, housing-code enforcement, neighborhood disorder, and property prices are not empty. The topic feels niche rather than field-shifting.
- **Top-Journal Potential:** **Low.** In current form this reads as a competent local-policy DiD, not a paper that would change how economists think about housing regulation. Without

---

## Gemini 3.1 Pro

**Tokens:** 5924

### Rankings

**#1: When the Train Doesn't Come: The Property Value Destruction of HS2's Northern Cancellation**
- **Score**: 88/100
- **Strengths**: This brilliantly flips the saturated transit capitalization literature on its head by measuring the *destruction* of anticipatory premiums, turning a massive policy reversal into a natural experiment. Using the surviving Phase 1 corridor as a within-project control group is an exceptionally sharp and credible identification strategy.
- **Concerns**: The post-period is relatively short, meaning the estimates might capture a temporary market freeze or liquidity dry-up rather than the long-run equilibrium price adjustment. 
- **Novelty Assessment**: Very high. While infrastructure construction is studied to death, infrastructure *cancellation* and the unwinding of policy uncertainty/anticipatory pricing is genuinely understudied. 
- **Top-Journal Potential**: High. This perfectly fits the "first-order stakes + one sharp causal channel" archetype. It uses universe-scale data to resolve a general puzzle about anticipatory pricing and policy uncertainty, elevating it far beyond a standard transit paper.
- **Identification Concerns**: The primary threat is that the North (Phase 2) and the Midlands/South (Phase 1) are subject to different macroeconomic or regional shocks independent of HS2. However, the built-in distance-gradient dose-response largely neutralizes this threat.
- **Recommendation**: PURSUE

**#2: Speed Kills Less at 20mph: The Welsh Default Speed Limit and Road Casualties**
- **Score**: 58/100
- **Strengths**: The proposal outlines a highly competent, robust triple-identification strategy (cross-border DiD, spatial RDD, dose-response) using excellent universe-level administrative data. It addresses a highly salient public policy with clear welfare implications.
- **Concerns**: The core finding—that driving slower reduces accidents—is entirely expected and dictated by basic physics, lacking any surprising economic mechanism. Furthermore, the post-period is too short to achieve statistical power on rare outcomes like fatal collisions.
- **Novelty Assessment**: Low to Medium. The specific Welsh policy is new, but the relationship between speed limits and traffic casualties is one of the most heavily saturated topics in transport economics and public health.
- **Top-Journal Potential**: Low. This is the textbook definition of "technically competent but not exciting." It estimates a standard ATE for a well-understood mechanism without challenging conventional wisdom or revealing a new conceptual object.
- **Identification Concerns**: Spatial sorting and route substitution are major threats; drivers may simply shift to unregulated roads, meaning the spatial RDD might just capture accident displacement rather than a true reduction.
- **Recommendation**: CONSIDER (conditional on: pivoting the outcome to a surprising mechanism, such as economic costs via travel time, route substitution/spillovers, or political backlash/voting behavior, rather than just an ATE on casualties)

**#3: Does Regulating Private Landlords Raise Property Values? Selective Licensing in England**
- **Score**: 45/100
- **Strengths**: It attempts to evaluate a widespread local policy using modern staggered DiD estimators and a large, high-quality dataset.
- **Concerns**: Local authorities adopt selective licensing endogenously—almost always in response to deteriorating neighborhood conditions or spikes in anti-social behavior—making parallel trends highly unlikely. The policy itself is also a "diffuse package" of fees and standards, making it hard to isolate a specific causal channel.
- **Novelty Assessment**: Low. Housing regulations and licensing schemes have been studied extensively, and looking at property value impacts is the most standard approach possible.
- **Top-Journal Potential**: Low. It lacks a sharp causal channel, addresses a relatively niche local policy, and does not crack a broader general puzzle. It would likely be rejected at top journals as a standard, endogenous local policy evaluation.
- **Identification Concerns**: Severe endogeneity in policy adoption. LAs that consult and adopt are on fundamentally different unobservable trajectories than those that do not, and standard staggered DiD cannot fix this dynamic selection into treatment.
- **Recommendation**: SKIP

### Summary

This is a top-heavy batch with one standout proposal. **Idea 1 (HS2 Cancellation)** is a superb, top-tier research design that cleverly uses a major policy reversal to test anticipatory pricing, and it should be pursued immediately before others write it. Ideas 2 and 3 suffer from the classic "competent but not exciting" problem; they propose standard ATE evaluations of well-understood mechanisms and lack the surprising angles or identification rigor required for top-tier economics publications.

---

## GPT-5.4 (B)

**Tokens:** 7448

### Rankings

**#1: When the Train Doesn't Come: The Property Value Destruction of HS2's Northern Cancellation**
- Score: 73/100
- Strengths: This is the most novel idea in the batch: infrastructure *cancellation* is much less studied than infrastructure construction, and the setting speaks directly to whether markets had capitalized anticipated accessibility gains. The data are excellent, and using Phase 1 as a within-project comparison is a smart instinct.
- Concerns: The paper could easily become “another transit capitalization study” unless it leans hard into the expectation-reversal/cancellation angle. Identification is also less clean than it first appears because station areas and route-corridor areas may have opposite effects: losing a station hurts, but removing route blight/noise/compulsory purchase risk could help.
- Novelty Assessment: Exact topic is genuinely understudied. The broader literature on transit and property prices is crowded, but I do not know of an established academic literature on HS2 Phase 2 cancellation effects specifically, and cancellations are rare enough to make this a real contribution.
- Top-Journal Potential: **Medium.** This could be a strong AEJ: Economic Policy / JUE-type paper, and maybe higher if framed as a paper about infrastructure credibility and anticipatory capitalization rather than simply house prices near stations. For top-5, it would likely need a sharper causal chain such as cancellation → loss of expected accessibility → lower property values / firm entry / local activity, with compelling heterogeneity and mechanism evidence.
- Identification Concerns: The key threat is anticipation: markets may have revised expectations before 4 October 2023 given years of political uncertainty around HS2. You also need to separate station-access effects from route-blight relief and address transaction-composition bias with repeat-sales, hedonic controls, or both.
- Recommendation: **PURSUE (conditional on: separating station-area and route-corridor effects; documenting the surprise/no-anticipation margin with news/search/listings evidence; using repeat-sales or rich property-level controls)**

**#2: Speed Kills Less at 20mph: The Welsh Default Speed Limit and Road Casualties**
- Score: 68/100
- Strengths: This has the cleanest outcome-policy match in the batch: the policy is about traffic speed and safety, and STATS19 is a serious administrative dataset. The multi-design approach is sensible, and the England-Wales border gives the project a more compelling counterfactual than the usual before-after government monitoring.
- Concerns: The question is important but not especially novel in the broader literature, because speed limits and road safety are already heavily studied. The short post period is a real limitation, and casualty counts can be noisy enough that even a decent design may yield imprecise or contestable estimates.
- Novelty Assessment: The Welsh reform itself is new and likely not yet well covered in peer-reviewed causal work. But the general topic—do lower speed limits reduce crashes and injuries?—is a mature literature, so this is incremental rather than field-defining.
- Top-Journal Potential: **Medium.** Editors like immediate, welfare-relevant outcomes like casualties, and a clean border-based design could make this attractive for AEJ: Economic Policy or a strong public/transport field journal. It is unlikely to be top-5 unless it overturns the current policy narrative or shows a striking mechanism, such as large effects despite limited enforcement or strong heterogeneity by road type and pedestrian exposure.
- Identification Concerns: You should not treat all urban Wales as uniformly treated; the crucial object is which roads actually shifted from 30 to 20 and where exemptions applied. Border comparisons may still absorb differential traffic, enforcement, and reporting trends, and the short post window limits trend diagnostics.
- Recommendation: **CONSIDER**

**#3: Does Regulating Private Landlords Raise Property Values? Selective Licensing in England**
- Score: 55/100
- Strengths: There is a real policy question here, lots of treatment variation, and the data are feasible. If measured at the right geographic scale, the paper could speak to neighborhood quality, landlord compliance costs, and capitalization.
- Concerns: As written, this is the weakest design. Selective licensing is adopted precisely in places with private-rental problems, anti-social behaviour, and often weak local housing markets, so endogeneity is severe; LA-level treatment timing is too coarse for a policy that is often targeted to specific neighborhoods.
- Novelty Assessment: The exact national property-price angle may be understudied, but the broader space—landlord regulation, housing quality enforcement, rental market interventions, and neighborhood outcomes—is already fairly populated. So novelty is modest, not high.
- Top-Journal Potential: **Low.** In current form this reads as a competent staggered-DiD evaluation of a local housing policy, not a paper that would change how the field thinks. Without much sharper geographic treatment measurement and a stronger mechanism, it is unlikely to clear the excitement threshold for top journals.
- Identification Concerns: Staggered DiD does not rescue a design where adoption responds to deteriorating local trends. You would need scheme-level polygons, within-LA comparisons, and probably boundary/event-study evidence to make the design credible.
- Recommendation: **SKIP**

### Summary

This is a decent batch, but only one idea clearly stands out. I would pursue the HS2 cancellation project first because it is the most novel and has the best chance of becoming more than a routine policy evaluation if framed around infrastructure credibility and expectation reversal. The Wales 20mph idea is worth considering as a solid field-journal project; the selective licensing idea is too endogenous and too diffuse in its current form.

