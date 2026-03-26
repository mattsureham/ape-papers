# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-26T23:57:57.713501

---

**Idea Fidelity**

The paper generally follows the original manifest: it focuses on the potential mortgage-market wedge created by the federal exclusion of cannabis-derived income from FHA/VA/USDA mortgages after state legalization, uses HMDA data, and centers the analysis on FHA share (with placebo and substitution tests implied). However, several planned elements are missing or underdeveloped. Most notably, the paper never implements the border/county-level analysis, the proposed substitution test is only indirectly reported (no county-level heterogeneity or cannabis employment interaction), and the “welfare” calculations (interest rate spreads, borrower cost of the “penalty”) promised in the manifest do not appear. The narrative highlights the methodological lesson (TWFE vs. CS), which was not in the manifest’s core research question. While the central idea—legalization affecting FHA access—is pursued, the empirical implementation veers toward a null-with-methodology lesson rather than fully testing the channel and mechanisms the manifest emphasized. 

**Summary**

This paper examines whether the federal prohibition on counting cannabis-derived income for FHA/VA/USDA mortgages, in the face of staggered state-level recreational legalization, causes a decline in FHA market share using state-year HMDA data. A conventional TWFE DiD suggests a 1pp drop, but a Callaway–Sant’Anna estimator that allows for heterogeneous cohort effects yields a null average treatment effect with clean pre-trends and a convincing VA placebo. The main contribution becomes both an upper bound on the policy effect and a cautionary example about relying on TWFE in staggered DiD settings.

**Essential Points**

1. **Mechanism and Scale**: The manuscript falls short of convincingly tying legalization to FHA share through the proposed mechanism. While the institutional story is clear, the paper never shows that cannabis workers are proportionally represented among FHA applicants or that such applicants are actually blocked from FHA access post-legalization. Without exploiting finer variation (e.g., high vs. low cannabis-employment counties or low-income borrower segments) or documentary evidence that FHA application incomes meaningfully shifted, the null may simply reflect a weak first-stage rather than an absence of the effect. I recommend either (i) implementing the originally intended heterogeneity tests (e.g., triple difference with QCEW cannabis employment or borrower income bins) or (ii) collecting data showing the expected composition change after legalization. For now, the link between legalization and FHA share remains theoretical.

2. **Interpretation of Null and TWFE Comparison**: The paper emphasizes that the TWFE result is misleading, primarily because early cohorts (Illinois) have positive ATT while later cohorts are null/negative. However, the analysis stops short of explaining *why* that heterogeneity arises. Illinois is singled out as coinciding with housing reforms, but this is speculative. Without additional diagnostics (e.g., placebo year tests, examining other policies in Illinois, or exploiting within-state variation) the argument risks circularity: “TWFE is wrong because the cohort effects are heterogeneous,” but we still do not know if those cohort effects reflect causal treatment or residual confounding. The authors should elaborate why the cohort heterogeneity is not itself policy-related or due to timing of workforce build-out, and possibly show cohort-specific leads/lags to support the causal interpretation.

3. **Data and Inference Limitations**: The paper aggregates to the state-year level and reports extraordinarily precise TWFE estimates (p<0.05), yet the CS estimator from the same data is essentially zero with a large standard error. This raises concerns about statistical power and measurement error. Aggregating to state-year cells likely masks any small but economically meaningful effects. The authors should explore whether more granular data (county panel, borrower income strata, or monthly HMDA files) could raise power or reveal localized effects, or otherwise provide formal power calculations showing that even a small effect would be detectable if it existed. Without this, arguing that “the effect is too small to detect” is speculative, and the paper risks overstating the lesson about TWFE.

**Suggestions**

- **Mechanism heterogeneity**: As hinted in the manifest, consider a triple-difference design: interact legalization with county-level cannabis employment shares (QCEW NAICS 111998/424590/453998). If the exclusion matters, legalizing should reduce FHA share more in counties with more cannabis workers. Similarly, examine whether effects concentrate among lower-income borrowers or in later years when the cannabis workforce matures. This would help distinguish a true null from a power issue and directly test the channel.

- **Borrower-level analysis**: HMDA reports borrower income categories and race/ethnicity. Even if FHA borrowers do not explicitly report “cannabis income,” one could examine whether legalization changes the income distribution of FHA applicants or the share of FHA borrowers in income categories associated with cannabis workers (e.g., $40–60k). This would provide indirect evidence about who is affected.

- **Temporal dynamics**: The paper states that licensed sales and workforce growth lag legalization by 1–2 years. Presenting event-study plots of FHA share relative to legalization (with leads and lags) within cohorts would help gauge whether effects appear only after the workforce grows. Also, examine whether the cohort heterogeneity corresponds to the timing of retail rollouts or workforce maturation. If the absence of effects is simply due to timing (too early in the lifecycle), that would set expectations for future research.

- **Supplementary outcomes**: The manifest proposed interest rate spreads and denial rates as secondary outcomes. Even if the main effect is null, analyzing whether denial rates change or whether conventional-FHA spread shrinks could reveal subtle credit impacts (e.g., lenders steering applicants toward conventional despite similar rates). Including these would enrich the story and potentially yield detectable effects even if FHA share is stable.

- **Discuss statistical power**: Provide a power calculation or minimal detectable effect using the state-year panel, acknowledging that cannabis workers are a small share of the workforce. This would clarify whether the null is informative. If the minimal detectible difference is larger than the theoretical maximum impact, then the null is expected; otherwise, the paper should qualify the strength of the null.

- **Broaden methodological discussion**: The paper rightly emphasizes the TWFE vs. CS divergence, but it should be framed more carefully. Specifically, clarify that TWFE is not “wrong” per se but can produce misleading averages when cohort effects differ; the CS estimator still requires assumptions (parallel trends for each group). If the goal is a methodological cautionary tale, include diagnostics such as the Goodman-Bacon decomposition or treatment effect plots by cohort-year to make the lesson concrete.

- **Clarify scope of data and controls**: The summary statistics table has odd entries (mean income shown as zero). Ensure all reported statistics are informative. Also, state explicitly whether the panel includes DC and whether always-treated states are entirely excluded or only from the CS estimation. For robustness, consider including these always-treated states in TWFE but clarify their role.

- **Transparency about autonomy**: The paper notes it was autonomously generated. To increase credibility, provide more detail in the appendix about data processing steps, code validation, and any manual corrections. If possible, share reproducible scripts (even in supplementary material) so referees can verify the findings.

In its current form, the paper identifies an interesting policy question and presents a clear institutional story, but it needs deeper empirical follow-through on the mechanism, additional robustness checks, and more careful interpretation of the null and methodological lesson to make a convincing contribution.
