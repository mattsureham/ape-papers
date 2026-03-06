# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T19:30:21.371294
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20718 in / 4847 out
**Response SHA256:** 0a57471eebd6cac0

---

This paper studies whether France’s staggered rent-control rollouts capitalized into residential sale prices, using DVF transactions and a triple-difference design that compares small apartments (“investment-type”) to houses/large apartments (“owner-occupier-type”) in treated versus untreated cities before and after adoption. The paper is well motivated, asks an important question, and is commendably candid about several limitations, especially the lack of pre-treatment data for Paris and Lille. The most promising evidence is the heterogeneity: Bordeaux appears to show a sizable negative effect, and the within-apartment size gradient is suggestive of a capitalization channel.

That said, I do not think the paper is publication-ready for a top general-interest journal or AEJ:EP in its current form. The two central problems are: (i) inference is not yet credible given the small number of treated policy shocks and the mismatch between treatment assignment and clustering, and (ii) the identification strategy is weaker than the paper suggests because the main comparison mixes very different property segments and the event-study evidence does not directly validate the DDD identifying assumption. The paper is potentially salvageable, but it requires substantial redesign of inference and stronger validation of identification.

## 1. Identification and empirical design

### A. The core DDD idea is sensible, but the identifying comparison is not yet fully convincing

The paper’s main empirical strategy compares small apartments to larger apartments/houses within treated versus untreated cities over time (Section 5). In principle this is a reasonable way to isolate the segment more exposed to rent regulation. The main advantage is exactly the one the paper emphasizes: citywide shocks that affect all property types similarly should difference out.

However, the key identifying assumption is not simply “parallel trends across cities.” It is that, absent treatment, the **relative price path of small apartments versus large apartments/houses** would have evolved similarly in treated and control cities. That is a strong and very specific assumption. Treated cities are tighter rental markets by construction, and the relative valuation of studios/small apartments versus larger units can move for many reasons unrelated to rent control: remote work, household formation changes, mortgage conditions affecting first-time buyers, short-term rental regulation, student demand, local investor composition, and differential pandemic responses. The paper discusses some of these threats qualitatively, but the empirical validation is incomplete.

Most importantly, the event-study evidence in Section 6.2 does **not** directly test the DDD identifying assumption. The paper estimates separate event studies for investment-type and owner-occupier-type properties. That can show whether each series is flat relative to controls, but it does not test whether the **gap between them** was on parallel trends prior to adoption. What needs to be shown is a dynamic **triple-difference event study**: coefficients on event-time × investment-type × treated status, with the omitted pre-period normalized to zero. Without that, the paper has not directly validated the key assumption behind the headline coefficient.

### B. The treatment/exposure proxy is plausible but coarse, and may absorb non-policy compositional differences

The treatment exposure variable is “investment-type” = apartments with ≤2 rooms (or small apartments with missing rooms), while the comparison group pools houses and larger apartments (Section 4.3). This is understandable given the data constraints, but it introduces an important threat: the paper is not only comparing rental-exposed units to owner-occupier units, but also comparing **very different asset classes**.

Houses and studios differ in location within cities, buyer composition, financing, lot size, liquidity, and exposure to pandemic-era demand shocks. Even within city, these groups can have different trend behavior. The controls for surface area and rooms help little with this fundamental concern because they do not make houses and studios comparable assets. The strongest evidence in the paper is actually the apartment-only size-gradient analysis (Section 6.5), because it keeps the comparison within a more homogeneous segment. That analysis should be elevated from “mechanism” to something closer to the main design.

Relatedly, the claim that larger apartments/houses are “owner-occupier-type” is plausible but not directly verified in the data. For a top journal, I would want either external validation of the ownership/tenure composition by property type in French cities, or a linkage to auxiliary data showing that small apartments are indeed much more likely to be rented in treated and control locations alike.

### C. The identified sample restriction is appropriate and commendably transparent

Excluding Paris and Lille from the identified sample is the right choice. The paper is careful not to overstate those estimates. This is a strength. But that choice also reveals how limited the actual identifying variation is: only five treated city groups, several with short pre-periods (Appendix Table A2 / Section 5.2). That sharply constrains what can be learned.

### D. Timing and treatment definition need tighter justification

The treatment dates appear coherent, but the paper should be clearer about the transaction timing relative to policy implementation. Real estate prices can capitalize anticipated policy changes before the formal start date, especially when implementation is publicly known in advance. If adoption is announced or legislated months ahead, using the legal start date may misclassify part of the anticipatory effect as “pre-trend.” This matters particularly because the pre-period is already short. I would want a discussion and robustness using announcement dates where available, or at least a narrower window around adoption with flexible leads.

### E. Threats from non-random adoption remain serious

The paper acknowledges that adoption is politically endogenous (Section 7.4), but does not do enough to address it empirically. Cities that adopted rent control likely had tighter rental markets, more severe affordability pressure, and possibly different pre-existing trajectories in the small-unit segment. A control group of large non-adopting cities is a start, but it is not enough for a strong causal claim. At minimum, the paper needs more evidence that treated cities looked similar to controls in the evolution of the small-versus-large price differential before adoption.

## 2. Inference and statistical validity

This is the paper’s most serious weakness.

### A. Standard errors are likely invalid for the main causal claim

Treatment is assigned at the level of **city groups / communes under a common policy shock**, not at the individual transaction level. Yet the paper clusters at the commune level throughout (Section 5.6; Tables 1–4). This is problematic because communes within Plaine Commune or Est Ensemble share the same adoption date and likely common shocks induced by the same policy regime. Clustering below the level of treatment assignment can substantially overstate precision.

The paper recognizes this issue but does not solve it. Saying that commune clustering “provides within-city variation in outcomes” is not enough. The issue is not whether outcomes vary within city, but whether the residuals are correlated within the treated policy unit. They almost certainly are.

This matters a lot because the headline result is only statistically significant under one specification and with a modest t-statistic. If clustering were done at the treatment-shock level, precision would almost certainly deteriorate materially.

### B. The effective number of treated clusters is extremely small

The “identified sample” has only **five treated city groups**. This is a classic few-treated-clusters setting. Conventional clustered asymptotics are unreliable here even if clustering were done at the correct level. The paper’s own randomization inference does not reject the null (RI p-values 0.46 and 0.65 in Section 6.6). That is not a side note; it is central evidence that the claimed significance is fragile.

For a top journal, this is disqualifying unless the authors can provide design-based inference that is convincing under a few-cluster environment. At minimum, I would expect:
- wild cluster bootstrap or randomization-based p-values aligned to the treatment assignment mechanism,
- inference clustered at the city-group level (or treatment-shock level),
- and preferably permutation tests that reassign treatment status/timing across city groups rather than arbitrary date shifts.

### C. The randomization inference as implemented is not persuasive

The RI procedure shifts adoption dates by ±1–3 years (Appendix B.2). I do not find this compelling. It does not appear closely tied to the institutional assignment mechanism, and with a short sample window it can create placebo timings that are mechanically uninformative or that alter pre/post balance in odd ways. More importantly, the null being tested is unclear: random shifts in dates within the same treated units is not the same as placebo reassignment of policy across comparable cities.

A better RI design would operate at the level of city groups: randomly assign placebo adoption dates or treated status among comparable cities, preserving the actual number and timing structure of adoptions. As currently implemented, RI mostly tells us that the estimated coefficient is not rare under one arbitrary placebo design.

### D. The event study has too little pre-treatment support to do the work the paper asks of it

The paper openly notes that there is effectively one usable pre-treatment lead in the event study (Section 6.2). With only one pre-period coefficient, and with different cohorts contributing differently to each bin, the event study cannot strongly validate parallel trends. This is not fatal by itself, but it means the design is underpowered for dynamic validation. The text should be much more restrained on this point.

### E. Sample sizes are coherent, but the inferential target is not

The transaction counts are clearly reported and coherent across specifications. That is good. But the relevant sampling uncertainty is not governed by 450,000 transactions; it is governed by a handful of treated policy shocks. The paper sometimes writes as if the large micro sample compensates for design weakness. It does not.

## 3. Robustness and alternative explanations

### A. The robustness exercises are useful but do not yet hit the main threats

The paper reports:
- uncontrolled vs controlled DDD,
- price vs price per square meter,
- stacked DiD,
- excluding COVID-affected quarters,
- post-COVID adopters only,
- leave-one-out,
- apartment size interactions,
- RI.

Several are useful, especially the apartment-size gradient and the stacked approach. But the current robustness package still misses the key alternative explanations:

1. **Differential pre-trends in small-vs-large segment prices**: needs direct DDD event-study evidence.
2. **Control-group dependence**: the results could be sensitive to which 20 non-treated cities are used. I would want leave-one-control-city-out or reweighting/matching results.
3. **Within-city location composition**: if small apartments transact in different neighborhoods than houses/large units and those neighborhoods are on different trajectories, the DDD can be biased. Neighborhood fixed effects are probably unavailable, but perhaps postal-code fixed effects or finer geographic controls are possible in DVF.
4. **Short-term rental regulation / tourism shocks**: especially relevant for Bordeaux and Paris, and possibly tightly correlated with small-apartment prices.
5. **Announcement effects / anticipation**: not addressed.

### B. The leave-one-out result materially weakens the general claim

The leave-one-out exercise (Section 6.4) is quite revealing: dropping Bordeaux reduces the identified-sample estimate to -0.031 and renders it clearly insignificant. That means the evidence for a pooled French effect is weak. The paper is relatively honest about this, but the framing still centers the pooled 9.3% estimate. The more accurate conclusion is that there is suggestive evidence of capitalization in one setting where bindingness may have been high, not a robust average effect across treated French cities.

### C. Mechanism claims are suggestive, not established

The size-gradient result is the strongest piece of evidence in the paper. It is directionally consistent with rent-control bite. But even here the interpretation should remain cautious. Small units may have been differentially affected by other city-specific shocks in 2021–2023. Without linking units to actual ceiling stringency or rental-market exposure, the paper cannot firmly attribute the gradient to rent caps rather than broader market segmentation.

The paper itself points to the ideal extension: merge transaction data with neighborhood-level reference rents and, ideally, market rent proxies. That would allow a far more convincing “dose-response” design where effects are stronger in cells where the regulation is predicted to bind more tightly.

## 4. Contribution and literature positioning

The paper’s topic is important and potentially publishable. Asset-price capitalization of rent control is under-studied relative to rental-market outcomes, and the French setting is interesting. The literature discussion is broadly competent and covers major domain references.

That said, for a top-journal submission the methods positioning should be sharper, especially around modern DiD/DDD inference and few-cluster settings. I would suggest adding and engaging more directly with:

- **Olden and Møen (2022)** on triple-difference designs and interpretation.
- **MacKinnon and Webb** on wild bootstrap / inference with few treated clusters.
- **Ferman and Pinto** / related few-cluster inference papers.
- Potentially **Roth (2022)** or related work on pre-trend testing limitations, given the heavy reliance on a very short event-study pre-period.
- If the stacked design is retained, cite the stacked-DiD implementation literature more explicitly, not just Goodman-Bacon/Sun-Abraham.

On the policy side, the paper could also better differentiate itself from the existing European rent-control capitalization literature by clarifying what the French design adds beyond “another event study of rent control.” Right now the distinctive contribution is somewhat undercut by the weakness of the identifying window and the heavy dependence on Bordeaux.

## 5. Results interpretation and claim calibration

To the paper’s credit, the discussion and conclusion are more restrained than many papers. Still, some claims remain too strong relative to the evidence.

### A. The abstract and conclusion lean too heavily on the controlled pooled estimate

The abstract leads with “The pooled DDD estimate is -0.093 with controls (p = 0.017)” even though:
- the uncontrolled baseline is insignificant,
- RI does not reject,
- the estimate appears sensitive to city composition,
- and the effect is largely driven by Bordeaux.

Given the inferential concerns, the paper should not present the 9.3% estimate as the central take-away. The central take-away is heterogeneity plus weak pooled evidence.

### B. “Randomization inference does not reject because of low power” is too convenient

This may be true, but it is asserted rather than demonstrated. When the design-based test fails to reject and the asymptotic clustered SEs produce significance, the burden is on the authors to justify why readers should privilege the latter. Right now the paper does not meet that burden.

### C. The welfare calculations are not warranted by the evidence

Section 7.5 gives back-of-the-envelope wealth-transfer numbers for Bordeaux and especially Paris. These are too speculative for the current design. For Bordeaux they rely on a city-specific estimate that may still reflect confounding; for Paris they rest on an acknowledged non-causal comparison. These calculations risk overreach and should either be removed or sharply demoted.

### D. The Paris discussion is interesting but should stay peripheral

The paper generally handles Paris carefully, but the prominence of the -0.392 estimate still creates a rhetorical pull toward a stronger result than the identified sample can support.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

**1. Rebuild inference around the actual treatment-shock level.**  
- **Why it matters:** Current commune-clustered SEs are not credible when communes within the same treated city group share the policy shock. With only five treated groups, the headline significance is not reliable.  
- **Concrete fix:** Re-estimate main specifications with inference appropriate to few treated clusters: cluster at the city-group/policy-shock level, use wild cluster bootstrap where feasible, and provide design-based/randomization-based p-values that reassign treatment across city groups or adoption timings in a way that mirrors the institutional setting.

**2. Estimate a proper dynamic triple-difference event study.**  
- **Why it matters:** The current separate-by-type event studies do not test the identifying assumption behind the DDD.  
- **Concrete fix:** Estimate event-time × treated × investment-type coefficients in one regression, report pre-treatment lead coefficients for the DDD estimand, and interpret the limited pre-period honestly.

**3. Reframe the paper around heterogeneous effects rather than a pooled average.**  
- **Why it matters:** The pooled result is largely driven by Bordeaux; dropping Bordeaux largely eliminates the finding.  
- **Concrete fix:** Make city-level heterogeneity central. Consider treating Bordeaux as the main credible treated case and the pooled estimate as secondary, rather than the reverse.

**4. Address the comparability problem in the main design.**  
- **Why it matters:** Houses/large apartments are not an ideal counterfactual for small apartments.  
- **Concrete fix:** Move the apartment-only size-gradient design closer to center stage; ideally make apartment-only specifications primary. If possible, compare studios/1-room to 3-room+ apartments within apartments only, with richer controls/fixed effects.

**5. Reassess the randomization inference design.**  
- **Why it matters:** The current RI is not closely tied to the assignment mechanism and currently undermines the headline claim rather than clarifying it.  
- **Concrete fix:** Implement placebo treatment assignment/timing across comparable city groups while preserving the number of treated units and cohort structure; report the exact null and why that placebo design is appropriate.

### 2. High-value improvements

**6. Validate the “investment-type” proxy using external data.**  
- **Why it matters:** The causal interpretation depends on small apartments being much more rental-exposed than the comparison group.  
- **Concrete fix:** Use census/housing survey/tabulations by city and unit type to show rental shares by rooms/type, ideally separately for treated and control cities.

**7. Add stronger control-group diagnostics and sensitivity.**  
- **Why it matters:** Results may depend on the choice of 20 control cities.  
- **Concrete fix:** Show pre-period comparability of the small-vs-large price gap, implement reweighting or matching, and run sensitivity dropping major controls one at a time.

**8. Address anticipation/announcement effects.**  
- **Why it matters:** Sale prices can capitalize expected policy before implementation.  
- **Concrete fix:** Compile announcement dates where feasible; add specifications using announcement rather than enforcement dates, or windows excluding the immediate pre-adoption period.

**9. Explore more granular geography.**  
- **Why it matters:** Composition across neighborhoods within cities may confound the DDD.  
- **Concrete fix:** If available in DVF, use postal code or finer location fixed effects interacted with property-type categories, at least in large cities.

**10. Link outcomes to predicted bindingness.**  
- **Why it matters:** Mechanism would be much more convincing if stronger effects appear where rent ceilings should bind most.  
- **Concrete fix:** Merge reference-rent schedules and any available market-rent proxies to construct a predicted bite measure by city/neighborhood/unit type.

### 3. Optional polish

**11. Remove or sharply downweight speculative welfare calculations.**  
- **Why it matters:** They overstate certainty given the design.  
- **Concrete fix:** Either drop Section 7.5 or present it as a very tentative illustration after a strong caveat.

**12. Tighten claim calibration throughout.**  
- **Why it matters:** The current evidence supports “suggestive heterogeneous capitalization,” not “France’s rent control depresses property values” as a general statement.  
- **Concrete fix:** Rewrite abstract/introduction/conclusion to emphasize heterogeneity, limited treated clusters, and weak support for a general pooled effect.

**13. Expand methods citations around DDD and few-cluster inference.**  
- **Why it matters:** The paper currently under-engages with the inferential challenges most relevant to its design.  
- **Concrete fix:** Add references on DDD interpretation and few-treated-cluster inference and discuss how your revised procedures respond to that literature.

## 7. Overall assessment

### Key strengths
- Important and policy-relevant question.
- Good use of administrative microdata.
- Appropriate decision to exclude Paris and Lille from the identified sample.
- Candid discussion of limitations.
- Interesting heterogeneity, especially Bordeaux.
- Apartment-size gradient is the most compelling empirical pattern in the paper.

### Critical weaknesses
- Main inference is not credible as currently implemented: clustering is below the treatment-shock level, with only five treated groups.
- Design-based/randomization evidence does not support the headline significance.
- Event study does not test the actual DDD identifying assumption.
- Main treatment-exposure comparison mixes very different property classes.
- The pooled result is fragile and largely driven by one city.

### Publishability after revision
There is a potentially publishable paper here, but not yet in current form. The Bordeaux result and the within-apartment gradient suggest there may be a real capitalization effect where rent control binds tightly. However, to reach the bar of a top field/policy journal—let alone a top-five general-interest journal—the paper needs a much stronger inferential foundation and a more convincing identification validation. At present, the evidence is better described as suggestive and heterogeneous than as a clean causal estimate of an average effect.

DECISION: REJECT AND RESUBMIT