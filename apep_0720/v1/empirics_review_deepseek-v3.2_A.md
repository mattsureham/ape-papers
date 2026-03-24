# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-18T00:41:46.164010

---

### **Referee Report**

Thank you for the opportunity to review this manuscript, “Your Bet Ate My Lottery? Sports Betting Legalization and the Fiscal Cannibalization Hypothesis.” The paper addresses a timely and policy-relevant question using a credible staggered-adoption design and a valuable administrative dataset. My review is structured as requested.

---

### **1. Idea Fidelity**

The paper partially pursues the original idea but deviates from the proposed research design in several critical ways, weakening its ability to answer the core cannibalization question.

*   **Research Question & Scope:** The original manifest proposed a “unified framework tracing revenue reallocation across ALL categories,” with a primary focus on **lottery revenue** as a key target for cannibalization. The submitted paper, however, centers its analysis on the aggregate “Amusement/Gambling” tax category (T11). This shift is a major limitation, as T11 mechanically increases when sports betting taxes are added, conflating the new revenue stream with changes in *other* gambling revenues. The analysis of pari-mutuel taxes (T20) is preserved, but the lottery channel—the most fiscally significant potential source of cannibalization—is not directly tested with the proposed supplementary NASPL data.
*   **Identification Strategy:** The manifest specified 39 treated states. The paper uses only 26. This significant reduction requires explicit justification (e.g., data availability, definition of “material” revenue) as it alters the external validity and statistical power of the study. The use of Callaway-Sant'Anna DiD is consistent with the plan.
*   **Data:** The paper uses the primary Census STC data as intended. However, it does not incorporate the planned supplementary lottery sales data (NASPL), which is essential for a direct test of the most plausible cannibalization channel.

In summary, the paper provides a test of whether **total** gambling-related tax revenue increased, but it does not fully execute the planned, more nuanced test of whether new sports betting revenue **cannibalized** existing, specific revenue streams like the lottery.

### **2. Summary**

This paper provides the first national-scale, staggered difference-in-differences analysis of the impact of online sports betting legalization on state tax revenues. Using Census data from 2012-2022, it finds a large, statistically significant increase in aggregate “Amusement/Gambling” tax revenue and no evidence of decline in pari-mutuel taxes, concluding that the gambling revenue “pie” expanded in the short run rather than being reshuffled.

### **3. Essential Points (Must Address)**

The following issues are fundamental and must be convincingly resolved for the paper to be suitable for publication.

1.  **The Primary Outcome Variable is Mis-specified for the Research Question.** The dependent variable in the main analysis—log(T11)—is not fit for purpose. Category T11 (“Amusements”) is a basket that includes taxes on all forms of legal gambling. When a state legalizes sports betting, those new tax dollars are *added to* T11. Therefore, finding that T11 increases post-legalization is tautological; it confirms that states collected *some* sports betting revenue, not that cannibalization did *not* occur. To test cannibalization, the analysis must isolate the *non-sports-betting components* of T11 (e.g., casino taxes, lottery transfers) or, better yet, use disaggregated data. The current setup cannot distinguish between a net increase in gambling revenue and a scenario where sports betting revenue simply offsets declines in other T11 components.

2.  **Direct Evidence on Lottery Revenue is Missing and Crucial.** The central fiscal trade-off debated by policymakers is between sports betting and the state lottery. The paper notes the New York case study but does not test this channel with its own data. The original manifest listed NASPL lottery sales data for this reason. The authors must incorporate a direct analysis of lottery revenue (using NASPL or another source) as a core outcome. Without it, the paper’s conclusion that “the gambling dollar… is not zero-sum” is not fully supported, as the largest potential source of substitution remains unexamined.

3.  **Justification for the Treatment Sample is Incomplete.** The analysis departs from the pre-analysis plan by defining 26 treated states versus the 39 mentioned in the manifest. The criteria for inclusion (“collects material sports betting tax revenue”) must be clearly defined and justified. A table listing all 51 jurisdictions, their treatment year (or never-treated status), and the sports betting tax revenue collected (if any) in the first year of treatment is essential. This transparency is needed to assess potential selection bias (e.g., if states with weaker pre-existing lottery growth legalized earlier) and to allow for replication.

### **4. Suggestions**

The following recommendations are offered to strengthen the paper.

*   **Reframe the Analysis Around the Cannibalization Test.**
    *   **Primary Analysis:** The core test should use an outcome that reflects *pre-existing* gambling revenues. This could be operationalized as: **Log(Total Gambling Tax Revenue *Excluding Sports Betting*)**. Constructing this will require obtaining or estimating sports betting tax revenue by state-year (available from sources like the American Gaming Association or state reports) and subtracting it from T11. This is the cleanest test of the cannibalization hypothesis.
    *   **Secondary Analyses:** Present the results for the individual components as originally envisioned: (1) Lottery Revenue (NASPL), (2) Pari-mutuel (T20), (3) Alcohol Tax (T10, as a complement test), (4) Placebos (Sales Tax T09, Tobacco T16). The current table can be restructured to reflect this hierarchy of outcomes.

*   **Address Threats to Identification More Thoroughly.**
    *   **Parallel Trends:** Present event-study graphs for the key outcomes (lottery, non-sports T11, pari-mutuel) using the CS-DiD framework. The paper mentions testing pre-trends but does not show the results. Visually assessing pre-trends is a standard requirement.
    *   **COVID-19 Confounder:** The treatment period (2019-2022) is entirely confounded by the COVID-19 pandemic, which dramatically affected state budgets, consumer behavior, and gambling venues (e.g., casino closures). The claim that state and year FE absorb this is insufficient, as the pandemic’s impact varied by state. Conduct a robustness check interacting year dummies with state-level pandemic severity measures (e.g., monthly unemployment spikes, stringency indices) or estimate the model on the pre-2020 period only (though this shortens the post-period).
    *   **Heterogeneity by Tax Rate:** The original manifest planned to test heterogeneity by state tax rate. This is an excellent idea and should be implemented. A simple test is to split the sample by high/low tax rate or include an interaction `Post x Treated x TaxRate`. This can speak to the fiscal efficiency of legalization.

*   **Improve Presentation and Interpretation.**
    *   **Interpretation of Magnitude:** The main coefficient of 0.66-0.74 log points is interpreted as a “rough doubling” (94% increase). This seems extremely large for total gambling revenue. Provide a back-of-the-envelope calculation: compare the estimated dollar increase (from a levels regression) to the average annual sports betting tax revenue collected in treated states. This will help readers judge if the effect is plausible or if it suggests the coefficient is capturing more than just sports betting.
    *   **Theoretical Framework:** Briefly sketch a simple theoretical model of a constrained gambling budget. This would clarify the null hypothesis (perfect substitution, zero net effect) and alternative hypotheses (market expansion, complementarity).
    *   **Visualization:** Include a map showing the staggered rollout of legalization over time. This effectively communicates the source of identifying variation.

*   **Discussion and Limitations.**
    *   **Time Horizon:** Emphasize that the results capture the short-run (2-4 year) effect. Cannibalization may be a dynamic process that unfolds over a longer period as habits form. This should be a central point in the discussion.
    *   **General Equilibrium Effects:** Acknowledge that legalization may increase overall gambling advertising and normalization, potentially growing the total gambling market over a longer horizon beyond what this study can measure.
    *   **Mechanism:** The discussion offers three interpretations (new participants, increased intensity, novelty). Suggest how future research could test these, e.g., using individual-level survey data on gambling participation.

**Conclusion:** The paper has a strong foundation—a clear policy shock, appropriate methods, and valuable data. However, in its current form, it does not adequately test the fiscal cannibalization hypothesis it sets out to examine. By refocusing the analysis on disaggregated revenue streams (especially the lottery), providing a cleaner cannibalization test, and robustly addressing confounding from COVID-19, the authors can make a significant and credible contribution to the literature. I look forward to seeing a revised draft.
