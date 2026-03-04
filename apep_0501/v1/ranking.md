# Research Idea Ranking

**Generated:** 2026-03-04T11:51:19.440691
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Municipal Mergers and Direct Democracy: ... | PURSUE (78) | PURSUE (88) | PURSUE (84) |
| Green Building Mandates and the Construc... | PURSUE (62) | SKIP (42) | CONSIDER (68) |
| When School Starts Earlier: The HarmoS C... | CONSIDER (58) | SKIP (52) | SKIP (56) |

---

## GPT-5.2

**Tokens:** 5972

### Rankings

**#1: Municipal Mergers and Direct Democracy: The Political Cost of Administrative Consolidation in Switzerland**
- **Score: 78/100**
- **Strengths:** Excellent “universe” setting: hundreds of mergers, 500+ referendums, and decades of pre-periods make this unusually well-powered for political economy in local-government reform. The outcome (policy voting participation in a direct democracy) is institutionally distinctive relative to the municipal-merger literature, and multi-margin outcomes (turnout, invalid/blank, vote convergence) support a credible mechanism story.
- **Concerns:** Unit redefinition is the core risk: post-merger outcomes are observed on new boundaries, so effects can be mechanical unless the aggregation/reconstruction is handled transparently and robustly. Voluntary mergers are plausibly endogenous (declining engagement, fiscal stress, demographic change), so even with long pre-trends you’ll need strong diagnostics and possibly complementary designs/controls.
- **Novelty Assessment:** **Moderately high.** Municipal mergers are well-studied (esp. Scandinavia), but *federal referendums in a direct-democracy context* at this scale is much less saturated; the “universe × long horizon” angle is meaningfully differentiating.
- **Top-Journal Potential: Medium–High.** A top field journal (AEJ:EP) seems plausible if you frame it as a first-order trade-off (administrative efficiency vs. democratic participation) and deliver a tight causal chain (merger → identity/engagement proxies → participation). Top-5 potential exists but likely requires a belief-changing mechanism (e.g., persistent participation losses concentrated in absorbed communes, clear identity channel, and welfare/political-selection implications).
- **Identification Concerns:** Staggered DiD is credible only if you (i) show strong event-study flat pre-trends in reconstructed “constant-boundary” units, (ii) address endogenous timing (e.g., merger propensity predicted by pre-trends), and (iii) rule out compositional artifacts from boundary changes (population weights, turnout denominators, registration).
- **Recommendation:** **PURSUE (conditional on: constant-boundary outcome construction with multiple robustness variants; strong pre-trend and “timing endogeneity” diagnostics; a mechanism/heterogeneity package that distinguishes identity loss vs. rational scale effects).**

---

**#2: Green Building Mandates and the Construction Trade-off: Evidence from Swiss Cantonal Energy Codes**
- **Score: 62/100**
- **Strengths:** High policy relevance and clear welfare stakes (decarbonization vs. housing supply/costs). Administrative construction outcomes are well aligned with the policy’s direct bite, and the renovation-vs-new-construction substitution margin can yield a compelling “offset” narrative rather than a single ATE.
- **Concerns:** Effective treated-cluster count is small (≈8 cantons with the cited stagger), which is exactly where inference and robustness often collapse; municipality-level N does not solve canton-level policy clustering. Adoption may be endogenous to political preferences, energy prices, or concurrent housing/land-use constraints, making parallel trends hard to defend without extensive diagnostics and placebo policies.
- **Novelty Assessment:** **Medium.** Energy codes/green building standards have a large international literature; Switzerland is a nice setting, but the basic question is not new. Novelty would come from (i) unusually clean measurement of permits/renovations and (ii) a convincing construction-supply vs. retrofit substitution result.
- **Top-Journal Potential: Medium.** A top field journal is conceivable if you can credibly estimate magnitudes and show a sharp trade-off (or a surprising “no trade-off” with tight bounds) with a verified first stage (code adoption → measurable compliance/technology shift). Top-5 is less likely given limited clusters unless you add an additional quasi-experiment or unusually strong internal replication.
- **Identification Concerns:** Few clusters + staggered adoption creates fragile inference; you will likely need randomization inference / wild bootstrap and a design that anticipates endogenous adoption (pre-trend tests, leads, political controls, and ideally an additional source of quasi-random variation or policy discontinuity).
- **Recommendation:** **CONSIDER (upgrade to PURSUE if: you expand the treated set beyond the 8 cantons and/or add an internal replication layer—e.g., building-type exposure, pre-announcement timing, or a compliance/technology first-stage from EPC/heat-system data).**

---

**#3: When School Starts Earlier: The HarmoS Concordat and Female Labor Supply in Switzerland**
- **Score: 58/100**
- **Strengths:** The referendum accept/reject split is attractive for interpretability, and the triple-diff idea (mothers of affected ages vs. not) is conceptually strong. The question is policy-relevant and ties to a large literature on childcare/schooling and maternal labor supply.
- **Concerns:** Two big feasibility/identification threats: (i) treatment “dose” may be heterogeneous and partially adopted even in rejecting cantons (contaminating controls), and (ii) SAKE/ESPA may be too thin at canton × child-age cells to deliver precise, convincing event studies. Also, HarmoS ratification (2008–2010) with implementation deadlines around 2015/16 risks limited usable timing variation right when Switzerland hits broader macro shocks—making attribution harder.
- **Novelty Assessment:** **Medium–Low.** Earlier kindergarten/school entry effects on maternal labor are extensively studied internationally; a Swiss canton DiD is a context extension unless you uncover a distinctly Swiss mechanism (direct-democracy constraints, childcare market interactions, part-time equilibrium) or provide unusually clean exposure measurement.
- **Top-Journal Potential: Low–Medium.** A solid field-journal paper is possible if you can demonstrate strong first-stage exposure (actual enrollment/attendance changes at age 4) and deliver precise bounds. Top-5 is unlikely unless the result overturns a standard prior (e.g., large effects despite high baseline part-time norms) and the design is unusually tight.
- **Identification Concerns:** Control contamination and weak/uncertain first stage (did school starting age actually change, and for whom?) are primary; small samples for the key subgroup make nulls uninformative unless framed as powered equivalence/bounds with verified bite.
- **Recommendation:** **CONSIDER (conditional on: obtaining administrative enrollment/entry-age data to verify the first stage and constructing adequate sample sizes via pooled years / alternative datasets; otherwise SKIP).**

---

### Summary

This is a strong batch conceptually, with one clearly standout idea. The municipal mergers–direct democracy project is the most promising because it combines unusual institutional relevance with “universe-scale” data and enough events to support a mechanism-rich design. The green building codes and HarmoS ideas are both policy-relevant but face classic publication risks—few treated clusters (Idea 2) and weak/contaminated first-stage plus sample-size constraints (Idea 3)—so I would prioritize Idea 1 while trying to upgrade Idea 2 with stronger replication/first-stage measurement.

---

## Gemini 3.1 Pro

**Tokens:** 8552

Here is the evaluation and ranking of the research proposals, applying the criteria and the empirically observed editorial patterns.

### Rankings

**#1: Municipal Mergers and Direct Democracy: The Political Cost of Administrative Consolidation in Switzerland**
- **Score**: 88/100
- **Strengths**: This leverages "universe" administrative data over a 65-year horizon to test a highly legible, first-order trade-off (administrative efficiency vs. democratic engagement). The focus on direct democracy—where citizens vote on policy rather than politicians—provides a unique mechanism decomposition that differentiates it from standard local government consolidation papers.
- **Concerns**: Because these are "voluntary bottom-up mergers," the timing and decision to merge are inherently endogenous and likely correlated with local economic or political shocks. Furthermore, tracking absorbed communes post-merger requires meticulous data mapping to ensure the denominator (eligible voters) remains consistent.
- **Novelty Assessment**: High. While municipal mergers are well-studied regarding fiscal outcomes and representative election turnout, their impact on direct democratic participation is a genuinely open question. 
- **Top-Journal Potential**: High. This perfectly matches the editorial preference for "trade-off discovery" and "scale as scientific content." A top-5 journal would find the tension between state capacity/efficiency and democratic participation compelling, especially backed by 65 years of universe-level data and long-horizon event studies.
- **Identification Concerns**: The primary threat is the endogeneity of voluntary mergers; communes that choose to merge might be experiencing simultaneous unobserved shocks (e.g., financial distress, demographic decline) that independently depress voter turnout and violate parallel trends.
- **Recommendation**: PURSUE (conditional on: developing a robust strategy to address the endogeneity of voluntary merger timing, such as an IV, matching on pre-merger financial trajectories, or exploiting cantonal-level merger incentives as instruments).

**#2: When School Starts Earlier: The HarmoS Concordat and Female Labor Supply in Switzerland**
- **Score**: 52/100
- **Strengths**: The use of a referendum-rejected control group provides a conceptually clean counterfactual of cantons that considered the policy but opted out. The policy itself represents a significant, staggered shock to de facto childcare provision.
- **Concerns**: The Swiss Labour Force Survey (SAKE) is sample-based, meaning the cell sizes for the specific treated subgroup (mothers of 4-year-olds) at the canton-year level will likely be too small to detect anything but massive effects. Additionally, control cantons may have independently adjusted their school entry ages, contaminating the DiD design.
- **Novelty Assessment**: Low. The link between early childhood education/childcare expansion and maternal labor supply is one of the most heavily saturated topics in empirical labor economics (e.g., Havnes & Mogstad, Baker et al., Fitzpatrick, Bauernschuster & Schlotter). 
- **Top-Journal Potential**: Low. As noted in the editorial appendix, the modal loss is a "technically competent but not exciting" standard DiD with an unsurprising sign on a narrow outcome. Without a belief-changing pivot, this reads as a replication of known mechanisms in a new geography.
- **Identification Concerns**: Beyond the severe power issues due to sample size, the staggered DiD relies on the assumption that rejecting cantons didn't implement substitute policies, which is a known risk in decentralized Swiss education policy.
- **Recommendation**: SKIP

**#3: Green Building Mandates and the Construction Trade-off: Evidence from Swiss Cantonal Energy Codes**
- **Score**: 42/100
- **Strengths**: It addresses a highly relevant, first-order policy question—the tension between climate mandates and housing affordability/supply. The mechanism decomposition between new construction and renovation is a smart way to evaluate net welfare effects.
- **Concerns**: With only 8 treated cantons, the study is severely underpowered for cluster-robust inference, making it highly vulnerable to being dismissed as an uninterpretable null. Furthermore, the lack of guaranteed property price data limits the ability to estimate the actual welfare and affordability impacts.
- **Novelty Assessment**: Moderate. The trade-off between environmental regulation and housing supply is well-documented, though the specific Swiss cantonal variation offers a relatively fresh setting to test the renovation vs. new-build margins.
- **Top-Journal Potential**: Low. The editorial appendix explicitly warns against "underpowered 'nulls' that cannot rule out plausible magnitudes" and "few treated clusters where RI/robust DiD makes results insignificant." Top journals will reject this on power and inference grounds alone.
- **Identification Concerns**: The fundamental threat is the tiny effective N (8 treated clusters); standard errors will be too large to make confident claims, and early adopters are likely systematically different (e.g., greener, wealthier) from late/never adopters in ways that violate parallel trends.
- **Recommendation**: SKIP

### Summary

This batch contains one standout proposal and two fundamentally flawed ones. Idea 1 is exceptionally promising because it combines universe-scale data with a novel, legible trade-off (efficiency vs. direct democracy) that appeals directly to top-journal sensibilities regarding scale and mechanism. Ideas 2 and 3 suffer from fatal flaws empirically observed in rejected papers: Idea 2 has too few treated clusters for credible inference, and Idea 3 applies a standard DiD to a heavily saturated literature using likely underpowered survey data. I strongly recommend dedicating resources exclusively to Idea 1.

---

## Grok 4.1 Fast

**Tokens:** 5652

### Rankings

**#1: Municipal Mergers and Direct Democracy: The Political Cost of Administrative Consolidation in Switzerland**
- **Score**: 84/100
- **Strengths**: Exceptional scale with universe-level data on 700+ merger events across 65 years and 503 referendums, enabling precise event-study dynamics and mechanism tests (e.g., size vs. identity channels via placebos); uncovers a novel trade-off between administrative efficiency gains and direct democratic erosion in a unique institutional setting with global relevance.
- **Concerns**: Post-merger data mapping for absorbed communes requires flawless execution of the SwissCommunes package to avoid composition bias; multi-margin outcomes risk diluting the core story if not tightly linked to a single causal chain.
- **Novelty Assessment**: Highly novel—prior work is limited to small single-canton studies or representative democracy contexts (e.g., Denmark); no known papers on Swiss mergers' impact on direct policy voting at national scale.
- **Top-Journal Potential**: High. Fits editorial winners: "trade-off discovery" (efficiency vs. participation losses), massive scale as content (universe admin data ruling out small effects), niche direct-democracy test adjudicating free-riding/identity puzzles, with legible causal chain (merger → engagement drop → vote shifts) and policy counterfactuals.
- **Identification Concerns**: Staggered DiD credible with abundant events, long pre-periods, and never-/not-yet-treated controls, but must robustly handle heterogeneous treatment effects (HTEs) via Callaway/Sant'Anna and test parallel trends rigorously; disappearing units pose mechanical bias risk if mapping fails.
- **Recommendation**: PURSUE (conditional on: validating SwissCommunes mapping with manual spot-checks on 10% of events; pre-registering core specs including HonestDiD tests)

**#2: Green Building Mandates and the Construction Trade-off: Evidence from Swiss Cantonal Energy Codes**
- **Score**: 68/100
- **Strengths**: Addresses timely "green vs. affordable housing" trade-off with mechanism decomposition (new builds vs. renovations), using clean staggered cantonal variation in a high-quality data environment; municipal-level analysis boosts power.
- **Concerns**: Only 8 treated cantons risks underpowered inference even with wild bootstrap, potentially yielding imprecise nulls that can't rule out plausible magnitudes; property price data access uncertain, limiting welfare analysis.
- **Novelty Assessment**: Moderately novel—Swiss cantonal codes underexplored vs. saturated US building code literature, but core green mandate effects on construction/activity well-studied globally.
- **Top-Journal Potential**: Medium. Promising trade-off framing and policy stakes, but few clusters and familiar policy lever (energy codes → supply shifts) read as "competent DiD" without belief-changing scale or counterintuitive pivot; lacks the universe data or long-horizon bite of top winners.
- **Identification Concerns**: Staggered DiD vulnerable to few-cluster bias (needs RI/wild bootstrap); short post-periods (2010-2020) and potential anticipation effects untestable without fuller pre-data; municipality-level helps but requires defensible treatment assignment.
- **Recommendation**: CONSIDER (conditional on: confirming municipal-level power via simulations; securing property data or bounding welfare without it)

**#3: When School Starts Earlier: The HarmoS Concordat and Female Labor Supply in Switzerland**
- **Score**: 56/100
- **Strengths**: Clean referendum-based controls (rejectors as counterfactual) enable triple-diff on affected mothers, linking to established childcare-labor literature; differentiates from prior Swiss childcare work.
- **Concerns**: Control contamination from independent school age changes in rejectors undermines exogeneity; cantonal SAKE sample sizes too small for subgroups (e.g., mothers of 4yos), yielding underpowered estimates.
- **Novelty Assessment**: Low to moderate—school entry/childcare effects on maternal labor well-studied (e.g., German reforms, US literature); Swiss HarmoS angle incremental, not transformative.
- **Top-Journal Potential**: Low. Standard childcare-labor ATE without counterintuitive mechanism, substitution offset, or scale; risks "technically competent but unsurprising" rejection, especially vs. papers with tighter channels or universe data.
- **Identification Concerns**: Rejector cantons not plausibly exogenous (some mimicked policy anyway), risking selection bias; staggered timing over 6 years with sample-based outcomes invites pre-trends violations and low power; triple-diff helps but needs verified first-stage enrollment shifts.
- **Recommendation**: SKIP

### Summary
This is a strong batch with one standout (Idea 1) leveraging unmatched scale and a fresh institutional angle for top-journal excitement, while the others suffer from familiar topics, few clusters, or contamination risks typical of "competent but not exciting" papers. Pursue Idea 1 immediately as it best matches editorial patterns for trade-offs and universe data; reframe Idea 2 for more power before investing, and skip Idea 3 due to identification fragility.

