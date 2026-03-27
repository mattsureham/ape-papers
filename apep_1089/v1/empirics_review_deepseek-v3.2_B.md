# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-27T17:26:45.163245

---

## Referee Report

**Paper:** "Compliance Theater: The EU's NIS2 Cybersecurity Directive and the Gap Between Documentation and Defense"

**Date:** 16 October 2023

---

### 1. Idea Fidelity

The paper faithfully executes the research program outlined in the original Idea Manifest. It adheres to the proposed identification strategy, exploiting the sharp 50-employee threshold of the NIS2 Directive in a Difference-in-Differences (DiD) design, using the 10-49 employee size class as the control group and the 50-249 class as treated. The core data source is correctly specified as the Eurostat ICT security survey (isoc_cisce_ra), and the research question—whether the regulation induces substantive behavioral change or merely formal compliance—is the central focus. The paper successfully incorporates the suggested elements: it uses the 2024 wave as the post-treatment period, includes the triple-difference (DDD) extension leveraging cross-country transposition variation, and conducts a dosage test using the 250+ employee class. No key element from the manifest is missed.

### 2. Summary

This paper provides the first causal evaluation of the EU's NIS2 cybersecurity directive. It finds that the regulation induces a significant increase in easily verifiable, formal compliance activities—specifically, compulsory staff training—but has no detectable effect on substantive, technical security investments. This divergence is labeled "compliance theater." A supplementary, suggestive finding indicates a reduction in reported security incidents for treated firms, hinting that awareness-focused compliance may still yield security benefits through behavioral channels.

### 3. Essential Points

The paper is promising and makes a genuine contribution, but it must convincingly address three critical issues before publication.

**1. Data Aggregation and the Ecological Inference Fallacy:** The analysis is conducted at the **country-size-class-year** level. This aggregation masks critical firm-level heterogeneity and risks the ecological fallacy. The treatment (NIS2 coverage) is assigned at the *firm* level based on its sector and size, but compliance costs, technical capacity, and pre-regulation security posture vary dramatically within a size class. The estimated "adoption rate" for a country-size cell could be driven by a small subset of firms making large changes, while most do nothing. The authors must directly acknowledge this as a fundamental limitation and discuss its implications for interpreting the null effect on technical measures. Could the null result stem from opposing reactions within the treated class (e.g., some firms investing heavily while others divest)? Supplemental analysis using national microdata from one or two member states (if available) or discussing the variance of outcomes within cells would significantly strengthen the credibility of the aggregate findings.

**2. Threats to Parallel Trends and Anticipation:** The parallel trends test uses only two pre-treatment periods (2019, 2022). This is extremely limited for establishing a credible counterfactual, especially given that NIS2 was adopted in December 2022. The 2022 survey wave likely captures significant **anticipation behavior**, biasing the estimated treatment effect toward zero. The authors correctly note this but treat it merely as a source of conservative bias. This needs deeper engagement. The paper should: (a) Quantitatively discuss the potential magnitude of this attenuation. Could a strong anticipation effect fully explain the technical-investment null? (b) Explore alternative pre-trend tests, such as comparing trends in the 2015-2019 period (if data exists) for the same size classes under the old NIS1 regime, to build a longer-term pattern of parallel evolution.

**3. Compositional Changes and Manipulation at the Threshold:** A major threat to the DiD design is that the regulation itself may change the composition of the treated and control groups. Firms near the 50-employee threshold have a clear incentive to manipulate their reported size (e.g., via outsourcing, splitting, or under-reporting) to avoid regulation. The authors dismiss this by citing literature on labor regulations, but the cost structures differ. Avoiding cybersecurity regulation may be cheaper than avoiding labor laws. If the least security-conscious firms in the 50-54 employee range manipulate their way into the 10-49 class, the DiD comparison becomes invalid (the control group would become less secure, making the treated group *appear* to improve). The authors must provide direct evidence against this. At a minimum, they should: (a) Test for discontinuous density around the 50-employee threshold in a separate dataset (e.g., Eurostat's structural business statistics) in the post-2022 period to detect bunching. (b) Include a robustness check where the control group is redefined as the smallest firms (e.g., 10-19 employees) who are less likely to be manipulators, to see if results hold.

### 4. Suggestions

The following suggestions are aimed at improving the paper's robustness, clarity, and impact.

**A. Robustness Checks & Additional Analysis**
*   **Alternative Control Groups:** Beyond the main 10-49 control, run analyses using: (1) Firms in 50-249 employees in sectors *not* covered by NIS2 (if identifiable in the data), (2) Firms in non-EU European countries (e.g., Switzerland, UK) as a placebo policy sample.
*   **Sectoral Heterogeneity:** The paper aggregates across all NACE sectors. The effect of NIS2 likely differs between a highly digital "important" sector (e.g., digital infrastructure) and a traditional "essential" sector (e.g., water). Disaggregating the analysis by broad sectoral categories would yield valuable policy insights about where regulation is more or less effective.
*   **Lead and Lag Analysis:** Instead of a simple post-2024 dummy, use the 2019, 2022, and 2024 waves in an event-study framework with 2022 as the reference year. This would more visually demonstrate the parallel pre-trends (2019 coefficient) and the post-treatment effect (2024 coefficient), and could hint at anticipation if the 2022 coefficient is positive.
*   **Placebo Thresholds:** Perform placebo tests using fake size thresholds (e.g., 100 employees) in the pre-period to confirm that the observed effect is unique to the 50-employee cutoff.

**B. Interpretation & Mechanism**
*   **The "Compliance Theater" Mechanism:** The paper convincingly shows an asymmetry between formal and technical measures. To strengthen the mechanism, the authors could: (1) Discuss whether the cost differential between training and technical measures is evident in market data (e.g., citing reports on cybersecurity service pricing). (2) Explicitly link the findings to theories of regulatory monitoring and enforcement. If ENISA's audits focus on document checks, the firm's response is rational.
*   **Incident Reduction Finding:** This is intriguing but requires more caution. The decline in *reported* incidents could mean: (a) true reduction in incidents, (b) improved detection and reporting (which NIS2 mandates), or (c) under-reporting due to fear of regulatory penalty. The authors should explicitly outline these competing hypotheses and, if possible, use textual analysis of ENISA reports or other data to assess whether reporting completeness changed post-NIS2. This finding should be presented more tentatively.

**C. Presentation & Clarity**
*   **Theoretical Framework:** The introduction and discussion would benefit from a more structured theoretical framework that clearly outlines the firm's cost-minimization problem under regulatory constraint, formalizing the trade-off between verifiable compliance and substantive investment.
*   **Policy Implications:** The conclusion's policy implications are good but could be sharper. Provide specific, actionable recommendations for regulators: e.g., "To close the compliance theater gap, audits should incorporate technical penetration tests rather than document reviews," or "Future directives could include graduated technical requirements scaled by firm size and revenue."
*   **Table & Figure Refinement:**
    *   In Table 2 (indicator-level effects), consider adding a column showing the pre-treatment mean for the treated group (50-249) to help readers gauge the relative size of the effect (3.67 pp is an 8.6% increase—this context is helpful but buried in the text).
    *   A graphical event-study plot for the compulsory training outcome would be more impactful than Table 4.
    *   In Table 1 (Summary Stats), the "Compliance Gap" (Formal - Technical) is negative, implying technical adoption is *higher* than formal adoption. This is counterintuitive to the term "gap" and the paper's narrative. Consider reversing the definition (Technical - Formal) so a positive gap aligns with the "technical deficit" story, or choose a clearer label like "Formal Deficit."

**D. Data & Reproducibility**
*   **Code and Data Sharing:** Given the use of public Eurostat data, the authors should commit to providing full replication code and detailed data construction scripts in a public repository (e.g., GitHub, Zenodo). This is a standard expectation for publication in a top journal.
*   **Sample Details:** The appendix should explicitly list the 27 countries in the sample and note any exclusions (e.g., Portugal's missing 50-249 class, as per the Manifest). A table showing transposition status by country would be useful.

**Overall,** this is a timely, well-executed, and important study. The core finding of "compliance theater" is compelling and policy-relevant. By rigorously addressing the essential points above and incorporating the suggested improvements, the paper can make an even stronger contribution to the literature on regulation and digital security.

---
