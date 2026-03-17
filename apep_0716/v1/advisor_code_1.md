# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-17T22:51:32.133598

---

**Idea Fidelity**

The paper largely follows the original idea manifest. It applies bunching estimation to the IRS EO BMF around the \$200,000 Form 990 threshold, exploits the focal placebo at \$50,000, discusses the pre-2010 threshold reform, and interprets outcomes through the compliance cost lens. The paper does skip two aspects emphasized in the manifest, however: it does not exploit the cross-state variation in state-level audit thresholds to separate federal versus state pressure, nor does it fully engage the “migration” test using pre‐ and post‐2010 data (beyond a single legacy bunching note). The identification strategy relies on smoothness and placebo tests, but the paper stops short of the richer falsification exercises hinted at in the manifesto. Explicitly integrating these stated plans—state variation and more thorough use of the 2010 reform—would strengthen the alignment.

---

**Summary**

This short paper documents statistically significant bunching of nonprofit gross receipts just below the \$200,000 IRS Form 990 filing threshold, implying roughly 1,000 organizations distort reported revenue to avoid the more demanding disclosure. The estimate survives placebo tests at the \$50,000 threshold and round-number cutoffs, and heterogeneity analysis points to small, religious, and human-service organizations as the most responsive, consistent with a compliance-cost mechanism. The result is framed as revealing a “compliance tax” imposed by the disclosure regime, extending the bunching literature to nonprofit regulation.

---

**Essential Points**

1. **Asset Threshold Interaction.** The filing requirement depends on both gross receipts and asset size (Form 990 applies whenever assets exceed \$500,000 regardless of revenue). The current estimation window does not condition on the asset ceiling, so the observed bunching could reflect an endogenous mass of high-asset organizations clustering below \$200K receipts but above the asset threshold. Please restrict the sample to organizations with reported assets below \$500K (or, alternatively, include the asset threshold in the polynomial fit or through nonparametric weighting) so the density around the \$200K threshold reflects the single discontinuity you claim to study.

2. **Identification requires stronger falsifications.** The identifying assumption is that absent the threshold, the density would be smooth, yet public reporting and operational constraints might create natural mass points (e.g., grant categories or budgeting norms) around even round numbers. While the \$50K placebo is helpful, it does not fully rule out endogenous heaping near \$200K driven by, say, fundraising bundles or public grant tiers around that revenue level. Provide additional falsification evidence—e.g., exploiting the 2010 threshold change explicitly by comparing densities before and after the reform (perhaps using earlier EO BMF extracts) or showing bunching does not differ for organizations in states with alternative disclosure regimes. Without such exercises it is hard to conclude the observed jump reflects compliance costs rather than other economic forces.

3. **Interpretation of “manipulation” needs caution.** The cross-sectional snapshot cannot distinguish between reporting manipulation, strategic behavior in calendarization, or genuine operational responses (keeping operations small to avoid the burden). This distinction matters for policy implications: manipulation suggests enforcement or audit risk; strategic downsizing implies the threshold distorts nonprofit activity. Clarify this distinction, and—better yet—provide evidence on whether organizations below the threshold disproportionately cite compliance (e.g., through state-level filings or by examining assets, expenditures, or officer counts) to support the compliance-cost interpretation.

If these issues cannot be addressed convincingly, the paper lacks sufficient identification and should not be published in its current form.

---

**Suggestions**

1. **Condition on asset size and other determinants of filing.** As noted, Form 990 status depends on both gross receipts and assets. Re-estimate the bunching with the sample restricted to organizations with assets below \$500K to isolate the pure revenue threshold. Additionally, organizations with liabilities or related organizations may trigger filing requirements; consider controlling for these if such data are available. If the asset threshold cannot be fully applied, supplement the main estimate with an analysis of how the density behaves for the subpopulation that is unambiguously subject to the revenue cutoff.

2. **Exploit the 2010 threshold reform.**
   - Locate older EO BMF releases (pre-2010) or use archival GuideStar/ProPublica data, if available, to compare the revenue distribution before and after the threshold move. A pre/post comparison (or a difference-in-differences using organizations whose asset/revenue profiles were unaffected) would show whether the kink migrated from \$100K to \$200K, strengthening the causal story.
   - As an interim step, construct cohorts whose most recent return dates span both periods, and test whether organizations that reported revenue around \$100K in earlier years still cluster there today. This would help confirm the “legacy bunching” you mention.

3. **Deepen placebos beyond the \$50K threshold.**
   - Add placebo bunching estimates at other filing-related thresholds (e.g., the \$500,000 asset cutoff, state-specific reporting triggers) or at non-policy round numbers matched on sector or region. Demonstrating that bunching occurs only when there is a meaningful disclosure jump, and not at other comparable cutoffs, would buttress the inference that compliance costs drive the response.
   - For the \$50K placebo, consider whether the compliance difference is truly negligible. If the e-Postcard is also burdensome for some organizations (due to software or administrative costs), the absence of bunching may just reflect differing capacity. Supplement the placebo with, say, a comparison of organizations whose filing requirement changed due to assets, not revenue.

4. **Improve counterfactual specification transparency.**
   - Provide the fit of the polynomial counterfactual (plots of residuals or fitted values) and explain how sensitive the estimates are to including/excluding bins just outside the exclusion window. The robustness table is helpful, but also show the actual density plot with the counterfactual and bunching region shaded (as is standard in bunching papers). This visual will allow readers to assess whether the polynomial is absorbing genuine shape differences rather than true counterfactual movements.
   - Explain the bootstrap procedure in more detail: why choose parametric Poisson noise, how is overdispersion handled, and are the standard errors stable across different replication seeds?

5. **Clarify mechanism interpretation.**
   - The heterogeneity results are suggestive, but to link them to compliance costs you could include additional proxies (e.g., proportion of organizations with paid staff, presence of audited financial statements, or reliance on public donations). If the data lacks these variables, explain why the current proxies (religious, asset size) are valid stand-ins.
   - Consider estimating a simple structural model or translating bunching mass into an implied lump-sum cost (as in Kleven’s framework). Even a back-of-the-envelope calculation using the estimated density jump and an assumed cost of disclosure would help policymakers understand the magnitude of the “compliance tax.”

6. **Address public availability and reporting lags.**
   - Since the EO BMF is a cross-sectional snapshot, there may be reporting lags or missing entries (especially for organizations that filed late). Document how current the data is, whether it covers the same tax year for all organizations, and how missingness is handled. If certain types of organizations (e.g., religious) are more likely to report late, this could bias density estimates.
   - A robustness check restricting the sample to filings from a single recent year (if possible) would alleviate concerns about mixing years, which is especially relevant for interpreting the magnitude of the bunching.

7. **Discuss alternative mechanisms in greater depth.**
   - Could the observed bunching arise because some organizations inflate expenses (or undervalue revenue) for programmatic or donation-motivated reasons rather than to dodge disclosure? If so, how would that manifest differently in the data? Articulate and, if possible, test these alternatives (e.g., by examining donation shares or expense ratios).
   - Similarly, could federal or state audit practices induce clustering (e.g., auditors focus on organizations just above \$200K)? If federal audit intensity is constant but states vary, this is a place to revisit the cross-state variation you originally intended to exploit. Provide concrete evidence (even historical audit guidance) that federal audits are not triggered at this threshold, and quantify state-level regulatory thresholds to support the heterogeneity claim.

By addressing these suggestions, the paper would substantially improve its empirical credibility and policy relevance, offering a compelling quantitative estimate of the hidden cost of nonprofit disclosure.
