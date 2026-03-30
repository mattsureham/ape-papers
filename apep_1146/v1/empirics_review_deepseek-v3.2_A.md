# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-30T15:40:54.729145

---

**Referee Report: "Lumpy Signals: How Batched Land Auctions Increased Housing Price Volatility in China"**

This paper examines the effect of China's 2021 "double concentration" land auction reform, which forced 22 major cities to batch residential land auctions into three annual rounds. Using a difference-in-differences (DiD) design with 70 cities, the paper finds the reform increased month-to-month volatility in new-construction housing prices by approximately 17%, with effects concentrated in Tier-1 and "hot" housing markets. The analysis is competently executed, the writing is clear, and the topic is policy-relevant. However, significant concerns regarding the alignment of the empirical exercise with the proposed theoretical mechanism, the credibility of the identification strategy, and the depth of the analysis must be addressed before the paper can be considered for publication.

---

### 1. Idea Fidelity

The paper **deviates substantially from the original research idea** outlined in the provided manifest. The manifest proposed a study of **within-city housing price dispersion** (specifically, the coefficient of variation across property size categories) and **developer market concentration**. The theory was about "lumpy information arrival" affecting the cross-sectional distribution of prices and market structure.

Instead, this paper studies **aggregate city-level price volatility** (absolute month-on-month change). This is a different outcome with a distinct theoretical implication. Volatility is about the time-series variation of an aggregate index; dispersion is about the cross-sectional spread within a city at a point in time. The former could result from synchronized city-wide shocks, while the latter speaks directly to how information is aggregated across heterogeneous market segments. The shift from dispersion to volatility represents a fundamental change in the research question. Furthermore, the paper completely omits the planned analysis of developer outcomes (concentration, stock returns), which was a key secondary component of the original idea. While focusing on a single outcome can be valid, the author must explicitly justify why the core idea of price dispersion was abandoned and how the current focus on volatility relates to the proposed information mechanism.

### 2. Summary

The paper provides causal evidence that consolidating urban land auctions into three annual batches increased short-run volatility in new-construction housing prices in treated Chinese cities. The effect is absent for used housing, which the author interprets as evidence that the mechanism operates through the land auction information channel rather than city-wide shocks.

### 3. Essential Points (Critical Issues to Address)

The authors must convincingly address the following three issues. Failure to do so would be grounds for rejection.

**1. Reconcile the Empirical Focus with the Theoretical Mechanism.** The paper is theoretically motivated by the literature on information aggregation (Hayek, Grossman-Stiglitz) and the idea that batching creates "lumpy information arrival." However, the chosen outcome—city-level price volatility—is only loosely connected to this theory. A stronger test would analyze **cross-sectional price dispersion** (as originally intended), as lumpy information could lead different segments (e.g., luxury vs. affordable) to update expectations differently, increasing dispersion. Alternatively, if volatility is the focus, the mechanism should be more directly tested. For example, does volatility spike in the months immediately following batched auction rounds? The current used-housing placebo is a good start but is a passive test; an active test showing volatility is correlated with auction timing would be more compelling. The author must either reframe the theory to explicitly predict aggregate volatility or reorient the empirics to test the dispersion implications of lumpy information.

**2. Substantially Strengthen the Credibility of the Parallel Trends Assumption.** The identifying assumption is that, absent the reform, price volatility trends would have been parallel between treated and control cities. This is highly questionable.
*   **Confounding Policies:** The treatment coincides with the intense implementation of the "Three Red Lines" policy (2020-2021), which targeted developer leverage. It is plausible that large, Tier-1 developers (concentrated in treated cities) were more affected, potentially altering their bidding behavior and project timing in ways that affect price volatility independently of auction batching. The single interaction control in Column 2 of Table 2 is insufficient. The author must directly control for city-level exposure to this policy (e.g., using developer leverage profiles) or provide compelling evidence that its effects are orthogonal to treatment status.
*   **COVID-19 Dynamics:** The author acknowledges a significant COVID placebo effect (Table 4, Column 1). The event study (mentioned but not shown) is crucial. It must be provided and should demonstrate a clear break precisely at the reform date, not a continuation of a differential COVID recovery trend. The control group of smaller cities may have experienced a different post-COVID economic and housing market trajectory. The author should test for sensitivity to alternative control groups constructed via matching on pre-COVID trends and economic characteristics.
*   **Pre-Trends Visualization:** A full event-study graph with 95% confidence intervals for all pre- and post-period months is non-negotiable. The text's claim of "approximately zero effects for most pre-reform months" needs visual verification.

**3. Provide a More Convincing, Direct Test of the Proposed Mechanism.** The used-housing placebo is the paper's primary mechanism test, but it is indirect. It rules out *only* shocks that affect new and used markets identically. It does not rule out shocks specific to the *new* housing market in treated cities that are unrelated to land auction information flow (e.g., changes in pre-sale regulations, construction material supply chains, or new-home buyer sentiment). To strengthen the case for the "lumpy information" channel, the author should:
    *   Test for **dynamic effects** around auction rounds. Does volatility increase specifically in the 1-2 months following a batched auction? Is it subdued in the months between rounds?
    *   Utilize the **property-size-category data** mentioned in the manifest. If information is lumpy, do price changes for different size categories become less synchronized (increasing cross-sectional dispersion) after the reform? This would directly link to the original idea and provide powerful supporting evidence.
    *   Consider a "close call" or border-pair design focusing on cities just above and below the administrative threshold for treatment, if a plausible cutoff exists.

### 4. Suggestions for Improvement

*   **Reframe the Introduction and Theory Section:** Clearly state that the paper examines the effect of auction frequency on **price volatility**. Ground this in a simple theoretical model or clear hypotheses derived from market microstructure, explaining why batching might increase the variance of price updates. Distinguish this from the (perhaps more intuitive) question of price dispersion.
*   **Expand the Data and Measurement Appendix:** The NBS indices are known to be smoothed and potentially manipulated. A short discussion of this and its implications (likely biasing results toward zero) is necessary. Describe the exact AKShare call used. Clarify why Suzhou is excluded.
*   **Deepen the Heterogeneity Analysis:** The Tier-1 vs. Tier-2 split is useful. Go further. Interact treatment with pre-reform measures of market liquidity, developer concentration, or reliance on land sales revenue. This can help rule out alternative mechanisms (e.g., fiscal stress responses).
*   **Improve the Robustness Checks:**
    *   Conduct a **randomization inference** test, randomly assigning the "treatment" status among the 70 cities to generate an empirical p-value distribution.
    *   Report results using **Conley-Taber standard errors** for a small number of treated clusters.
    *   Test sensitivity to using a **long-difference model** (comparing pre- and post-period averages) to reduce noise from monthly fluctuations.
*   **Revisit the Conclusion:** The policy discussion is one-sided, focusing on a "cost." Acknowledge that the reform may have achieved its *stated goals* (e.g., reducing land premium volatility or curbing speculation). The conclusion should present a balanced cost-benefit consideration based on the paper's findings and the policy's objectives.
*   **Presentation and Tables:**
    *   **Table 1 (Summary Stats):** Include a column for the DiD difference (Post-Pre for Treated vs. Control). This sets the stage for the regression.
    *   **Table 2 (Main Results):** The column labeled "+ Tier ctrl" is unclear. Specify the exact interaction (Tier-1 × Post?). Label columns more intuitively (e.g., "Baseline," "+ Tier-1 Interaction").
    *   **Create and Discuss an Event-Study Figure:** This is essential for assessing parallel trends and dynamic effects. Plot coefficients and confidence intervals for leads and lags relative to the reform.
    *   **Clarify the "Hot/Cold" Market Split:** In Table 3, is this split within the treated group or the full sample? The note says "all 70 cities," but the number of treated cities differs (9 vs. 12). Explain how this classification interacts with the DiD design.

**Overall Judgment:** The paper identifies a interesting policy shock and applies standard empirical methods. However, in its current form, it is a well-executed but somewhat superficial application of DiD to a new policy. To make a significant contribution, it must either (a) rigorously tackle the harder and more novel questions of price dispersion and developer outcomes as originally proposed, or (b) significantly deepen the analysis of volatility by providing airtight identification and direct, dynamic tests of the information channel. I recommend **major revisions** along the lines detailed above. The project has promise, but substantial work is needed to elevate it to the standards of a top-tier journal.
