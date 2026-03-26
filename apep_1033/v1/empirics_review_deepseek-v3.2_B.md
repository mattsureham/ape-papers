# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-27T00:37:40.416941

---

**Referee Report**

**Paper:** The Pasteurization Illusion: Why Cross-Sectional Evidence Overstates Raw Milk Risk
**Authors:** APEP Autonomous Research et al.
**Journal Format:** AER: Insights

---

### 1. Idea Fidelity

The paper pursues the core research question from the original Idea Manifest: estimating the causal effect of raw milk legalization on foodborne illness outbreaks using modern staggered Difference-in-Differences (DiD) methods. It correctly utilizes the proposed CDC NORS data and a staggered adoption design. However, there are significant deviations and omissions:

*   **Research Question Focus:** The manifest's stated idea was that legalization **increased** outbreaks. The paper's abstract and introduction frame the contribution as showing that this cross-sectional association is an "illusion" and that the causal effect is "an order of magnitude smaller." While a null or small effect is a valid finding, the paper's narrative heavily emphasizes debunking prior work rather than neutrally testing a hypothesis. The title and conclusion reinforce this polemical stance.
*   **Heterogeneous Effects:** The manifest specifically highlighted heterogeneous effects by sales channel (retail, on-farm, herdshare). The paper relegates this to a single, underpowered robustness check (Panel C of Table 4). A core element of the proposed idea is underdeveloped.
*   **Identification Strategy:** The paper employs both TWFE Poisson and the Callaway-Sant'Anna estimator as suggested. However, the interpretation switches between a Poisson model (estimating a proportional change) and an OLS linear probability model for the extensive margin without a clear justification for which is the primary specification. The manifest's focus on a "Poisson DiD for count outcome" is followed but not consistently centered.

Overall, the paper addresses the manifest's components but shifts the intellectual contribution from "providing the first causal estimate" of an effect to primarily arguing that prior cross-sectional evidence is illusory, a shift that is not fully supported by its own statistically inconclusive results.

### 2. Summary

This paper uses staggered state-level legalization of raw milk sales from 2005-2023 and CDC outbreak data in a Poisson DiD framework. It finds a positive but statistically insignificant point estimate for the effect of legalization on unpasteurized dairy outbreaks (a 40% increase), which is substantially smaller than the cross-sectional odds ratio of 3.87 from prior literature. The authors conclude that the cross-sectional association is largely driven by selection, a phenomenon they label the "pasteurization illusion."

### 3. Essential Points

The following critical issues must be resolved for the paper to be considered for publication.

**1. The paper's central finding is statistically inconclusive, severely limiting its contribution.** The primary coefficient of interest (0.339, Table 2, Column 1) is not statistically significant (p=0.32). The 95% confidence interval ranges from a 28% decrease to a 174% increase. The Callaway-Sant'Anna ATT is negative and insignificant. The paper cannot claim to have "provide[d] the first causal estimate" in a meaningful sense, as the estimate is indistinguishable from zero. The entire narrative—that the causal effect is "modest" and "an order of magnitude smaller"—rests on interpreting an insignificant point estimate. The authors must reframe the contribution to reflect this fundamental uncertainty. A paper whose main result is a null finding can be valuable, but it must be framed as such, with a focus on the precision of the estimate and the implications of not being able to reject a range of effects, including substantively large ones.

**2. The analysis does not adequately address the critical threat of surveillance and reporting bias.** The authors acknowledge this but their placebo test is insufficient. They find a positive (though insignificant) coefficient for non-dairy outbreaks (0.208, p=0.14), which they suggest hints at a "surveillance capacity channel." This is a major threat to identification. If legalization is correlated with improved general outbreak reporting (perhaps due to increased public health attention or resources in states with active food policy debates), then the estimated effect for raw milk outbreaks is conflated with better detection. The authors must:
    *   Formally test for parallel trends in reporting *capacity*. This could involve using data on state public health budgets, CDC ELC funding, or the number of outbreak reports per capita for pathogens unrelated to food (e.g., waterborne or person-to-person enteric outbreaks) as a direct measure of surveillance intensity.
    *   Discuss the possibility that legalization might *increase* the likelihood that an outbreak is *attributed* to raw milk, as consumers and clinicians may be more aware of the risk.
    *   If a significant surveillance effect exists, the main specification should be adapted to control for it (e.g., by including a control for non-dairy outbreak counts or a surveillance proxy).

**3. The treatment heterogeneity analysis is underpowered and superficially addressed.** The manifest promised insight into effects by sales channel. The paper's single test (farm-gate+ vs. herdshare-only) has only 5 treated states in the former group, yielding an immense standard error. This analysis is uninformative as presented. The authors should:
    *   Clearly define theoretical expectations: retail sales likely increase access more than on-farm sales, which increase access more than herdshares.
    *   Explore alternative, feasible approaches. Instead of splitting samples, they could code treatment intensity (e.g., an ordinal measure from 0=illegal, 1=herdshare, 2=on-farm, 3=retail) or use the legalization of *broader* channels as a second treatment. Even if estimates remain imprecise, a structured discussion of the heterogeneity would fulfill the original idea's promise and provide guidance for future research.

### 4. Suggestions

**Substantive and Empirical Improvements:**

*   **Reframe the Contribution:** The paper should be repositioned as follows: "We provide the first panel-based causal *test* of the effect of raw milk legalization. Our estimates, while imprecise, suggest that the large cross-sectional association is likely overstated due to selection. We cannot rule out a null effect, nor can we rule out a doubling of risk. Our analysis highlights the importance of accounting for state heterogeneity and surveillance capacity in food safety policy evaluation."
*   **Deepen the Literature Review:** The introduction cites two public health studies. Engage more thoroughly with the economics of regulation, safety, and consumer choice literature mentioned in the introduction. How does this setting compare to deregulation of alcohol, cannabis, or other consumer products with health risks?
*   **Strengthen the Parallel Trends Evidence:** The event study table (Table 3) is hard to interpret. Plot the event-study coefficients with confidence intervals. Visually assessing pre-trends is standard and more intuitive. Discuss the pre-treatment estimates substantively.
*   **Address Power and Precision:** Perform a power calculation or simulation. Given the rarity of outbreaks (mean 0.19 per state-year), what is the Minimum Detectable Effect (MDE) for the observed variation? Acknowledging the study's limited power to detect anything but very large effects would contextualize the wide confidence intervals and be intellectually honest.
*   **Expand the Discussion of Mechanisms:** The "Discussion" section lists potential mechanisms (preexisting consumption, surveillance, demand) but does not tie them to empirical patterns in the data. Can the data provide any suggestive evidence? For example, do states with larger dairy cow populations show a different pre-legalization outbreak rate? Does the "illusion" vary by region?
*   **Revisit the "Placebo" Outcomes:** The pasteurized dairy outcome is an excellent placebo. The non-dairy outcome is less convincing as a pure placebo if surveillance is a channel. Consider a more targeted placebo, such as outbreaks linked to specific foods that are unrelated to dairy policy but likely subject to similar surveillance (e.g., leafy greens, poultry).

**Presentation and Clarity:**

*   **Title and Abstract:** The current title ("The Pasteurization Illusion") is catchy but overstates the paper's definitive conclusion. Consider a more neutral title reflecting the methodological contribution, e.g., "Legalizing Raw Milk: A Causal Test Using Staggered State Laws." The abstract should lead with the methodological innovation and the inconclusive nature of the causal estimate, not the debunking narrative.
*   **Table 2 (Main Results):** The table is confusing. Columns (1)-(3) use the "Full" sample (including always-treated states), while (4)-(5) use the "CS" (Callaway-Sant'Anna) sample. Why are the samples different for the primary Poisson specification? Justify the use of the full sample in the primary specification if the CS estimator is needed for robustness. It is unconventional to have two different primary samples. Choose one as the main specification and present the other as robustness.
*   **Interpretation of Coefficients:** Consistently interpret the Poisson coefficients. On page 8, the illness coefficient is described as "essentially zero," but it is a log-point coefficient. Similarly, state that exp(0.339) = 1.40, so the point estimate is a 40% increase.
*   **Table 3 and 4:** Format these for readability. Table 3 should be a plot. In Table 4, the "Classification" column in Panel A ("Large positive") is highly misleading for statistically insignificant estimates. Remove these subjective classifications.
*   **Data Appendix:** Provide more detail on the classification of "always legal" states. A list of these 24 states is crucial for replication and understanding the comparison. The timeline for newly-legalized states is helpful and should be in the main text or a table footnote.

**Conclusion:**
The paper tackles a timely and policy-relevant question with an appropriate modern empirical framework. However, in its current form, its contribution is muted by statistically insignificant main results and insufficient attention to key identification threats, particularly surveillance bias. The authors have a solid foundation. By reframing the paper around a rigorous but inconclusive causal test, deepening the analysis of reporting bias and heterogeneity, and improving the transparency of presentation, the paper could make a valuable contribution to the literature on food safety regulation. I recommend a **major revision** along the lines outlined above.
