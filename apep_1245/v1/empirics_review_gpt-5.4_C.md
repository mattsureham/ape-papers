# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-04-01T13:02:06.279126

---

## 1. **Idea Fidelity**

The paper only partially pursues the original idea in the manifest. The core policy setting is the same, and the paper does use the symmetric imposition/removal of Korea’s 2023–2025 short-selling ban as a natural experiment. But it departs in important ways from the original identification and data plan.

Most importantly, the manifest’s central treatment-intensity variable was **pre-ban short interest**, ideally from KRX data, with investor-type trading data used to quantify **retail welfare losses**. The paper instead uses **pre-ban volatility** as a proxy for short-selling demand, and it never delivers the proposed welfare calculation. That is a major shift, not a minor implementation detail. Volatility is at best an indirect proxy for shorting demand and also directly proxies for speculative sentiment, disagreement, lottery demand, and exposure to other contemporaneous news. As a result, the paper no longer cleanly identifies “the effect of suppressing negative information” through short-selling demand; it identifies that more volatile stocks moved more around these dates.

The paper also sharply narrows the sample from the manifest’s intended universe of roughly 2,500 stocks to just **69 names**. That is a serious loss of external validity and probably internal validity as well, because sample selection becomes central. Why these 69? Are they the largest firms with reliable Yahoo coverage? Were they chosen partly because they visibly moved on the event dates? With a universal policy and a rich cross-section available from KRX, restricting attention to 69 stocks is hard to justify.

So: the paper keeps the broad question and institutional setting, but misses two of the manifest’s most important elements—**actual short-interest-based treatment** and **retail welfare measurement**—while also abandoning the intended comprehensive sample.

## 2. **Summary**

This paper studies South Korea’s 17-month short-selling ban and argues that stocks with higher pre-ban volatility rose more when the ban was imposed and fell more when it was lifted. The paper interprets this as evidence that short-selling restrictions inflated prices of speculative stocks and ultimately harmed retail investors rather than protecting them.

The topic is important and timely, and the symmetric policy reversal is potentially a strong design. But in its current form, the paper’s evidence is more suggestive than convincing: the treatment proxy is weak, the sample is small and selected, and the welfare claims outrun the results.

## 3. **Essential Points**

1. **You need the actual treatment variable the paper is about: pre-ban short-selling exposure, not just volatility.**  
   The paper’s central causal claim is about the suppression of short sellers and negative information. But the empirical design uses pre-ban volatility, which is not equivalent to shorting demand. Volatility may capture speculative demand, disagreement, retail clientele, industry composition, or sensitivity to macro/AI/battery themes that were very salient in Korea during this period. This is especially concerning because names like Ecopro and battery-related firms had extreme event-date movements for reasons broader than short-selling constraints. At minimum, you need stock-level pre-ban short volume/short balance/lending utilization from KRX or another official source, and you should show that the main results survive when the intensity measure is actual shorting exposure. Without that, the paper’s interpretation is too strong.

2. **The sample choice and representativeness problem must be fixed.**  
   A policy that applied to the entire market should not be analyzed on 69 handpicked stocks unless there is a compelling data limitation, and here there likely is not. Using Yahoo Finance for 69 firms is not credible when KRX data exist. A selected sample creates obvious concerns: selection on liquidity, fame, data availability, sector composition, and ex post salience. The results may simply reflect a handful of large speculative names. The paper should be redone on the full KOSPI/KOSDAQ universe, or at least on a clearly defined, pre-registered rule-based sample (e.g., all common shares with continuous trading and valid pre-ban data). Show how the selected 69 compare with the universe on size, turnover, volatility, and pre-ban shorting.

3. **The welfare and efficiency claims are overstated relative to the evidence.**  
   The paper’s strongest evidence is a cross-sectional event-study relation between volatility and CARs on two dates. That does not by itself establish retail harm, overpricing magnitude, or degraded price efficiency. The variance-ratio section is especially weak and, as presented, does not support the narrative: the during-ban inefficiency estimate is not significant, and the post-ban period looks worse by your own metric. If you want to claim a “retail protection paradox,” you need actual investor-type trading data and a transparent back-of-the-envelope welfare calculation along the lines proposed in the manifest: retail net purchases during the ban interacted with subsequent correction in the same stocks. Otherwise the claim should be softened to say the ban appears to have increased prices of stocks likely favored by retail investors.

## 4. **Suggestions**

The paper has a good question and a potentially publishable setting, but it needs to become much more disciplined empirically. Here are the main ways to improve it.

First, **rebuild the data around KRX rather than Yahoo**. This would solve several problems at once. You can expand to the full stock universe, obtain exchange-consistent returns, access investor-type trading, and likely recover some direct measure of short-selling activity or short balances. In a paper about a market microstructure policy, Yahoo is a weak primary source. Reviewers will immediately ask why official exchange data were not used when available.

Second, **clarify the timing and event windows more carefully**, especially for the lift. The imposition is plausibly close to a clean shock because of the Sunday evening announcement. The lift is not. You acknowledge that reinstatement was announced about a week in advance, but then still treat March 31, 2025 as a sharp event. That makes the “symmetry” argument less persuasive than advertised. A better approach would be:
- analyze both the announcement of the reinstatement date and the actual effective date;
- show cumulative adjustment in the intervening days;
- interpret the lift estimates as lower bounds if the adjustment was anticipated;
- consider distributed-window specifications rather than a single narrow event.

Third, **the market-adjusted abnormal return model needs strengthening**. Using the KOSPI Composite as the sole benchmark for both KOSPI and KOSDAQ stocks is rough, especially because KOSDAQ stocks can have systematically different factor exposures. At minimum, use exchange-specific benchmarks and show robustness to:
- KOSDAQ benchmark for KOSDAQ names,
- estimation-window market model,
- industry-adjusted returns,
- factor adjustments if feasible.

Fourth, **the standard errors are probably not your biggest problem, but they need cleaner presentation**. For the cross-sectional event regressions with one observation per stock, heteroskedasticity-robust SEs are fine in principle. But the tables are incomplete: coefficients are shown without standard errors or \(R^2\), despite text discussing t-statistics and high explanatory power. That is not acceptable in a finance/event-study paper. Also, with \(N=69\), inference can be sensitive to outliers. I strongly recommend:
- reporting HC2 or HC3 robust SEs;
- showing wild-bootstrap p-values;
- reporting influence diagnostics and leave-one-out estimates, especially excluding the battery/EV complex and other obvious extreme movers;
- winsorizing or robust-regressing as a check.

Fifth, **the magnitudes need to be made more transparent and more believable**. Some are plausible; some feel overstated given the design. A coefficient of 0.1317 on annualized volatility means that a 0.16 SD shift in volatility implies about a 2.1 percentage point difference in 3-day CAR, which is economically large relative to the 1.67 percent average CAR. That could be real in this episode, but with only 69 stocks and some spectacular names, it may be driven by a few outliers. The claim that volatility alone explains 49 percent of cross-sectional variation among KOSPI stocks is striking enough that readers will suspect overfitting or selection. You should:
- plot the raw scatter with point labels for the most influential stocks;
- report slope estimates with and without the top 5 movers;
- show binned scatterplots;
- report nonparametric comparisons by volatility quintile;
- test whether the result is monotone, not just linear.

Sixth, **the paper needs stronger falsification tests**. A single placebo date one year earlier is not enough. For this design, you should run a full permutation/randomization-style exercise: estimate the same cross-sectional slope on many non-event dates and show that the true event date is in the extreme tail. This would be much more convincing than one placebo. I would also suggest:
- placebo event dates in the same month in adjacent years,
- placebo using future volatility measured after the event,
- placebo using characteristics that should not proxy for short-selling demand.

Seventh, **deal explicitly with sector composition and contemporaneous narratives**. Korea in late 2023 and early 2025 had very large sector-specific moves, particularly in batteries, biotech, and tech. High volatility stocks are not randomly distributed across sectors. Exchange fixed effects are not enough. Add industry fixed effects or, better, estimate within-industry specifications. Then show the result survives. Otherwise the coefficient on volatility may just be picking up that certain hot sectors moved more around broad policy and risk-on/risk-off news.

Eighth, **the price-efficiency section should either be redesigned or dropped**. As written, it is not helping the paper. The interpretation is muddled, the during-ban estimate is weak, and the post-ban period looks more “inefficient” by your own measure. Also, variance ratios over long periods are influenced by many things unrelated to short-selling constraints. A more convincing efficiency design would focus on whether high-short-exposure stocks exhibited slower post-earnings-announcement drift correction, stronger reversals, or weaker incorporation of bad news during the ban. If you cannot do that convincingly, the paper is cleaner as an event-study paper rather than an efficiency paper.

Ninth, **soften the rhetoric until the evidence catches up**. Phrases like “establish,” “clear welfare conclusion,” and “the ban harmed the investors it was designed to protect” are too strong for what is currently shown. What you have now is evidence of event-date price responses concentrated in volatile stocks. That is interesting. But it does not yet establish a retail welfare transfer. A tighter and more credible framing would be: the ban appears to have disproportionately boosted prices of volatile/speculative stocks, consistent with reduced ability of pessimists to trade; if retail investors were net buyers of these stocks during the ban, the policy may have harmed them.

Tenth, and related, **actually deliver the welfare exercise promised by the title and abstract**. The title says “overpricing” and the abstract says “retail protection paradox.” Readers will expect a quantified retail welfare analysis. If KRX investor-type data are available, compute:
- net retail buying by stock during the ban,
- post-lift correction by stock,
- the implied mark-to-market loss attributable to buying inflated stocks during the ban.

Even a simple lower-bound accounting exercise would make the paper much stronger and more policy-relevant.

Finally, **tighten the presentation and fix internal inconsistencies**. A few examples:
- The abstract says a 1-SD increase in volatility predicts 1.3 percentage points higher returns at imposition, but the text later says 2.1 percentage points. Reconcile this.
- Table notes mention variables not shown and, in places, standard errors “in parentheses” that are not actually printed.
- The efficiency table text says deviation increased during the ban, but Panel A shows a lower average \(|VR-1|\) during the ban than pre-ban.
- The sample period and trading-day counts should be verified carefully.

In short: the setting is excellent, and the broad intuition is plausible. The event-date reactions are likely real. But the current paper does not yet isolate short-selling exposure cleanly, does not justify its sample, and does not substantiate its welfare claims. A version built on full-universe KRX data, actual shorting measures, investor-type trading, stronger falsification, and more disciplined interpretation could be quite compelling.
