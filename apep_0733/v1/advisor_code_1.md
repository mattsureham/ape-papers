# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-22T13:45:13.374823

---

**Idea Fidelity**

The paper largely follows the manifested idea: it exploits the January 2015 franc shock, uses HESTA monthly canton-by-origin data, and implements intra-canton comparisons of Eurozone and Swiss visitors to recover exchange rate pass-through to tourism demand. The data description, treatment timing, and focus on exchange rate heterogeneity are all faithful. However, the manifest’s triple-difference/Bartik strategy — leveraging differential exposure across both visitor origin and canton composition — is only partially implemented. Table 3’s Bartik specification lacks statistical precision and is not fully integrated into the identification narrative; the paper relies principally on the simpler within-canton Eurozone-vs-domestic DiD. A clearer explanation of how the Bartik variation supplements the DiD (or why it fails) would realign the paper with the original identification ambition.

**Summary**

The paper estimates the causal effect of the 2015 SNB removal of the EUR/CHF floor on Swiss hotel demand using canton-level monthly HESTA data, comparing Eurozone visitors (treated) to Swiss domestic visitors (control). A within-canton DiD yields a roughly 24% decline in Eurozone overnight stays post-shock, implying a real exchange rate elasticity near –2.0, with larger effects in leisure-oriented cantons than in business centers. Event studies and heterogeneity checks are used to argue for exchange-rate-driven demand shifts across visitor origins.

**Essential Points**

1. **Parallel Trends and Control Validity.** The identification hinges on Swiss domestic tourism providing a valid counterfactual for Eurozone tourism within each canton. The event study in Table 2, however, shows sizable positive coefficients for years –10 through –2, indicating that the Eurozone/domestic gap was evolving before the shock (and not flat). This undermines the key parallel-trends assumption. The authors need to show more convincingly that the pre-trends are either absent in the most relevant window (e.g., 2010–2014) or that the estimated pre-trends do not distort the post-shock estimate (e.g., by including linear trends or synthetic control). Without addressing this, the causal interpretation is fragile.

2. **Differential Trends by Visitor Origin.** Swiss domestic tourism could itself be responding to factors correlated with foreign demand (e.g., a business cycle shift, domestic policies, or exchange rate effects on domestic leisure). The paper does not explore whether domestic tourism exhibits seasonally-varying, origin-correlated shocks that could confound the DiD. The authors should either demonstrate that domestic tourism trends are stable (e.g., via placebo “treatment” for other origins) or use alternative control groups (e.g., non-Eurozone European tourists with near-zero appreciation) to bolster identification. Relying solely on domestic visitors risks attributing to exchange rate effects what might partly reflect broader tourism demand shifts.

3. **Bartik Specification and Exposure Measurement.** The Bartik regression in Table 1 is introduced but not effectively developed: the exposure weights show little cross-sectional variation, the coefficient is imprecise and counterintuitive (positive but insignificant), and the connection back to the “shift-share DiD” promised in the manifest is weak. Either deepen this analysis—clarify how this specification contributes to identification, perhaps by augmenting it with more granular exposure (e.g., canton-by-origin shares), or drop it to avoid confusing the reader. Additionally, the exposure definitions (Eurozone vs. non-Eurozone) are quite coarse; finer variation in actual exchange rate changes across currencies (or a continuous exposure variable) could improve precision.

If these three points cannot be addressed satisfactorily, the paper risks overclaiming a causal effect; rejection might be appropriate, as the identification would remain unconvincing.

**Suggestions**

1. **Strengthen Pre-Trend Evidence.** Re-estimate the event study using post-2010 data with tighter windows (2011–2014) and display the coefficients graphically with confidence intervals. Alternatively, de-trend the pre-period or include canton-by-origin linear time trends in the main specification, then show that the coefficient remains stable. Presenting a placebo DiD where the “shock” occurs in an earlier year (as in Table 4) is useful; extend that exercise by conducting a rolling DiD or a permutation test that assigns the shock to every possible year and plot the distribution of coefficients to show 2015 is a clear outlier.

2. **Augment Control Group Strategy.** Introduce additional control groups beyond Swiss domestic visitors. For example, compare Eurozone visitors to those from countries whose currencies appreciated differently (e.g., UK, Scandinavia) but whose tourism patterns are similar. Alternatively, within the origin-level panel, interact the treatment indicator with a continuous measure of each origin’s exchange rate change vis-à-vis the franc—this would allow a dose-response curve rather than a binary Eurozone/non-Eurozone split. Such continuous exposure would mitigate concerns that domestic tourism has unrelated trends.

3. **Clarify the Multi-Level Identification Framework.** If the intention is to leverage both within-canton (group-level) and cross-canton (share-based) variation, provide a unified model. For instance, estimate a specification of the form:
   \[
   \ln Y_{cgt} = \alpha_{cg} + \gamma_t + \beta_1 \cdot \text{Post}_t \times \Delta \text{ER}_g + \beta_2 \cdot \text{Exposure}_{c} \times \text{Post}_t + \varepsilon_{cgt},
   \]
   where $\Delta \text{ER}_g$ is the currency-specific appreciation and $\text{Exposure}_{c}$ is the canton’s pre-shock Eurozone share. This would make explicit how between-canton shares identify the effect, and the Bartik-style reduced form would naturally emerge. Discuss how much variation comes from each term and why the Bartik estimate in Table 1 behaves as observed.

4. **Provide Consumer Price Adjustment and Real Exchange Rate Context.** The elasticity interpretation depends on treating the franc shock as a pure price change. Spell out whether hotel prices in CHF adjusted immediately and whether there were any simultaneous price movements (e.g., Swiss hotels raising tariffs endogenous to demand), and discuss how real exchange rate changes were constructed (nominal versus CPI deflated). If possible, show evidence that Swiss hotel prices in CHF were sticky—for example, by documenting that room rates (in CHF) were unchanged pre/post 2015, supporting the idea that foreign tourists faced only the currency channel.

5. **Robustness to Clustering and Serial Correlation.** The paper clusters standard errors at the canton level, but with only 26 clusters and a long time dimension, there is a risk of downward bias. Consider reporting wild cluster bootstrap confidence intervals for the main specification or using more conservative clustering (e.g., canton-by-year). Alternatively, exploit the high-frequency monthly data to estimate standard errors using block bootstrap in time.

6. **Explore Heterogeneous Dynamics.** The conclusion that leisure demand is more elastic than business travel is plausible but would be stronger with more detailed heterogeneity. Use the origin-level data to interact the treatment indicator with measures of visitor trip purpose (if available) or proxies such as average length of stay, share of overnight stays in Alpine cantons, or typical travel season. Similarly, plot trends for Alpine tourism cantons separately to ensure that their pre-shock trajectories do not differ systematically from urban cantons.

7. **Discuss Policy Implications with Caution.** The policy paragraph implies that the SNB overlooked tourism costs. While this is plausible, it would be valuable to contextualize the magnitude: what share of tourism revenue did the affected segments represent, how persistent was the decline, and how does this compare to other macroeconomic effects of the shock? This would help policymakers assess trade-offs rather than infer a straightforward oversight.

8. **Improve Transparency of Data Construction.** Provide an appendix table that lists the 77 origin categories, their classification into the four groups, and the cumulative exchange rate change they experienced. Also describe any data cleaning (e.g., how missing values were handled) and whether the HESTA data include all hotels or only licensed ones.

9. **Enhance Diagnostic Visualizations.** Include a figure showing monthly hotel stays for Eurozone vs. Swiss visitors (perhaps plotted as ratios) to illustrate the jump in 2015 and the following divergence. Another helpful figure would plot each canton’s Eurozone share versus its estimated post-shock decline to show cross-sectional variation (or lack thereof), making the point about limited Bartik variation visually apparent.

Addressing these suggestions would substantially improve the credibility and richness of the analysis, making the causal claims more convincing and the policy implications more grounded.
