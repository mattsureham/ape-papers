# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-04-01T13:12:26.368370

---

## 1. **Idea Fidelity**

The paper does **not** really execute the original idea in the manifest. The manifest proposed a notch-bunching design around the 25% disclosure threshold, using the universe of PSC records, pre/post 2016 launch, and ideally the 2023 ECCTA tightening as natural experiments. The paper instead uses a **cross-section from five of 31 chunks in 2026**, abandons the temporal design, and replaces bunching with a “configuration anomaly” statistic based on companies with exactly four individual PSCs.

That shift is consequential. The paper no longer identifies a policy effect of the 2016 reform, nor does it estimate difference-in-bunching around ECCTA. It also does not use pre-2016 ownership data or any credible counterfactual tied to the institutional change. So while the paper is in the spirit of the manifest’s research question—avoidance of the 25% threshold—it misses the key identification strategy, the main natural experiments, and the promised “universe” data.

## 2. **Summary**

This paper documents that among firms with exactly four individual PSCs, a large share have all four recorded in the 25–50% band, which the author interprets as evidence of strategic ownership engineering around the UK’s >25% beneficial ownership disclosure threshold. The paper further shows that this pattern is more common in firms with foreign PSCs and argues that the result reveals a leak in beneficial ownership transparency.

The topic is important and potentially publishable. But in its current form, the empirical design is too weak to support the paper’s central causal and policy claims.

## 3. **Essential Points**

1. **The main benchmark is not credible, so the headline 26:1 result is not informative.**  
   The paper compares the observed frequency of “all four PSCs in the 25–50 band” to a benchmark based on **independent assignment of bands across PSCs**. That assumption is economically and mechanically inappropriate. Ownership shares within a firm must satisfy adding-up constraints, and PSC status itself is selected by the >25% rule. Once you condition on exactly 4 PSCs, independence is especially indefensible. As a result, the exact binomial and permutation p-values do not rescue the design; they are both tied to a misspecified null.

2. **The paper has not established that the observed four-way pattern is avoidance rather than a feature of how PSC data are defined and recorded.**  
   “All four in the 25–50 band” does **not** necessarily mean four owners at 25% each. PSC records are triggered by shares, voting rights, and other control rights; the same individual can qualify on multiple dimensions; and coarse bands obscure exact holdings. More importantly, four people each holding **strictly more than 25% of the same margin** is impossible if those shares sum to 100. This means the paper must first show that the pattern reflects actual equal ownership engineering rather than data architecture, overlapping control rights, duplicate reporting, joint arrangements, or filing conventions.

3. **The paper does not identify the effect of the policy change it is discussing.**  
   Without pre/post evidence around 2016, or before/after 2023 enforcement tightening, the paper cannot claim that the PSC threshold induced restructuring. At most, it shows a cross-sectional anomaly in 2026 data. That is interesting, but it is not the same as showing strategic response to the introduction or strengthening of the regime.

## 4. **Suggestions**

The paper has a good question and a potentially valuable dataset, but it needs a substantial redesign to become convincing. My suggestions are as follows.

First, **return to the original design**. The UK setting is attractive precisely because the PSC regime starts in April 2016 and enforcement changes in 2023. The cleanest paper would exploit those changes directly. Even a simple event-study or cohort-based design would be much more persuasive than the current cross-section. For example:

- Compare newly incorporated firms just before and just after April 2016 in the propensity to adopt four-owner structures or five-owner dilution.
- Track firms over time, if possible, and ask whether PSC counts and ownership-band configurations shift discontinuously after the policy.
- Use ECCTA as a second shock: if the 25% threshold creates gaming and stronger verification raises its cost, some patterns should attenuate or filings should change composition after 2023.

Second, if exact ownership percentages are unavailable, **be very careful about what can be inferred from coarse bands**. “25–50%” is not “25%,” and the language throughout the paper overstates what the data show. I would strongly recommend rewriting the framing from “all four hold 25%” to “all four are reported in the lowest PSC band.” That is still potentially suggestive, but much more accurate. In the current draft, the interpretation often outruns the measurement.

Third, the paper needs a **data-validation section** before any economic interpretation. At minimum, you should tabulate, among firms with four individual PSCs all in 25–50%:

- the associated `nature_of_control` fields,
- whether the qualification is by shares, voting rights, or other influence/control,
- whether there are also corporate PSCs or legal-person PSCs attached to the same company,
- whether the same person appears multiple times,
- whether the company has statements indicating no registrable person or restrictions/ongoing investigations.

If a large fraction of these observations are generated by mixed control categories rather than four equal equity owners, the central interpretation changes materially.

Fourth, the **regression specification should be reconsidered**. The dependent variable is currently an indicator equal to one for “exactly 4 individual PSCs, each in 25–50%,” estimated over firms with 2+ PSCs. That bundles together several margins: having 4 PSCs, having all individual PSCs, and having all in the lowest band. The foreign-PSC coefficient is therefore difficult to interpret. A better approach would decompose the problem:

1. probability of having exactly 4 PSCs,  
2. conditional on 4 PSCs, probability all are individuals,  
3. conditional on 4 individual PSCs, probability all are in 25–50%.

That would tell the reader whether foreign-linked firms are truly more likely to choose the suspicious configuration, rather than simply more likely to have more complex ownership structures.

Fifth, the paper needs a **credible counterfactual**. If you want to keep a configuration-based exercise, compare the 4-PSC pattern to other structures under economically meaningful restrictions, not iid assignment. For instance:

- simulate from the empirical joint distribution of PSC counts and bands, imposing adding-up constraints;
- compare to pre-2016 ownership filings if accessible;
- benchmark against jurisdictions or firm types where the disclosure regime differs;
- examine whether there is excess mass in firms with exactly four shareholders/PSC-linked owners relative to neighboring counts.

Right now, the benchmark is too naive for an AER: Insights paper.

Sixth, the **placebo analysis is internally inconsistent**. Table 1 shows that for 3-PSC firms, 66.6% have all three in 25–50%, which is obviously not a null result relative to the stated benchmark. Yet the text says the anomaly “vanishes” at \(k=3\). That contradiction must be resolved. More broadly, 2- and 3-PSC firms being overwhelmingly concentrated in the 25–50 band may simply reflect the PSC data structure: firms with multiple PSCs often mechanically place everyone in the lowest qualifying band. If so, the 4-PSC result is less distinctive than the paper suggests.

Seventh, **sample construction needs clarification**. Several numbers do not line up cleanly:
- 1.77 million companies are said to be in sample, but the PSC-count totals in Table 1 do not sum to that number.
- The merge rate is only 53%, which raises concerns about selective observability for sector and incorporation-year controls.
- The paper sometimes refers to all companies with PSC records, sometimes to multi-PSC firms, and sometimes to exactly four-PSC firms. Keep denominators explicit everywhere.

Eighth, I would strongly encourage the author to obtain and use the **full register rather than 5/31 chunks**. Given the centrality of rare configurations and cross-tabulations by sector/foreign status, there is little upside to partial sampling if the full data are available. Using the universe would also align the paper more closely with the original motivation.

Ninth, the paper should be much more disciplined in its **policy claims**. The current draft jumps from a descriptive anomaly to statements about a “design failure” of the global AML regime and the “cost of transparency.” That is too strong. The evidence, even if it survives revision, would likely support a narrower claim: the 25% rule may create avoidance incentives and focal ownership structures. It would not yet quantify welfare costs, AML leakage, or the value of opacity.

Finally, on **standard errors and inference**: the robust OLS standard errors in the linear-probability models are not the core problem. At the company level, heteroskedasticity-robust SEs are fine as a default. The real problem is that the paper emphasizes extremely small p-values from tests built on an implausible null. I would de-emphasize significance and focus on magnitudes under better identification. As written, the magnitudes are intriguing but not yet interpretable, because the object being measured is not pinned down.

In short: the paper has a strong topic and a possibly important fact, but the econometrics need to move from “striking pattern” to “credible causal evidence.” If the author can validate the PSC coding, rebuild the counterfactual, and exploit the 2016/2023 policy timing promised in the original idea, this could become a clear and economically meaningful paper. In its current form, it is not there yet.
