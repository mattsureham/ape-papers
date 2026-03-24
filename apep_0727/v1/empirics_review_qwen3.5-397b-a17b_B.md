# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-20T18:49:01.802892

---

# Referee Report

**Paper Title:** Too Small by Design: Bunching Evidence on Germany's Solar Capacity Trap
**Journal:** AER: Insights

## 1. Idea Fidelity

The paper pursues the core empirical strategy outlined in the original idea manifest: applying a bunching estimator to German solar installation data to quantify behavioral responses to the EEG 2014 10 kWp threshold. However, there are significant deviations from the feasibility claims made in the manifest that affect the identification strength. 

First, the manifest explicitly proposed exploiting the 2021 threshold expansion (10 to 30 kWp) as a "difference-in-discontinuities test" to validate that bunching is policy-induced rather than technological. The paper abandons this design, citing a data cutoff at 2018 in the Open Power System Data (OPSD) dataset. This contradicts the manifest's feasibility check, which confirmed access to the MaStR bulk download (updated regularly) and the `open-mastr` Python package. 

Second, the manifest's smoke test confirmed the availability of `AnzahlSolarModule` (module count) and `ArtDerSolaranlageBezeichnung` (installation type) to decompose technical bunching and run ground-mount placebo tests. The paper states in the Discussion that these distinctions were not possible with the chosen dataset. While OPSD is a valid derivative of MaStR, relying on a version that lacks variables confirmed as available in the original proposal represents a loss of identification power. The core research question remains intact, but the execution is less robust than the manifest promised.

## 2. Summary

This paper provides striking evidence that Germany's 2014 EEG self-consumption surcharge exemption created a massive distortion in residential solar installation sizes, with a bunching ratio of 113 at the 10 kWp threshold. The author estimates that this regulatory notch caused approximately 200 MW of foregone solar capacity between 2014 and 2020, highlighting the unintended consequences of threshold-based climate policy.

## 3. Essential Points

1.  **Data Currency and the Missed Natural Experiment:** The most significant limitation is the failure to utilize the 2021 reform as proposed in the manifest. The manifest explicitly stated the 2021 threshold expansion was a "clean test" and that MaStR data was freely available via bulk download. By stopping at 2018, the paper relies on a pre/post comparison (2008–2013 vs. 2014–2018) that is more vulnerable to confounding trends (e.g., general FIT reductions, market saturation) than the proposed difference-in-discontinuities design. The authors must either update the data to include 2019–2024 from the direct MaStR source to execute the 2021 test or provide a much stronger defense of the parallel trends assumption in the pre/post design.

2.  **Unused Variables for Identification:** The manifest confirmed the availability of module counts and installation types, yet the paper does not use them. Module counts are critical for distinguishing between "technical bunching" (e.g., standard roof sizes fitting exactly 30 modules) and "policy bunching." Similarly, distinguishing ground-mount systems (which face different incentives) is a standard placebo test in this literature (as noted in the manifest). The authors should access the raw MaStR CSVs to incorporate these variables. If the bunching persists even when controlling for module discreteness or is absent in ground-mount systems, the causal claim becomes significantly stronger.

3.  **Welfare Calculation Sensitivity:** The headline welfare cost ("200 MW foregone") relies on a specific counterfactual assumption: that bunched systems would have averaged 12 kWp absent the threshold. This is an informed guess but not empirically identified. Given the AER: Insights focus on policy relevance, this number will be heavily cited. The authors should present a sensitivity analysis (e.g., what if the counterfactual mean was 11 kWp or 13 kWp?) or reframe the conclusion to emphasize the *existence* of the distortion rather than the precise megawatt estimate, which is currently point-identified based on an assumption.

## 4. Suggestions

**Data and Identification Improvements**
*   **Update to Full MaStR:** I strongly encourage the authors to bypass the OPSD intermediary and download the bulk `EinheitenSolar.csv` directly from the Bundesnetzagentur (as indicated in the manifest's feasibility check). This dataset is updated monthly and contains the 2021–2024 period required for the difference-in-discontinuities test. Showing that the 10 kWp spike *disappears* post-2021 while a 30 kWp spike *emerges* would be a definitive causal proof that currently elevates this from a strong correlation to a near-experimental result.
*   **Module Count Decomposition:** If you access the full MaStR data, use the `AnzahlSolarModule` variable. Plot the distribution of module counts. If bunching at 10 kWp is driven by policy, you should see systems with the *same* number of modules being derated (reported at lower kWp) or systems with fewer modules being chosen specifically to stay under the limit. This helps rule out the argument that 10 kWp is simply a technological optimum.
*   **Placebo Tests:** Revisit the ground-mount placebo. The manifest noted `ArtDerSolaranlageBezeichnung` was available. Even if ground-mount systems are rare in the 3–20 kWp range, excluding them or showing they do not bunch strengthens the claim that this is a *residential/regulatory* phenomenon, not a general technological constraint.

**Mechanism and Interpretation**
*   **Installer Incentives:** The paper argues that professional installers drive this response. This is plausible but asserted rather than demonstrated. Consider adding a brief discussion or citation regarding installer contracting norms. Do installers explicitly market "9.9 kWp systems" as tax-exempt products? Anecdotal evidence from installer forums or consumer protection reports could bolster the mechanism section.
*   **Pre-2014 FIT Tier:** The paper acknowledges the 2012 FIT tier at 10 kWp but attributes the jump from ratio 6.7 to 113 entirely to the 2014 surcharge. It might be worth explicitly modeling the 2012 change as a separate event in the annual estimates table. If the 2012 jump was small (ratio ~10) and the 2014 jump was large (ratio ~80+), this isolates the *surcharge* (notch) from the *tariff tier* (kink), which is a valuable distinction for policy design.
*   **Welfare Framing:** Be careful with the term "deadweight loss." If the households are rationally avoiding a tax, the welfare loss is the distortion in capacity, not necessarily the tax avoidance itself. Clarify that the loss is the *under-installation* of renewable capacity relative to the social optimum, assuming the social benefit of solar exceeds the private cost + surcharge.

**Presentation and Formatting**
*   **Bunching Plot:** The text describes the results well, but the review package did not include the actual histogram figure (only tables). For AER: Insights, a clear, high-resolution bunching plot (observed vs. counterfactual density) is essential. Ensure the exclusion window is shaded and the counterfactual polynomial is clearly visible.
*   **AER: Insights Style:** Ensure the paper adheres to the specific word count and formatting constraints of *AER: Insights* (typically shorter than a regular AER paper, with a focus on policy takeaways). The current LaTeX template looks standard; verify against the journal's specific author guidelines regarding abstract length and footnote style.
*   **Table 1 (Summary Stats):** Consider adding a row for the standard deviation of capacity in the pre vs. post period. A reduction in variance post-2014 would be additional descriptive evidence of the threshold constraining choice.
*   **Confidence Intervals:** In Table 2 (Annual Estimates), consider adding 95% confidence intervals for the bunching ratio. While the t-stats are huge, visualizing the precision over time helps readers assess the stability of the estimate during the transition years (2013–2014).

**Minor Corrections**
*   **Abstract:** The phrase "281 times more installations at 9.9 kWp than at 10.1 kWp" is dramatic but relies on single-bin counts which can be noisy. Ensure this ratio is robust to slight bin shifts (e.g., 9.85–9.95 vs 10.05–10.15).
*   **Section 2 (Institutional Background):** Clarify the 10 MWh generation limit. The paper says it was "effectively non-binding." A brief calculation showing the typical yield of a 9.9 kWp system (e.g., 9,900 kWh) reinforces this.
*   **References:** Ensure all citations (e.g., `eu2018red2`, `bundestag2012eeg`) are fully detailed in the bibliography. Some look like placeholder keys.

This paper tackles a high-impact question with a clean empirical design. The core finding—that climate policy thresholds can suppress renewable adoption—is vital for the EU's ongoing energy transition. By addressing the data limitations identified above, particularly the incorporation of the 2021 reform and module-level data, this could become a definitive reference on regulatory design in environmental economics.
