# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-03-23T11:14:27.569759

---

**Referee Report – “Building Around the Ban: Supply Restrictions and the Elusive Conversion of Vacation Housing in Switzerland”**  

_AER: Insights (short empirical paper)_  

---  

### 1. Idea Fidelity  

The manuscript follows the original research plan outlined in the idea manifest:

* **Policy question** – the paper asks whether the 2012 Swiss Second‑Home Initiative (a sharp 20 % second‑home share threshold) achieved its stated objective of converting vacation housing into permanent residences.  
* **Data** – it uses the federal housing inventory (ZWG) released semi‑annually from 2017 to 2025 for all 2 121 municipalities, exactly as proposed.  
* **Identification** – a sharp regression‑discontinuity design (RDD) at the 20 % cutoff is implemented, with the same bandwidth‑selection (CCT‑optimal), balance checks, and placebo cut‑offs reported in the manifest.  
* **Mechanism tests** – the paper examines primary‑home share, secondary‑home share, and total dwelling‑stock growth, matching the “conversion” focus of the original idea.  

Thus, the authors have largely stayed true to the proposed design and data set. The only noticeable deviation is the treatment timing: the manifest emphasized the 2016 implementation of the ZWG, whereas the paper treats the ban as if it were fully binding from the moment of the 2012 referendum. This discrepancy creates a small but important identification issue (see Essential Point 1).  

---  

### 2. Summary  

The paper exploits the sharp 20 % second‑home share cutoff to estimate the causal impact of Switzerland’s ban on new second‑home construction. Using a municipal‑level panel of the federal housing inventory (2017‑2025) it finds that the ban does **not** significantly increase the primary‑home share of dwellings at the margin (point estimate ≈ +1.6 pp, p = 0.21). However, it does raise total dwelling‑stock growth by about 3.6 % relative to comparable municipalities (p ≈ 0.04), suggesting a substitution channel in which developers build more primary residences rather than converting existing vacation homes.  

---  

### 3. Essential Points  

Below are the three most serious issues that must be resolved before the paper can be accepted. If they cannot be addressed satisfactorily, the manuscript should be rejected.  

| # | Issue | Why it matters | What is needed |
|---|-------|----------------|----------------|
| **1** | **Treatment timing and definition of the running variable** | The policy became legally enforceable only on **1 January 2016** (after the ZWG entered into force). The manuscript treats the ban as if it were effective immediately after the 2012 referendum, yet the running variable (baseline second‑home share) is measured in 2017‑2018, **after** the law is already in force. This raises two problems: (i) the “treatment” may already be endogenous to the 2017‑2018 share, and (ii) municipalities could have adjusted their share **before** the observed baseline, violating the continuity assumption. | – Clarify the exact treatment date used in the RDD. <br>– Re‑estimate the RDD using the **pre‑policy** second‑home share (e.g., the 2010 or 2011 inventory, if available) as the running variable, or alternatively construct a *pre‑post* design that treats 2016 as the cutoff for the panel RDD. <br>– Provide a robustness check that shows results are unchanged when the running variable is measured **one year before** the ban becomes binding. |
| **2** | **Interpretation of the “null” on composition given denominator changes** | The primary‑home share is a *ratio* (primary homes / total homes). An increase in total dwelling stock (the second outcome) may mechanically dilute the share‑change estimate, even if many new primary homes are built. Consequently, the null on composition could be a measurement artefact rather than evidence of policy failure. | – Re‑run the main specification using **levels** (e.g., number of primary dwellings) or **log‑differences** rather than percentages, and report the corresponding effect size. <br>– Conduct a decomposition (e.g., Oaxaca‑Blinder) to separate the contribution of (i) new primary homes, (ii) new secondary homes, and (iii) changes in the denominator. <br>– Discuss whether the observed 3.6 % increase in total stock is sufficient to “mask” a substantive conversion of vacation units. |
| **3** | **Dynamic effects and potential attenuation after the 2024 relaxation** | The dynamic panel RDD shows statistically significant positive effects on primary‑home share from 2019‑2024, which then fade by 2025. The manuscript attributes this solely to the 2024 partial relaxation, but provides no formal test of a *policy‑change* interaction. Moreover, the early significant effects raise the spectre of *multiple‑testing* and of *pre‑trend* exploitation. | – Estimate a **difference‑in‑differences‑in‑RDD** that explicitly allows for a post‑relaxation break‑point (e.g., interaction with a post‑Oct 2024 dummy). <br>– Apply a **Bonferroni / Holm** correction or adjust confidence intervals for the multiple waves to verify that the early‑wave significance is not a false positive. <br>– Present a visual inspection (e.g., local polynomial plots) of the treatment effect trajectory over time, with confidence bands, to substantiate the narrative. |

If any of these points cannot be remedied, the paper’s central claim—that the ban fails to convert vacation housing—remains empirically unsubstantiated.  

---  

### 4. Suggestions  

The following recommendations are not essential for the paper’s acceptance but would markedly improve its clarity, credibility, and relevance.  

1. **Expanded Robustness Suite**  
   * **Alternative kernels & higher‑order polynomials** – present results for Gaussian, Epanechnikov kernels and quadratic/cubic specifications, not only the triangular‑linear case.  
   * **Donut‑hole widths** – test several exclusion windows (0.2, 0.5, 1.0 pp) to ensure that any “bunching” is truly absent.  
   * **Placebo outcomes** – report RDD estimates for outcomes that should be unaffected by the policy (e.g., number of schools, road length) to further demonstrate specificity.  

2. **Spillover Checks**  
   * The ban may affect **neighboring municipalities** (e.g., developers shift projects just across the 20 % line). Include a spatial lag of the treatment indicator or a “buffer” analysis that excludes municipalities within a certain distance of a treated unit.  

3. **Power Calculations**  
   * With an optimal bandwidth of 6.93 pp the effective sample is 588 observations. Provide a post‑hoc power analysis to show whether the study is adequately powered to detect a realistic composition effect (e.g., 2 pp). This helps readers interpret the non‑significant primary‑home share result.  

4. **Heterogeneity Exploration**  
   * **Alpine vs. non‑Alpine** – the effect may differ in high‑tourism cantons (Graubünden, Valais). Estimate separate RDDs for alpine and non‑alpine municipalities.  
   * **Size of municipality** – larger towns might face tighter land constraints, altering substitution patterns.  

5. **Policy‑relevant Counterfactuals**  
   * Discuss how the observed substitution effect would have unfolded in the **absence** of any regulation (e.g., using a synthetic control of municipalities just below 20 % but with similar trends).  
   * Relate the findings to **vacancy‑tax** or **occupancy‑requirement** policies that are being considered in other jurisdictions.  

6. **Presentation Improvements**  
   * **Figures** – include RDD plots (scatter + fitted line) for the three outcomes, and a time‑series plot of the dynamic treatment effects with confidence bands.  
   * **Table clarity** – in Table 1, label “Baseline second‑home share” as “2017 share” (or the year used) and note any imputation. In Table 3, indicate the exact bandwidth in percentage points for each column.  
   * **Notation** – the estimating equation (1) mixes a binary treatment with a continuous interaction term; consider writing it as a standard RDD with a treatment indicator and a running‑variable polynomial term for readability.  

7. **Discussion of External Validity**  
   * Highlight how the Swiss institutional context (municipal autonomy, strong cadastral data) may limit the transferability of the results to other countries with different land‑use regimes.  

8. **Citation Updates**  
   * Incorporate recent literature on **short‑term rental regulation** (e.g., Gurran et al., 2023; Lee & Cheng, 2024) that explicitly examines *conversion* as an outcome, to position the contribution more clearly.  

9. **Software & Replicability**  
   * Provide a public replication package (e.g., on the AER Data Archive) that includes the data‑download script, R/ Stata code for bandwidth selection, and the full RDD estimation pipeline.  

10. **Clarify the “Construction Substitution” Mechanism**  
    * The paper speculates that developers switched to primary‑home construction. If possible, supplement the analysis with **building‑permit data** (type of permit, construction dates) to directly verify this channel. Even a descriptive appendix would strengthen the narrative.  

---  

**Overall Assessment**  

The manuscript tackles an important and under‑examined policy question with a clean quasi‑experimental design and a novel data set. The empirical strategy is broadly appropriate, and the paper is well‑written. However, the treatment timing/definition and the interpretation of the primary‑home share outcome raise serious concerns about causal identification and the validity of the main “null” claim. Addressing the three essential points outlined above is a prerequisite for acceptance. If these revisions are made, the paper will make a valuable contribution to the literature on housing‑supply regulation and the efficacy of quantity‑based policy tools.  

---  



*Referee*  
AER Insights – 2026*
