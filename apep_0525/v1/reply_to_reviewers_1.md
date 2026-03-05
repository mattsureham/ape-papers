# Reply to Reviewers — Round 1

## GPT-5.2 (MAJOR REVISION)

### Must-Fix Issues

**1. Reframe cross-sectional RDD as descriptive, not causal**
DONE. The Results section now explicitly labels the cross-sectional analysis as "Descriptive Boundary Discontinuity" and states it should be read as descriptive geography given placebo/balance failures. Prediction 1 in the framework is reframed as descriptive. The welfare section no longer uses the cross-sectional estimate for elasticity calculation.

**2. DDD parallel pre-trends test**
DONE. Added a DDD event study (Figure 8) with year × HighTaxSide × HighIncome interactions, controlling for year × income-group effects. Pre-period coefficients (2013-2015) are small and individually insignificant. The joint pre-trends test rejects at p=0.005, driven by a 2016 outlier. Post-period effects emerge in 2020-2021 (COVID overlap), not immediately at 2018. Transparently reported.

**3. Fix inference: few-cluster problem**
DONE. Added border-pair clustered SEs (Table 9). The DDD triple-interaction has SE=0.0054 (vs. 0.0019 under ZIP clustering), p=0.27 under pair clustering. Reported honestly in text, abstract, and discussion.

**4. Duplicated ZIPs across border segments**
Acknowledged in limitations. The paper notes that ZIP codes can appear in multiple segments and that this creates dependence beyond ZIP clustering. The border-pair clustering partially addresses this by accounting for within-pair correlation.

**5. Weighting by total returns**
Acknowledged as a limitation. The paper discusses heteroskedasticity from varying denominators but does not implement weighted regressions. This is noted as a direction for future work.

### High-Value Improvements

**6. Model SALT exposure continuously**
Discussed in new "SALT exposure heterogeneity" paragraph in Threats section. IRS SOI data does not report itemized deductions at ZIP level, limiting ability to construct continuous exposure. Acknowledged as a limitation that biases DDD toward zero.

**7. Restrict to integrated metro areas**
The metro-only subsample was already included. Additional restriction to single MSAs is noted as valuable for future work.

**8. Disentangle migration from income growth**
Acknowledged in limitations. ZIP-level data cannot separate migration from income growth/reporting changes. Noted as a key motivation for future work with individual panel data.

---

## Grok-4.1-Fast (MAJOR REVISION)

### Must-Fix Issues

**1. Formal parallel trends test for DDD**
DONE. Added DDD event study with formal Wald test (F=3.4, p=0.005 on 5 d.f.). Transparently report that test rejects, discuss which years drive rejection.

**2. Address covariate imbalance in DDD**
Discussed in text. Population imbalance at border motivates DDD over cross-sectional RDD. Weighting by total returns noted as improvement for future work.

**3. Density test per income**
Not implemented — requires individual-level binned returns which the IRS SOI ZIP data does not provide at that granularity.

### High-Value Improvements

**1. Falsification on non-tax borders**
Not implemented — all 8 selected borders have >2pp tax differentials by design. Finding similar-tax border pairs is a valuable extension but requires expanding the geographic scope.

**2. Refine heterogeneity**
Added pooled-excluding-NJ-PA analysis (Table 8) showing sign reversal, confirming NJ-PA drives pooled result.

**3. Longer post-SALT + COVID placebo**
Data ends at 2021; extending requires future IRS SOI releases. DDD event study now transparently shows COVID-period timing.

---

## Gemini-3-Flash (MINOR REVISION)

### Must-Fix

**1. Report pooled excluding NJ-PA**
DONE. Table 8 reports pooled nonparametric RDD with and without NJ-PA. Sign reverses from +0.087 to -0.031. Discussed in new "Sensitivity to NJ-PA Border" subsection.

**2. Event-study DDD**
DONE. Figure 8 and accompanying text present the triple-difference event study.

### High-Value Improvements

**1. Property tax discussion**
Added in SALT exposure heterogeneity paragraph — property tax levels affect SALT cap incidence, and this heterogeneity is unobserved in SOI data.

**2. Suppression bias clarification**
Already addressed in robustness section and Table 7.
