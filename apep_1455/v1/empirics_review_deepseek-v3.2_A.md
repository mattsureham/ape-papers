# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-04-09T16:53:05.213846

---

**Referee Report**

**Paper:** The Missing Middle Stays Missing: Upzoning and Dwelling Type Composition in New Zealand
**Authors:** APEP Autonomous Research et al.

---

### 1. Idea Fidelity

The paper departs significantly from the original, well-motivated research plan outlined in the Idea Manifest, compromising its core identification strategy and analytical power.

*   **Data Granularity:** The manifest specified using **monthly building consent microdata at the Territorial Authority (TA) level**. The paper instead uses **annual data aggregated to the region level**. This is a major, unjustified reduction in granularity. It discards substantial within-region, within-year variation (e.g., Wellington City vs. Porirua; monthly lags in policy implementation and response), drastically reduces statistical power (from ~6,400 to 165 observations), and potentially obscures early-stage compositional shifts that annual data might average out.
*   **Identification Strategy:** The manifest proposed a **staggered DiD** (Callaway-Sant'Anna/Sun-Abraham) to handle the nuanced, multi-city rollout, with TA as the unit of analysis. The paper’s primary design is a **simple, two-period TWFE DiD** comparing four treated *regions* to eleven control *regions*. This fails to leverage the staggered timing (e.g., Porirua in Sep-2022 vs. Wellington City in 2024) and introduces severe measurement error by treating entire regions (which contain both MDRS and non-MDRS TAs) as homogeneously “treated.”
*   **Missing Analysis:** The manifest’s proposed secondary **Regression Discontinuity Design (RDD) at the lot-size threshold** is absent. This was a key component for strengthening causal inference on the intensive margin.
*   **Research Question Match:** While the paper retains the focus on dwelling-type composition, the flawed empirical execution means its “precise null” finding is not a credible test of the original question. The analysis, as executed, asks whether upzoning *entire regions* changed *regional* composition, not whether the policy changed composition in the *specific cities* where it was applied.

### 2. Summary

This paper investigates whether New Zealand’s 2022 Medium Density Residential Standards (MDRS), a major nationwide upzoning reform, shifted the composition of new housing construction toward multi-unit dwellings. Using annual, region-level building consent data and a difference-in-differences design comparing four treated regions to eleven control regions, the authors find a precisely estimated null effect on the multi-unit share. They conclude that regulatory reform alone is insufficient to produce “missing middle” housing when other constraints (e.g., construction costs, developer capacity) are binding.

### 3. Essential Points (Critical Issues Must Be Addressed)

The paper, in its current form, contains fundamental flaws in its empirical design that undermine the validity of its central claim. The following issues must be conclusively resolved for the paper to be considered for publication.

1.  **Mis-specified Treatment and Inappropriate Data Aggregation:** The unit of analysis (region) does not align with the unit of policy implementation (Territorial Authority/City). Treating the Waikato region as “treated” because it contains Hamilton City, while the region includes many non-MDRS rural and semi-urban areas, introduces severe non-differential misclassification bias. This bias **attenuates the estimated treatment effect toward zero**, making the paper’s “precise null” result potentially an artifact of measurement error. The analysis must be re-run at the **TA level** using the **monthly data** specified in the manifest.

2.  **Invalid Parallel Trends Assumption in a Macroeconomic Downturn:** The paper acknowledges a severe national construction downturn (consents fell ~35%) beginning precisely when the MDRS took effect. The parallel trends assumption requires that, absent the MDRS, the *difference* in multi-unit share trends between treated (major urban) and control (smaller urban) regions would have remained constant. This is highly questionable. Major urban centers (like Wellington and Christchurch) likely have different development portfolios and sensitivities to interest rates and construction cost inflation than smaller cities. A simple pre-trend test over a stable period (2016-2022) is inadequate to guarantee this assumption holds during a historic sectoral contraction. The authors must provide much stronger evidence, such as: (a) event studies showing parallel trends in the *growth rates* of multi-unit vs. single-family consents pre-downturn, (b) a triple-differences design using a non-housing sector as a control for regional business cycles, or (c) compelling narrative/quantitative evidence that the downturn’s impact was homogeneous across treated and control areas.

3.  **Failure to Account for Policy Anticipation and Implementation Lags:** The paper defines the “Post” period starting in August 2022. However, the legislation was passed in December 2021, and developers likely anticipated it. Furthermore, the manifest notes that full implementation in Wellington City was delayed until 2024. The annual aggregation and simple post dummy fail to capture these dynamics. The event study in Table 4 shows no jump in 2023, but this could be due to aggregation and lagged effects. The analysis must use monthly/quarterly TA-level data in a proper **event-study framework** (e.g., Sun & Abraham) to visually and statistically test for anticipation (pre-2022 effects) and to trace the effect dynamics over the 3-4 years post-passage.

### 4. Suggestions for Improvement

**A. Empirical Execution & Identification:**
*   **Follow the Original Plan:** Re-analyze the data at the **TA-month level**. Distinguish between “always-treated” (Auckland, to be excluded), “newly-treated” (Hamilton, Tauranga, Wellington TAs, Porirua, Christchurch with precise operative dates), and “never-treated” (Tier 2/3 TAs) units. This is your most important task.
*   **Implement Staggered DiD Correctly:** Use a robust estimator like the Callaway & Sant’Anna (2021) or Sun & Abraham (2021) method as your primary specification, not just a robustness check. This properly handles heterogeneous treatment timing.
*   **Revive the RDD:** Conduct the planned RDD using LINZ parcel data. Does allowing three units on a ~400m² lot increase the probability of a multi-unit project compared to a ~600m² lot (if such a threshold exists in pre-MDRS rules)? This provides a complementary, within-city identification strategy less susceptible to region-wide shocks.
*   **Strengthen Placebo and Robustness Tests:**
    *   Test for effects on **total consents** and **single-family consents** more thoroughly. A null effect on totals is reassuring but not sufficient.
    *   Conduct a **donut-hole analysis** comparing MDRS TAs to non-MDRS TAs *within the same region* (e.g., Hamilton City vs. surrounding Waikato districts) to control for region-specific demand shocks.
    *   Use **population-weighted** outcomes or include time-varying controls (net migration, local GDP, interest rates) more systematically, even if just in robustness tables.

**B. Interpretation & Mechanism:**
*   **Refine the “Null” Interpretation:** If the re-analyzed results remain null, discuss more nuanced interpretations. Was the policy simply irrelevant, or did it *enable* multi-unit development that was otherwise suppressed by the downturn, resulting in a net-zero compositional effect? The significant negative effect on log(multi-unit levels) hints at this. Explore this “what-if” scenario more deeply.
*   **Deepen Mechanism Analysis:** The discussion of construction costs, developer capacity, and infrastructure is good but speculative. Can you provide any supportive evidence? For example, correlate the (null) treatment effect with TA-level measures of builder concentration, infrastructure spending, or pre-existing medium-density share? Even suggestive cross-sectional heterogeneity analysis would strengthen the mechanism section.
*   **Engage with Literature More Precisely:** Contrast your (revised) findings not just with Auckland’s supply study but directly with the composition-focused papers you cite (e.g., Maltman & Greenaway-McGrevy 2024). Why might results differ between Lower Hutt and the broader Tier 1 cities?

**C. Presentation & Transparency:**
*   **Clarify Data Construction:** The Appendix must explicitly state how TAs are mapped to regions and justify the exclusion of Auckland while including other regions with mixed-treatment TAs. A map would be invaluable.
*   **Justify Aggregation Choice:** In the paper’s current form, you must defend why region-level annual data is preferred over TA-monthly data. Given the manifest’s plan and standard practice in urban economics, this will be a difficult case to make.
*   **Improve Table Readability:** Label event-study years more clearly (e.g., “t-6”, “t+1”) relative to the reform date. In Table 1 (“Summary Statistics”), clarify if the means are for the entire panel period or pre-period only (the text says pre-period, the table seems to be entire panel).
*   **Tone Down Definitive Conclusions:** Phrases like “The finding… suggests that the ‘missing middle’ gap is structural, not regulatory” are too strong for a null result, especially one from a potentially mis-specified model. Frame conclusions as evidence that regulatory reform alone may be insufficient under prevailing macroeconomic conditions.

**Overall:** The research question is important and policy-relevant, and a well-executed null finding would be a valuable contribution. However, the current empirical approach does not meet the standard required for a credible causal test. The authors must fundamentally rework the analysis to align with the original, superior identification strategy. Addressing the three Essential Points is non-negotiable for making the paper credible. The Suggestions provide a pathway to strengthen the paper substantially once the core identification issues are resolved.
