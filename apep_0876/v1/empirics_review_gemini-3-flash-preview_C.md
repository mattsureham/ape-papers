# V1 Empirics Check — google/gemini-3-flash-preview (Variant C)

**Model:** google/gemini-3-flash-preview
**Variant:** C
**Date:** 2026-03-24T21:44:02.734335

---

This review evaluates the paper "The Tax Flight Gradient: Income-Stratified Migration Elasticities from the SALT Deduction Cap" following the requested format.

### 1. Idea Fidelity
The paper maintains high fidelity to the core identification strategy proposed in the manifest, specifically the triple-difference approach (High Income $\times$ High SALT $\times$ Post-2018). It successfully utilizes the IRS SOI `inmigall.csv` data across 7 AGI brackets. However, it noticeably omits "Strategy 1" from the manifest—the staggered DiD on the 37+ individual state tax rate changes (e.g., CA Prop 30, NY 2021). By focusing exclusively on the SALT cap (Strategy 2 and 3), the paper sacrifices a significant source of variation that would have allowed for a comparison between *legislated* rate changes and *federal tax base* changes.

### 2. Summary
The paper estimates the income gradient of tax-induced migration using the 2017 SALT deduction cap as a quasi-experimental shock that differentially affected high-income filers in high-tax states. It finds a monotonic relationship where migration responsiveness increases with income, with the top AGI bracket ($>\$200k$) showing a net outmigration response three times larger than the lowest bracket. The effect is primarily driven by an increase in outflows (incumbents leaving) rather than a decrease in inflows.

### 3. Essential Points

*   **The 2020-2021 Pandemic Confound:** While the author includes a robustness check excluding these years, the paper underestimates the structural break in migration patterns caused by remote work. High-SALT states (NY, CA, IL, NJ) are also the states with the highest concentration of "work-from-home" capable professional jobs. The triple-difference assumes that the *difference* between high and low-income migration would have remained stable across states, but the pandemic specifically "unlocked" the top of the income distribution (knowledge workers) to move, while leaving the bottom (service workers) tied to local geography. The "Post" period (2018-2021) is 50% pandemic-era. A more narrow 2018-2019 "Post" window should be the primary specification, not a robustness check.
*   **The Migration Rate Denominator:** The paper defines the Net Migration Rate as $(Inflow - Outflow) / Total Returns$. However, for the $>\$200k$ bracket, "Total Returns" in the state is highly endogenous to the tax change itself (and to the SALT cap). If high-income people not only move but also experience income fluctuations or tax-planning shifts (e.g., shifting income into 2017 or out of 2018), the denominator moves with the treatment. Using a fixed pre-2018 denominator (e.g., 2017 returns for that bracket) would be more robust.
*   **Omitted State-Level Tax Responses:** Several high-SALT states (e.g., CT, NJ, NY) enacted "SALT Workarounds" (Pass-Through Entity Taxes) shortly after 2018 to mitigate the cap's impact for business owners. The paper treats the SALT cap as a uniform shock, but the effective shock was mitigated in states that moved quickly to implement PTE taxes. Not controlling for these workarounds likely biases the elasticities downward for the most affected brackets.

### 4. Suggestions

*   **Plausibility of Magnitudes:** The estimate for the $>\$200k$ bracket is -0.385 percentage points (Table 2). Given this bracket has a baseline net migration rate of +0.34% (Table 1), the SALT cap effectively flipped a net-gain group into a net-loss group. This result is economically large—it suggests the SALT cap neutralized the natural "pull" these states had for high-income talent. You should explicitly discuss whether this 0.4pp shift is large enough to trigger the "self-defeating" threshold mentioned in the introduction.
*   **Standard Errors:** State-level clustering (51 clusters) is correct. However, consider the "Wild Cluster Bootstrap" given the concentration of the treatment in a few very large states (CA and NY represent a massive share of the high-income population).
*   **Inflow vs. Outflow Interpretation:** The finding that 70% of the effect is outflows is your most novel contribution. You should link this to the "Sunk Cost" of migration. It suggests that while the "rich don't flee" (as Young/Varner argue), a large enough tax shock can overcome the social/occupational capital that keeps them in place. 
*   **Visualizing the Gradient:** The current Table 2 is a list of coefficients. A figure showing the $\beta$ coefficients for each of the 7 brackets with 95% CIs would be the "Money Plot" of this paper. It would visually confirm the "Tax Flight Gradient."
*   **Continuous Exposure:** In Section 5.1, you use standardized SALT exposure. Please provide the non-standardized coefficient as well. For a policymaker, knowing the "Migration loss per $1,000 of lost deduction" is more actionable than a standard deviation move.
*   **Sample Limitations:** The $>\$200k$ bracket is quite broad. In high-SALT states like NY/CA, $200k is "upper middle class." The real "tax flight" debate is usually about the $>\$1M$ or $>\$5M$ earners. Using the IRS SOI's more granular zip-code level data (which allows for higher breaks in some years) might be too difficult, but you should acknowledge that your "High Income" group still includes many "Working Rich" who are less mobile than the "Capital Rich."
*   **The "SALT Cap Surprise":** You mention the cap was a partial surprise. To prove this, you could check for an "anticipatory surge" in outflows in late 2017. If people saw it coming, they might have moved in Dec 2017 to lock in one last year of deductions.
*   **Standardized Effect Sizes (Appendix):** This is a great addition for AER: Insights. It makes the paper much easier to digest for meta-analyses. Ensure the classification of "Large" (SDE > 0.15) is cited or justified based on recent labor/public econ literature.
