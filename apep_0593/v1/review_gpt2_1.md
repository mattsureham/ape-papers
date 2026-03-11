# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T11:08:48.710318
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 18927 in / 4842 out
**Response SHA256:** a3db7f035e740aef

---

This paper asks an interesting and policy-relevant question: did the EU’s 2017 “Roam Like at Home” (RLAH) reform increase foreign tourist accommodation nights, especially in border regions? The topic is well chosen for a general-interest applied micro paper: the policy is salient, the institutional setting is clear, and the null result is itself potentially informative. The paper is also admirably transparent about limitations and conducts more robustness work than many papers with stronger headline effects.

That said, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ: Economic Policy. The central concern is not prose or presentation, but scientific substance: the empirical design identifies, at best, a relative change in tourism between border and interior regions after a common EU-wide shock, but the paper often interprets that estimate as if it were evidence on the overall effect of roaming abolition on cross-border mobility. That interpretation is too strong given the treatment structure, the outcome measure, and the exposure proxy. The inference is mostly careful, but the identification argument needs substantial strengthening and the claims need recalibration.

## 1. Identification and empirical design

### A. Core identification problem: everyone is treated, border is only an exposure proxy
The paper’s design is a difference-in-differences comparing internal-border NUTS2 regions to interior regions before and after June 2017 (Sections 3–4). But the policy was implemented simultaneously across all EU/EEA countries and applies to travelers wherever they go within the EU/EEA, not just to travelers to border regions. That means the paper does **not** identify the overall causal effect of RLAH on foreign tourism. It identifies whether border regions experienced a **differential** post-2017 change relative to interior regions.

That distinction matters a great deal. Interior regions receive many foreign tourists who also benefited from RLAH—especially air travelers to capitals and major tourist centers. If roaming abolition increased tourism to both border and interior regions, your DiD could estimate zero even when the true aggregate treatment effect is positive. The paper acknowledges this partially in the Discussion (“some interior regions … may also be affected”), but it remains too peripheral relative to how the abstract, introduction, and conclusion frame the null. The design is fundamentally an **intensity-of-exposure design**, not a treated-vs-untreated design.

This is the single biggest issue for publication readiness. The current title, abstract, and contribution claims overstate what is identified.

### B. Border status is an imperfect and potentially weak exposure measure
The paper argues that border regions are more exposed because cross-border day trips and short stays are more likely there. That is plausible, but the mapping from “shares a land border” to treatment intensity is coarse.

Problems include:
- NUTS2 regions can be large; a region that touches a border may still have most population/tourism far from the border.
- Some “interior” regions are highly exposed to foreign travel via airports and international tourism flows.
- Border adjacency does not distinguish high-integration corridors (Basel/Strasbourg/Vienna) from remote mountain borders.
- The outcome is foreign nights by all non-residents, not EU/EEA tourists specifically.

The paper does attempt a continuous-treatment variant using pre-treatment foreign share (Equation 2), but that variable is not a clean measure of roaming exposure. High foreign-share regions may be tourism hubs dominated by long-haul or air travel, where land-border roaming frictions are least relevant. In fact, this continuous measure may confound “international tourism orientation” with many unobserved determinants of differential post-2017 growth.

A more convincing exposure strategy would rely on a measure closer to the hypothesized mechanism: e.g., pre-2017 share of tourists from contiguous neighboring countries, border-market access, or distance-weighted proximity to an internal EU land border. The current border dummy is too blunt to carry the interpretation the paper wants.

### C. Parallel trends are not fully persuasive for the preferred identifying variation
The paper reports reassuring pre-trends in the event study (Figure 1; Section 5.2), but the event study appears to correspond to the baseline region-and-year FE design, not clearly to the preferred country-by-year FE specification in Equation (3). Since the preferred estimate is Column 3 of Table 2, the most relevant identifying assumption is **within-country parallel trends between border and interior regions**. That is a stricter and somewhat different assumption than the pooled border-vs-interior event study.

I would want to see:
- an event study estimated with country-by-year FE or an equivalent residualized event-study design,
- country-specific or region-group-specific pre-trends,
- and ideally tests/plots for the exact sample used in the preferred specification after singleton removal.

As written, the evidence for pre-trends is helpful but not fully aligned with the preferred identifying variation.

### D. Threats to identification from spatially differential tourism shocks remain under-addressed
Country-by-year FE absorb national shocks, which is valuable. But the remaining comparison is between border and interior regions within countries. Those regions can differ systematically in ways that generate differential trends unrelated to RLAH:
- border regions may be less urban, less capital-city intensive, and less airport-oriented;
- border regions may have different exposure to refugees, security concerns, transport investments, or destination-specific shocks;
- tourism trends can be highly regional (coastal/capital/alpine/cultural city), not national.

The paper’s domestic-tourism placebo helps, but only partially. A shock affecting international border-region attractiveness but not domestic tourism could still bias the estimates. Also, the placebo is not reported in the same preferred country-by-year FE framework.

I do not think these threats invalidate the design outright, but they mean the design is not yet sufficiently convincing for a strong causal claim in a top journal.

### E. Timing issues are acknowledged, but annual data remain a real limitation
RLAH starts on June 15, 2017, while the main outcome is annual accommodation nights. The paper appropriately runs a robustness check dropping 2017. That is good. But the coarseness of annual data is more consequential here because the hypothesized effect is likely strongest for short-run, seasonal, and nearby trips. If the treatment mainly affects summer discretionary travel or short-stay behavior, annual aggregation is a serious attenuation source.

This again pushes the paper toward a “no detectable effect on annual accommodation nights under this design” interpretation, not the broader “did not increase cross-border mobility” language used in several places.

## 2. Inference and statistical validity

### A. Inference is generally careful and one of the paper’s strengths
The paper reports standard errors for all main estimates (Table 2), clusters at the country level, and supplements asymptotic inference with wild cluster bootstrap (Section 7). Given 27 country clusters, that is appropriate and reassuring. The use of wild cluster bootstrap is especially important and well justified.

### B. Sample sizes and specification changes are unusually transparent
The discussion of why observations fall from 1,698 to 1,661 in the country-by-year FE specification is helpful (Section 3.4). This is good practice. The common-sample robustness check in Section 7 also addresses a natural concern.

### C. But several inferential comparisons are not yet aligned with the preferred design
The paper repeatedly leans on evidence from:
- the event study,
- the domestic placebo,
- matched sample results,
- leave-one-country-out,

yet many of those are presented only for the simpler region+year FE model, not for the preferred country-by-year FE specification. If Column 3 is the preferred model, then the main supporting diagnostics and placebo tests should be run in that same framework whenever feasible.

For example:
- Domestic placebo should be estimated with country-by-year FE.
- Event-study diagnostics should correspond to the preferred identifying variation.
- Heterogeneity analyses should clarify whether they use the preferred specification or not.
- Matched-sample results are of limited relevance once region FE are included unless matching targets trend comparability rather than levels.

### D. The paper should avoid implying “precisely estimated null” too strongly
The preferred estimate is 0.010 with SE 0.016. That does rule out large effects, but it does **not** rule out modest effects. A rough 95% CI is approximately [-0.021, 0.041]. Depending on the policy context, increases of 2–4 percent in border-region foreign nights may still matter economically. The abstract and introduction currently say things like “This null is not driven by imprecision,” which is too categorical.

The evidence is strong against large border-specific increases in annual accommodation nights, but not against all economically relevant effects.

## 3. Robustness and alternative explanations

### A. Robustness breadth is good, but some exercises are lower value than the paper suggests
The paper includes many robustness checks: leave-one-country-out, placebo timing, population weighting, excluding 2017, continuous treatment, distance-based treatment, matching, Rambachan-Roth sensitivity, wild bootstrap. This is a strong feature.

However, not all checks are equally informative:
- **CEM matching on pre-treatment levels and population** is not especially probative in a FE DiD setting unless it also addresses pre-trends.
- **External border placebo** is weak because there are only 7 external-border regions and the comparison sample is small (Table 3). This test has very low power and should not be overinterpreted.
- **Placebo timing** over 2012–2016 uses only a short pre-period and annual data; a non-significant placebo is mildly reassuring but far from dispositive.
- **Rambachan-Roth** is useful, but its credibility depends on the relevance of the underlying event-study setup to the preferred identifying variation.

### B. The mechanism discussion is thoughtful but mostly speculative
Section 6 is conceptually interesting, but the mechanisms are not actually tested. The paper is generally honest about this, which I appreciate. Still, several passages verge on treating these explanations as established:
- roaming costs were inframarginal,
- existing travelers simply substituted mobile data for Wi-Fi,
- binding constraints are cultural/institutional rather than digital.

These are plausible interpretations of a null reduced-form finding, but they are not separately identified in the data. They should be framed more cautiously as interpretations consistent with the evidence rather than conclusions drawn from it.

### C. Important alternative explanation: compositional dilution
The paper notes that the foreign-nights outcome includes non-EU visitors. This is not a minor caveat; it is central. If a large share of foreign nights in many regions comes from non-EU tourists, the treatment is measured with substantial noise/dilution. That attenuation could easily be large enough to make a modest true effect undetectable. Relatedly, even among EU tourists, the intensity of treatment varies by domestic mobile plan, fair-use caps, and pre-2017 operator pricing.

This is one reason the conclusion should be much narrower than currently stated.

### D. Missing robustness most needed: more directly relevant exposure measures
The most valuable robustness is not another placebo or another weighting scheme; it is a more credible treatment-intensity measure. Examples:
- share of pre-2017 foreign nights from neighboring countries,
- share from EU/EEA countries only,
- border regions weighted by population or tourism mass near the border,
- adjacency to highly integrated cross-border corridors,
- distance to nearest internal border for population centers rather than region polygons.

Without such exercises, the paper’s main “null” remains hard to interpret.

## 4. Contribution and literature positioning

### A. The question is novel and potentially interesting
The paper’s main contribution—linking a telecom regulation to real-economy tourism outcomes—is fresh and potentially important. The combination of digital market integration and border economics is appealing.

### B. The literature positioning could be sharper on empirical analogs
The current literature review covers roaming regulation and broad border/infrastructure papers, but it underplays closer literatures:
1. **Tourism demand and border frictions**: there is a large tourism-economics literature on transport costs, cross-border shopping/trips, exchange rates, visas, and border facilitation. The paper should engage more directly with work on what drives short-distance international tourism.
2. **Digital connectivity and mobility/travel behavior**: there is likely relevant literature on mobile communication costs, internet access, smartphone adoption, and travel/search behavior.
3. **Modern DiD interpretation under universal policy shocks with heterogeneous exposure**: even though staggered adoption is not the issue here, the paper is estimating a common-shock differential-exposure design. It would benefit from situating itself in that design class more explicitly.

Concrete references depend on the journal’s conventions, but the paper should add citations from:
- tourism demand under transport/transaction costs,
- border-region integration and commuting/shopping/travel,
- reduced-form evidence on digital frictions and physical mobility.

### C. The paper oversells its place relative to the RLAH literature
The statement that “No paper has tested whether RLAH generated real-economy spillovers beyond the telecom sector” may be true, but the paper should be careful not to imply that its design cleanly adjudicates the broader integration objective. At present it tests one specific margin: differential annual accommodation nights in border regions.

## 5. Results interpretation and claim calibration

This is where the paper most needs revision.

### A. The strongest claim supported by the evidence is narrower than the paper states
What the paper shows fairly convincingly is:

> There is no detectable **border-region-specific increase** in annual foreign accommodation nights after RLAH, relative to interior regions, and any such differential effect is likely small.

What the paper often says instead is:

> RLAH did not increase cross-border mobility / did not reduce real border frictions / did not move the needle on integration.

That broader claim is not justified by the design because:
- all regions are treated to some degree,
- the outcome excludes day trips,
- the outcome includes untreated non-EU tourists,
- the exposure proxy is noisy,
- annual data are coarse.

### B. The “not driven by imprecision” language is overstated
As noted above, the preferred estimate is not infinitely precise. The paper can reject large border-differential effects; it cannot rule out modest effects. This is especially important because the outcome is heavily attenuated relative to the underlying behavior of interest.

### C. The discussion sometimes interprets differences across specifications too strongly
The paper says the decline from Column 1 to Column 3 “reflects removal of country-level confounders that inflate both signal and noise.” That is possible, but not established. Another interpretation is that country-by-year FE are changing the estimand and emphasizing within-country contrasts that may have different signal content. The paper should not present this as a resolved causal decomposition.

### D. Policy implications should be softened
The current conclusion that digital policies “should not be expected to create new cross-border activity” goes beyond the evidence from one policy, one outcome, one frequency, and one exposure design. A more proportionate conclusion is that this particular highly salient digital-friction reform did not produce a detectable increase in annual overnight stays in border regions.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

**1. Reframe the estimand and claims throughout the paper.**  
- **Why it matters:** The current framing overstates what the design identifies. This is the most serious scientific issue.  
- **Concrete fix:** Rewrite the title, abstract, introduction, results, discussion, and conclusion to make clear that the design estimates a **differential border-region effect** of a common EU-wide policy shock, not the aggregate effect of RLAH on tourism or mobility. Avoid claims that RLAH “did not increase cross-border mobility” without qualification.

**2. Strengthen the treatment-intensity/exposure measure.**  
- **Why it matters:** Border adjacency is too coarse and likely mismeasures the channel of interest. With noisy treatment intensity, the null is hard to interpret.  
- **Concrete fix:** Construct and prioritize more relevant exposure measures, ideally based on pre-treatment shares of tourists from contiguous neighboring countries or at least EU/EEA-origin tourists if available. If Eurostat cannot provide origin-country composition at NUTS2, say so clearly and explore country-level or national-origin decomposition where possible. At minimum, provide stronger distance/proximity-based measures tied to population/tourism centers rather than simple polygon touches.

**3. Align pre-trend diagnostics and placebo tests with the preferred specification.**  
- **Why it matters:** The main credibility claim rests on the country-by-year FE model, but supporting diagnostics are mostly shown for simpler models.  
- **Concrete fix:** Report an event study or equivalent dynamic specification for the preferred within-country design; estimate the domestic-tourism placebo with country-by-year FE; and present diagnostics on the common estimation sample.

**4. Recalibrate the interpretation of the null given attenuation and outcome limitations.**  
- **Why it matters:** The foreign-nights outcome includes untreated non-EU tourists and omits day trips, both of which mechanically weaken the link between the estimate and the underlying causal question.  
- **Concrete fix:** Treat these as first-order limitations, not caveats in passing. Revise claims to “no detectable effect on annual foreign accommodation nights under this design.” If possible, provide back-of-the-envelope attenuation calculations using plausible EU/EEA shares to show what true underlying effect sizes are consistent with the observed reduced form.

### 2. High-value improvements

**5. Add more targeted within-country controls or subgroup designs.**  
- **Why it matters:** Border and interior regions may differ in tourism trends for reasons unrelated to RLAH.  
- **Concrete fix:** Consider specifications that compare border regions only to near-border non-border regions, or include interactions for capital region/coastal/alpine status, airport intensity, or baseline tourism structure. Even if imperfect, such analyses would improve confidence in within-country comparability.

**6. Clarify the interpretation of the continuous-treatment design.**  
- **Why it matters:** Pre-treatment foreign share is not obviously a measure of roaming exposure and may proxy for unrelated tourism dynamics.  
- **Concrete fix:** Either demote this specification or replace it with a better exposure measure. If retained, explicitly state why it is only suggestive and what its limitations are.

**7. Report economically interpretable confidence bounds.**  
- **Why it matters:** Readers need to know what effect sizes are ruled out.  
- **Concrete fix:** For the preferred specification, explicitly discuss the 95% confidence interval in percent terms and translate into nights per average border region. Do the same under plausible attenuation assumptions if possible.

**8. Sharpen the contribution relative to tourism and border-friction literatures.**  
- **Why it matters:** The current literature review is somewhat broad but not maximally targeted.  
- **Concrete fix:** Add closer references from tourism demand, border-region integration, and digital-friction/mobility literatures, and explain more clearly how this paper complements rather than supersedes them.

### 3. Optional polish

**9. Demote lower-information robustness checks and elevate the most credible ones.**  
- **Why it matters:** The robustness section is broad but a bit diffuse.  
- **Concrete fix:** Put less weight on CEM and the external-border placebo; foreground instead the preferred-spec pre-trends, dropped-2017 results, alternative exposure measures, and sensitivity to attenuation.

**10. Tone down mechanism language.**  
- **Why it matters:** Section 6 is interesting but more interpretive than causal.  
- **Concrete fix:** Rephrase mechanism discussion consistently as plausible interpretations, not findings.

## 7. Overall assessment

### Key strengths
- Important and timely policy question.
- Clean institutional setting with a sharp, well-defined reform.
- Transparent data construction and thoughtful acknowledgment of limitations.
- Careful inference, especially use of wild cluster bootstrap with 27 clusters.
- Useful null result, if properly framed.
- Strong instinct to test robustness rather than rely on one headline estimate.

### Critical weaknesses
- Main identification design estimates only a relative border-vs-interior effect after a universal policy shock; the paper often interprets it as evidence on the overall effect of RLAH on cross-border mobility.
- Treatment intensity is measured crudely.
- Preferred specification is not fully supported by corresponding pre-trend and placebo diagnostics.
- Outcome dilution (non-EU tourists included) and omitted day-trip margin are central, not peripheral, limitations.
- Claims and policy conclusions are stronger than the design can sustain.

### Publishability after revision
I think the paper is salvageable, but only with substantial reframing and additional empirical work focused on the identification problem. If the authors can:
1. narrow the estimand and claims,
2. improve the exposure measure,
3. align diagnostics with the preferred specification,
4. and more explicitly confront attenuation and omitted-margin issues,

then the paper could become a credible and useful “small-or-null effect” study. In its current form, however, the gap between design and interpretation is too large for acceptance.

DECISION: MAJOR REVISION