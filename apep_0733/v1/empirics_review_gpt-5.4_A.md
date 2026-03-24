# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-03-22T13:46:00.043100

---

## 1. Idea Fidelity

The paper pursues the broad question in the manifest: how the January 2015 SNB floor exit affected Swiss hotel demand using HESTA data disaggregated by canton and visitor origin. It also preserves the core institutional motivation and uses the right broad outcome/data source.

That said, the paper materially departs from the manifest’s strongest proposed design. The manifest emphasized a Bartik/shift-share design exploiting cross-canton differences in pre-shock foreign-tourist composition across 78 origins, ideally combined with a triple-difference structure within canton and across origin groups. In the paper, the main specification is instead a much simpler within-canton DiD comparing Eurozone visitors to Swiss domestic visitors. The Bartik specification is relegated to one reduced-form column, is imprecisely estimated, and in fact goes in the wrong sign. Since the paper’s headline claim rests on the simpler DiD rather than the shift-share design, the paper does not fully deliver on the original identification strategy.

This matters because the manifest’s key advantage was the use of differential exposure across origins and cantons. The current paper collapses much of that variation into coarse origin groups and then interprets the resulting contrast as exchange-rate pass-through. That is a weaker design than the one originally envisioned, especially given obvious concerns that Eurozone and Swiss domestic tourism were on different underlying trends even before 2015.

## 2. Summary

This paper studies the effect of the January 2015 Swiss franc appreciation on Swiss hotel demand using HESTA monthly data by canton and visitor origin. The main result is that Eurozone overnight stays fell sharply relative to Swiss domestic stays after the shock, with larger declines in tourism-oriented cantons than in urban business centers; the paper interprets this as evidence of high exchange-rate elasticity of tourism demand.

The topic is important and the institutional setting is potentially compelling. However, the paper in its current form does not yet establish a credible causal estimate of exchange-rate pass-through, because the empirical design does not adequately address differential pre-trends and compositional changes across origin markets.

## 3. Essential Points

1. **The identification strategy is currently not credible because the control group is not plausibly comparable, and the paper’s own event-study evidence rejects parallel trends.**  
   The main design compares Eurozone visitors to Swiss domestic visitors within canton. But Table 2 shows large, highly significant pre-trends for nearly the entire pre-period. That is not a minor imperfection; it is a direct failure of the identifying assumption. The text describing these pre-trends as “generally small” is inaccurate. Moreover, the placebo shock in 2012 is also significantly negative, which reinforces the concern that the paper is picking up longer-run relative decline in Eurozone tourism rather than the 2015 shock itself. Unless the authors can replace or substantially strengthen the design, the headline causal interpretation is not warranted.

2. **The empirical approach does not yet match the exchange-rate research question closely enough.**  
   The paper aims to estimate exchange-rate pass-through to demand, but the main treatment is a binary “Eurozone × Post” indicator. This ignores the rich cross-origin variation in actual bilateral exchange-rate movements that is central to the question. A convincing version of this paper should exploit country-level treatment intensity—at minimum using origin-specific exchange-rate changes, ideally in a canton × origin × month panel with origin and canton fixed effects and dynamic effects around January 2015. As written, the design conflates exchange-rate exposure with broad origin-group-specific demand trends.

3. **Several results and interpretations are internally inconsistent and weaken confidence in the analysis.**  
   The Bartik coefficient is positive and insignificant, despite the manifest and paper’s framing that higher pre-exposure should predict larger declines. The non-European “placebo” is strongly positive, suggesting major differential origin-trend shifts after 2015. Randomization inference yields only a marginal p-value. The text of the event study does not match the reported coefficients. These are not fatal individually, but together they indicate that the current empirical narrative is too confident relative to the evidence.

## 4. Suggestions

The paper has the ingredients for a useful short paper, but it needs a substantial redesign around the strongest available variation. My suggestions below are intended to help the authors get there.

First, **rebuild the analysis around the origin-country panel rather than the coarse Eurozone-versus-Swiss contrast**. The HESTA data are unusually rich; the paper should use them. A natural specification is at the canton × origin × month level:
\[
\log Y_{cot}=\alpha_{co}+\delta_{ct}+\lambda_{ot}+\beta \cdot Exposure_{ot}+u_{cot},
\]
or some close variant, where \(Exposure_{ot}\) is the post-2015 bilateral exchange-rate change relevant for origin \(o\), \(\alpha_{co}\) are canton-origin fixed effects, and the time effects are chosen to absorb broad canton-level and origin-level shocks. The exact FE structure will depend on what variation remains identified, but the key point is to use **continuous treatment intensity** tied to actual exchange-rate movements rather than a binary Eurozone indicator. This would align the empirical approach much more closely with the stated research question.

Relatedly, I would strongly encourage the authors to **implement the triple-difference idea implicit in the manifest**. A design comparing, within canton and month, more exposed origins to less exposed origins before and after January 2015 is much more persuasive than comparing foreigners to Swiss domestic travelers alone. Swiss domestic demand is an especially problematic control because it responds to many forces unrelated to the franc shock: substitution away from foreign travel by Swiss residents, changes in domestic business travel, and differential income effects. Those mechanisms are economically interesting, but they make domestic tourists a poor stand-alone counterfactual for Eurozone tourists.

Second, **take the pre-trend problem seriously and make it central rather than peripheral**. In AER: Insights format, one clean event-study figure would be more persuasive than several coefficient tables. I would suggest a monthly event study centered on January 2015, estimated on a narrower window such as 2012–2017, with seasonality absorbed flexibly. If pre-trends remain visible even in the narrower window, the paper should not claim a clean DiD effect. In that case, the authors could instead reposition the paper as estimating the effect of a sharp appreciation in a setting with pre-existing erosion of European demand, using methods that allow for differential trends.

Concretely, the authors should try:
- allowing origin-group-specific linear or flexible pre-trends;
- restricting the comparison set to European non-euro countries with similar tourism composition but smaller CHF appreciations;
- using synthetic-control-style reweighting or matching at the origin level;
- estimating local projections around the shock date using a short window rather than one permanent post dummy.

Third, **exploit actual booking seasonality and timing of exposure**. The shock happened mid-January 2015, but many ski-season trips were booked in advance. One might therefore expect weaker immediate effects and larger effects in later months or the following winter season. A monthly dynamic analysis by season would both sharpen the mechanism and help validate the interpretation. If the response is strongest exactly where one would expect repricing and replanning to matter, that would strengthen the case considerably.

Fourth, **clarify the economic object being estimated**. The paper interprets the coefficient as a tourism demand elasticity with respect to the real exchange rate of about -2.0. That step is too quick. A reduced-form decline in overnight stays for Eurozone visitors relative to Swiss domestic visitors is not automatically an elasticity with respect to a common percentage price change. The relevant exchange-rate movement differed across origins and over months; hotel prices may also have adjusted in CHF; and total trip cost includes transport and food, not just lodging. If the authors want an elasticity, they should estimate it directly using origin-specific exchange-rate changes and be explicit about whether the elasticity pertains to hotel nights with respect to the bilateral nominal or real exchange rate. Otherwise, it is safer to present the core result as a reduced-form demand response.

Fifth, **reconsider the Bartik design rather than dropping it after one weak table**. The manifest’s original insight was strong: cantons differed in pre-shock exposure because of their tourist-origin mix. The current Bartik implementation appears too coarse, and the paper acknowledges little cross-canton variation in Eurozone shares. But the better shift-share object is not simply the Eurozone share; it is the canton’s predicted appreciation exposure based on its full 2014 origin composition interacted with origin-specific post-shock CHF movements. That exposure should vary much more than a single Eurozone share. If that more faithful Bartik design still produces weak results, that is itself informative and should temper the claims.

Sixth, **address compositional demand shocks across origins much more explicitly**. The positive non-European “placebo” is not something to wave away. It suggests that post-2015 origin-specific growth trajectories were diverging for reasons beyond exchange rates—especially rising Asian tourism. That is exactly why coarse origin-group DiD is problematic. The authors should show that the results are not driven by secular reorientation of Swiss tourism toward non-European markets, perhaps by:
- focusing on Europe only;
- comparing euro and non-euro European origins with similar distance/income;
- including origin-specific trends;
- excluding fast-growing long-haul markets entirely.

Seventh, **improve inference**. With only 26 canton clusters, conventional clustered standard errors may be fragile. The paper mentions randomization inference, but the reported RI p-value of 0.100 is notably weaker than the conventional inference and deserves more discussion. I recommend reporting wild-cluster bootstrap p-values for the main estimates. Also, if the preferred specification shifts to canton × origin panels, clustering may need to be multiway or at a more aggregated level depending on the source of identifying variation.

Eighth, **tighten the presentation and ensure tables match the text**. At present there are several discrepancies:
- Table 2 pre-trends are positive and significant, while the text characterizes them as small and partly negative.
- The text references a “sharp discontinuity” and coefficients of -0.25 to -0.40 post-shock, which do not match the displayed table.
- The Bartik estimate has the wrong sign relative to the paper’s mechanism.
These inconsistencies make it hard to assess the actual evidence. For a short-format journal, the empirical story needs to be very clean and internally coherent.

Ninth, **tone down the business-versus-leisure interpretation unless supported with direct evidence**. The heterogeneity by “tourism” versus “urban” cantons is suggestive, but canton type is not the same as trip purpose. Geneva, Zurich, and Vaud also host substantial leisure tourism, while Alpine cantons host conferences and domestic second-home travel. If trip-purpose data are unavailable, the paper should frame this as heterogeneity by destination type rather than claiming that business travel is less elastic. Even a simple validation—e.g., showing stronger effects in ski-heavy months or resort municipalities—would make that interpretation more convincing.

Finally, **the paper would benefit from a more modest and transparent contribution statement**. There is clearly something important in these data, and the 2015 SNB shock is worth studying. But the strongest contribution is likely not “a clean natural-experiment estimate of exchange-rate elasticity” in the current design. Rather, it may be a high-frequency, granular description of how a major currency appreciation reallocated Swiss hotel demand across origins and destination types, with suggestive causal evidence once origin-specific exposure is incorporated. Framed that way, and with a redesigned empirical strategy, this could become a strong and credible AER: Insights-style paper.

Overall, I find the question promising and the data excellent, but the current causal design is too weak for the claims being made. A revised paper that leans into the origin-level variation and confronts the pre-trend problem head-on would be much more compelling.
