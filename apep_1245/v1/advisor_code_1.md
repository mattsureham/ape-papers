# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-01T13:01:18.739632

---

**Idea Fidelity**

The manuscript largely follows the original idea manifest: it studies Korea’s 17-month short-selling ban, emphasizes the symmetric imposition/lift structure, and uses cross-sectional variation in pre-ban firm traits to infer effects. However, it departs from the manifest in several important respects. The manifest proposed exploiting the entire universe of roughly 2,500 listed stocks, using actual short-interest data when available, and focusing on the welfare cost via retail trading volume during the ban. The paper instead analyzes only 69 selected stocks (50 KOSPI, 19 KOSDAQ) and proxies treatment intensity solely with pre-ban volatility, arguing that short-interest data are not available. The welfare discussion remains qualitative rather than the quantitative “retail net purchases × post-ban correction” calculation described in the manifest. These deviations shrink the scope and precision of the original empirical strategy and should be made explicit; if short-interest data are truly unavailable, the paper should motivate and validate volatility as a proxy more systematically and acknowledge the limited sample as a constraint.

---

**Summary**

This paper studies South Korea’s 17-month complete short-selling ban (November 2023–March 2025) as a symmetric quasi experiment by relating cross-sectional pre-ban volatility to cumulative abnormal returns at ban imposition and lift. Volatile stocks earned significantly higher abnormal returns when shorts were banned and suffered larger reversals when the ban ended, a pattern absent in a placebo year. The findings are interpreted as evidence that the ban inflated speculative stocks held by retail investors, creating a “retail protection paradox.”

---

**Essential Points**

1. **Sample representativeness and selection.** The original claim (and policy brainteaser) hinged on exploiting the cross-section of all 2,500 listed stocks, yet the empirical work uses just 69. The paper should either (a) justify why the restricted sample is still informative (e.g., covers firms with the clearest short-selling interest, data limitations) or (b) expand to a larger sample. As it stands, the inferences about aggregate welfare and retail exposure are overstated given the narrow coverage.

2. **Causal interpretation of volatility as treatment intensity.** Pre-ban volatility is treated as a proxy for short-selling demand, but this assumption needs stronger validation. Without direct short-interest data, the paper must demonstrate (e.g., via correlations with contemporaneous short-sale constraints, lending fees, analyst dispersion, or subsequent short-covering activity) that volatility indeed predicts differential short-selling pressure rather than capturing other confounds. Otherwise, the regression may simply be describing a mechanical relationship between volatility and event-driven returns.

3. **Event-window identification and anticipation around ban lift.** The lift was announced in advance and appears to have been anticipated, so the symmetric identification claim is weakened. The paper acknowledges this but does not fully address it: for instance, if prices gradually adjust before the lift date, the [-1,+1] window may understate the true correction and bias the cross-sectional slope. The authors should show the time series of CARs before the lift and either adjust the event window or use a regression of returns on the probability of relaxation to demonstrate that the reversal is indeed driven by the ban’s end rather than concurrent news.

If these issues cannot be convincingly resolved, the paper may overstate its causal claims and should be reconsidered.

---

**Suggestions**

1. **Expand and justify the sample.** If possible, leverage more of the 2,500 listed firms or at least a broader subset that includes smaller stocks. If data constraints (e.g., missing price series) prevent that, then explain why the 69 selected stocks are still relevant—for example, because they are the most liquid and thus the most likely to have attracted short sellers. Provide a table showing how the 69 differ from the rest in terms of size, volatility, retail ownership, etc., to assess representativeness. If selection is driven by data availability rather than economic reasoning, make this transparent and discuss how it might bias the results.

2. **Validate the volatility proxy.** Construct additional evidence that pre-ban volatility is correlated with true short-selling demand or proxies. Possible approaches include:
   - Use alternative pre-ban measures (e.g., analyst forecast dispersion, implied volatility, margin requirements) and show that these yield similar patterns.
   - For the post-ban period when short-sale disclosures resumed (after March 2025), show that stocks that had high pre-ban volatility also exhibited higher short interest once reporting resumed. This would support the proxy’s validity.
   - Link volatility to observable short-selling-related outcomes such as higher lending fees (if data exist) or larger temporary price impact upon the ban’s end.

3. **Address anticipation/decay around the lift.** The advance notice for the lift weakens the identification. To address this:
   - Plot the cumulative market-adjusted returns over a longer window (say, [-10,+10]) around the lift, separately for high- and low-volatility stocks, to document whether the reversal is concentrated at the lift date or already underway beforehand.
   - Alternatively, exploit the variation in announcement timing: if the lift was more anticipated for some stocks (e.g., liquid ones), test whether the volatility slope remains in regressions that use returns from day -5 to day -1 as the outcome. If pre-announcement movement systematically differs across stocks, that would challenge the symmetry claim.
   - Consider an instrumental variable or event-time specification where the dependent variable is the change in expected (ex-ante) returns implied by derivatives or analyst revisions, which may better capture expectation shifts rather than realized returns in a window polluted by anticipation.

4. **Quantify the welfare argument.** The policy contribution hinges on showing that retail investors (the supposed beneficiaries) were hurt. The paper currently asserts this qualitatively. Strengthen it by:
   - Using investor-type trading data (mentioned in the manifest) to compute retail net buying during the ban for the focal stocks. If such data are accessible (perhaps at the aggregate level), present the correlation between retail net flows and volatility or ban-day returns.
   - Multiply the abnormal returns during the reversal by average retail holdings or net purchases to approximate the monetary loss experienced by retail investors, even if only for the 69-stock sample. This would make the “retail protection paradox” more concrete.
   - If retail holdings data are limited, cite existing literature on retail preferences and show that the high-volatility stocks here overlap with typical retail favorites (e.g., from 2020–2021 “donghak ant” trades).

5. **Clarify price-efficiency measures.** The variance ratio analysis is interesting but underdeveloped. Suggestions:
   - Report more conventional efficiency metrics (e.g., autocorrelation coefficients, variance decomposition) and interpret the economic magnitude.
   - Show whether the inefficiency is concentrated in high-volatility stocks by interacting period dummies with volatility, perhaps using quantile regressions.
   - Explain why the post-ban period shows higher inefficiency than the ban period, which seems counterintuitive if the ban suppressed incorporation of information. If the variance-ratio pattern is driven by volatility clustering rather than short-sale restrictions, make that clear.

6. **Discuss potential confounders.** High-volatility stocks may differ along many margins (e.g., growth orientation, retail ownership, sector). While exchange fixed effects are included, consider adding sector or factor controls, or performing a matching exercise that pairs high- and low-volatility stocks within the same industry. This would bolster the claim that the effects are due to short-selling constraints rather than, say, sector-specific news coinciding with the ban.

7. **Place results in broader context.** The manuscript could do more to compare the magnitude of these effects with prior short-selling ban studies. For example, how do the R²s and slope coefficients compare to Beber and Pagano (2013)? Is the 13 percentage-point slope implausibly large relative to earlier evidence? Explicit benchmarking will help readers assess whether Korea’s ban was truly exceptional.

8. **Document the timing of the lift announcement.** The assumption of symmetric surprise is central. Provide precise dates/times of regulatory announcements (e.g., when was the lift date disclosed, when were details of the NSDS released). This could help convince readers that anticipation was limited, especially if the announcement came within a narrow window before the spring 2025 market open.

9. **Address heterogeneity between KOSPI and KOSDAQ.** The results appear driven by KOSPI stocks (Table A1). Discuss whether the policy implications should differ for the two exchanges and explore whether the slope differs by exchange. If the KOSDAQ results are noisy, explain why—maybe because the trade-offs between retail exposure and liquidity differ there.

10. **Check for confounding market-wide events.** Even though the ban announcement happened on a Sunday, other shocks (macroeconomic news, global factors) could still coincide with March 31, 2025. Present evidence (e.g., momentum of global indices, policy news) that no major confounders were clustered on those dates, or show that the results survive controlling for concurrent global or sectoral returns. This will make the identification claim more credible.

Overall, the paper studies an important question with a rare natural experiment, but it needs stronger justification for the proxy, clearer quantification of welfare, and more transparent handling of identification threats before it can convincingly answer its research question.
