# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-14T14:09:10.687220

---

# Referee Report

**Paper:** Paying for Diplomas? Performance-Based Funding and the Cream-Skimming Margin in U.S. Higher Education
**Format:** AER: Insights

## 1. Idea Fidelity

The paper largely adheres to the core empirical strategy and research question outlined in the Original Idea Manifest. Both propose using staggered difference-in-differences (Callaway-Sant'Anna) on IPEDS data to evaluate Performance-Based Funding (PBF) 2.0, specifically testing for "cream-skimming" alongside completion effects. However, there are notable deviations from the Manifest's scope and feasibility claims that reduce the breadth of the contribution:

*   **Sample Reduction:** The Manifest feasibility check estimated "~2,000 public institutions per year." The paper restricts the sample to 676 public *four-year* institutions. This excludes the community college sector, where PBF policies are often most aggressive and where at-risk student populations are concentrated. This significantly limits the external validity of the equity claims.
*   **Missing Novelty Elements:** The Manifest highlighted five specific novelty gaps, including field-of-study shifting (CIP codes) and faculty investment mechanisms. The paper drops these analyses entirely. While the cream-skimming result is valuable, the absence of the CIP and faculty analysis removes the ability to rule out alternative mechanisms (e.g., degree dilution vs. enrollment shifting).
*   **Outcome Measures:** The Manifest emphasized testing cream-skimming using "IPEDS race/**income** data." While the Data section mentions linking Student Financial Aid (SFA) data for Pell recipients, the Results section focuses exclusively on race/ethnicity shares. The promised income-based analysis is absent from the tables.

## 2. Summary

This paper estimates the causal effect of Performance-Based Funding (PBF) 2.0 adoption on public four-year universities using institution-level IPEDS data and heterogeneity-robust staggered DiD methods. The authors find a precise null effect on bachelor's degree completions and graduation rates, but detect a statistically significant 1.6 percentage point decline in minority enrollment share, consistent with institutions engaging in cream-skimming rather than improving student success.

## 3. Essential Points

To support the causal claims and ensure the paper meets the standard for publication, the authors must address the following three issues:

1.  **Visualization of Identification (Event Study):** The text states that "pre-treatment event-study coefficients... are centered near zero," but no figure is provided. In staggered DiD designs, particularly with heterogeneous treatment timing, visual evidence of parallel pre-trends is non-negotiable for credibility. The authors must include an event-study plot (coefficients and confidence intervals for leads and lags) for the main outcomes (completions and minority share). Without this, the claim that the private-institution placebo validates the parallel trends assumption is insufficient, as private and public institutions may respond differently to state-level shocks even if PBF is not the cause.
2.  **Outcome Construction (Shares vs. Levels):** The primary evidence for cream-skimming rests on a decline in *minority enrollment share*. A decline in share can result from a decrease in minority enrollment (numerator) or an increase in non-minority enrollment (denominator). Table 1 shows total log enrollment is null, suggesting the numerator is driving the result, but this should be explicit. The authors must present results for *absolute* enrollment levels by race (e.g., log Black enrollment, log Hispanic enrollment) alongside shares. Furthermore, the Manifest promised an analysis of Pell recipients (income), which is often a more direct measure of "at-risk" status than race. Given the data is linked (per the Data section), the authors should include Pell share or levels to robustly support the equity argument.
3.  **Sample Scope and Selection:** The Manifest feasibility check anticipated ~2,000 public institutions, but the analysis sample includes only 676 four-year institutions. Community colleges (two-year) are major recipients of PBF policies and serve disproportionately high shares of minority and low-income students
