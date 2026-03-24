# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-24T23:19:21.002080

---

# Referee Report

**Paper:** Does Raising the Floor Change Who Gets Hired? Minimum Wage Increases and the Racial Composition of Worker Flows
**Format:** AER: Insights

## 1. Idea Fidelity

The paper largely pursues the core research question outlined in the Original Idea Manifest: testing the Becker discrimination channel using minimum wage (MW) variation and racial hiring flows. The central hypothesis, data source (QWI), and econometric approach (Callaway-Sant'Anna DiD) align with the proposal. However, there are notable deviations from the proposed identification strategy. The Manifest explicitly listed "Border county pairs (Dube-Lester-Reich 2010)" as a key component of the identification strategy to control for local economic shocks. The submitted paper omits this entirely, relying instead on state-level variation with state fixed effects and triple-difference specifications. Additionally, the Manifest proposed a sample period of 2010–2024, while the paper uses 2005–2024; while extending the panel is generally beneficial, it introduces pre-2010 variation where federal MW changes were more frequent, potentially complicating the "never-treated" control group definition. Finally, while the Manifest specified a derived Azure Parquet dataset for race-specific QWI data, the paper describes the data as standard Census QWI, which does not publicly provide race/ethnicity breakdowns at the county-industry level. This discrepancy requires clarification regarding data access and replicability.

## 2. Summary

This paper provides a novel test of Becker's (1957) model of taste-based discrimination by examining whether binding minimum wages alter the racial composition of hiring flows. Using administrative worker-flow data from the Quarterly Workforce Indicators (QWI) and staggered state minimum wage increases, the author finds no evidence that higher wage floors change the Black share of new hires in low-wage industries. However, the analysis reveals a significant increase in Black separation rates following minimum wage hikes. These findings suggest that while minimum wages may not reduce discriminatory hiring at the entry margin, they may exacerbate racial disparities in job stability, shifting the equity implications of wage floor policies from employment levels to flow dynamics.

## 3. Essential Points

The following issues must be addressed to ensure the causal claims and contributions are supported by the evidence:

1.  **Identification Strategy and Border Pairs:** The omission of the border-county design proposed in the Manifest is a significant weakening of the causal strategy. State-level minimum wage changes are often correlated with state-specific economic trends that also affect racial composition (e.g., political shifts, industrial composition changes). Relying solely on state-level variation with state fixed effects may not adequately purge these confounders. The authors must either implement the border-county specification as a robustness check or provide a compelling justification for why state-level variation is sufficient given the potential for endogenous policy adoption.
2.  **Data Access and Replicability:** The paper treats race-specific QWI data as standard, but public QWI files do not contain race/ethnicity dimensions at the county-industry level due to disclosure avoidance. The Manifest referenced a specific derived Azure dataset. The authors must explicitly clarify the data source (e.g., LEHD Infrastructure Files, restricted access) and discuss replicability. For an *AER: Insights* paper, the inability of other researchers to replicate the core data construction is a major barrier to publication unless the data access pathway is clearly documented.
3.  **Interpretation of Separation Mechanisms:** The finding that Black separation rates rise is the paper's most significant empirical contribution, yet the interpretation remains speculative. The paper lists three candidate interpretations (selective retention, displacement, voluntary mobility) but lacks evidence to distinguish them. Claiming this refutes the Becker hiring channel is valid, but implying it confirms discriminatory *exit* behavior requires more caution. The authors must temper causal claims regarding the *mechanism* of separations or provide additional evidence (e.g., tenure profiles) to support the "selective retention" hypothesis over general turnover effects.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's empirical rigor, clarity, and policy relevance. Addressing these will significantly improve the manuscript's suitability for publication.

**Strengthening the Identification Strategy**
While the Callaway-Sant'Anna (CS) estimator is appropriate for staggered adoption, the unit of variation (state) is coarse. To address the essential point on identification, I strongly recommend adding a border-county analysis as a robustness check, even if it is not the main specification. Following Dube, Lester, and Reich (2010), comparing counties across state borders where one side raised the minimum wage and the other did not would control for local labor market shocks that might correlate with racial demographics. If the border results align with the state-level CS estimates, confidence in the causal null effect on hiring will increase substantially. Additionally, consider including state-specific linear time trends in the TWFE specifications to account for differential pre-existing trends in racial composition across states, which the event study pre-trends test may not fully capture.

**Clarifying Data Construction and Access**
Transparency regarding the QWI race/ethnicity data is crucial. The manuscript should explicitly state whether this analysis uses public use files, restricted access LEHD Infrastructure Files (LIF), or a specific derived dataset (as hinted in the Manifest). If this is restricted data, include a detailed data appendix describing the application process or availability for replication. Furthermore, the discrepancy between the Manifest's summary statistics (Black hire share mean = 0.1785) and the paper's Table 1 (mean = 0.133) should be explained. The paper notes this is for "Low-Wage Industries," but explicitly stating that the Manifest stats were likely broader (all industries) would resolve potential confusion about data consistency.

**Deepening the Mechanism Analysis**
The separation rate result is the most policy-relevant finding. To deepen this analysis, consider exploiting the tenure data available in some QWI versions. If the data allow, distinguish between "new hire separations" (very short tenure) versus "established worker separations." If the effect is driven by new hires leaving quickly, it suggests a matching problem or trial-period firing. If it affects established workers, it suggests displacement or hours reductions converted to separations. Additionally, the heterogeneity analysis shows significant effects only for "Large MW Bite" states (Table 3, Col 3). This suggests a non-linear threshold effect. The discussion should emphasize this: small minimum wage increases may be absorbed without compositional changes, while large hikes trigger adjustment on the separation margin. This nuance is critical for policy design.

**Visualizing Dynamic Effects**
The Appendix includes a table of event study coefficients (Table A1), but *AER: Insights* readers benefit greatly from visual evidence. I recommend converting the event study table into a coefficient plot with confidence intervals. Visual inspection of the pre-treatment coefficients (event times -5 to -1) is standard practice for validating the parallel trends assumption in staggered DiD designs. Ensure the plot clearly marks the treatment event (year 0) and distinguishes between the CS dynamic estimates and any TWFE event study counterparts to highlight the bias correction.

**Refining the Theoretical Contribution**
The paper claims to reject the simple Becker prediction. However, the Becker model primarily concerns wage discounts, not necessarily hiring shares if productivity differs. The discussion should engage more deeply with statistical discrimination models (e.g., Phelps 1972) where race is used as a proxy for unobserved productivity. If minimum wages compress wages but employers still perceive higher variance or lower mean productivity for minority workers, they may hire fewer or fire more frequently. Explicitly linking the separation result to statistical discrimination theory (rather than just taste-based) would strengthen the theoretical contribution. The current draft mentions this briefly but could make it a central pillar of the discussion.

**Policy Implications and Welfare**
The conclusion notes an "equity-efficiency tradeoff," but this could be quantified. If Black workers earn higher wages but face higher separation rates, what is the net effect on expected annual income? A simple back-of-the-envelope calculation comparing the wage gain (from the earnings ratio coefficient) against the expected income loss from higher unemployment duration (implied by separation rates) would make the policy implications concrete. Even if precise unemployment duration data is unavailable, discussing the direction of this tradeoff would add significant value for policy-oriented readers.

**Minor Editorial Suggestions**
*   **Table 1:** Ensure the "Never-Treated" column sums correctly. The text says 21 control states, but the Manifest mentioned 15+. Clarify if the sample expansion to 2005 added more control states that later treated.
*   **Equation 1:** The CS estimator notation is dense. Consider simplifying the text explanation to focus on the intuition (weighted average of cohort-specific ATTs) rather than the full algebra, which may distract Insights readers.
*   **Abstract:** The abstract mentions "28 treated states between 2005 and 2024." Ensure this matches the main text exactly (Section 2 says 2008-2016 adoption waves). Consistency in treatment timing definitions is key.

By addressing the identification concerns, clarifying data access, and deepening the mechanism analysis, this paper has the potential to make a lasting contribution to how economists understand the distributional effects of labor market regulations. The null result on hiring is itself a valuable correction to the literature, provided the test is robust.
