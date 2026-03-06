# Research Idea Ranking

**Generated:** 2026-03-06T17:39:13.920039
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Does Rent Control Destroy Property Value... | PURSUE (73) | PURSUE (78) | PURSUE (72) |
| Unshackling Growth? France's Loi Pacte a... | CONSIDER (55) | PURSUE (62) | SKIP (44) |
| The Price of Exclusion — Do Housing Quot... | SKIP (42) | SKIP (35) | CONSIDER (51) |

---

## GPT-5.4 (A)

**Tokens:** 8524

### Rankings

**#1: Does Rent Control Destroy Property Value? Staggered Evidence from France's Encadrement des Loyers**
- **Score: 73/100**
- **Strengths:** This is the strongest package: a first-order policy, a sharp capitalization channel, and unusually rich universe transaction data. The staggered French rollout is genuinely useful, and the proposed third difference gives the design more bite than a plain city-by-time DiD.
- **Concerns:** The key risk is that “investment-type” units and “owner-occupier-type” units may have different underlying trends for reasons unrelated to rent control, especially around COVID, Airbnb, student demand, and mortgage-rate shocks. Also, this is still a crowded international literature on rent control capitalization, so the paper needs a clean French-specific angle rather than “yet another rent-control paper.”
- **Novelty Assessment:** **Moderately novel.** Rent control’s effects on prices/capitalization have been studied many times internationally, but the exact French reintroduction setting and multi-city staggered rollout on **sale prices** appear much less worked over than the general topic.
- **Top-Journal Potential: Medium.** The question is important and the outcome is economically legible, but top-5 placement would likely require either a surprising result or a stronger incidence/mechanism story than simple ATEs. As currently framed, this looks more naturally like a strong **AEJ: Economic Policy / JUE / JHE** paper than a slam-dunk top-5.
- **Identification Concerns:** Adoption is politically and economically endogenous, and the third difference only works if small apartments and larger owner-occupied properties would have evolved similarly absent treatment. Inference also needs care because the effective number of treated policy units is not huge, despite millions of transactions.
- **Recommendation:** **PURSUE (conditional on: showing strong pre-trend evidence by property type; validating the “rental-probability” classification; mapping exact policy perimeters and using boundary/placebo tests to address city-specific shocks)**

**#2: Unshackling Growth? France's Loi Pacte and the 50-Employee Regulatory Threshold**
- **Score: 55/100**
- **Strengths:** The policy question is important, and the reform speaks directly to one of the most famous French labor-market distortions. If you could show that removing the 50-worker bite actually changed firm growth, that would be a valuable causal complement to the classic bunching paper.
- **Concerns:** The main problem is that the proposed open data are too aggregated to cleanly study a threshold mechanism. With only coarse size bins, this is not really a discontinuity design, and the 2020 timing is contaminated by COVID in ways that may not wash out with a simple cross-boundary comparison.
- **Novelty Assessment:** **Moderately novel on the exact reform, not very novel on the underlying question.** The “50-employee curse” is already a heavily studied object; what is newer is the post-reform test, but I would be surprised if this remains untouched for long.
- **Top-Journal Potential: Low.** In principle, a clean causal reversal of a famous bunching result could be exciting. But with bracketed département-sector-year counts, this currently reads as a competent reform follow-up rather than a paper that would change how the field thinks.
- **Identification Concerns:** The proposed 49/50 vs 99/100 comparison is weak because the data do not observe local behavior around exact cutoffs, and different parts of the size distribution can respond differently to macro shocks. The 5-year grace period also means treatment status depends on firms’ crossing histories, which the aggregate data cannot recover.
- **Recommendation:** **CONSIDER**

**#3: The Price of Exclusion — Do Housing Quotas Break Residential Segregation? Evidence from France's Loi SRU**
- **Score: 42/100**
- **Strengths:** Conceptually, this is the most ambitious idea: it links penalties, social-housing construction, exclusionary local behavior, and property-market capitalization. If identified cleanly, this is the kind of housing paper that could matter a lot.
- **Concerns:** In its current form, the design is underidentified. The fatal issue is timing: the main price data start essentially after the 2013 reform, leaving almost no pre-period for the key outcome, while the treatment intensity is highly correlated with municipality characteristics that drive prices and construction anyway.
- **Novelty Assessment:** **Fairly novel on the exact 2013 tightening and the capitalization angle.** But the broader areas—social housing quotas, exclusion, and segregation—are already well populated literatures, so novelty alone cannot rescue a weak design.
- **Top-Journal Potential: Low.** The underlying question has high upside, but top journals will not forgive a thin pre-period and endogenous treatment intensity on such a politically loaded housing question. In current form, this is not competitive.
- **Identification Concerns:** Municipalities below 25% social housing are systematically different from those above it, and with almost no pre-reform price data you cannot credibly assess counterfactual trends. The “around social housing construction sites” outcome is also vulnerable because site placement is endogenous to municipal planning and neighborhood dynamics.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea is clearly worth pushing now. **Idea 1** is the best combination of feasible data, policy importance, and a potentially credible design, though it still needs serious work on property-type trends and endogenous adoption. **Idea 2** is worth revisiting only if you can obtain firm-level microdata around exact employment thresholds; **Idea 3** should be shelved unless redesigned around a cleaner shock such as newly covered municipalities with a real pre-period.

---

## Gemini 3.1 Pro

**Tokens:** 7900

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, focusing on identification quality, data feasibility, and the empirical editorial patterns that separate top-tier publications from competent but unexciting working papers.

### Rankings

**#1: Does Rent Control Destroy Property Value? Staggered Evidence from France's Encadrement des Loyers**
- **Score**: 78/100
- **Strengths**: This proposal leverages a massive, high-quality administrative dataset (DVF) and a clean staggered rollout to test a fundamental economic theory. The triple-difference design (investment vs. owner-occupier properties) is a clever way to isolate the capitalization channel while netting out city-level macroeconomic shocks.
- **Concerns**: The proxy for investment properties (small apartments/studios) vs. owner-occupiers (large apartments/houses) is vulnerable to pandemic-era preference shifts. If COVID-19 caused a general "flight to space" (lowering demand for studios and raising demand for houses), this could perfectly confound the triple-difference estimate for cities adopting in 2020-2022.
- **Novelty Assessment**: Medium-High. Rent control is heavily studied (e.g., Diamond et al., Autor et al.), and the theoretical prediction here is entirely standard. However, estimating the *capitalization* of rent control introduction across a multi-city staggered rollout using a triple-diff is empirically novel and provides much higher statistical power than standard single-city case studies.
- **Top-Journal Potential**: Medium-High. To hit a Top-5, it cannot just be a "competent ATE" showing that rent control lowers property values (which everyone expects). It needs to be framed around a sharp causal channel—such as the exact incidence on investors vs. owner-occupiers, or using the universe-scale data to precisely bound spillover effects into uncontrolled neighboring suburbs. Otherwise, it is a very strong fit for *AEJ: Economic Policy* or *JUE*.
- **Identification Concerns**: The primary threat is the aforementioned COVID-19 "flight to space" confounding the property-type difference. You must prove that the price spread between studios and large apartments remained stable in the control cities during the pandemic to validate the triple-diff.
- **Recommendation**: PURSUE

**#2: Unshackling Growth? France's Loi Pacte and the 50-Employee Regulatory Threshold**
- **Score**: 62/100
- **Strengths**: This asks a first-order macroeconomic question and directly targets a famous, highly cited paper (Garicano et al., 2016, *AER*). Testing the *removal* of a regulatory threshold is the perfect "reverse experiment" to prove whether the regulation was truly the binding constraint on firm growth.
- **Concerns**: The proposed data is fatally flawed for the research design. You cannot estimate a sharp difference-in-discontinuities or measure de-bunching using binned aggregate data (20-49 vs. 50-99 employees); you need exact firm-level headcounts to observe the density at exactly 49 versus 50.
- **Novelty Assessment**: High. While the "50-employee curse" is well-known, causal evidence on what happens when you *remove* the curse is scarce. Resolving this live confusion in the literature (is it real misallocation or just reporting evasion?) is a highly valuable contribution.
- **Top-Journal Potential**: High (if data is fixed). Papers that overturn or significantly update famous benchmark results using a sharp policy reversal are classic Top-5 material. It has first-order stakes (firm growth, macro misallocation) and a clear narrative arc.
- **Identification Concerns**: Beyond the binned data issue, the 2020 implementation perfectly coincides with the COVID-19 pandemic. The diff-in-disc assumes COVID affected 50-employee firms exactly the same as 100-employee firms, which may be violated if pandemic relief loans (e.g., PGE) or labor subsidies had size-dependent eligibility criteria.
- **Recommendation**: PURSUE (conditional on: securing restricted firm-level microdata with exact employee counts, such as DSN or FARE, rather than using open binned data).

**#3: The Price of Exclusion — Do Housing Quotas Break Residential Segregation? Evidence from France's Loi SRU**
- **Score**: 35/100
- **Strengths**: The "price of exclusion" is a conceptually interesting framing, attempting to link municipal finance penalties directly to local property market capitalization.
- **Concerns**: The research design is dead on arrival due to data timing. You cannot run a Difference-in-Differences model for a January 2013 reform using a dataset (DVF) that begins in April 2014; there is literally zero pre-treatment period to establish parallel trends or baseline levels.
- **Novelty Assessment**: Low-Medium. The SRU law has been evaluated before (Gobillon & Vignolles, 2016). While looking at the 2013 penalty quintupling is a new angle, it reads as an incremental update to existing literature rather than a paradigm shift.
- **Top-Journal Potential**: Low. Even if the data timing worked, this reads as a standard policy evaluation of a quota penalty. It lacks the surprising mechanism or universe-scale counter-intuitive finding required to elevate it above a field journal.
- **Identification Concerns**: The lack of a pre-period is a fatal flaw. Furthermore, treatment intensity (gap below 25%) is highly endogenous; municipalities that are furthest from the quota are likely fundamentally different (wealthier, more exclusionary, different zoning laws) than those hovering near compliance, violating parallel trends.
- **Recommendation**: SKIP (unless completely retooled to focus exclusively on the 2017 extension, which would provide a 3-year pre-period, though this is still quite short for property market dynamics).

### Summary

This batch contains one highly executable, solid empirical project (Idea 1), one potentially field-shifting project crippled by a bad data proposal (Idea 2), and one fundamentally flawed project (Idea 3). I strongly recommend pursuing **Idea 1** immediately, as the data is ready and the triple-diff design is clever. Simultaneously, you should investigate acquiring restricted micro-data for **Idea 2**; if you can get exact firm sizes, Idea 2 actually has the highest ceiling for a Top-5 journal because it directly answers a major unresolved macroeconomic puzzle.

---

## GPT-5.4 (B)

**Tokens:** 11287

### Rankings

**#1: Does Rent Control Destroy Property Value? Staggered Evidence from France's Encadrement des Loyers**
- **Score:** 72/100
- **Strengths:** Big, legible policy question with an outcome that directly matches the policy’s economic mechanism: if rent ceilings bite, expected rental income should capitalize into sale prices. The staggered French rollout plus universe-scale DVF transactions gives this much better power and scope than the usual single-city rent-control paper.
- **Concerns:** Adoption is endogenous to very tight housing markets, and the proposed third difference relies on investor-type and owner-occupier-type properties having similar underlying trends. That is a strong assumption, especially through COVID/WFH when small flats and larger homes moved very differently.
- **Novelty Assessment:** **Moderate.** Rent control and housing values are heavily studied in general, but I do not know of a crowded literature on the **French multi-city reintroduction** and its capitalization into **sale prices** specifically.
- **Top-Journal Potential:** **Medium.** There is a good causal chain here—rent control → lower expected rent stream → lower asset values—and the data scale helps. But for top-5/top field placement, it needs more than “another rent-control ATE”: ideally sharp bindingness heterogeneity, strong placebos, and a persuasive design against city-specific shocks.
- **Identification Concerns:** The main threat is differential trends across property types rather than rent control. I would want apartment-only comparisons, border/perimeter checks, announcement-timing tests, and strong pre-trend evidence before treating the DDD as clean.
- **Recommendation:** **PURSUE** *(conditional on: using a tighter exposure measure than houses vs small flats; explicitly handling COVID/announcement timing; verifying regulatory boundaries and bindingness)*

---

**#2: The Price of Exclusion — Do Housing Quotas Break Residential Segregation? Evidence from France's Loi SRU**
- **Score:** 51/100
- **Strengths:** This is the most conceptually ambitious idea: exclusionary housing policy, compliance incentives, and capitalization are all first-order. The 2013 tightening of SRU penalties is substantially less mined than the original law and could support a compelling compliance → construction → price/segregation story.
- **Concerns:** As written, the price design is very weak because DVF starts after the reform, leaving essentially no usable pre-period. Also, the title promises “segregation,” but the proposed outcomes are mainly prices, which risks over-claiming relative to the evidence.
- **Novelty Assessment:** **Relatively high.** The original SRU law has been studied, but I know far less work on the **2013 strengthening** and especially on the **capitalization channel**.
- **Top-Journal Potential:** **Medium.** The underlying question is absolutely journal-worthy, but the current empirical design is not. If redesigned around a cleaner shock—newly covered municipalities, a sharper compliance discontinuity, or better pre-reform price data—the upside is meaningful.
- **Identification Concerns:** Municipal deficit relative to the 25% target is clearly endogenous, and without a real pre-period you lose the standard DiD/event-study credibility checks. You also need a direct measure of actual social-housing production and, ideally, segregation itself.
- **Recommendation:** **CONSIDER** *(conditional on: redesigning around the 2017 extension or another cleaner treatment margin; obtaining genuine pre-reform price data or dropping prices; adding a direct segregation/composition outcome)*

---

**#3: Unshackling Growth? France's Loi Pacte and the 50-Employee Regulatory Threshold**
- **Score:** 44/100
- **Strengths:** The policy question is real and tied to a famous result, so the basic motivation is strong. In principle, a post-reform test of whether the 50-employee barrier actually relaxed firm growth could be valuable.
- **Concerns:** With the proposed data, this is not a credible threshold paper: the bins are far too coarse, the unit is establishments rather than firms, and implementation coincides with COVID plus a 5-year grace period. The likely output is a descriptive note, not a clean causal paper.
- **Novelty Assessment:** **Low.** The French size-threshold/bunching literature is already crowded, and I would be surprised if the post-Pacte reform has not already been explored in policy notes or working papers.
- **Top-Journal Potential:** **Low.** In current form this reads as incremental and measurement-constrained. Top journals would want firm-level microdata, precise density changes at the cutoff, and a result that changes beliefs about threshold regulation.
- **Identification Concerns:** The proposed “difference-in-discontinuities” is not really identified with 20–49 vs 50–99 brackets. COVID need not affect the 50 and 100 margins symmetrically, and the legal threshold applies to firms/ESUs, not cleanly to establishments.
- **Recommendation:** **SKIP**

---

### Summary

This batch has **one clear lead**: the rent-control capitalization paper. It has the best combination of feasible data, aligned outcomes, and a question that both policymakers and journals immediately understand. The SRU idea has higher conceptual upside than the firm-threshold idea, but only after a substantial redesign; the Loi Pacte proposal is too aggregated, too confounded, and too incremental to prioritize.

