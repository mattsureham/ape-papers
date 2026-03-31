# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-31T13:17:02.946998

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It successfully exploits the triple-threshold design of the UK Feed-in Tariff (FIT) and leverages the January 2016 removal of the 4 kW band as a threshold-off experiment. The key elements of the identification strategy—triple-threshold bunching, temporal variation at the 4 kW threshold, and the use of the 10 kW and 50 kW thresholds as within-system placebos—are all present and well-executed. The paper also makes good use of the Ofgem dataset, which includes 860,000+ solar PV installations with exact capacity and commissioning dates.

The paper’s focus on the "hidden notch" created by the average-rate tariff structure is a novel and insightful extension of the bunching literature. The manifest’s emphasis on the triple-threshold design and the temporal variation at the 4 kW threshold is fully realized in the empirical analysis. The only minor deviation is the exclusion of the 50 kW threshold from the main analysis due to confounding administrative changes, but this is a reasonable choice given the data limitations.

---

### 2. Summary

This paper documents extreme bunching at the 4 kW capacity threshold in the UK’s Feed-in Tariff (FIT) program, where crossing the threshold resulted in a discrete drop in the tariff rate applied to the entire system output. Using data on 860,000 solar PV installations, the authors show that bunching at 4 kW was extreme during the FIT period (2010–2015), with raw bunching ratios reaching 2,230:1. The February 2016 merger of the ≤4 kW and 4–10 kW bands eliminated the 4 kW threshold, causing bunching to collapse. The paper uses the unchanged 10 kW threshold as a placebo and engineering mass points at non-policy capacities as additional robustness checks. The results highlight how average-rate tariff designs can create hidden notches that distort behavior, even when the policy appears smooth.

---

### 3. Essential Points

The paper is methodologically sound and makes a compelling contribution to the literature. However, there are three critical issues that the authors must address to strengthen the analysis:

1. **Clarify the Economic Magnitude of the Distortion**
   The paper provides raw bunching ratios and missing-tail shares but does not quantify the aggregate welfare loss or capacity distortion caused by the 4 kW threshold. While the authors note that the distortion is "modest compared to the German case," a back-of-the-envelope calculation of the foregone capacity (e.g., how many additional kW of solar capacity were lost due to bunching) would help contextualize the economic significance of the findings. This could be done by comparing the observed distribution to a counterfactual distribution without the threshold, even if only approximately.

2. **Address Potential Confounding from Degression**
   The paper acknowledges that tariff rates declined over time due to degression, which narrowed the absolute differential at the 4 kW threshold. However, it does not fully explore whether degression might confound the interpretation of the 2016 reform. For example, if the 4 kW threshold became less salient over time due to degression, the collapse in bunching post-2016 might partly reflect a pre-existing trend rather than the band merger alone. The authors should test for pre-trends in bunching at 4 kW (e.g., whether the ratio was already declining before 2016) or interact the post-reform indicator with time to assess whether the effect is stable.

3. **Improve the Counterfactual for the 4 kW Threshold**
   The paper relies on raw bunching ratios and missing-tail shares for the 4 kW threshold because the standard Kleven-Waseem estimator is not credible in this setting. While this is understandable, the authors should provide more justification for why the polynomial counterfactual is inappropriate (e.g., show that the distribution is too concentrated or that the counterfactual produces implausible results). Additionally, they could explore alternative approaches, such as using a wider window for the counterfactual or comparing the 4 kW distribution to the 10 kW distribution (where the estimator works) to validate the qualitative pattern.

---

### 4. Suggestions

The following recommendations are non-essential but would improve the paper’s clarity, robustness, and contribution:

#### **Conceptual and Theoretical Improvements**
1. **Sharpen the Hidden Notch Framework**
   The paper introduces the concept of a "hidden notch" but could do more to formalize it. For example:
   - Provide a simple algebraic example comparing a marginal-rate kink, an explicit notch, and an average-rate hidden notch to clarify how the UK FIT’s structure differs from other policies.
   - Discuss whether the hidden notch is more or less distortionary than an explicit notch, given that the stakes are higher (the entire subsidy is at risk) but the threshold may be less salient to policymakers and installers.
   - Highlight other settings where hidden notches might arise (e.g., income tax brackets in developing countries, utility tariffs, or firm-size thresholds).

2. **Discuss the Role of Installer Learning**
   The paper notes that installers, not homeowners, determine system sizes, which likely amplifies the bunching response. However, it does not explore whether installer behavior changed over time (e.g., did bunching intensify as installers learned about the threshold?). The authors could:
   - Test whether bunching at 4 kW increased in the early years of the FIT (2010–2012) as installers became more aware of the threshold.
   - Examine whether bunching was more pronounced in regions with more installer competition (e.g., urban areas), which might incentivize optimization around thresholds.

3. **Compare to Other UK FIT Thresholds**
   The paper focuses on the 4 kW and 10 kW thresholds but briefly mentions the 50 kW threshold. While the 50 kW threshold is confounded by administrative changes, the authors could:
   - Provide descriptive evidence on bunching at 50 kW (e.g., raw ratios or missing-tail shares) to show whether the pattern is qualitatively similar to the 4 kW and 10 kW thresholds.
   - Discuss why the 50 kW threshold might be less distortionary (e.g., larger systems may have higher adjustment costs or face different market dynamics).

#### **Empirical and Robustness Improvements**
4. **Provide a Tariff-Rate Crosswalk**
   The paper lacks a precise quantification of the notch size at the 4 kW and 10 kW thresholds over time. The authors should:
   - Construct a crosswalk of tariff rates by band and year, including the degression adjustments, to show how the notch size evolved.
   - Use this crosswalk to estimate the NPV of the revenue loss from crossing the 4 kW threshold in each year, which would help explain why bunching was more extreme in some years (e.g., 2012) than others.

5. **Test for Heterogeneity by Installation Type**
   The Ofgem data include installation types (e.g., domestic vs. commercial). The authors could:
   - Test whether bunching at 4 kW was more pronounced for domestic installations (where the stakes may be higher relative to system size) or for commercial installations (where installers may be more sophisticated).
   - Examine whether the post-2016 collapse in bunching was uniform across installation types or whether some segments (e.g., commercial) adjusted more quickly.

6. **Explore Geographic Heterogeneity**
   The paper does not exploit the geographic variation in the data. The authors could:
   - Test whether bunching was more extreme in regions with higher electricity prices (where the tariff differential would be more salient) or in areas with more installer competition.
   - Examine whether the post-2016 collapse in bunching was faster in some regions, which might reflect differences in installer behavior or local market conditions.

7. **Improve the Placebo Tests**
   The placebo tests at non-policy capacities (e.g., 3.68 kW, 3.99 kW) are a strength of the paper, but they could be expanded:
   - Show the time series of bunching at these placebo capacities (similar to Table 2) to demonstrate that they do not exhibit the same collapse as the 4 kW threshold.
   - Test whether the placebo capacities exhibit bunching in other years (e.g., due to engineering constraints) to further validate that the 4 kW response is policy-driven.

8. **Address Potential Measurement Error in DNC**
   The paper notes that some installers may have underreported DNC to stay below the 4 kW threshold (e.g., by installing a smaller inverter). The authors could:
   - Provide more descriptive evidence on the relationship between DNC and installed capacity (e.g., histograms or scatterplots) to show how common this behavior was.
   - Test whether the gap between DNC and installed capacity narrowed after the 2016 reform, which would suggest that installers were no longer incentivized to underreport.

#### **Presentation and Clarity**
9. **Clarify the Bunching Ratio Calculation**
   The paper defines the raw bunching ratio as the count at 4.0 kW divided by the average count per 0.1 kW bin in [4.1, 4.5). While this is clear, the authors should:
   - Justify why they use a 0.5 kW window above the threshold (e.g., why not 0.3 kW or 1 kW?) and show robustness to alternative window sizes.
   - Explain why they do not use a symmetric window below the threshold (e.g., [3.5, 4.0)) for comparison, which might provide a more intuitive counterfactual.

10. **Improve the Discussion of the 10 kW Threshold**
    The 10 kW threshold serves as a useful placebo, but the paper could do more to interpret the results:
    - Discuss why the bunching ratio at 10 kW declined post-2016 (from 56.5 to 36.3). Is this due to degression, or did the 2016 reform have spillover effects on installer behavior at other thresholds?
    - Compare the 10 kW bunching ratio to estimates from other settings (e.g., the German 10 kWp threshold) to contextualize the magnitude.

11. **Add a Welfare Analysis**
    The paper’s focus is diagnostic, but a brief welfare analysis would strengthen the policy implications. The authors could:
    - Estimate the foregone solar capacity due to bunching at 4 kW by comparing the observed distribution to a counterfactual (e.g., a smooth distribution or the post-2016 distribution).
    - Discuss whether the distortion was "worth it" from a policy perspective (e.g., did the FIT achieve its deployment goals despite the bunching?).

12. **Improve the Figures**
    The paper would benefit from more visual evidence. Suggested figures:
    - A histogram of DNC around 4 kW for the pre- and post-reform periods (similar to Kleven-Waseem figures) to show the collapse in bunching.
    - A time series plot of the raw bunching ratio at 4 kW and 10 kW to visually emphasize the contrast.
    - A plot of the tariff rates over time to show how the notch size evolved due to degression.

#### **Broader Implications**
13. **Discuss Policy Design Lessons**
    The paper’s findings have important implications for subsidy design. The authors could:
    - Propose alternative tariff structures that avoid hidden notches (e.g., marginal-rate tariffs or explicit notches with smaller stakes).
    - Discuss whether policymakers should avoid capacity-based thresholds altogether or whether they can be designed to minimize distortions (e.g., by making thresholds less salient or by grandfathering existing systems).
    - Highlight other policies where hidden notches might arise (e.g., income tax brackets, utility tariffs, or firm-size thresholds) and suggest how to diagnose them.

14. **Compare to Other Bunching Settings**
    The paper’s bunching ratios are among the most extreme in the literature. The authors could:
    - Compare their results to other settings with extreme bunching (e.g., UK stamp duty notches, French firm-size thresholds) to discuss what drives the magnitude of the response.
    - Speculate on why the UK FIT produced such extreme bunching (e.g., the combination of professional intermediation, modular technology, and high stakes).

---

### Final Thoughts

This is a strong and innovative paper that makes a valuable contribution to the bunching literature and the study of renewable energy policy. The identification strategy is credible, the empirical approach is well-suited to the research question, and the results are compelling. With the suggested improvements—particularly around quantifying the economic magnitude of the distortion, addressing potential confounding from degression, and sharpening the counterfactual for the 4 kW threshold—the paper could be even more impactful. The authors should also consider expanding the discussion of policy design lessons to maximize the paper’s relevance for policymakers. Overall, this is a well-executed study that deserves publication with minor revisions.
