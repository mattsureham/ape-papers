# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-03-26T23:57:58.893890

---

**Referee Report: "The Federal Dissonance Penalty That Wasn't: Marijuana Legalization and FHA Mortgage Exclusion"**

### 1. Idea Fidelity
The paper maintains high fidelity to the original manifest's core mechanism: the federal-state regulatory conflict that excludes cannabis income from FHA/VA/USDA loans but allows it for conventional loans. It utilizes the suggested HMDA data and the staggered DiD approach (Callaway–Sant’Anna 2021). However, it deviates from the manifest in two significant ways that impact its contribution:
*   **Temporal Scope:** The manifest suggested a 2012–2023 panel (24 treated states). The paper instead uses a 2018–2023 window (14 treated states), treating the earliest and most mature markets (CO, WA, OR) as "always-treated" and excluding them. This significantly reduces the power to detect an effect, as the mature markets are precisely where the cannabis workforce is largest.
*   **Granularity:** The manifest proposed state, county, and census-tract-year analysis with a triple-difference based on cannabis employment (QCEW data). The paper sticks strictly to state-year aggregation. This loss of granularity explains the null result: state-level "FHA share" is too noisy to capture a shift driven by 0.3% of the workforce.

---

### 2. Summary
The paper investigates whether the federal exclusion of cannabis-derived income from government-backed mortgage programs (FHA/VA) leads to a shift toward conventional loans following state-level legalization. Using a staggered DiD design on HMDA data (2018–2023), the author finds that while a naive TWFE model suggests a 1.0 percentage point decline in FHA share, a modern Callaway–Sant’Anna estimator reveals a precise null result. The primary contribution is methodological, illustrating how treatment effect heterogeneity in staggered designs can produce artifactual significance in housing policy research.

---

### 3. Essential Points
1.  **Selection and Power:** The decision to exclude "always-treated" states (legalized 2012–2017) is a major experimental design flaw. The manifest correctly noted that the cannabis workforce is highly concentrated in mature markets. By limiting the sample to 2018–2023, the author examines states where dispensaries were often not yet fully operational or where the workforce was in its infancy during the treatment years. The null result is almost mechanical given the state-year aggregation.
2.  **Aggregation Level:** As the author admits in the Discussion, a 0.15 pp expected shift is "below the standard error" of a state-year estimate. To provide a genuine contribution, the author *must* move to the county or census-tract level (as suggested in the manifest). Using QCEW data to identify "high-cannabis-employment" tracts would allow for a triple-difference design that isolates the affected population from the 99.7% of the population that is unaffected.
3.  **Missing Mechanism Tests:** The author suggests "enforcement" and "selection" as reasons for the null but does not test them. HMDA includes borrower income and debt-to-income ratios. The manifest suggested testing if the effect concentrates among lower-income borrowers (the typical FHA demographic). The paper provides aggregate shares but ignores the rich borrower-level data that could reveal if *specific* types of applicants are being "locked out."

---

### 4. Suggestions
The paper is well-written and the methodological point about TWFE vs. CS is well-taken, but as an empirical contribution to the "causal effects of policies," it currently reports a failure of scale rather than a policy insight. To elevate this to an *AER: Insights* quality paper, I suggest the following:

*   **Move to the Census-Tract Level:** HMDA data provides census tract identifiers. I strongly recommend merging this with a proxy for cannabis industry presence (e.g., number of licensed dispensaries per capita or QCEW employment in NAICS 111998). A result showing that FHA share *specifically* drops in tracts with high cannabis employment, while remaining stable in neighboring tracts, would be a high-impact finding. 
*   **Extend the Pre-Period:** The manifest suggested 2007–2023. By starting in 2018, you lose the ability to see how CO/WA/OR evolved. Including the early adopters provides the "dosage" necessary to see if the exclusion matters once the industry matures. You can use the "Never-Treated" states as a consistent control group for the 2012 cohorts.
*   **Analyze Denial Reasons:** HMDA includes a `denial_reason` field. If the hypothesis is correct, we might expect an increase in FHA denials for "Unverifiable Information" or "Other" in legalizing states, specifically for applicants whose income comes from the cannabis sector. Even if the aggregate share doesn't move, a shift in denial patterns would be strong evidence of the mechanism.
*   **Intensive Margin of the Penalty:** Calculate the "Interest Rate Spread" (available in HMDA) for those who *successfully* switched to conventional loans. This would allow you to quantify the "Federal Dissonance Penalty" in dollars (i.e., the extra monthly interest paid by a cannabis worker who was forced out of FHA). This turns a null result into a welfare analysis.
*   **Lender Heterogeneity:** Some lenders (e.g., local credit unions in legal states) might be more willing to "look the other way" or categorize income differently than large national banks. Splitting the sample by lender type could reveal whether the exclusion is being bypassed by local institutions, which would be a fascinating insight into credit rationing.
*   **Visuals:** Replace some of the tables with the event-study plot from the Callaway-Sant'Anna output. Specifically, showing the Illinois (2019) cohort's pre-trends versus the aggregate would help visualize the "TWFE deception" you describe in Section 5.2.
*   **JEL Codes:** Consider adding R31 (Housing Supply and Markets) and G21 (Banks; Depository Institutions; Micro Finance Institutions; Mortgages) to better target the housing finance audience.
