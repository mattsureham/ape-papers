# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-30T20:37:55.604326

---

# Referee Report

**Manuscript:** Cheaper Labor, Same Jobs: Evidence from Belgium's Record Employer Payroll Tax Cut
**Journal:** AER: Insights
**Date:** October 26, 2026

## 1. Idea Fidelity

The paper adheres closely to the Original Idea Manifest (ID: idea_0245). The core research question (employment effects of Belgium's 2016-2018 SSC cut), data sources (Eurostat namq_10_a10_e, lc_lci_r2_q), and identification strategy (cross-country DiD with permutation inference) match the proposal. The decision to truncate the sample at 2019-Q4 rather than 2022 (as initially suggested in the manifest) is well-justified by the COVID-19 structural break and aligns with the "Design Parameters" noted in the manifest's feasibility check. One minor deviation is the replacement of the proposed Synthetic Control Method (SCM) with permutation inference on a fixed control group; while methodologically sound, this shifts the weight from constructing a counterfactual to testing significance against a distribution. Overall, the execution demonstrates high fidelity to the proposed design.

## 2. Summary

This paper evaluates the employment effects of Belgium's 2016-2018 reduction in employer social security contributions, exploiting wage rigidity institutions to isolate labor demand responses. Using sector-level Eurostat data and a cross-country difference-in-differences design, the author finds a sharp reduction in non-wage labor costs but no corresponding increase in employment relative to neighboring controls. The results suggest that in rigid-wage economies, payroll tax cuts may function as profit windfalls rather than employment subsidies, contributing valuable evidence to the debate on tax incidence and labor market institutions.

## 3. Essential Points

The paper is well-written and addresses a policy-relevant question with a clean natural experiment. However, three critical issues regarding identification and inference must be addressed before publication.

1.  **Inference and Power with Limited Clusters:** The primary specification clusters standard errors at the country level with only four countries (one treated, three controls). Even with permutation tests, the degrees of freedom for the treatment effect are extremely low. The permutation p-value of 0.75 indicates the effect is not distinguishable from noise, but it does not confirm the *absence* of an effect. The paper needs to report power calculations or equivalence tests to demonstrate that the design can rule out economically meaningful elasticities (e.g., can you rule out an elasticity of -0.3?). Without this, the "null result" may simply reflect low power rather than a true zero effect.
2.  **Confounding Shocks to Belgium (2016-2018):** The treatment period coincides with specific shocks to Belgium that may violate the parallel trends assumption. Notably, the Brussels terrorist attacks (March 2016) occurred immediately prior to the reform onset, potentially depressing service sector employment (tourism, hospitality) independently of tax policy. Additionally, Belgium experienced specific industrial disputes and political instability during this window. The event study shows clean pre-trends, but the post-period drift could be driven by these confounders rather than the tax policy. The author must discuss or control for these contemporaneous shocks.
3.  **Treatment Intensity Heterogeneity:** The triple-difference strategy relies on sectoral labor shares to identify variation in treatment intensity. However, the Belgian SSC cut was a reduction in the *statutory* standard rate. Many sectors, particularly labor-intensive ones, already benefited from targeted reductions (e.g., for low-wage workers or first hires) prior to the reform. Consequently, the *effective* tax rate reduction may not correlate perfectly with aggregate labor shares. If high labor-share sectors already had lower effective rates, the triple-diff may be biased. The author should clarify whether the statutory cut applied uniformly across sectors or if pre-existing reductions dampened the treatment intensity in specific industries.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's robustness and policy impact. While not strictly essential for acceptance, addressing them would significantly elevate the contribution.

**1. Revive the Synthetic Control Method (SCM)**
The original manifest proposed SCM, but the paper opted for permutation inference on a fixed control group. Given the small number of control countries, a Synthetic Belgium constructed from a weighted combination of OECD countries (not just neighbors) might provide a tighter counterfactual. Even if the main results hold, adding an SCM specification in the appendix would reassure readers that the null result is not driven by the specific choice of Netherlands/Germany/Luxembourg. You could use the `Synth` package in R or Stata to construct a donor pool from the extended list of 9 countries mentioned in Table 1, Column 5. This would complement the permutation test by showing that no weighted combination of controls matches Belgium's post-reform trajectory better than the actual data.

**2. Conduct Equivalence Testing**
To address the power concern, consider implementing an equivalence test (e.g., Two One-Sided Tests or TOST). Instead of testing $H_0: \beta = 0$, test whether the effect lies within a bounds of economic insignificance (e.g., $|\beta| < 0.05$). This allows you to statistically claim that the effect is "negligible" rather than just "not significantly different from zero." Given the policy stakes (€3 billion annual cost), establishing an upper bound on the job creation effect is more valuable than a standard null hypothesis test. Report the minimum detectable effect (MDE) given your sample size and clustering structure.

**3. Deepen the Wage Mechanism Analysis**
Table 2, Column 3 shows that Belgium's wage index grew *less* than controls (-2.98 points). The text attributes this to indexation tracking CPI while controls grew with market forces. This deserves more nuance. If nominal wages grew slower in Belgium, did *real* wages behave differently? If inflation was higher in Belgium, nominal indexation might still imply real wage rigidity. Adding a brief analysis of real wage growth (deflating by national CPI) would strengthen the claim that wages were truly rigid. Furthermore, if wages grew slower than controls, could this offset the SSC cut's effect on total labor costs? A decomposition of total labor cost growth (Wages + SSC) vs. employment would clarify the net cost shock faced by employers.

**4. Corroborate the "Profit Windfall" Hypothesis**
The paper argues the tax cut became a profit windfall. While direct firm-level profit data is unavailable, you could use aggregate Eurostat data on Gross Operating Surplus (GOS) by sector (nama_10_a10). If the SSC cut boosted profits, we should see a rise in the labor share of income (or a fall in the share of compensation in value added) in Belgium relative to controls. Adding a simple DiD on the labor share outcome would provide direct evidence for the proposed mechanism. If the labor share fell significantly, it confirms the incidence fell on capital/profits; if it remained stable, the cost savings may have been passed to consumers via lower prices.

**5. Extend the Sample with COVID Controls**
The manifest originally proposed data through 2022. Truncating at 2019 loses valuable post-treatment data. Consider extending the sample to 2022 but including interaction terms for the COVID period (e.g., `Post2020 × Country` fixed effects) or simply dropping 2020-Q2 to 2021-Q4. Adding 2021-2022 data would increase the post-period length from 15 to ~23 quarters, improving power. Given that the tax cut was permanent, the effect should persist post-pandemic. If the null holds with more data, the result is more robust.

**6. Clarify Statutory vs. Effective Rates**
In the Institutional Background, explicitly state whether the 32.4% to 25% cut applied uniformly across all sectors. If there were sector-specific exemptions or phased implementations for certain industries (common in Belgian labor law), this should be noted. You might construct a more precise treatment intensity measure using the effective average tax rate (EATR) if available from OECD Taxing Wages data, rather than relying solely on sectoral labor shares. This would tighten the link between the policy variable and the empirical specification.

**7. Discuss General Equilibrium Effects**
The paper focuses on partial equilibrium labor demand. However, a tax cut of this magnitude (€3 billion) might have general equilibrium effects via increased aggregate demand. If the tax cut was financed by consumption tax increases (as noted in the background), this could dampen product demand, offsetting employment gains. Briefly discussing this financing side would provide a more complete picture. Did the VAT increase coincide with the SSC cut? If so, the net effect on demand might be neutral, explaining the null employment result.

**8. Visual Enhancements**
While AER: Insights is text-heavy, adding a single figure showing the event study coefficients with confidence intervals would be valuable. The text describes the event study, but a visual plot (similar to Figure 1 in many AER papers) allows readers to instantly assess pre-trend parallelism and the precision of post-treatment estimates. Ensure the plot clearly marks the two phases of the reform (2016 and 2018) to show if there was any differential response to the larger cut.

**9. Refine the Policy Conclusion**
The conclusion states that payroll tax cuts may not work in rigid-wage economies. Consider nuancing this to suggest *conditional* effectiveness. For example, if the goal is employment, targeted cuts (e.g., for low-wage workers where labor supply is more elastic) might work better than broad statutory cuts. Or, if the goal is competitiveness, the reform might have succeeded in preventing job *losses* rather than creating new jobs. Distinguishing between "job creation" and "job preservation" could refine the policy implication, as the counterfactual might have been worse employment performance without the cut.

**10. Data Availability Statement**
Ensure the replication code is deposited in a stable repository (e.g., OpenICER or the project GitHub linked in the acknowledgements). The paper mentions the AEP project repository; verify that the specific scripts for data cleaning (Eurostat API calls) and estimation are included and documented. Given the reliance on API data which can be revised by Eurostat, providing the frozen dataset used for the analysis is crucial for reproducibility.

By addressing the inference limitations and deepening the mechanism analysis, this paper has the potential to become a definitive reference on payroll tax incidence in rigid labor markets. The core finding is striking and policy-relevant; strengthening the empirical backbone will ensure it withstands scrutiny.
