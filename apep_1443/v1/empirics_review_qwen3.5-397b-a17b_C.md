# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-04-09T11:25:14.837624

---

# Review: Lock-In or Cash-Out? Holding-Period Bunching at Taiwan's Housing Tax Notches

## 1. Idea Fidelity

The paper largely pursues the original idea manifest, utilizing the specified Taiwan Actual Price Registration data and the Consolidated Housing Tax reform (Tax 1.0 vs. Tax 2.0) as the core identification strategy. However, there is a significant deviation in data construction. The manifest projected ~4 million records based on quarterly transaction downloads, implying a universe of transactions. The paper instead constructs a sample of 344,274 *repeat-sale pairs*. This reduction is necessitated by the lack of unique property identifiers in the public data, forcing the author to match transactions by address. This shift fundamentally alters the research design from a universe-level analysis to a selected sample of mobile properties, introducing selection bias not anticipated in the manifest's feasibility check. Additionally, the manifest assumed clean holding-period measurement; the paper reveals severe measurement error due to address-level matching in multi-unit buildings, a critical constraint that weakens the original identification strategy.

## 2. Summary

This paper estimates behavioral responses to Taiwan's steep capital gains tax notches using housing transaction data from 2012–2024. While the Tax 1.0 regime shows moderate bunching at the 2-year threshold, the tighter Tax 2.0 regime yields a precisely estimated null. However, a placebo test on tax-exempt properties reveals massive spurious bunching at the same threshold, attributed to data limitations in matching property units. The author concludes that housing illiquidity and transaction costs likely dominate tax incentives, preventing observable timing distortions.

## 3. Essential Points

1.  **Catastrophic Placebo Failure:** The placebo test results ($\hat{b}=6.68$ for exempt properties) are not merely a "limitation" but a fundamental identification failure. If exempt properties exhibit 668% excess mass at the 730-day mark due to structural noise, the smoothness assumption required for the bunching estimator is violated. You cannot claim a "bounded null" for the treatment group (Tax 2.0) when the control group exhibits massive spikes at the exact same cutoff. The structural noise likely exists in the treatment group as well, meaning the $\hat{b}=-0.04$ estimate may simply be noise canceling out signal, rather than a true economic null.
2.  **Repeat-Sale Selection Bias:** By restricting the sample to repeat-sales (approximately 10% of the market), the paper estimates the elasticity of *frequent movers*, not the marginal home seller. Properties that transact frequently are inherently different from those held long-term (the very group targeted by the tax). This selection bias likely attenuates the estimated bunching effect, as the sample excludes the "lock-in" population who never sell. The paper must address whether the repeat-sale sample is representative of the marginal taxpayer facing the notch.
3.  **Counterfactual Misspecification:** The use of a 7th-order polynomial to fit the counterfactual density is inappropriate given the acknowledged structural spikes in the data. Polynomials are global approximators and struggle to fit local discontinuities caused by data construction (e.g., construction-to-resale cycles). If the data generating process includes structural spikes at round-number holding periods (due to address matching), the polynomial will either overfit the noise or underfit the trend, rendering the excess mass calculation unreliable.

## 4. Suggestions

The core contribution of this paper—the documentation of Taiwan's tax notches and the attempt to measure housing elasticity—is valuable, but the current econometric implementation cannot support the causal claims. The following recommendations aim to salvage the empirical strategy or reframe the contribution to align with the data's limitations.

**Reframing the Identification Strategy**
The most critical issue is the placebo failure. Rather than treating the exempt group as a simple placebo, consider a Difference-in-Differences (DiD) bunching approach. Compare the *change* in excess mass at the 730-day notch between Tax 1.0 and Tax 2.0, while simultaneously differencing out the change observed in the exempt group. If the structural noise (address matching) is time-invariant, differencing might remove it. Specifically, estimate:
$$ \Delta \hat{b} = (\hat{b}_{Tax2.0} - \hat{b}_{Exempt}) - (\hat{b}_{Tax1.0} - \hat{b}_{Exempt, pre}) $$
If the structural spike is constant over time, this removes the bias. However, given the massive magnitude of the placebo bunching, you must demonstrate that the noise is indeed stable across regimes. Plot the density of exempt properties for the 2016–2021 period versus the 2021–2024 period. If the spike magnitude varies, the DiD approach will also fail.

**Improving the Counterfactual Density**
The polynomial estimator assumes a smooth counterfactual. Your data explicitly violates this. I recommend replacing the polynomial with a more flexible non-parametric estimator or a semi-parametric approach that controls for the structural spikes. For example, include dummy variables for "round number" holding periods (365, 730, 1095 days) in the counterfactual estimation phase, even for the treatment group. This allows the model to absorb the address-matching noise separately from the tax-induced bunching. Alternatively, use a local linear regression on either side of the notch rather than a global polynomial, which is less sensitive to distant structural features. You should also test higher-order polynomials (up to 15) to see if the fit improves, though this risks overfitting.

**Addressing Sample Selection**
The repeat-sale restriction is the second largest threat to validity. If possible, attempt to acquire unit-level data through a research agreement with the Ministry of Interior. The public CSVs lack unit numbers, but the underlying registry likely has them. If this is impossible, you must explicitly quantify the selection bias. Compare the price distribution and district composition of your repeat-sale sample against the universe of transactions (which you have from the manifest's smoke test). If repeat-sales are concentrated in specific districts or price ranges, the elasticity you estimate is local to those segments. Consider weighting your estimates to match the universe of transactions on observable characteristics (price, area, district).

**Re-evaluating the "Null" Result**
The conclusion that "large notches alone do not guarantee behavioral distortion" is strong, but currently unsupported by the data quality. A null result in the presence of massive measurement error is uninformative. I suggest conducting a power analysis specifically accounting for the noise variance observed in the placebo group. Calculate the Minimum Detectable Effect (MDE) given the standard deviation of bin counts in the exempt sample. If the MDE is larger than the theoretical bunching predicted by standard elasticity parameters (e.g., $\epsilon = 0.5$), you must state that the paper cannot distinguish between "no response" and "response obscured by noise." This shifts the contribution from a policy evaluation to a data quality warning, which is still valuable for the literature on Asian housing markets.

**Alternative Outcome Variables**
Since timing bunching is obscured by noise, consider looking for responses on other margins. Does the tax reform reduce the *volume* of short-term transactions (extensive margin)? Compare the share of transactions occurring <2 years relative to total transactions before and after the reform, using the exempt group as a control for market-wide trends. This does not require precise holding-period measurement, only accurate acquisition date classification (which is available in the registry). A drop in the share of short-term holdings would support the "deterrence" hypothesis without relying on the noisy bunching estimator.

**Clarifying the Tax Calculation**
The paper mentions tax savings in NTD but does not clarify if the tax is applied to the nominal gain or inflation-adjusted gain. Taiwan's tax system may have indexation provisions. If the tax base is inflation-adjusted, the real tax notch might be smaller than the statutory 10pp suggests, especially in high-inflation periods. Clarifying the effective marginal tax rate (EMTR) at the notch is crucial for mapping the bunching estimate to an elasticity. If the EMTR is low due to deductions or indexation, the null result becomes more plausible.

**Visual Evidence**
Include binned scatter plots of the hazard rate (probability of sale conditional on surviving to day $t$) rather than just the density. The hazard rate is often more informative for timing decisions than the raw density, which conflates survival probabilities with bunching. Plot the hazard rate for Tax 2.0 vs. Exempt around the 730-day mark. If the tax matters, the hazard should jump at 730 for Tax 2.0 but remain smooth for Exempt. If both jump, it confirms the data noise hypothesis.

**Robustness to Bin Width**
Your robustness table shows stability across bin widths, but given the structural noise, this might be misleading. If the noise is concentrated exactly at 730 days, wider bins (14 days) might dilute the spike, while narrower bins (5 days) might capture it. The fact that estimates are stable suggests the polynomial is smoothing over the spike entirely. I recommend plotting the residuals of the polynomial fit. If you see systematic patterns (e.g., positive residuals at 730, negative at 720), the model is misspecified.

**Conclusion Refinement**
Finally, temper the policy conclusions. The current draft suggests the tax "may not produce intensive-margin distortions." Given the identification issues, a more accurate conclusion is that "data limitations prevent precise estimation of intensive-margin distortions, though extensive-margin deterrence remains possible." This honesty strengthens the paper's credibility and highlights the need for better administrative data access in emerging market tax research.

By addressing the placebo failure through differencing, improving the counterfactual fit, and acknowledging the selection bias, this paper can transition from a flawed policy evaluation to a rigorous methodological contribution on the challenges of measuring housing tax elasticities in data-constrained environments.
