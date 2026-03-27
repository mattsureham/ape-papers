# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-27T17:25:38.676844

---

**Idea Fidelity**

The paper remains largely faithful to the idea laid out in the manifest. It exploits the EU’s NIS2 size-based threshold using Eurostat’s ICT security survey, treats the 10–49 employee firms as controls versus 50–249 firms as newly treated, and emphasizes the causal question of whether regulation shifts firms toward substantive defenses or mere documentation. The DiD specification, inclusion of country×size and country×year fixed effects, and the exploration of the transposition-based triple-difference and dosage test all align with the promised identification strategy. One divergence is that the paper does not explicitly model the anticipated “instrumental variable” from the 50-employee cutoff beyond the aggregate size class comparison; any discussion of manipulation or bunching is cursory. Otherwise, the core components—data source, research question, and causal design—are all present.

**Summary**

This paper evaluates whether the NIS2 Directive meaningfully changes cybersecurity practices by exploiting the sharp 50-employee threshold using Eurostat’s triennial ICT security survey. A DiD comparison between 10–49 and 50–249 employee firms shows no effect on a composite technical security index but a pronounced adoption of compulsory training, suggesting a shift toward formal compliance (“compliance theater”). Supplemental results on security incidents and mandated-versus-non-mandated measures reinforce the behavioral interpretation.

**Essential Points**

1. **Credibility of Parallel Trends with Aggregate Cells:** The DiD relies on size-class aggregates observed only three times; the parallel trends test is thus very limited. The event study includes only one effective pre-period (since 2019 and 2022 are combined in coefficients) and does not account for potential co-movement driven by sectoral composition or macro shocks that differentially affect medium-sized firms. The paper should test parallel trends more granularly—perhaps using sector-specific subsets or by exploiting additional waves from related surveys—to bolster the identifying assumption. Without this, the null technical effect may merely reflect differential pre-existing trends.

2. **Interpretation of Aggregated Indices vs. Indicator-Level Effects:** The headline claim of “compliance theater” rests heavily on one measure—compulsory training—even though the formal index itself is imprecise and only one technical measure (biometrics) shows movement. The paper treats the nonsignificant aggregate index as evidence of “no technical response,” which could be misleading if substantial heterogeneity exists within the index. The authors need to justify why the Technical Index is the appropriate aggregation and consider methods (e.g., principal components or weights based on regulation stringency) that better capture NIS2-relevant technical efforts. Otherwise, the narrative risks overstating the evidence from one or two indicators as a generalized shift.

3. **Potential Confounding from Survey Measurement Changes and Reporting Standards:** Eurostat’s ICT security survey may have updated question wording or sampling between 2022 and 2024, especially since 2024 is the first wave after NIS2. If the treated and control size cells differ in their responsiveness to such methodological changes (e.g., larger firms better able to interpret questions), the DiD coefficient may confound regulation with survey artefacts. The paper should document any questionnaire revisions and, if possible, re-estimate using only indicators whose question wording remained constant. Alternatively, if microdata exist (even in anonymized form), a reweighting procedure could adjust for any changes in sampling frame across waves.

Given the gravity of these issues, especially the identification concerns, I would hesitate to recommend acceptance until they are satisfactorily addressed.

**Suggestions**

1. **Strengthen Parallel Trends and Dynamics**
   - Present pre-treatment trends separately by indicator (for example, plot the Technical and Formal Indices for 2019 and 2022 across size classes) to visualize any divergence before 2024. If possible, use sector-year averages (since Eurostat stratifies by NACE) to increase the number of observations for trend assessment.
   - Consider constructing a synthetic control at the size class level (e.g., using 2022 size distributions) to evaluate whether the treated medium-sized firms exhibit unexpected jumps relative to a composite of smaller firms from other countries.

2. **Refine the Technical Index and Highlight Indicator-Specific Contribution**
   - Instead of equally weighting the eight technical measures, explore alternative aggregation schemes such as weighting by baseline variance or policy relevance (e.g., measures explicitly mentioned in NIS2’s annex). This would help determine whether the null effect is driven by aggregation of stagnant measures with those that might be responsive.
   - Run a factor analysis or principal components decomposition on the technical indicators to identify latent constructs (e.g., “network controls” vs. “access management”) and examine which constructs respond, if any. This may reveal subtler shifts masked by the mean index.

3. **Address Measurement/Survey Variation**
   - Provide a table documenting any changes in questionnaire items or sampling methodology between 2022 and 2024. If question wording was consistent, state this clearly; if not, re-estimate the DiD excluding affected indicators or adjusting for mode changes.
   - Where possible, exploit the fact that the 2024 survey may have included sectoral breakdowns to check whether observed changes are concentrated in sectors most likely subject to NIS2 compliance pressure. This could help rule out alternative explanations such as sectoral shocks.

4. **Clarify the Role of Anticipation and Treatment Timing**
   - The paper notes that NIS2 was adopted in December 2022, but the baseline includes a 2022 wave that might already partially capture anticipation. Consider estimating a version where the treatment is defined as 2024 vs. 2022 only, treating 2019 as a long-run pre-period, to see if the effect is sensitive to the choice of baseline. Alternatively, use a stacked DiD approach (each pre-post pair separately) to test if effects emerge earlier.
   - Expand the discussion (and ideally the empirical approach) around anticipation: if firms began preparing in 2022, the DiD should use 2019 as the only pre-period while treating 2022–2024 as the treated change. This would clarify whether the observed training bump is compressed into 2024 or was building earlier.

5. **Explore Mechanisms in Greater Depth**
   - The decline in reported security incidents is intriguing. Disaggregate incidents into categories if available (e.g., phishing vs. ransomware) to explore whether the reduction is concentrated in areas plausibly affected by training. If the survey only reports aggregate incidents, discuss how reporting behavior might change (regulated firms may become better at detecting, thus potentially increasing reported incidents) and test for such reporting shifts using additional outcomes (e.g., perceived severity or detection capabilities if available).
   - Consider augmenting the dataset with external compliance indicators (e.g., fines, incident reports, national supervisory data) that could validate whether documentation increases are indeed tied to enforceable compliance rather than survey noise.

6. **Discuss External Validity and Policy Implications Carefully**
   - While the notion of “compliance theater” is compelling, emphasise that the evidence is short-run and based on medium-sized EU firms; the long-run dynamics (e.g., whether training leads to technical upgrades later) remain speculative. Framing this carefully will prevent overgeneralization to other jurisdictions.
   - Expand on how the findings inform the design of cybersecurity interventions (e.g., mandating independent audits, incentivizing technical investments) beyond highlighting the regulatory gap. If compliance documents are easily observable but technical defenses are not, discuss whether regulators could complement documentation requirements with performance-based metrics or third-party attestation.

Overall, the paper tackles an important and timely question with a promising quasi-experimental setup. Addressing these suggestions would substantially strengthen the credibility and policy relevance of the findings.
