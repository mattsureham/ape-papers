# Research Idea Ranking

**Generated:** 2026-03-09T17:13:44.104354
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Losing Rural Tax Breaks and Voting for t... | PURSUE (67) | PURSUE (88) | PURSUE (70) |
| Maternity Ward Closures and Birth Outcom... | CONSIDER (59) | CONSIDER (55) | PURSUE (61) |
| The Loi NOTRe and Municipal Mergers: Eff... | SKIP (44) | SKIP (45) | SKIP (45) |

---

## GPT-5.4 (A)

**Tokens:** 8351

### Rankings

**#1: Losing Rural Tax Breaks and Voting for the Rassemblement National: The ZRR Reclassification of 2017**
- **Score:** 67/100
- **Strengths:** This is the most novel idea in the batch: a specific, sharp, national policy change with many treated communes and a politically salient outcome. The loser/gainer symmetry is attractive, and there is a plausible mechanism from place-based tax incentives → local economic activity → anti-system voting.
- **Concerns:** The timing is awkward: the reform was legislated in 2015, implemented in mid-2017, and partially phased out through 2020, so “pre” and “post” are not clean. Also, the broad claim “economic decline increases far-right voting” is already crowded; without a strong mechanism, this could look like a French replication of an existing theme.
- **Novelty Assessment:** **Moderately high.** I do not know of papers on this exact ZRR reclassification and RN voting margin. But the broader literature on economic shocks/austerity/place-based decline and populist voting is already large, so the novelty is in the policy setting and design, not in the underlying hypothesis.
- **Top-Journal Potential:** **Medium.** This could make a good AEJ: Economic Policy or strong field-journal paper if it cleanly shows a causal chain from tax-break loss to local economic contraction to RN vote gains. For a top-5, it likely needs to do more than document another distress→far-right result in one country.
- **Identification Concerns:** The main DiD comparison of losers vs stayers may fail if these places were already on different trajectories, and the 2015 announcement plus 2020 transition blur treatment timing. The RD angle is promising, but a two-threshold EPCI rule is harder to execute cleanly than a standard single-cutoff design, and the number of observations near the joint margin may be limited.
- **Recommendation:** **PURSUE** *(conditional on: making the cutoff-based design central rather than relying mainly on broad DiD; demonstrating a strong first stage on firm creation/employment; dealing explicitly with anticipation in 2015 and the transition through 2020)*

---

**#2: Maternity Ward Closures and Birth Outcomes in France**
- **Score:** 59/100
- **Strengths:** The outcome is first-order and policy-relevant: birth outcomes and access to obstetric care are much more general-interest than most local-policy topics. If done well, the paper has a strong causal chain—closure → longer travel time/capacity strain → neonatal risk—which is exactly the sort of narrative editors like.
- **Concerns:** As written, the identification is too weak. Maternity wards do not close randomly; they close where births are already falling, staffing is difficult, or quality concerns are rising, so a staggered DiD on closure timing is highly vulnerable to endogenous selection.
- **Novelty Assessment:** **Moderate.** There is already an international literature on hospital and obstetric-unit closures and maternal/infant outcomes. France-specific causal evidence is thinner, so the setting has value, but this is not a blank-slate topic.
- **Top-Journal Potential:** **Medium.** Substantively, this has the highest upside in the batch because mortality/birth outcomes are high-stakes and broadly legible. But no top journal will buy it on a generic staggered DiD alone; the design needs a much sharper quasi-experimental lever.
- **Identification Concerns:** Closure timing is plausibly driven by exactly the same local conditions that affect birth outcomes. Also, I am not convinced the stated data are sufficient: prematurity and low birth weight typically require health administrative microdata by maternal residence, not just état civil aggregates, and commune-level perinatal mortality will be noisy.
- **Recommendation:** **CONSIDER** *(ideally redesign around the 300-birth threshold or another closure rule; verify access to maternal-residence microdata with gestational age/birth weight before proceeding)*

---

**#3: The Loi NOTRe and Municipal Mergers: Effects on Local Public Spending and Tax Competition**
- **Score:** 44/100
- **Strengths:** The policy is important and large-scale, and administrative fiscal data should make a basic evaluation feasible. Spending and tax rates are outcomes that policymakers care about directly.
- **Concerns:** This is the least novel question and the weakest design as proposed. The municipal amalgamation literature is already crowded, and a simple merged-vs-unaffected DiD is not convincing because mergers were not random and the affected EPCIs were structurally different ex ante.
- **Novelty Assessment:** **Low to moderate.** French evidence may be less developed than the international literature, but the question—do local government mergers change spending/taxes?—has been studied many times in many settings.
- **Top-Journal Potential:** **Low.** In current form, this reads as a standard territorial-reform paper: competent, relevant, but not especially surprising. Without a sharp threshold, unexpected mechanism, or major welfare result, it is unlikely to clear top-journal excitement bars.
- **Identification Concerns:** Treated and untreated EPCIs are likely non-comparable because merger exposure was tied to size, geography, and prior institutional structure. “Public service quality” is also vague and may not be consistently measurable, which makes the paper feel diffuse rather than centered on one sharp outcome.
- **Recommendation:** **SKIP** *(unless you can build the paper around a sharp population threshold or another quasi-exogenous NOTRe rule rather than a broad DiD)*

### Summary

This is a decent batch, but only one idea is clearly worth pushing now. **Idea 1** is the best combination of novelty, feasible data, and a potentially publishable design, though it must be framed as a full causal chain rather than just another populism paper. **Idea 3** has higher substantive stakes but needs a major redesign around a cleaner source of exogenous variation; **Idea 2** is too incremental and too weakly identified in its current form.

---

## Gemini 3.1 Pro

**Tokens:** 7733

Here is the evaluation and ranking of the research proposals, applying the criteria and editorial patterns provided.

### Rankings

**#1: Losing Rural Tax Breaks and Voting for the Rassemblement National: The ZRR Reclassification of 2017**
- **Score**: 88/100
- **Strengths**: This perfectly matches the "first-order stakes + one sharp channel" winning formula by linking a highly salient political economy question (populist voting) to a sharp, exogenous policy shock. The proposed identification strategy is exceptionally strong, combining DiD, RD, and a symmetric placebo test on "gainers."
- **Concerns**: The economic mechanisms (business closures, employment drops) may be too slow to materialize between the July 2017 reform and the 2019/2022 elections. If economic outcomes don't move in time, the paper will have to rely on a "signaling/resentment" mechanism, which is harder to prove with administrative data.
- **Novelty Assessment**: High. While the "economic shock to populism" literature is large (e.g., trade shocks, austerity), isolating the specific withdrawal of a place-based tax subsidy is novel. It provides a much cleaner, dateable shock than broad macroeconomic trends.
- **Top-Journal Potential**: High. A top-5 journal would find this exciting because it uses a niche setting (French ZRR zones) to answer a general, high-stakes question. It moves beyond a simple ATE by offering a complete causal narrative and a symmetric test (do gainers vote less for the RN?), which editors love.
- **Identification Concerns**: The main threat is anticipation effects; since the law was passed in 2015, the April 2017 presidential election might not be a perfectly clean pre-treatment period if local mayors and voters reacted to the announcement rather than the implementation.
- **Recommendation**: PURSUE (conditional on: verifying that the 2017 election results were not already tainted by anticipation of the reform)

**#2: Maternity Ward Closures and Birth Outcomes in France**
- **Score**: 55/100
- **Strengths**: Addresses a highly emotive, first-order welfare question using excellent, granular administrative health data. The policy relevance for local healthcare provision and spatial inequality is undeniable.
- **Concerns**: The treatment (ward closure) is mechanically endogenous to local demographic decline, making causal claims highly suspect. Furthermore, the literature on hospital and maternity ward closures is heavily saturated.
- **Novelty Assessment**: Low. The effect of maternity ward closures on birth outcomes has been studied extensively in health economics across multiple countries (e.g., Sweden, US, UK), and similar studies already exist for the French context.
- **Top-Journal Potential**: Low. This reads as "technically competent but not exciting." Unless the paper overturns a canonical fact—for instance, by proving that closures actually *improve* outcomes due to the consolidation of medical expertise (the volume-outcome tradeoff)—it will struggle to stand out in a crowded field.
- **Identification Concerns**: Severe endogeneity. Wards are closed *because* they fall below the 300 births/year threshold, meaning treated communes are already on a downward demographic and economic trajectory compared to control communes, violating parallel trends.
- **Recommendation**: CONSIDER (conditional on: finding a strictly exogenous instrument for closure, or pivoting the framing to explicitly test the counter-intuitive "volume-outcome" quality tradeoff rather than just travel time)

**#3: The Loi NOTRe and Municipal Mergers: Effects on Local Public Spending and Tax Competition**
- **Score**: 45/100
- **Strengths**: Evaluates a major, structural French territorial reform using readily available, high-quality administrative fiscal data.
- **Concerns**: The literature on municipal mergers is extremely crowded, and the proposed outcomes (spending, taxes) are standard and uninspired.
- **Novelty Assessment**: Low. The fiscal effects of municipal consolidation have been studied to death across many countries (Denmark, Germany, Japan), and there are already multiple papers evaluating the Loi NOTRe specifically.
- **Top-Journal Potential**: Low. This is the textbook definition of a paper that is "technically competent but not exciting." It estimates a standard average treatment effect of a standard policy on standard outcomes, lacking the novel mechanism or counter-intuitive finding required for top-tier economics journals.
- **Identification Concerns**: "Unaffected" EPCIs are likely systematically different (e.g., larger, more urban) than those forced to merge, threatening the parallel trends assumption. Additionally, the exact choice of merger partners within the forced consolidation is highly endogenous.
- **Recommendation**: SKIP

### Summary

This batch presents one clear standout alongside two standard, heavily-studied topics. Idea 1 is an exceptionally promising proposal that leverages a sharp, multi-pronged identification strategy to answer a high-stakes political economy question, making it highly competitive for top journals. Ideas 2 and 3 suffer from saturated literatures and endogeneity issues, reading as competent but unexciting evaluations that are better suited for field journals or internal policy briefs; I strongly recommend prioritizing Idea 1.

---

## GPT-5.4 (B)

**Tokens:** 7784

### Rankings

**#1: Losing Rural Tax Breaks and Voting for the Rassemblement National: The ZRR Reclassification of 2017**
- **Score:** 70/100
- **Strengths:** This is the most novel of the three, with a real policy shock, thousands of losers and gainers, and a plausible mechanism from place-based tax incentives to local economic activity to voting. The data are unusually feasible: national election returns, treatment coding, and business-demography outcomes all exist at scale.
- **Concerns:** The biggest risk is timing: the reform was legislated before it took effect, so 2017 may not be a clean pre-period if communes already knew their future status. The transition period through 2020 also means the economic shock may be gradual, leaving only a thin post-treatment electoral window.
- **Novelty Assessment:** The exact question—ZRR reclassification and RN voting—appears largely unstudied. But the broader literature on economic shocks, place-based policy, and populist/far-right voting is already substantial, so the contribution is policy-specific rather than topic-defining.
- **Top-Journal Potential:** **Medium.** This could be attractive in a top field journal, and maybe higher if the paper nails a strong causal chain: **tax break loss → weaker firm formation/employment → higher RN vote**. For a top-5, the question is interesting but not obviously field-changing unless the first stages are strong and the design is very hard to attack.
- **Identification Concerns:** You need to establish the true treatment date as the date of information, not just implementation. The proposed RD is also not automatically clean: eligibility depends on two EPCI-level thresholds plus transition rules, so credibility will depend on a careful institutional audit and possibly a local-randomization/multidimensional RD strategy rather than a simple cutoff design.
- **Recommendation:** **PURSUE (conditional on: establishing whether 2017 is already post-treatment in voters’ information sets; adding a more consistent election panel and election-type strategy; showing strong first-stage effects on firms/employment)**

**#2: Maternity Ward Closures and Birth Outcomes in France**
- **Score:** 61/100
- **Strengths:** This has the biggest substantive stakes: infant health, travel time, and service access are first-order outcomes with clear welfare relevance. If identified well, the paper has a compelling and general causal chain: **ward closure → longer travel time / provider strain → birth outcomes**.
- **Concerns:** As written, the design is too weak relative to the question. Closure timing is likely endogenous to low volume, rural decline, staffing shortages, and underlying risk trends, all of which can affect outcomes directly; data feasibility is also shakier than stated, especially for prematurity and low birth weight at the commune level.
- **Novelty Assessment:** The French setting is not heavily mined in economics, but maternity/hospital closure effects on birth outcomes are already a well-studied topic in health economics and public health. So this is not highly novel unless the French institutional margin provides unusually clean identification.
- **Top-Journal Potential:** **Medium.** The outcome is top-journal sized, but the current design is not. A cleaner strategy tied to the 300-birth threshold, regulator rules, or a strong IV/RD could make this much more publishable and interesting.
- **Identification Concerns:** A staggered DiD around closures will struggle because closures are policy responses to local conditions, not plausibly exogenous shocks. You likely need individual-level birth data by maternal residence and a design exploiting the minimum-volume rule or other quasi-mechanical closure criteria.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you can obtain micro birth data and redesign around the 300-birth threshold or another clearly exogenous margin)**

**#3: The Loi NOTRe and Municipal Mergers: Effects on Local Public Spending and Tax Competition**
- **Score:** 45/100
- **Strengths:** The reform is large, the timing is clear, and fiscal outcomes are measurable with administrative data. There is enough treatment variation to estimate effects precisely if the design were stronger.
- **Concerns:** This is the least novel and the least exciting of the three. A simple DiD between merged and unmerged EPCIs is not very credible because merger exposure was shaped by pre-existing size, geography, exemptions, and political-administrative conditions; even a clean estimate would likely read as incremental.
- **Novelty Assessment:** Municipal consolidation and its effects on spending/tax competition are a mature literature. The French setting adds institutional detail, but not much conceptual novelty.
- **Top-Journal Potential:** **Low.** “Forced mergers changed spending/taxes” is unlikely to move a top journal unless the paper exploits a sharp threshold in the law and uncovers a surprising mechanism. As framed, this is a competent local public finance paper, not a frontier one.
- **Identification Concerns:** The control group is weak, and post-merger harmonization/accounting changes may mechanically move spending and tax measures. A threshold-based design around the law’s population rules would be much more credible than the proposed treated-vs-unaffected DiD.
- **Recommendation:** **SKIP**

### Summary

This is a mixed batch: one clearly worth pursuing, one worth salvaging with a major redesign, and one that is mostly incremental. I would **pursue Idea 1 first**, because it combines genuine policy-specific novelty with feasible data and a reasonably plausible design; I would **keep Idea 3 alive only if the team can secure better data and a sharper identification strategy**.

