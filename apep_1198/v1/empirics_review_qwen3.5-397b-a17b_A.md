# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-31T13:16:49.317801

---

**1. Idea Fidelity**

The paper largely fulfills the core empirical promise of the original idea manifest, utilizing the specified Ofgem dataset (860,470 installations) and exploiting the January/February 2016 band merger as the primary identification shock. The central finding—extreme bunching at the 4 kW threshold that collapses upon threshold removal—is consistent with the manifest's "Smoke Test." However, there are two notable deviations. First, the manifest promised a "Triple-Threshold" design (4, 10, and 50 kW), yet the paper explicitly excludes the 50 kW threshold from main analysis due to confounding administrative regimes (MCS-FIT vs. ROO-FIT). While methodologically sound, this reduces the design from a triple- to a dual-threshold experiment. Second, the manifest suggested estimating the "bunching-elasticity relationship," whereas the paper correctly identifies that the domestic capacity distribution is too concentrated for standard structural elasticity estimation, opting instead for raw ratios and missing-tail shares. This is a justified empirical adjustment, but it shifts the contribution from structural estimation to diagnostic documentation.

**2. Summary**

This paper documents extreme behavioral responses to "hidden notches" in the UK Feed-in Tariff, where average-rate subsidy bands created discrete revenue cliffs at capacity thresholds. Exploiting the 2016 merger of the ≤4 kW and 4–10 kW bands as a natural experiment, the author shows that bunching at 4 kW collapsed from ratios exceeding 2,000:1 to near-zero, while bunching at the unchanged 10 kW threshold persisted. The findings highlight how regulatory design features invisible in nominal tariff schedules can induce first-order distortions in technology adoption and sizing.

**3. Essential Points**

1.  **The Exclusion of the 50 kW Threshold:** The original design leveraged three thresholds to establish a dose-response relationship across capacity scales. By excluding the 50 kW threshold, the paper loses the ability to show whether the "hidden notch" effect scales with system size or installer sophistication (commercial vs. domestic). If the 50 kW data is too confounded by administrative regimes, the authors should explicitly test whether the *nature* of the confounding (e.g., different accreditation processes) can be controlled for, or else temper claims about the generality of the mechanism across all FIT bands.
2.  **Parallel Trends in Bunching Intensity:** The identification relies on the 10 kW threshold serving as a valid control for the 4 kW threshold. While the paper shows 10 kW bunching persisted, it is crucial to demonstrate that the *trend* in bunching intensity at 10 kW was parallel to 4 kW prior to 2016. If degression rates affected the economic value of the 10 kW cliff differently than the 4 kW cliff over time (e.g., if the 4 kW differential narrowed faster than the 10 kW differential), the differential collapse might be partly driven by changing incentives rather than the threshold removal itself. A plot of the ratio of bunching intensities (4 kW / 10 kW) over time would clarify this.
3.  **Quantifying the Capacity Loss:** The paper states the aggregate capacity loss is "modest compared to the German case" but does not provide a concrete estimate. For policy relevance, the authors should attempt a back-of-the-envelope calculation of the foregone capacity. Using the post-2016 distribution as a counterfactual for the pre-2016 period, how many megawatts of solar were lost because systems were capped at 4.0 kW instead of 4.5–5.0 kW? This transforms the paper from a documentation of behavior to a quantification of policy inefficiency.

**4. Suggestions**

The following recommendations are intended to strengthen the empirical presentation and policy impact of the paper. These suggestions focus on visualization, robustness, and welfare quantification.

**Visualizing the Distributional Shift**
Bunching papers rely heavily on visual evidence. While the tables provide precise ratios, the reader needs to *see* the cliff and its removal.
*   **Histogram Figure:** Construct a high-resolution histogram of the capacity distribution around 4 kW for two periods: pre-2016 and post-2016. Overlay the counterfactual density (even if approximated by the post-2016 distribution) to visually demonstrate the "missing mass" above 4 kW in the first period.
*   **Time-Series Plot:** Plot the raw bunching ratio at 4 kW and the Kleven-Waseem estimate at 10 kW on the same time-series graph (with dual axes if necessary). Mark the February 2016 reform clearly. This will visually reinforce the "difference-in-differences" nature of the identification—the 4 kW line should plummet while the 10 kW line remains relatively stable.
*   **Placebo Distribution:** Include a density plot for a non-policy threshold (e.g., 3 kW or 5 kW) to show the absence of spikes compared to the policy thresholds. This reinforces the claim that the mass points are policy-driven, not engineering-driven.

**Refining the Welfare Analysis**
The paper currently describes the distortion qualitatively. To meet the standards of *AER: Insights*, the policy implication should be quantified.
*   **Counterfactual Capacity Imputation:** Use the post-2016 capacity distribution (where the constraint is removed) to impute what the pre-2016 distribution *would* have looked like absent the cliff. For example, if 12% of systems were >4 kW post-2016, but only 0.6% were pre-2016, apply the post-2016 density shape to the pre-2016 total volume.
*   **Revenue vs. Capacity Trade-off:** Calculate the implied transfer. Homeowners gained higher tariff rates by downsizing, but the government paid higher rates on potentially smaller systems. Did the government save money because systems were smaller, or lose money because the rate was higher? A simple budget impact estimate (Total FIT payments under actual vs. counterfactual distribution) would be highly valuable for policymakers designing future subsidies.
*   **Environmental Cost:** Briefly estimate the CO2 emissions associated with the foregone capacity. If, for example, 50 MW of capacity was lost due to bunching, what is the equivalent annual generation and carbon abatement? This connects the micro-behavior to macro-environmental goals.

**Strengthening the Mechanism Evidence**
The paper argues that professional intermediation (installers) drives the result. This can be substantiated further with the available geographic data.
*   **Installer Concentration:** If postcode or local authority data allows, calculate the Herfindahl-Hirschman Index (HHI) of installer activity in high-bunching vs. low-bunching areas. If bunching is stronger in areas dominated by large installer firms, it supports the "sophisticated intermediation" mechanism.
*   **Inverter vs. Panel Capacity:** The paper notes that some installations have panel capacity > DNC. Create a scatter plot of Panel Capacity vs. DNC for systems near the 4 kW threshold. Highlight the cases where Panel Capacity is 4.5–5.0 kW but DNC is registered as 4.0 kW. This provides direct micro-evidence of the "inverter-limiting" strategy mentioned in Section 6.1.
*   **Temporal Granularity:** The reform was announced before implementation. Check for "anticipatory bunching." Did installers rush to register 4.0 kW systems in January 2016 before the merger took effect? A spike in January 2016 relative to December 2015 would confirm that agents were actively monitoring the policy calendar.

**Statistical Robustness**
*   **Standard Errors for Raw Ratios:** While the 10 kW estimates have bootstrap standard errors, the 4 kW raw ratios do not. Given the large sample size, these should be precise, but providing confidence intervals for the *change* in the raw ratio (pre vs. post
