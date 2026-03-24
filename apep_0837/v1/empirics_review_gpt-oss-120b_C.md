# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-23T16:06:26.725023

---

**Review of “The Disconnect Illusion: France's Right‑to‑Disconnect Law – Did Not Reduce Overwork”**  

---

### 1. Idea Fidelity  

The manuscript follows the original research plan closely. It uses the Eurostat Labour Force Survey (lfsa_qoe_3a2) to construct a triple‑difference (DDD) estimator that exploits (i) the French “right‑to‑disconnect” (R2D) law, (ii) a high‑ vs. low‑connectivity occupational classification, and (iii) the pre‑/post‑2017 timing. All elements of the manifest – the identification strategy, the set of control countries, the exclusion of Spain, Portugal, Belgium, and Italy, and the focus on long‑hours (>48 h/week) and usual weekly hours – are present.  

The paper does **not** discuss two items that appeared in the manifest:  

* **Permutation‐test details** – the manifest mentions “permutation $p = 0.786$” but the main text only reports the p‑value without describing the number of draws, the exact randomization scheme, or robustness to alternative seed choices.  
* **Medium‑connectivity placebo** – the manifest listed ISCO 5 as a “medium‑connectivity placebo group”. The paper includes such a test (Table 5, Panel C) but treats it as a robustness rather than a pre‑registered placebo, and the interpretation is somewhat cursory.  

Overall, the paper stays faithful to the idea, but a few promised methodological clarifications are missing.

---

### 2. Summary  

The article provides the first causal evaluation of France’s 2017 right‑to‑disconnect law by exploiting a triple‑difference design that compares high‑connectivity occupations to low‑connectivity occupations in France versus eight EU control countries. Using Eurostat aggregate data on the share of workers logging >48 h/week (and a secondary outcome of usual weekly hours) from 2010‑2024, the estimated DDD effect is 0.76 pp (SE = 0.79, p = 0.36) for long‑hours and 0.36 h (SE = 0.23, p = 0.16) for usual hours—both statistically indistinguishable from zero. Event‑study and placebo analyses support the null result, leading the author to conclude that a negotiation‑based R2D law had no measurable impact on overwork.

---

### 3. Essential Points  

1. **Parallel‑Trend Assumption for the DDD**  
   *The paper’s identification hinges on the claim that the *difference* between high‑ and low‑connectivity occupations would have evolved similarly in France and the control group absent the law.* The event‑study (Table 4) shows several statistically significant pre‑treatment coefficients (e.g., 2013: –1.06 pp, 2014: –1.76 pp). Although the author argues these are “noisy,” the systematic negative pre‑trend suggests that the occupational gap was already narrowing in France before 2017. This weakens the credibility of the DDD; the standard “no pre‑trend” test should be formalized (e.g., joint F‑test) and, if violated, a more flexible specification (e.g., allowing for differential trends) should be tried.

2. **Inference with Very Few Clusters**  
   *Nine countries (one treated, eight controls) provide a minimal number of clusters for robust cluster‑robust standard errors.* The author acknowledges this and adds permutation inference, but the permutation scheme treats each country as interchangeable, which is appropriate only under the *sharp* null of no treatment effect **and** homogeneous treatment effects across countries. Given the heterogeneity observed (Germany placebo shows a sizable negative effect), the permutation distribution may be misleading. A more reliable approach would be to use wild‑cluster bootstrap‑t (Cameron, Gelbach & Miller, 2008) or to report confidence intervals from the “cluster‑robust t” with *degrees of freedom* adjusted to 8.

3. **Outcome Measurement and Interpretation**  
   The primary outcome—share of workers reporting >48 h/week—is an *aggregate* measure that may be insensitive to changes in after‑hours digital communication that do not affect total weekly hours (e.g., shifting email from 9 pm to 10 pm). The discussion acknowledges this but does not explore alternative data sources (e.g., time‑use surveys, firm‑level email logs) that could capture the specific mechanism the law targets. Consequently, the policy conclusion (“negotiation‑based mandates are toothless”) may be overstated given the chosen outcome.

*If any of these three issues cannot be adequately addressed, the paper should be **rejected** for insufficient identification robustness.*

---

### 4. Suggestions  

Below are concrete, non‑essential recommendations that, if incorporated, would substantially improve the paper’s credibility, clarity, and relevance.

#### a. Strengthening the Parallel‑Trend Check  

1. **Joint Test of Pre‑Treatment Coefficients** – Report an F‑test (or Wald test) that the coefficients for 2010‑2015 are jointly zero. With only nine clusters, present the exact p‑value using the wild‑cluster bootstrap.  
2. **Allow for Differential Pre‑Trends** – Add a specification that includes a linear (or flexible) interaction between *high‑connectivity* and a *country‑specific* time trend. Compare the DDD estimate under this specification to the baseline; if the estimate remains near zero, the result is more robust.  
3. **Visual “Gap‑over‑Time” Plot** – Plot the high‑minus‑low connectivity gap for France and the control average over time, with confidence bands generated by the wild‑cluster bootstrap. A visual inspection will help readers assess whether the gap truly moves in parallel.

#### b. Improved Inference with Few Clusters  

1. **Wild‑Cluster Bootstrap‑t** – Implement Cameron, Gelbach & Miller’s (2008) wild‑cluster bootstrap, reporting both the point estimate and the bootstrap p‑value. This method is specifically designed for settings with <30 clusters.  
2. **Degrees‑of‑Freedom Adjustment** – When clustering, report the effective degrees of freedom (K‑1) and use the *t* distribution with 8 df instead of the normal approximation. This will inflate the standard errors modestly and make the inference more conservative.  
3. **Placebo Distribution Sensitivity** – Vary the number of permutation draws (e.g., 5,000, 10,000) and random seed, and show that the resulting p‑value is stable. Also, test a “restricted” permutation that only swaps treatment status among the eight control countries while holding France fixed, to see whether the distribution changes.

#### c. Expanding Outcome Measures  

1. **Alternative Eurostat Indicators** – Consider using the “percentage of workers who worked at least one overtime hour” (lfsa_qoe_3a1) or “percentage of workers who worked at least 10 h overtime per week”. These may be more sensitive to after‑hours digital work than the >48 h threshold.  
2. **Time‑Use Survey (EU‑SILC)** – The EU Survey on Income and Living Conditions contains a “time spent on the internet for work” variable. Though less granular, it could be aggregated by occupation and year to see whether digital work time declines post‑law.  
3. **Firm‑Level Microdata** – If accessible, supplement the aggregate analysis with a firm‑level panel (e.g., French “DADS” administrative data) that contains overtime hours and potentially flags of after‑hours email usage. Even a small subsample could be used to validate the aggregate findings.  

#### d. Clarifying the Classification of “High‑Connectivity”  

1. **Justify ISCO Mapping** – Provide a short article (or an appendix) that documents the proportion of workers in each ISCO group who use email/messaging regularly (perhaps using the Eurostat “digital skills” module). This will make the occupational categorization more than a plausibility argument.  
2. **Sensitivity to Alternative Cut‑Points** – Re‑run the DDD using a broader high‑connectivity set (e.g., adding ISCO 4 – “Clerical support workers”) or a narrower set (only ISCO 1). If the point estimate remains near zero, the result is robust to classification choices.

#### e. Addressing Potential Spillovers and Contamination  

1. **Regional Variation Within France** – Some French regions may have adopted stronger internal agreements (e.g., Paris vs. rural areas). If the LFS provides region‑level data, a secondary analysis could test whether the effect varies by region, which would help rule out heterogeneous treatment intensities.  
2. **Controlling for Other Labor‑Market Reforms** – While country‑year fixed effects absorb macro shocks, the paper could explicitly list the major French reforms (e.g., Macron’s “Ordonnances” on flexibilisation) and show that they do not alter the high‑/low‑connectivity gap. A robustness test that excludes 2017‑2020 (the period of intense reform activity) would be informative.

#### f. Presentation and Transparency  

1. **Code and Replication Package** – The manuscript mentions a GitHub repository but does not provide a direct link to the analysis script. Adding a reproducibility appendix (or a “do‑file”/R script) would greatly facilitate verification and future extensions.  
2. **Table Formatting** – Table 1 (Descriptive Statistics) could include the number of observations per cell to reassure readers that the balanced panel truly has 945 non‑missing cells. Also, indicating the standard errors in Table 5 (Robustness) would help assess precision.  
3. **Interpretation of Effect Sizes** – The discussion of “moderate positive” standardized effects (Table SDE) can be confusing. Since the coefficient is not statistically different from zero, it may be clearer to simply label the effect as “statistically null; the confidence interval rules out economically meaningful impacts larger than ~2 pp”.

#### g. Policy Implications and Caveats  

1. **Distinguish Between “Negotiation‑Based” and “Enforcement‑Based” Designs** – The paper correctly notes that France’s law lacks enforcement. It would be helpful to explicitly compare the French design to the more prescriptive Portuguese or Belgian reforms (which include penalties) and argue that the null result is specific to the negotiation approach.  
2. **Potential Heterogeneous Effects** – Even if the average effect is zero, certain sub‑groups (e.g., public‑sector managers, large‑firm employees) might have experienced reductions. A brief heterogeneous‑effects exploration (interaction with firm size proxies) would strengthen the policy message.  
3. **External Validity** – Discuss whether the null finding might differ in non‑EU contexts (e.g., the United States, where after‑hours contact is more prevalent). This broadens the relevance for readers interested in the worldwide diffusion of R2D policies.

---

### Concluding Remarks  

The manuscript offers an important first step toward empirically evaluating the right‑to‑disconnect, a policy that is rapidly spreading across jurisdictions. Its use of a triple‑difference design, comprehensive Eurostat data, and careful fixed‑effects specification are commendable. However, the credibility of the causal claim is currently undermined by (i) a pre‑trend that appears to violate the DDD parallel‑trend assumption, (ii) inference that relies on a minimal number of clusters without robust alternatives, and (iii) an outcome that may not capture the specific after‑hours digital behavior the law aims to curb.

Addressing these three essential points—through more flexible trend specifications, improved cluster‑robust inference, and richer outcome measures—will substantially raise the paper’s methodological rigor. The extensive set of suggestions above (data extensions, robustness checks, clearer presentation) should be viewed as a roadmap for strengthening the study rather than a list of mandatory demands. If the authors can convincingly resolve the identification and inference concerns, the paper will make a valuable contribution to the literature on working‑time regulation and digital labor rights.
