# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-22T13:46:59.163839

---

**Referee Report**

**Paper:** “The Fortress Premium: Exchange Rate Pass-Through and Tourism Demand after Switzerland’s Franc Shock”
**Author(s):** APEP Autonomous Research & @CONTRIBUTOR_GITHUB

---

### 1. Idea Fidelity

The paper aligns closely with the original idea manifest in its core objective, data source, and exploitation of the 2015 SNB shock. However, it departs in one **significant methodological aspect** and omits a planned element:

*   **Primary Identification Strategy:** The manifest proposed a **Bartik shift-share DiD** as the central design, leveraging cross-canton variation in pre-shock exposure (the *share*) interacted with a common shock (the *shift*). The submitted paper’s primary specification (Eq. 1, Table 2 Col 1-2) is a **standard two-way fixed effects (TWFE) DiD** comparing Eurozone to Swiss domestic visitors *within* cantons. A Bartik-style reduced form is presented in Table 2, Column 3 but is poorly explained and yields an insignificant result. The paper does not adequately justify why it abandoned the planned Bartik design, which is better suited to handle heterogeneous treatment intensity across cantons based on pre-existing tourist composition. The current within-canton design, while valid, does not fully exploit the cross-sectional variation in exposure that was central to the original idea.

*   **Omitted Analysis:** The manifest mentioned using Tourism Satellite Accounts and tourism-related employment FTE data. The paper does not incorporate these broader economic outcome variables, which could have strengthened the analysis of aggregate economic impacts beyond hotel stays.

*   **Fidelity Summary:** The paper is faithful to the research question, data source, and shock narrative. However, the shift from a Bartik design to a standard within-unit DiD represents a substantive methodological deviation that weakens the connection to the original identification strategy. The authors should either reinstate and properly motivate a Bartik design or provide a compelling explanation for why the within-canton design is superior in this context.

### 2. Summary

This paper provides a clean, causal estimate of the exchange rate elasticity of tourism demand. Leveraging the unexpected 2015 appreciation of the Swiss franc and granular data on hotel stays by visitor nationality and Swiss canton, it finds a large decline (approx. 24%) in stays by Eurozone visitors relative to Swiss domestic visitors. A key contribution is documenting substantial heterogeneity: the effect is much larger in tourism-dependent Alpine cantons than in urban business centers, highlighting greater price sensitivity for leisure travel.

### 3. Essential Points

The authors must convincingly address the following three critical issues for the paper to be publishable.

**1. The Pre-Trends Evidence Undermines the Parallel Trends Assumption.**
Table 3 (Event Study) shows **strongly positive and statistically significant pre-trend coefficients** for the Eurozone vs. Swiss domestic gap in the decade before the shock. This indicates a sustained period where Eurozone tourism was growing faster than domestic tourism. The sudden reversal in 2015 could therefore reflect a **mean reversion** or the end of a pre-existing trend rather than a causal shock. The authors’ note about “modest negative values” is contradicted by their own table. This is a fundamental threat to identification.
*   **Required Action:** (a) Re-specify the event study with the standard normalization (period t=-1 = 0) and plot the coefficients. (b) Conduct a formal test (e.g., joint F-test) on the pre-period coefficients. (c) Most importantly, the empirical strategy must be modified to account for this. Potential solutions include: introducing origin-group-specific linear or quadratic time trends; using a synthetic control method for the Eurozone group within each canton; or leveraging the continuous “dose” of exchange rate movement (see point 2 below) in a design less reliant on parallel trends for a binary treatment.

**2. The Treatment is Continuous, Not Binary.**
The shock was a currency appreciation of varying magnitude against different origin currencies. Coding visitors as binary “Eurozone” or “non-Eurozone” treats, for example, a French visitor (large EUR/CHF move) and a British visitor (moderate GBP/CHF move) as identically treated. This loses information and muddles the dose-response relationship.
*   **Required Action:** The primary specification should interact the `Post` dummy with a **continuous measure of the exchange rate shock** specific to each origin country (e.g., the percent change in the origin currency/CHF rate from Dec 2014 to Jan/Feb 2015). This directly estimates the elasticity (β = %ΔQ / %ΔE) and provides a more compelling, continuous “dose-response” test. The binary results can remain as a simplified illustration, but the continuous treatment analysis must be central.

**3. The “Placebo” Result for Non-Europeans Actually Suggests a Major Confound.**
Table 5 shows a large *positive* “placebo” effect (+0.243) for Non-European visitors relative to Swiss domestic. The authors explain this as “secular growth,” but this is precisely the problem: strong, origin-specific trends exist. Since time fixed effects are common to all groups, they cannot absorb origin-specific trends. If non-European tourism was on a strong upward trend for unrelated reasons (e.g., rising Asian wealth), and Eurozone tourism was on its own pre-shock trend, the DiD estimate is confounded.
*   **Required Action:** The model must more flexibly account for differential trends by visitor origin. At a minimum, include **origin-group-specific linear time trends**. A more robust approach is to saturate the model with `Origin × Year` fixed effects (or `Origin × Year-Month` if feasible), which would non-parametrically control for all origin-specific annual shocks and trends. This will absorb the “secular growth” in non-European tourism and provide a cleaner isolation of the exchange rate effect.

### 4. Suggestions

**A. Empirical Strategy & Specification**
1.  **Reconsider the Bartik Design:** Revisit the original plan. A well-specified Bartik design (`ΔY_ct = β (EuroShare_c,2014 × Post_t) + γ_c + δ_t + ε_ct`) could be more robust to within-canton pre-trend issues, as it relies on cross-canton variation in exposure. Explain clearly why Column 3 of Table 2 is not the main specification. If cross-canton variation in Eurozone share is too limited (as the note suggests), state this explicitly and justify the within-canton focus.
2.  **Address Few Clusters:** With only 26 cantons, cluster-robust standard errors may be biased. Use **wild cluster bootstrap** procedures for your main specifications to obtain valid inference.
3.  **Refine Control Group:** The Swiss domestic group may also be affected by general equilibrium income effects from the appreciation. Consider a **triple-difference** using non-Eurozone foreign visitors (with their own exchange rate “dose”) as an additional control layer, though this adds complexity.
4.  **Distinguish Margins:** Analyze **log arrivals** separately from log nights to see if the effect works through fewer visitors (extensive margin) or shorter stays (intensive margin).

**B. Presentation & Interpretation**
1.  **Clarify the Shock Magnitude:** The abstract says “12–15% appreciation,” the introduction says “15–20%,” and the elasticity calculation uses ~12%. Justify the choice of 12% for the elasticity calculation. Cite a source for the pass-through rate from nominal appreciation to final tourist prices.
2.  **Improve Table 2:**
    *   Column 3: The note is insufficient. Why is the Bartik coefficient positive? Discuss whether this hints at positive demand shocks in high-Euro-share cantons post-2015 that the within-canton DiD nets out.
    *   Label columns more clearly (e.g., “Canton-Group Level,” “Canton-Origin Level,” “Canton Level (Bartik Reduced Form)”).
3.  **Improve Heterogeneity Analysis:** The canton classification (Tourism/Urban/Other) appears arbitrary. Define these categories based on objective, pre-shock data (e.g., share of overnight stays from abroad, employment in tourism). A continuous analysis (plotting canton-specific coefficients against tourism dependence) would be more persuasive.
4.  **Discuss the Insignificant Randomization Inference:** A p-value of 0.100 from RI is not strong corroborating evidence. Acknowledge this limitation. It likely arises because other periods (e.g., 2010-2011) also saw franc strength.
5.  **Policy Implications:** The claim that tourism costs were absent from SNB analysis needs a citation. Also, discuss the net effect: did growth from non-European markets offset the Eurozone decline? The positive placebo coefficient suggests maybe, which is an important nuance for the overall economic impact.

**C. Additional Robustness Checks**
1.  **Seasonality:** Test if the effect differs between peak (summer, winter) and shoulder seasons.
2.  **Dynamic Effects:** The event study suggests the effect grows for 2-3 years post-shock. Discuss potential mechanisms (multi-year booking patterns, slow adjustment of marketing strategies).
3.  **Price Data:** If you can obtain canton-level hotel price indices, a quick check on whether prices fell in response to the demand shock would be informative, though not essential.

**Overall:** This is a promising paper with a great natural experiment and excellent data. The core finding is plausible and important. However, the current evidence for parallel trends is weak, and the specification does not fully leverage the nature of the shock. Addressing the three essential points is **mandatory**. The suggestions, if implemented, would significantly strengthen the paper and its contribution.
