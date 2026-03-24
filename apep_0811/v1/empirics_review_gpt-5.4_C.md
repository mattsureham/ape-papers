# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-23T12:55:17.552421

---

## 1. **Idea Fidelity**

The paper does **not** pursue the original idea in the manifest in any meaningful sense. The manifest proposed a design centered on the **250-employee threshold** in the English regulation, using a **firm-size RD/fuzzy RD**, supplemented by cross-border DiD and menu-platform data to study **menu composition, reformulation, and consumer demand**. This paper instead asks a different question—whether the regulation deterred **new business incorporations**—and uses a **country-sector-time triple-difference** with Companies House data only.

That is a legitimate question, but it is not the paper that was promised. In particular, the central institutional feature of the policy—the fact that the mandate applied only to firms with **250+ employees**—is almost entirely unused. That omission matters a great deal because the paper’s own outcome, new incorporations, is measured for firms that are overwhelmingly **too small to be directly treated**. So the paper moves from a sharp policy discontinuity affecting large chains to an indirect spillover design on mostly exempt entrants. That is a much weaker exercise, both conceptually and empirically, than the original idea.

## 2. **Summary**

This paper studies whether England’s April 2022 mandatory calorie labeling law reduced entry into food service. Using monthly company incorporations from Companies House and a DDD comparing food service to placebo sectors in England/Wales versus Scotland before and after the policy, the paper finds a near-zero estimate and interprets it as evidence that the regulation imposed negligible entry burdens.

The paper’s contribution is potentially useful as a narrow test of one industry claim. However, the current design is too far from the policy’s treated margin, and the inference and identification are not strong enough to support the paper’s confidently stated conclusion of a “precisely estimated null.”

## 3. **Essential Points**

1. **The design is poorly aligned with the treated margin of the policy.**  
   The law applies to businesses with **250+ employees**; your outcome is **new incorporations**, which are almost all tiny entities at birth. So the paper does not estimate the direct effect of compliance costs on treated firms. It estimates, at best, a diffuse equilibrium spillover on exempt small entrants. That is a much less compelling estimand. You need either (i) direct evidence that entry at the relevant margin could plausibly respond—for example, chain-affiliated incorporation, outlet expansion by larger groups, franchise entry, or multi-establishment firms—or (ii) a substantial reframing of the paper as a study of *spillovers to exempt entrants*, not of “the regulation’s effect on entry” in general.

2. **The identification is not credible enough in its current form, especially given the rejected pre-trends.**  
   The event-study evidence is troubling, not reassuring. You report multiple significant pre-treatment coefficients and a joint rejection at \(p=0.003\). In a paper whose headline result is a null, one cannot simply say the pre-trends are “noisy” and move on. The concern is not that pre-trends mechanically create a negative effect—you estimate zero—but that the design is unstable and the identifying assumptions are weak. The fact that a placebo sector (real estate) generates a large significant “effect” should not be presented as validation; it is equally consistent with the design loading on unrelated England–Scotland sector-specific shocks. You need a more persuasive control strategy or a much more cautious interpretation.

3. **The standard errors and “precision” claims are overstated.**  
   With effectively two jurisdictions and serially correlated monthly outcomes, heteroskedasticity-robust HC1 standard errors are not appropriate for the main inference. Driscoll–Kraay is not a panacea here, especially with such a small cross-sectional dimension and a highly aggregated panel. More fundamentally, the paper repeatedly claims a “precisely estimated null” and that it “rules out” effects larger than 7 percent. That is too strong given the inference problem and the instability visible in the event study. You need inference that matches the design—e.g., randomization/permutation-style inference, wild bootstrap over plausible clusters if available, collapsing to fewer independent comparisons, or at minimum presenting the result as suggestive rather than definitive.

## 4. **Suggestions**

The paper can still become a useful short note, but it needs to be much tighter, more modest, and more transparent about what it can and cannot identify.

First, I would **reframe the contribution**. Right now the title, abstract, and conclusion imply that you have tested whether calorie labeling deterred restaurant entry. That is too broad. A more accurate statement is: *there is no detectable change in small-company incorporations in SIC 56 in England relative to Scotland and placebo sectors after the policy*. That is narrower, but honest. The paper would improve immediately if you stopped conflating “incorporation of mostly exempt firms” with “entry into the treated market.” The 250-employee threshold is the core institutional feature, and if you do not exploit it, you should not write as though you did.

Relatedly, you should do much more to **characterize the outcome you actually observe**. Are these incorporations restaurants, holding companies, SPVs, dormant entities, franchise vehicles, or single-site operators? How many ever become active trading businesses? What share survive 12 months? If the outcome is noisy and only loosely connected to economically meaningful entry, that weakens the paper considerably. A simple descriptive table on survival, legal form, or whether the company later files accounts would be very helpful. If you can identify likely operating businesses versus shell incorporations, do so.

Second, I strongly recommend exploiting the **policy threshold more directly**, even if imperfectly. The manifest’s original RD idea may be ambitious, but some version of it is needed. For example:
- Link incorporations to subsequent employment or account filings where possible, and test whether there is any effect on entrants likely to scale above very small size.
- Separate incorporations by legal form or by chain/franchise affiliation if detectable.
- Distinguish outlet expansion by existing chains from de novo incorporations, since compliance costs are more likely to matter for the former than for a typical new independent takeaway.
- If you cannot get at size, then say clearly that the paper studies **spillovers to exempt entrants**, and adjust the theory accordingly.

Third, the paper needs a better **control group justification**. The five placebo sectors are ad hoc and quite heterogeneous. IT services and real estate are not obvious comparators for restaurants. They have different cyclicality, different exposure to remote work, different financing conditions, and very different pandemic trajectories. Since your DDD relies heavily on these sectors, you should show:
- pre-2022 trends graphically for each sector by country;
- the England/Scotland ratio over time within each sector;
- leave-one-out results for **all** placebo sectors, not just retail and real estate;
- results using a more defensible control set, perhaps only consumer-facing local service sectors such as personal services and selected retail subgroups.

A particularly important point: the paper currently aggregates **England and Wales together** and compares them to Scotland, despite the fact that the policy applied to **England**, not Wales. That is a serious problem. Wales is untreated but included on the treated side. This induces treatment misclassification that pushes estimates toward zero and undermines interpretation. You need to separate England from Wales using the registered office address or another geography field. If that is impossible in the chosen Companies House extract, then the design is substantially weaker than presented and the paper should say so prominently. As written, the treatment definition is inaccurate.

Fourth, I would rethink the **time-series design** in light of COVID and post-COVID recovery. Your sample begins in 2019, so much of the identifying variation is dominated by extraordinary pandemic movements. Even with saturated fixed effects, England-by-food-service dynamics could easily differ from Scotland-by-food-service dynamics during reopening, labor shortages, energy price shocks, and shifts in city-center demand. The rejected event-study pre-trends are consistent with exactly that concern. Some useful steps:
- present the analysis on a cleaner window, e.g. 2021–2023, with a transparent tradeoff between sample size and comparability;
- include linear or flexible country-by-sector-specific trends;
- show a stacked specification that excludes the worst pandemic period rather than only a coarse month drop;
- consider year-over-year changes to attenuate seasonality and pandemic level effects.

On inference, I would be much more careful. With 1,008 observations, it is tempting to feel well powered, but the actual number of independent units is tiny. The identifying variation is essentially at the level of **country-sector-time paths**, not millions of firms. AER: Insights readers will notice this immediately. I suggest:
- report Newey–West or HAC standard errors for the collapsed series;
- do inference on quarterly rather than monthly data as the main specification, not as a robustness check;
- use permutation inference over treatment timing and sector assignment where feasible;
- show sensitivity of confidence intervals across HC, HAC, DK, and collapsed-time specifications.

You should also tone down the phrase **“precisely estimated null.”** With a confidence interval of about \(\pm 7\%\), the estimate is informative, but not definitive—especially once one accounts for serial correlation and treatment misclassification. In many entry settings, a 5–10 percent change is economically meaningful. So the right claim is not “negligible burden” but “no evidence of a large effect on measured incorporations.”

The paper would also benefit from more attention to **economic magnitude and plausibility**. The null itself is plausible. It would actually be surprising if a regulation aimed at large chains produced an immediate large drop in small business incorporations. That plausibility cuts both ways: it makes the zero unsurprising, but also makes the paper less informative unless you can show why this margin is policy-relevant. The industry claims you quote concern outlet-level compliance costs for affected chains, not necessarily de novo incorporation by small independents. You need to align the rhetoric with the empirical object.

I would also revise the discussion of the **placebo sector result**. A significant placebo does not validate the design. If anything, it shows the DDD can generate large “effects” when sector-specific England–Scotland shocks occur, which is exactly the identification concern. This should be treated as a cautionary result, not supporting evidence.

A few additional suggestions that would improve the paper materially:

- Add simple figures. At minimum: monthly food-service incorporations in England, Wales, and Scotland separately; England/Scotland ratios; and analogous series for the placebo sectors.
- Report levels as well as logs. With counts this large, level effects are interpretable and help assess whether “less than one firm per month” is a meaningful statement.
- Consider population- or firm-stock-normalized entry rates rather than raw counts.
- If available, use establishment data rather than corporate registrations. The current outcome is a weak proxy for restaurant market entry.
- Clarify whether SIC 56 includes pubs/bars and catering in ways that may dilute the restaurant margin most relevant to calorie labeling.
- Remove the “standardized effect size” table; it adds little and is not informative in this context.

In sum, the main result—a small estimated effect on measured incorporations—is plausible. But the current paper overclaims relative to what the design can support. If you tighten the estimand, fix the England/Wales issue, improve inference, and stop treating a rejected pre-trend test as a minor nuisance, this could become a careful null-result note. In its present form, however, the identification is too weak and the interpretation too strong.
