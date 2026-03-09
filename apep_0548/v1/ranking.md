# Research Idea Ranking

**Generated:** 2026-03-09T09:38:04.930892
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Does Regulating Private Landlords Raise ... | PURSUE (67) | PURSUE (82) | PURSUE (71) |
| No-Fault Eviction Abolition and Private ... | CONSIDER (56) | CONSIDER (68) | CONSIDER (62) |
| Universal Credit Full Service and the Bo... | SKIP (51) | SKIP (52) | SKIP (48) |

---

## GPT-5.4 (A)

**Tokens:** 7938

### Rankings

**#1: Does Regulating Private Landlords Raise Property Values? Selective Licensing and Housing Markets in England**
- Score: **67/100**
- Strengths: This is the most promising of the three because the policy is relatively under-studied, the outcomes are economically meaningful, and the setting offers many staggered adoptions over a long period. If executed with precise treatment geography, it could speak to an important housing question: whether landlord regulation creates neighborhood-quality gains that capitalize into prices or instead depresses market activity.
- Concerns: The biggest issue is that selective licensing is typically **area-specific within local authorities**, not LA-wide, so an LA-level treatment design risks serious measurement error and attenuation. Adoption is also likely targeted at troubled neighborhoods, so a simple staggered DiD could mistake mean reversion or pre-existing decline for treatment effects.
- Novelty Assessment: **Fairly novel.** I know of little causal evidence on national housing-market effects of England’s selective licensing schemes; most related work is descriptive, local, or focused on health rather than prices/supply/disorder.
- Top-Journal Potential: **Medium.** This could plausibly be an **AEJ: Economic Policy / JUE-style** paper if it cleanly links licensing to neighborhood externalities and then to prices or market activity. It is less obviously top-5 unless the paper reframes the setting as a broader test of whether landlord regulation improves housing quality enough to offset supply-side distortions.
- Identification Concerns: The proposal overstates the cleanliness of the variation: scheme placement is endogenous, and treatment intensity varies enormously across areas. I would want exact scheme boundaries, within-LA comparisons, event studies, and ideally a boundary-based or matched untreated-area design rather than LA adoption alone.
- Recommendation: **PURSUE (conditional on: obtaining exact scheme boundaries and timing; using sub-LA treatment assignment rather than LA-level adoption; adding a sharper mechanism test on disorder/quality and, ideally, PRS exposure)**

**#2: No-Fault Eviction Abolition and Private Rental Supply: Evidence from Wales**
- Score: **56/100**
- Strengths: The question is important, politically live, and genuinely novel. Wales moving ahead of England creates a natural policy contrast on an issue with broad international relevance.
- Concerns: As written, the outcome is poorly matched to the question: **Land Registry prices and sales volumes are not clean measures of private rental supply**. More seriously, the Welsh reform is a **bundled tenancy reform**, not a clean “Section 21 only” shock, and Wales is effectively one treated polity with a short post-period during an unusually volatile housing market.
- Novelty Assessment: **Highly novel.** I am not aware of a mature causal literature on the Welsh reform specifically, and certainly not much on this exact policy window.
- Top-Journal Potential: **Low.** The stakes are high, but in the current form this would read as a one-country policy comparison with indirect outcomes and weak separation of mechanisms. With better supply data and a sharper border/synthetic-control strategy, it could become much more interesting.
- Identification Concerns: Inference is hard because treatment occurs at the country level, not across many independent treated clusters. Concurrent Welsh-specific policy differences, the bundled nature of the Renting Homes Act, and the 2022–24 interest-rate/housing shock make a simple Wales-vs-England DiD fragile.
- Recommendation: **CONSIDER (conditional on: replacing Land Registry outcomes with rental listings / tenancy-deposit / EPC / PRS-stock measures; treating the intervention as a broader tenancy-rights reform unless no-fault can truly be isolated; using border or synthetic-control evidence as the main design)**

**#3: Universal Credit Full Service and the Bottom of the Wage Distribution**
- Score: **51/100**
- Strengths: The policy stakes are first-order, and the question goes to the heart of UC’s stated work-incentive logic. The rollout covered most of Great Britain and has enough temporal variation to support standard policy-evaluation designs.
- Concerns: This is the most crowded topic area of the three, and the proposed outcome is weak. LA-level p10/p20 wages are a noisy, indirect object for a claimant-targeted reform; even a real effect on employment, hours, or earnings among exposed households may not show up cleanly in local wage percentiles.
- Novelty Assessment: **Limited.** The exact outcome may be less studied, but Universal Credit rollout has already generated a substantial literature, so this risks looking like another thin slice of a well-mined policy.
- Top-Journal Potential: **Low.** In its current form, this looks like a competent reduced-form exercise rather than a paper that would shift how the field thinks about welfare reform. Without claimant-level or worker-level earnings/hours data, it is hard to see this getting beyond a modest contribution.
- Identification Concerns: Rollout timing may not be fully orthogonal to local conditions, and aggregated percentile data confound treatment effects with composition changes. With only LA-year summaries, the design will struggle to demonstrate parallel trends or illuminate mechanisms.
- Recommendation: **SKIP (unless the team can get claimant- or worker-level earnings/hours data and exploit a sharper exposure measure than LA rollout timing alone)**

### Summary

This is a **mixed batch**: one idea is plausibly worth pursuing, while the other two need substantial redesign to become convincing. I would pursue **Idea 1 first**, but only if the team can move from LA-level adoption to exact scheme-level geography; **Idea 3** is more novel and potentially more exciting than Idea 2, but currently suffers from a serious outcome/design mismatch; **Idea 2** is the weakest because it combines a crowded literature with a low-information outcome.

---

## Gemini 3.1 Pro

**Tokens:** 7136

Here is my evaluation of the research proposals, ranked from most to least promising based on the provided criteria.

### Rankings

**#1: Does Regulating Private Landlords Raise Property Values? Selective Licensing and Housing Markets in England**
- **Score**: 82/100
- **Strengths**: Exploits a massive, underutilized quasi-experiment (100+ local authorities) with excellent administrative data (24M+ transactions) and built-in placebos (commercial properties). It links a major regulatory intervention to hard, economically legible outcomes (prices, crime).
- **Concerns**: Local authorities likely adopt licensing schemes in response to deteriorating local conditions (e.g., spiking anti-social behavior or falling prices), which could violate parallel trends. 
- **Novelty Assessment**: Very high. It is genuinely surprising that a policy of this scale has not been causally evaluated for its primary market impacts in the economics literature. 
- **Top-Journal Potential**: High. It fits the winning "first-order stakes + one sharp channel" pattern. If the paper can document a surprising mechanism—such as licensing driving out amateur landlords, leading to gentrification, or showing that compliance costs are fully passed through to property values—it would be highly competitive for a top-5 or top field journal.
- **Identification Concerns**: Endogenous adoption timing is the primary threat; LAs do not adopt randomly. The design will heavily rely on event-study plots to rule out Ashenfelter's dip dynamics and the credibility of the commercial property placebo.
- **Recommendation**: PURSUE (conditional on: passing pre-trend tests for endogenous adoption; ideally securing data on rental prices to complement transaction prices).

**#2: No-Fault Eviction Abolition and Private Rental Supply: Evidence from Wales**
- **Score**: 68/100
- **Strengths**: Addresses a highly topical, first-order policy question (eviction bans) using a clean, sharp legislative change. The data is highly feasible and the policy relevance is immediate given ongoing debates over the Renters (Reform) Bill in England.
- **Concerns**: With only 22 treated units, statistical power is a major concern, and Wales-specific macro shocks could easily confound the difference-in-differences estimate.
- **Novelty Assessment**: High for the UK context. While eviction moratoria have been studied in the US (especially during COVID), a permanent legislative abolition of no-fault evictions is a rare and valuable quasi-experiment.
- **Top-Journal Potential**: Medium. The policy stakes are excellent, but the small N and potential for macro confounding make it a tough sell for a top-5 journal. It is more likely to land in a top field journal like *AEJ: Economic Policy* or the *Journal of Urban Economics*.
- **Identification Concerns**: 22 treated units is below the comfort zone for standard clustered standard errors, requiring wild cluster bootstrap or permutation inference. The border-county subsample helps with macro confounding but further reduces statistical power.
- **Recommendation**: CONSIDER

**#3: Universal Credit Full Service and the Bottom of the Wage Distribution**
- **Score**: 52/100
- **Strengths**: Tests the core theoretical mechanism of Universal Credit (labor supply and wage incentives) using a plausibly exogenous IT-driven rollout schedule.
- **Concerns**: Relying on LA-level aggregated wage percentiles severely limits the ability to detect effects, explore mechanisms, or account for compositional changes in the labor force.
- **Novelty Assessment**: Low to Medium. The Universal Credit rollout has been heavily mined by researchers for various outcomes (crime, health, housing). While this specific outcome is relevant, it feels like a residual slice of an already crowded literature.
- **Top-Journal Potential**: Low. This fits the "technically competent but not exciting" losing pattern. Without microdata to show individual-level transitions, hours worked, or a surprising mechanism, it reads as a standard ATE on a noisy aggregate proxy.
- **Identification Concerns**: LA-level percentiles may mask significant compositional changes (e.g., people entering the labor force at the bottom diluting the wage percentiles). Furthermore, DWP's IT readiness might correlate with local state capacity or unobserved economic conditions.
- **Recommendation**: SKIP

### Summary

This is a solid batch of proposals, but Idea 1 stands out significantly from the rest. Idea 1 offers a rare combination of an understudied, large-scale policy with excellent administrative data and clear economic mechanisms, making it highly promising for a top journal. Idea 3 is highly policy-relevant but suffers from small-N limitations, while Idea 2 is fundamentally handicapped by its reliance on aggregated data in an already crowded literature. I strongly recommend prioritizing Idea 1.

---

## GPT-5.4 (B)

**Tokens:** 7874

### Rankings

**#1: Does Regulating Private Landlords Raise Property Values? Selective Licensing and Housing Markets in England**
- **Score:** 71/100
- **Strengths:** This is the best mix of novelty, policy relevance, and feasible hard outcomes. The policy is under-studied, the housing-price data are excellent, and the setting offers many adoptions over a long horizon with outcomes that policymakers actually care about.
- **Concerns:** As written, the design likely treats adoption as LA-wide when selective licensing is usually neighborhood-specific; that creates serious treatment-mismeasurement and dilution. Adoption is also clearly targeted toward troubled PRS areas, so a naive staggered DiD at the LA level is not credible.
- **Novelty Assessment:** Fairly novel. I know of very little causal work on national housing-market effects of England’s selective licensing schemes, though the broader literature on landlord regulation and housing quality is not new.
- **Top-Journal Potential:** **Medium.** This could be an AEJ: Economic Policy / JPubE-type paper if framed as housing-quality regulation → neighborhood externalities → capitalization into prices. For top-5, you would need a sharper treated-area design and a clearer mechanism than “licensing affects prices.”
- **Identification Concerns:** The main threat is endogenous targeting: schemes are introduced in places with deteriorating housing conditions and ASB. Also, repeated schemes, renewals, and partial geographic coverage make a simple staggered LA-level treatment indicator inappropriate.
- **Recommendation:** **PURSUE (conditional on: obtaining exact scheme boundaries and start dates; estimating effects at the treated-neighborhood/postcode level or with boundary comparisons rather than LA-wide treatment; showing one sharp mechanism such as ASB or housing complaints)**

**#2: No-Fault Eviction Abolition and Private Rental Supply: Evidence from Wales**
- **Score:** 62/100
- **Strengths:** This is the most novel and most topical idea in the batch. The policy stakes are first-order, and Wales offers a rare early reform that could speak directly to England’s ongoing debate.
- **Concerns:** The proposed outcomes do not really measure rental supply. Land Registry transaction volumes and prices may capture landlord exit only indirectly, and the post-2022 environment is full of confounding housing and interest-rate shocks.
- **Novelty Assessment:** Very novel for this exact reform. The broader literature on eviction rules and rental supply is substantial, but the Welsh abolition itself appears largely unstudied.
- **Top-Journal Potential:** **Medium-Low.** The question is top-journal caliber in principle, but not with these outcomes. If you had direct rental listings, landlord registrations, deposits, or tenancy starts, this could become much more compelling.
- **Identification Concerns:** Wales is effectively one treated jurisdiction, even if there are 22 LAs. Border-county comparisons help, but they do not fully solve Wales-specific contemporaneous shocks, anticipation effects, or pre-existing institutional differences.
- **Recommendation:** **CONSIDER (conditional on: replacing transaction outcomes with direct rental-supply measures; building a border-focused design; and addressing anticipation/short-post-period concerns explicitly)**

**#3: Universal Credit Full Service and the Bottom of the Wage Distribution**
- **Score:** 48/100
- **Strengths:** The policy is important, and the work-incentive question is economically meaningful. The rollout does provide broad geographic variation, and policymakers would care about credible evidence on whether UC changed low-end earnings.
- **Concerns:** This is a crowded policy area, and LA-level ASHE percentile wages are a weak outcome for the population UC actually affects. Even with a decent rollout design, the first-stage exposure is partial and the expected effect on aggregate local wage percentiles is likely very small and hard to interpret.
- **Novelty Assessment:** Low-to-moderate. The exact p10/p20 wage-distribution angle may be less studied, but Universal Credit itself—especially its labor-market consequences—has already been heavily examined.
- **Top-Journal Potential:** **Low.** This reads as a narrow margin on a very well-studied reform using aggregated outcomes, not a new object or a decisive resolution of an active debate. A top journal would likely ask for claimant-level or payroll microdata.
- **Identification Concerns:** Rollout timing is not obviously exogenous to local labor-market conditions in a way that cleanly identifies wage effects, and annual percentile wages confound wages with selection into employment. A change in p10 pay could reflect who is working, not what jobs pay.
- **Recommendation:** **SKIP** *(unless you can obtain claimant-level or RTI-style earnings microdata and measure treatment intensity for the actually exposed population)*

### Summary

This is a decent batch, but only one idea is clearly worth pushing now. I would pursue **Idea 1** first, but only after redesigning it around exact scheme boundaries rather than LA-wide adoption. **Idea 3** is the most novel and policy-salient, but it needs much better outcome data; **Idea 2** is the weakest because it targets a crowded reform with an outcome that is too aggregated and too weakly connected to treatment.

