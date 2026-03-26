# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-26T12:10:33.107774

---

# Review of "The Yakuza Tax: Organized Crime Exclusion and Property Markets in Japan"

## 1. Idea Fidelity

The paper largely pursues the core research question outlined in the manifest: estimating the real-economy effects of Japan's Yakuza Exclusion Ordinances (YEOs) using staggered adoption timing. However, there are notable deviations in data and scope. The manifest specified the use of **MLIT Real Estate Transaction Prices (Kaggle)** to capture actual market transactions, but the paper utilizes **e-Stat aggregated benchmark land prices (Koji Chika)**. This shifts the analysis from transaction-level market activity to official appraisals, which are smoother and less responsive to short-term shocks. Additionally, the manifest promised an analysis of **establishment entry/exit using the Economic Census** to capture business formation; the paper includes "Building Starts" but does not deliver the promised business formation analysis. Finally, the heterogeneity analysis uses pre-treatment crime rates rather than the **Yakuza concentration HHI** specified in the manifest. While the core identification strategy (Callaway-Sant'Anna DiD) remains faithful, the empirical execution downgrades the granularity and scope originally proposed.

## 2. Summary

This paper estimates the impact of Japan's Yakuza Exclusion Ordinances on residential land prices and crime rates using a staggered difference-in-differences design across 47 prefectures. The authors find that YEO adoption reduced reported crime by 7.7% but concurrently depressed residential land prices by approximately 1%, with heterogeneity suggesting that high-crime areas benefited from safety dividends while low-crime areas suffered market disruption. The study contributes to the literature on organized crime by highlighting the trade-off between security gains and economic friction when severing criminal ties from legitimate markets.

## 3. Essential Points

1.  **Data Granularity and Measurement Error:** The switch from transaction-level data (manifest) to aggregated benchmark prices (paper) weakens the identification. *Koji Chika* prices are official assessments updated annually, often smoothed for tax purposes, and may not reflect actual market clearing prices or liquidity constraints. This makes it difficult to distinguish between a true value decline and a measurement artifact of assessed values lagging market sentiment.
2.  **The Tohoku Earthquake Confound:** The identification relies heavily on variation around 2011, yet the main adoption cluster (April 2011, 24 prefectures) occurred one month after the Great East Japan Earthquake. Excluding the three directly devastated prefectures is insufficient; the earthquake caused nationwide supply chain and confidence shocks that likely correlated with prefectural economic structures. If early adopters (2010) differ systematically in industrial composition from late adopters (late 2011), the "not-yet-treated" control group is contaminated by differential exposure to the earthquake shock.
3.  **Incomplete Outcome Coverage:** The manifest committed to analyzing business formation and commercial activity via the Economic Census. The current paper focuses almost exclusively on land prices and crime, with "Building Starts" as a secondary outcome. Without evidence on establishment entry/exit, the claim that YEOs affected the "Real Economy" is incomplete, as property values are only one channel of economic activity.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's empirical credibility and align it more closely with the ambitious scope of the original proposal. These suggestions focus on data utilization, identification robustness, and mechanism exploration.

**Data and Measurement Improvements**
*   **Recover Transaction-Level Data:** I strongly encourage the authors to revisit the MLIT Kaggle dataset mentioned in the manifest. Transaction data would allow for a test of liquidity effects (volume of sales) versus price effects. If YEOs increased due diligence costs or scared off buyers, transaction volume should drop even if prices remain stable. Aggregated benchmark prices mask this distinction. If the transaction data is too noisy, explicitly justify why *Koji Chika* is preferred (e.g., coverage) and acknowledge the smoothing bias in the limitations.
*   **Incorporate Economic Census Data:** To fulfill the "Real Economy" promise, include the establishment entry/exit analysis from the e-Stat Economic Census (2009/2012/2014/2016). This is feasible given the panel structure. Even if the results are null, reporting them is crucial to bound the economic costs of the policy. Did businesses close because they could no longer rely on yakuza dispute resolution, or did new businesses enter due to reduced extortion? This directly tests the "market disruption" vs. "safety dividend" mechanism.

**Identification and Robustness**
*   **Address the Earthquake Shock More Rigorously:** The current robustness check (dropping Tohoku prefectures) is too weak given the nationwide nature of the March 2011 shock. Consider the following:
    *   **Control for Earthquake Exposure:** Interact a post-2011 indicator with prefecture-level exposure measures (e.g., manufacturing supply chain exposure, electricity rationing intensity, or distance from epicenter) to absorb differential shock effects.
    *   **Synthetic Control Methods:** For the early adopters (2010 cohort), construct synthetic controls using the later adopters to see if the 2010 trend diverges specifically at the policy date rather than the earthquake date.
    *   **Placebo Timing:** You include a "2 years early" placebo, but consider a "March 2011" placebo specifically. Assign a fake treatment date of March 2011 to see if
