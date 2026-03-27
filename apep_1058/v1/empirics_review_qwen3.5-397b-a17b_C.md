# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-27T11:30:21.179453

---

# Review: The Networked Bank Run: Social Connectedness and Deposit Flight During the2023 Banking Panic

## 1. Idea Fidelity

The paper largely adheres to the core conceptual framework outlined in the manifest, specifically the use of the Facebook Social Connectedness Index (SCI) to identify social contagion distinct from geographic or media channels. However, there is a significant deviation regarding data granularity and control variables. The manifest explicitly proposes using **bank-level quarterly deposits from FFIEC Call Reports** to control for "bank balance sheet fundamentals." The submitted paper instead relies on **county-level aggregates from the FDIC Summary of Deposits (SOD)**.

This deviation materially weakens the identification strategy promised in the manifest. By aggregating to the county level, the authors lose the ability to control for local bank fundamentals (e.g., the share of uninsured deposits in county *k*'s local banks), which was a key component of the proposed identification ("controlling for... bank balance sheet fundamentals"). Consequently, the paper cannot fully rule out that socially connected counties simply happened to host banks with SVB-like balance sheet vulnerabilities, rather than experiencing pure social contagion.

## 2. Summary

This paper investigates whether private social networks propagated the March 2023 banking panic beyond the epicenter of Silicon Valley Bank (SVB). Using a shift-share design where county exposure is weighted by social connectedness to SVB's branch footprint, the author finds that a one-standard-deviation increase in network exposure predicts a 0.89 percentage point larger decline in county deposits. The results are robust to pre-trend placebos and a non-failing bank (JPMorgan) placebo, suggesting that private social ties coordinated depositor behavior independently of public information channels.

## 3. Essential Points

1.  **Direct Exposure vs. Contagion (Aggregation Bias):** The outcome variable is total county deposits, which includes deposits held at SVB branches themselves in the nine California counties where SVB operated. Since the Social Connectedness Index (SCI) is highest within a county (SCI$_{c,c}$), counties containing SVB branches mechanically have the highest "Network Exposure." The current results may simply reflect direct withdrawals from SVB branches rather than contagion to *other* banks in socially connected counties. To claim contagion, the outcome must exclude SVB deposits or demonstrate the effect holds for non-SVB banks specifically.
2.  **Endogeneity of Social Weights (Economic Similarity):** The identification relies on the exogeneity of the SCI weights. However, SCI is strongly correlated with economic similarity (e.g., tech hubs are socially connected to other tech hubs). Even with tech employment controls, unobserved economic similarities (e.g., venture capital density, startup culture) could drive correlated deposit flight. The shift-share design requires that the *shares* (SVB footprint) be exogenous to the *weights* (SCI) conditional on controls, but SCI is not randomly assigned. The paper needs to address whether SCI predicts deposit flight in contexts unrelated to SVB (beyond the JPMorgan placebo) to rule out omitted variable bias driven by economic structure.
3.  **Inference and Spatial Correlation:** Standard errors are clustered at the state level (50 clusters). Given that the treatment variable (SCI) is spatially continuous and highly correlated across county borders, state clustering may not fully account for spatial correlation in the error terms. With 3,000 observations, there is sufficient power to implement Conley standard errors or spatial HAC estimators. Reliance solely on state clustering risks overstating precision if residuals are correlated across state lines (e.g., across the NY-NJ-CT tri-state area).

## 4. Suggestions

The paper addresses a timely and important question with a creative identification strategy. However, to meet the standard of a top-field journal like *AER: Insights*, the empirical execution needs to tighten the link between the data and the causal mechanism. Below are specific recommendations to strengthen the analysis.

**Data Granularity and Outcome Construction**
The most critical improvement would be to align the data with the manifest's promise and utilize bank-level data. The FDIC SOD allows for branch-level identification. You should construct the outcome variable as the deposit change for **non-SVB banks only**. Currently, a county with an SVB branch contributes to the regression both as a high-exposure unit and as a unit with massive direct outflows.
*   **Action:** Filter the SOD data to exclude CERT number 24735 (SVB) and its subsidiaries. Re-run the main specification. If the effect disappears, the result is driven by direct exposure, not contagion. If it persists, the contagion claim is much stronger.
*   **Action:** If possible, merge with Call Report data to control for the *local banking sector's* vulnerability. For example, construct a county-level weighted average of uninsured deposit shares for all banks operating in that county (excluding SVB). Include this as a control. This addresses the concern that socially connected counties simply had riskier local banks.

**Refining the Shift-Share Identification**
The shift-share (Bartik) design requires careful handling of the "shares" and "weights."
*   **Leave-One-Out Exposure:** A common critique of shift-share designs is that a single large shock unit drives the results. In this case, Santa Clara County dominates the SVB footprint. Construct a "Leave-One-Out" exposure measure where, for each county $c$, the exposure is calculated excluding the SCI weight connected to Santa Clara County. If the result holds, it demonstrates that the network effect is not solely driven by proximity to the epicenter but by the broader network topology.
*   **Rotemberg Weights:** The manifest mentions Rotemberg weights, but they are not reported in the paper. You should include a table or figure showing the distribution of Rotemberg weights. This informs the reader which counties are driving the identification. If the weights are highly concentrated in a few tech-heavy counties, the external validity of the "social network" claim is limited to similar economic environments.
*   **Exogeneity Test:** Following Borusyak, Hull, and Jaravel (2024), test the exogeneity of the SCI weights. Regress the SCI weights on pre-period county characteristics (income, employment, deposit growth) to show that social connectedness is orthogonal to economic trends prior to the shock.

**Inference and Standard Errors**
Spatial correlation is a first-order concern in network data.
*   **Conley Standard Errors:** Implement Conley (1999) standard errors that allow for correlation between counties within a certain geographic distance (e.g., 500 km). This is more appropriate than state clustering for social network data which ignores political boundaries.
*   **Randomization Inference:** Given the unique nature of the SVB shock, permutation tests could be valuable. Randomly reassign the SVB branch footprint across California counties (keeping the number of branches fixed) and re-estimate the coefficient 1,000 times. Plot the distribution of coefficients. This provides a non-parametric check on the p-value.

**Mechanism and Heterogeneity**
The paper claims the channel is "private social networks" vs. "public information." The current heterogeneity analysis (high vs. low deposit counties) is suggestive but not definitive.
*   **Digital vs. Physical Banking:** If the mechanism is social network transmission via digital channels, the effect should be stronger in counties with higher broadband penetration or higher usage of mobile banking apps. Interact Network Exposure with county-level broadband access data (FCC Form 477).
*   **Demographic Heterogeneity:** Social connectedness might matter more for demographic groups that rely on word-of-mouth. If data permits, interact with age demographics (e.g., younger depositors may be more networked).
*  
