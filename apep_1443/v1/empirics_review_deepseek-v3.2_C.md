# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-04-09T11:29:29.403917

---

## **Review of "Lock-In or Cash-Out? Holding-Period Bunching at Taiwan's Housing Tax Notches"**

### **1. Idea Fidelity**
The paper closely adheres to the original idea manifest. It executes the core identification strategy: using multi-notch bunching (Kleven & Waseem, 2013) on holding-period data from Taiwan's Actual Price Registration system, with a pre/post-reform comparison and a grandfathering-based placebo test. The paper correctly identifies the notches at 730 and 1825 days under the Tax 2.0 regime. It also attempts the corporate/individual differential analysis indirectly through heterogeneity by price quartile. No key elements from the manifest are omitted.

### **2. Summary**
This paper investigates whether sellers in Taiwan's housing market time their transactions to bunch just above sharp capital gains tax notches at 2 and 5-year holding periods. The main result is a precisely estimated null effect at the 2-year notch under the post-2021 "Tax 2.0" regime, despite a 10-percentage-point tax incentive. The paper argues this bounded null, robust across specifications, suggests high transaction costs and illiquidity can prevent behavioral responses even to large notches.

### **3. Essential Points**
The authors must address these three critical issues before publication:

*   **1. Fatal Flaw in Data Construction:** The core dependent variable—the holding period—is constructed via address matching, which the paper admits is severely flawed for multi-unit buildings. The massive, statistically significant "excess mass" at 730 days in the *exempt* placebo group (Table 2, Panel C: \(\hat{b}=6.68\)) is not just a "limitation"; it invalidates the fundamental identifying assumption of a smooth counterfactual density. This systematic, non-tax-related bunching directly contaminates the treatment groups. The positive point estimate for Tax 1.0 is likely a false positive driven by this noise. While the Tax 2.0 null is more defensible, the entire empirical framework rests on shaky ground. **The authors must either (a) obtain or construct a unit-level identifier (e.g., from construction permits or floor plans merged with transactions) or (b) provide compelling evidence that the address-matching error is random with respect to the tax notch.** If neither is possible, the paper's causal claims are untenable.

*   **2. Premature Analysis of Tax 2.0:** The analysis of the post-July 2021 Tax 2.0 regime is conducted with data through 2024. For properties acquired after July 2021, the maximum possible holding period by end-2024 is ~3.5 years. Therefore, the sample for the 2-year notch (730 days) consists *entirely* of "fast" sellers (those selling within ~3.5 years). This is a selected sample likely biased toward investors with high liquidity needs or different elasticity. The absence of "slower" sellers (who might be more flexible in timing) truncates the relevant population and limits external validity. **The authors must explicitly discuss this sample selection, test for compositional changes between Tax 1.0 and Tax 2.0 periods, and qualify their interpretation of the null result accordingly.**

*   **3. Unpersuasive Economic Interpretation of the Null:** The paper attributes the null result to "illiquidity and high transaction costs" but provides no direct evidence for this mechanism. This is a narrative, not a test. The heterogeneity analysis by price quartile (Table 4) is used to argue against an income effect, but it does not test for liquidity constraints (e.g., seller type: individual vs. corporate, owner-occupier vs. investor) or market thickness. **The authors must go beyond robustness checks and conduct a more principled investigation of potential mechanisms.** For instance, they could leverage variation in market liquidity across districts or property types, or use auxiliary data to identify likely investor-owned properties.

### **4. Suggestions**
These recommendations would substantially strengthen the paper.

*   **Empirical Strategy & Robustness:**
    *   **Alternative Counterfactual:** Given the structural spikes in the placebo density, the polynomial counterfactual may be inadequate. Implement the non-parametric local linear approach (Diamond & Persson, 2016) or a control function approach using the exempt group's density to "de-trend" the treated density. This could formally net out the non-tax bunching.
    *   **Standard Error Justification:** The use of 200 bootstrap replications for SEs is standard. However, for the bunching estimator, clarify if the bootstrap resamples *transactions* or *bins*. Also, discuss spatial/temporal correlation concerns. Transactions in the same building or quarter are not independent; cluster-robust or Conley standard errors at a district-quarter level might be more appropriate.
    *   **Manipulation Test:** Perform the density discontinuity test of McCrary (2008) *below* the notch. A key prediction of the bunching model is a *depletion* of transactions just *before* the notch as sellers delay. The absence of such a left-side hole would further corroborate the null finding.
    *   **Dynamic Analysis:** Instead of a static post-Tax 2.0 pool, plot the evolution of excess mass at 730 days quarter-by-quarter since the reform's implementation. This could show if a response was initially muted but learned over time, or if the market composition changed.

*   **Analysis & Interpretation:**
    *   **Magnitude Calibration:** Is a null effect of \(\hat{b} = -0.04\) (SE=0.30) plausible? Yes, but contextualize it. Calculate the implied elasticity of selling probability with respect to the net-of-tax rate. Compare this elasticity to those from stamp duty (Best & Kleven, 2018) or capital gains lock-in studies. The discussion should move from "we found zero" to "our confidence interval rules out elasticities larger than X, which is notably smaller than the literature on asset Y."
    *   **Deepen Mechanism Tests:**
        *   Exploit the **corporate vs. individual** differential more directly. Corporate entities may face different liquidity constraints or be more tax-sensitive.
        *   Test if bunching is stronger in **"hot" vs. "cold" markets** (using price growth volatility or time-on-market metrics). Illiquidity should matter more in cold markets.
        *   Use the **1-year notch under Tax 1.0** as an additional test. The paper finds \(\hat{b} = -0.14\). Is this also a null? If so, it reinforces the story. If it were positive, it would demand an explanation for why a 10pp notch at 1 year worked but at 2 years did not.
    *   **Address the 5-Year Notch:** Acknowledge that the 5-year notch under Tax 2.0 cannot be studied yet. However, for Tax 1.0 properties (acquired 2016-2021), there should be sufficient time to analyze the 5-year (1825-day) notch, which was a 15pp drop (20%->5% for 5-10yrs, or was it 20%->15%? The manifest and text are inconsistent. Clarify). This is a critical test—a larger notch might show an effect where the 2-year did not.

*   **Presentation & Narrative:**
    *   **Reframe the Contribution:** The primary contribution may not be the null result *per se*, but the documentation of a setting where a canonical public finance prediction fails due to specific market frictions. Position it as a case study on the *limits* of bunching and the importance of transaction costs.
    *   **Improve Transparency:** In the data section, provide a flowchart showing how the 4M+ transaction records are winnowed down to 344,274 repeat-sale pairs. Report match rates. This is crucial for assessing selection.
    *   **Visual Evidence:** The paper needs a key graphical figure: a plot of the transaction density (binned counts) for the Tax 2.0 group around the 730-day notch, with the polynomial counterfactual overlaid. The current tables are insufficient. A second figure comparing the densities of Tax 1.0, Tax 2.0, and Exempt groups would powerfully illustrate the contamination issue.
    *   **Policy Discussion:** Sharpen the conclusion. If the tax doesn't distort timing, does it still deter speculation? Possibly through the extensive margin (deterring purchase). Discuss what the policy objective was and whether this evidence suggests the tax is inefficient (no distortion) or potentially effective in a different way.
