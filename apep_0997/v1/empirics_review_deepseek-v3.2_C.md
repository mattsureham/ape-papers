# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-03-26T16:04:59.054115

---

### **Review of "The Formalization Dividend: Romania's Construction Tax Holiday and the Shadow Workforce"**

**1. Idea Fidelity**
The paper deviates from several key elements outlined in the original idea manifest. The manifest specified using Romania's National Institute of Statistics (INS/NIS) quarterly labor force survey (AMIGO) and administrative data, which would provide high-frequency, nationally representative data on formality. The paper instead uses aggregated annual and quarterly Eurostat national accounts data (`nama_10_a64_e`), which is a less granular, supra-national source. This substitution loses the potential for region-level analysis and the direct measurement of "undeclared work" via the gap method mentioned in the manifest. Furthermore, the manifest proposed a triple-difference design (construction vs. control × formal vs. informal) to isolate the formalization channel and an IV robustness check using an EU construction activity index to control for demand shocks. Neither of these more rigorous identification strategies is implemented in the paper. The core research question is maintained, but the empirical execution is simplified and less nuanced than originally planned.

**2. Summary**
This paper exploits Romania's 2019 sector-specific tax holiday—which eliminated income tax, reduced health contributions, and raised the minimum wage for construction workers—to estimate its effect on employment formalization. Using a difference-in-differences design comparing the construction sector to nine other sectors from 2010-2023, it finds the reform reduced the construction self-employment share by approximately 3-4 percentage points and increased salaried employment by roughly 12%, with effects growing monotonically over five years. The paper argues this demonstrates that large, sustained tax incentives can formalize an entrenched shadow workforce.

**3. Essential Points**
The following three critical issues must be addressed for the paper to be credible.
1. **Inference with Few Clusters is Invalid.** The analysis clusters standard errors at the sector level (10 clusters). With only one treated cluster (Construction), conventional cluster-robust standard errors are severely biased and will underestimate true uncertainty. The authors acknowledge the problem but apply inadequate solutions (leave-one-out, heteroskedasticity-robust SEs for a two-sector comparison). This invalidates all reported significance tests (p-values). The authors must implement and report inference methods valid for a small number of clusters, such as wild cluster bootstrap-t procedures or randomization inference, and reinterpret results accordingly.
2. **The Self-Employment Share is a Weak Proxy for Informality.** The outcome—(Total Employment - Salaried Employees)/Total Employment—captures all self-employed, including legitimate entrepreneurs and freelancers. In many economies, construction "informality" is specifically characterized by *disguised* employment, where salaried workers are misclassified as self-employed. The chosen measure conflates this with true independent contracting. The paper must either: a) justify why this proxy is valid in Romania using local evidence, or b) find a better measure (e.g., from household surveys distinguishing "dependent" self-employed, or using administrative tax registration data as hinted in the manifest).
3. **Confounding Sectoral Demand Shocks are Not Adequately Controlled.** Construction activity is highly cyclical and likely experienced different demand trends than the control sectors (e.g., Manufacturing, ICT) post-2019. The event study's gradually growing effect could reflect a concurrent construction boom (e.g., post-pandemic recovery, EU infrastructure funds) rather than the tax reform. A placebo test on Real Estate (sector L) is insufficient because real estate is directly tied to construction activity. The authors need to directly control for sector-specific demand, ideally using the EU construction activity index mentioned in the manifest as an IV or control variable, or by incorporating leads and lags of a construction output index into their DiD specification.

**4. Suggestions**
* **Data and Measurement:**
    * Reconcile with the original manifest by acquiring and using the Romanian INS (NIS) AMIGO microdata or aggregated sectoral data. This would allow finer quarterly analysis, regional breakdowns, and potentially a direct measure of informal employment. If Eurostat data must be used, explain why INS data was unavailable or inferior.
    * Report the raw trends graphically. Figure 1 should plot the self-employment share for Construction and the average of control sectors over time. This visual would make the parallel pre-trends and post-treatment divergence immediately clear to readers.
    * Compute an alternative "formal employment" measure: the ratio of Salaried Employees to Total Employment. This is the inverse of the current outcome and may be more intuitive. Check if results are symmetric.
    * Discuss the magnitude in economic context. Is a 3.1 pp reduction (≈26,000 workers) commensurate with the size of the tax wedge change (12+ pp)? Perform a simple back-of-the-envelope calculation linking the tax savings per worker to the estimated employment shift.

* **Empirical Strategy:**
    * The TWFE DiD is appropriate given single-treatment timing, but the specification should be explicitly written with an interaction term (`Construction × Post2019`) rather than the implicit description in Equation (1). Clarify the equation.
    * The event study is well-presented. However, the interpretation that the gradual effect indicates "costly adjustment" is speculative. Provide evidence or cite literature on why formalization might lag (e.g., slow renegotiation of contracts, delayed enforcement). Alternatively, test if the effect growth correlates with lagged measures of policy awareness or enforcement intensity.
    * Explore heterogeneous effects. The reform bundled three changes: tax exemption, health contribution reduction, and a minimum wage hike. While disentangling them is impossible, you can discuss which component likely drove the result. For instance, did the minimum wage hike potentially *reduce* formalization by making formal employment more expensive? Theorize based on existing literature.

* **Robustness and Interpretation:**
    * The "Manufacturing only" control is a good robustness check, but Manufacturing is not a perfect comparator (different skill sets, capital intensity). Discuss its pros and cons.
    * The placebo test on Real Estate should be expanded. Also test other sectors one-by-one (e.g., Transportation, Accommodation) to show the effect is unique to Construction.
    * Address the possibility of spillovers. Could the tax holiday have drawn workers from other sectors into construction, artificially inflating salaried employment growth? Check if total employment in control sectors declined post-2019.
    * The abstract claims the effect grew to "6.7 percentage points by 2023." This is the event study coefficient for 2023 (-0.0673). Ensure this is consistent with the DiD coefficient (which averages over all post-years). Clarify that the event study estimates are *cumulative* yearly effects relative to 2018, not the annual increment.

* **Presentation and Context:**
    * The introduction and background are clear. Strengthen the policy motivation by citing Romanian government documents or news reports about the law's objectives.
    * The discussion section's comparison to other studies (Sweden, Colombia) is useful. Expand it: why might Romania's bundled reform be more effective than isolated payroll tax cuts?
    * Clearly state the limitations. Beyond the few-cluster issue, acknowledge that the reform's three components are bundled, so the estimated effect is a composite. Also, the post-period includes the COVID-19 pandemic, which disproportionately affected contact-intensive sectors like Accommodation (a control). Consider adding COVID-era dummies or excluding 2020-2021.
    * The conclusion is policy-relevant. Emphasize that the "large and sustained" incentive size is key, but also note that such sector-specific tax holidays can create distortions and inequities across the economy.

* **Technical Corrections:**
    * Table 2 (Event Study) reports a significant pre-trend for 2017 for the self-employment share (0.0195, p<0.01). This contradicts the claim that "pre-treatment coefficients... are statistically indistinguishable from zero." Address this divergence; it may indicate a pre-existing trend.
    * In Table 1, Column (1) log salaried employment effect is 0.0834 (p=0.058). Describe this as marginally significant or "significant at the 10% level," not simply "*".
    * Ensure all references are complete and relevant. The bibliography is not provided, but cited works (Saez et al. 2019, Kugler & Kugler 2009, etc.) should be standard in the field.

Overall, the paper identifies a compelling natural experiment and finds plausible effects. However, the current draft requires major revisions to address fundamental econometric flaws and to strengthen the measurement of informality. With these fixes, it could make a valuable contribution to the literature on tax policy and formalization.
