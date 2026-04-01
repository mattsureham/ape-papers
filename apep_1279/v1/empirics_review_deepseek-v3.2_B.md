# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-04-01T22:56:21.210352

---

### Referee Report: “The Inertia Break: Military Conscription and the Farm-to-Factory Transition in World War I America”

**General Assessment:**  
This paper presents a clever and potentially important idea: exploiting the WWI draft’s nativity-based exemption to identify the causal effect of forced military service on structural transformation out of agriculture. The empirical analysis is competently executed on a large, novel dataset, and the core findings are economically meaningful. However, several critical issues—primarily concerning identification, sample construction, and mechanism validation—must be addressed before the paper makes a convincing causal contribution. With substantial revision, it has the potential to be a valuable addition to the literature.

---

#### 1. Idea Fidelity

The paper **partially pursues** the original idea outlined in the manifest but deviates in important ways regarding the identification strategy and scope of analysis.

*   **Identification Strategy:** The manifest proposed a **triangulated approach**: (1) a sharp RD at the age-21 eligibility cutoff, (2) a nativity-based DiD, and (3) a county-level DDD exploiting agricultural dependence. The paper decisively **abandons the RD and DDD frameworks** as primary strategies. It relegates the RD to a supplementary analysis (correctly noting contamination by age trends) and does not implement the proposed DDD. While focusing on the strongest design (nativity DiD) is reasonable, the complete dismissal of the other approaches without a full exploration (e.g., the DDD could have been a powerful test of mechanism) means the paper does not deliver on the proposed multi-armed identification plan.
*   **Data & Sample:** The manifest described a sample of ~10.7 million draft-eligible men from the full 43.9M MLP panel. The paper analyzes a **much smaller sample of 4.9 million men aged 10–20 in 1910**. The rationale for this age restriction is not explicitly defended, and it excludes the “too-old” control group (men aged 24+ in 1910) mentioned in the manifest. This choice may affect external validity and statistical power.
*   **Research Question:** The paper faithfully addresses the core question: does forced military service accelerate the farm-to-factory transition? The mechanism of “breaking inertia” is central to both the manifest and the paper.

**Verdict:** The paper captures the spirit of the original idea but executes a narrower empirical plan. The shift away from the promised RD/DDD framework and the smaller sample require explicit justification.

---

#### 2. Summary

This paper uses the nativity-based exemption in the WWI draft to estimate the causal effect of compulsory military service on occupational mobility. Comparing native-born (draft-exposed) to foreign-born (exempt) men across draft-eligible and ineligible age cohorts in linked 1910-1920 census data, the authors find that draft exposure increased farm exit by 1.6 pp and raised occupational income scores substantially. Effects are largest in high-agriculture counties and for Black men, supporting a mechanism whereby forced disruption overcame localized attachment costs and institutional barriers, thereby accelerating structural transformation.

---

#### 3. Essential Points (Must be Addressed)

1.  **The Validity of the DiD Parallel Trends Assumption is Not Established.** The core identification assumes that, absent the draft, the *difference* in occupational transitions between native and foreign-born men would have evolved similarly for the draft-eligible and ineligible age cohorts. This is a strong assumption given vast differences between these groups in 1910 (see Table 1: foreign-born men were much less likely to be on farms, had higher baseline occupational scores, were more literate, and were almost exclusively white). The paper provides only a linear age control to account for differential life-cycle trends. **The authors must:**
    *   Conduct a formal event-study or placebo test using pre-1910 data (e.g., the 1900-1910 MLP link) to examine whether native/foreign-born differentials in occupational mobility evolve in parallel for older cohorts who aged out of the treatment window before 1917.
    *   Discuss and test for potential confounding shocks that differentially affected native-born, draft-age men between 1910-1920 (e.g., wartime labor demand in manufacturing, the 1918 influenza pandemic).
    *   Consider adding cohort-specific trends or more flexible age controls to the DiD specification.

2.  **Sample Attrition and Representatives of the MLP Panel is a Serious Concern.** The paper begins with 43.9M linked individuals but analyzes only 4.9M men. The attrition from the full panel to the analysis sample must be transparently documented and its potential for bias addressed.
    *   **Linking Bias:** The MLP linking algorithm may have differential success rates for native vs. foreign-born individuals or for movers vs. stayers. If linkability is correlated with occupational mobility, estimates could be biased. The authors should report linking rates by nativity/draft-eligibility cells and discuss this threat.
    *   **Age-Restriction Justification:** Why restrict to ages 10-20? This excludes the “too-old” control group (men over 23 in 1910), which the manifest suggested would provide a valuable comparison. The authors should justify this choice or show results with the broader age range. Does the main result hold if the sample includes men up to age 30 in 1910?

3.  **The Proposed Mechanism Lacks Direct Evidence.** The paper argues military service broke “inertia” by removing men from farms and exposing them to new skills and networks. However, key evidence for this narrative is missing.
    *   The null effect on geographic migration is intriguing but **does not prove an in-place occupational shift**. The outcome “Moved County” is coarse; men could move within a county or to a neighboring county. More importantly, the paper lacks a direct test: among those who left farming, what specific occupations did they enter? A transition matrix (1910 farm → 1920 occupation) for treated vs. control groups would be revealing. Did they go into manufacturing, services, or remain in low-skill non-farm work?
    *   There is no direct evidence that the *experience of military service* (vs. simply being marked as draft-eligible) is the operative mechanism. Can the authors identify a subgroup of native-born, draft-eligible men who were *actually inducted* (using, for instance, the 1930 census veteran status question or military records) and show stronger effects for them? Without this, the treatment is “draft exposure risk,” not “military service.”

---

#### 4. Suggestions for Improvement

*   **Robustness and Specification Checks:**
    *   **Alternative Control Groups:** The foreign-born exemption had exceptions (e.g., declarant aliens). Can the control group be refined to only include non-declarant aliens, who were most clearly exempt? Conversely, consider using native-born men in states with very high agricultural employment as an alternative treated group and native-born men in industrial states as controls, as both were subject to the draft but had different baseline attachment costs.
    *   **Spatial Correlation:** Standard errors clustered at the state level (49 clusters) may be insufficient if shocks or draft board implementation were local. Consider clustering at the county or draft board district level and/or using Conley spatial HAC errors.
    *   **Falsification Tests:** Conduct falsification tests on outcomes that should not be affected, such as height or parental nativity. Also, test for effects on outcomes in 1910 (pre-treatment) to check for balance.

*   **Deepen the Mechanism and Heterogeneity Analysis:**
    *   **Occupational Transition Matrix:** As noted above, this is crucial. Create a table showing the distribution of 1920 occupations for 1910 farmers, split by treatment status.
    *   **Skill Acquisition:** Can you proxy for skill acquisition? For example, test if effects are larger for men who served in branches with more technical training (e.g., Engineers, Signal Corps) if such data can be linked.
    *   **Family and Network Effects:** Explore spillovers. Did having a brother or father drafted affect an individual’s own occupational mobility? This could help disentangle individual disruption from household-level labor reallocation.

*   **Improve the Literature Context and Contribution:**
    *   The discussion contrasting the positive effects here with Angrist’s (1990) negative Vietnam-era effects is excellent. **Expand this.** Frame the paper not just as a study of WWI, but as a broader theoretical contribution: the impact of conscription depends on the *counterfactual sector* from which draftees are drawn. This provides a unifying framework for seemingly contradictory findings in the literature.
    *   Engage more directly with the “Great Migration” literature (e.g., Collins 2020). The finding for Black men is among the most novel. Is the effect driven by migration out of the South, or occupational change within the South? Disentangle this.

*   **Data and Presentation:**
    *   **Transparency:** In an appendix, provide a detailed flowchart of sample construction from the raw MLP panel to the analysis sample, documenting every exclusion.
    *   **Visualization:** The paper lacks informative figures. Include: (1) A event-study graph for the DiD, (2) A binned scatterplot of farm exit vs. age, showing the absence of an RD jump, (3) A map showing heterogeneity of treatment effects across counties.
    *   **Table Clarity:** In Table 2 (Heterogeneity), the specifications are unclear. Panel A seems to be a triple interaction (DraftElig × Native × HighAg), but the table only shows two coefficients. Reproduce the full regression table or clarify the specification in the note.

*   **Policy Implications and External Validity:**
    *   The conclusion mentions relevance for developing countries. Sharpen this discussion. What are the modern analogs to the “draft”? Are there large-scale, quasi-random displacement programs (e.g., resettlement, public works) that could be studied through this lens? Acknowledge the potential dark side—forced displacement can also cause trauma and loss—to provide a balanced policy perspective.

**Overall:** The paper has a strong foundation and a compelling premise. Addressing the **Essential Points** is non-negotiable for establishing causal credibility. Implementing the **Suggestions** would significantly enhance its depth, nuance, and contribution. I recommend a **major revision**.
