# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-23T10:45:42.265881

---

 **Review of "The Detection Gap: Reporting Exemptions and Racial Disparities in Mortgage Lending"**

---

### 1. Idea Fidelity

The paper deviates substantially from the original research design outlined in the manifest. The manifest proposed a lender-level difference-in-differences (DiD) exploiting pre-treatment periods (2014–2017) to establish parallel trends, combined with a donut regression discontinuity (RDD) around the 500-origination threshold. The delivered paper instead employs a post-only cross-sectional comparison (2018–2022) with county×year fixed effects, omitting the pre-treatment data entirely. Consequently, the design cannot distinguish whether the documented gaps are caused by the reporting exemption or reflect pre-existing differences between small community banks and larger institutions. The RDD strategy—arguably the cleanest identification leveraging the policy’s deterministic threshold—is absent. While the paper retains the core data source (HMDA) and outcome (denial gaps), the identification strategy has shifted from a credible causal design to a selection-contaminated observational comparison.

---

### 2. Summary

The paper argues that small mortgage lenders exempt from expanded HMDA reporting under EGRRCPA Section 104 exhibit Black–White denial rate gaps that are approximately 2.3 percentage points wider than non-exempt lenders operating in the same county and year (2018–2022). The author interprets this as evidence that public disclosure requirements deter discriminatory lending, with the removal of such requirements creating a "detection gap" that disproportionately harms minority borrowers.

---

### 3. Essential Points

**1. Invalid Causal Identification Due to Absence of Pre-Treatment Data.**  
The paper uses only 2018–2022 data, with treatment beginning in May 2018. Without pre-period data (e.g., 2015–2017), the design cannot establish parallel trends or rule out the possibility that exempt lenders (small community banks with distinct customer bases) always exhibited wider racial denial gaps. The "event study" (Table 4) uses 2018—a partially treated year—as the reference category, rendering the dynamic patterns uninterpretable. The causal claim rests entirely on the untestable assumption that exempt and non-exempt lenders would have exhibited identical denial gaps absent the exemption.

**2. Statistical Fragility and Inconsistent Significance Reporting.**  
The preferred specification (Column 4, Table 2) reports a coefficient of 1.8 percentage points with a standard error of 1.11 ($t = 1.63$, $p \approx 0.10$), which is not statistically significant at the 5% level. This contradicts the abstract’s claim of $p < 0.05$ (which draws from Column 3, a specification lacking controls for applicant income composition). The result attenuates by 60% upon adding controls and fails to maintain significance, suggesting the baseline 2.3pp estimate is confounded by observable differences in applicant pools.

**3. Confounding by Lender Business Model and Selection Bias.**  
Exempt lenders are, by construction, small institutions specializing in relationship lending to established community members. The finding that exempt lenders lower denial rates for both races—but more so for Whites—is consistent with relationship banking favoring in-group members, not with the exemption causing discrimination. The Asian–White placebo test (Table 5, Panel C) shows a significant *negative* coefficient ($-1.19$pp, $p < 0.10$), indicating exempt lenders treat Asian applicants *better* than non-exempt lenders, which undermines the interpretation that the exemption uniquely facilitates discrimination against Black borrowers. Additionally, the 5.7 percentage point reduction in Black application share at exempt lenders indicates severe selection into lender type, biasing the intensive margin estimates via unobservable credit quality differences.

---

### 4. Suggestions

**Implement the DiD Design with Pre-2018 Data.**  
The manifest correctly identified that pre-2017 HMDA data (under the old reporting regime) would enable a proper DiD. Acquire the 2014–2017 HMDA files and estimate:
$$ \text{DenyGap}_{ict} = \beta (\text{Exempt}_i \times \text{Post}_t) + \alpha_i + \alpha_{ct} + \varepsilon_{ict} $$
where $\alpha_i$ absorbs time-invariant lender heterogeneity. This would address whether exempt lenders *increased* their relative denial gaps after 2018, or whether they simply maintained pre-existing disparities.

**Execute the Donut RDD Around the 500-Loan Threshold.**  
The policy creates a sharp threshold at 500 originations. Exclude lenders near the cutoff (e.g., 400–600 loans) and estimate:
$$ \text{DenyGap}_{ict} = f(\text{Loans}_{i,t-1}) + \beta \mathbb{I}[\text{Loans}_{i,t-1} < 500] + \gamma_{ct} + \varepsilon_{ict} $$
This isolates quasi-experimental variation in exemption status, netting out the continuous effect of lender size. Check for bunching below the threshold as a manipulation test. The manifest mentioned this strategy; its omission is a missed opportunity for credible identification.

**Address Inference with Few Treated Clusters.**  
With only 515 lender-county-year observations from exempt lenders spread across 190
