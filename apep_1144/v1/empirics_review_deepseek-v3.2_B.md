# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-30T14:35:04.565381

---

**Referee Report:** *The Patent Payroll Illusion: Examiner Leniency, Patent Grants, and Local Employment*

**1. Idea Fidelity**

The paper largely pursues the core idea from the manifest: it exploits quasi-random examiner assignment to construct a Bartik (shift-share) instrument for local patent grant shocks and estimates effects on county-level employment from the QWI. The key research question—whether patent grants *cause* local employment growth—is faithfully addressed, and the empirical design directly implements the proposed identification strategy.

However, the paper **deviates in one critical and potentially fatal way** from the original data plan, which undermines the entire causal argument. The manifest implied using the **full universe of patent applications** to construct pre-determined county technology shares. The paper reveals (Sec. 3.1) that it uses only **granted patents** from PatentsView for this purpose because application-level inventor geography is unavailable. This is not a minor measurement issue. The shares \( s_{ca} \) are now a function of past examiner leniency during the base period (2001–2003). If examiner leniency is persistent (as the literature suggests), these shares are correlated with the instrument’s shocks \( z_{at} \), violating the exogeneity requirement of the Bartik framework. The authors’ claim that “the Bartik identification framework… requires exogeneity of the shocks, not of the shares” is a misreading. While the shock-based approach of Borusyak et al. (2022) emphasizes shock exogeneity, it still requires that shares are *predetermined and uncorrelated with the shocks*. Here, shares are endogenous to the very shock-generating process. This flaw likely invalidates the exclusion restriction, as the instrument could affect outcomes through channels other than current patent grants (e.g., through historical patent stocks built by past leniency). The paper’s core causal claim is therefore built on unsound foundations.

**2. Summary**

This paper tests the causal effect of patent grants on local employment using a Bartik instrument that combines pre-determined county technology shares with quasi-random examiner leniency shocks. It finds a positive OLS correlation but a precisely estimated null effect using IV, dubbing this the “patent payroll illusion.” The authors conclude that the marginal patent grant does not create local jobs, challenging a common policy narrative.

**3. Essential Points**

The following critical issues must be resolved. The first is so severe that if it cannot be fixed, the paper should be rejected.

1.  **Endogenous Technology Shares Due to Grant-Based Geography:** As noted, the technology shares \( s_{ca} \) are constructed from *granted* patents (2001–2003), not applications. This introduces a direct correlation between the shares and the examiner leniency shocks \( z_{at} \), especially if leniency is persistent across examiners over time. Consequently, the Bartik instrument \( \sum_a s_{ca} z_{at} \) is likely correlated with unobserved county characteristics that also affect employment trends (e.g., past innovative capacity, historical examiner luck). This violates the exclusion restriction. The authors must either:
    *   Obtain application-level inventor geography (a significant but perhaps feasible task using USPTO filing documents or alternative sources).
    *   Use an earlier pre-period (e.g., 1980s) where examiner leniency shocks are plausibly uncorrelated with later shocks, though this may reduce sample overlap.
    *   Use an alternative, exogenous measure of county technology specialization (e.g., based on non-patent data like employment in tech industries from pre-2001 QWI).
    *   If none of these are possible, the paper must be reframed as a descriptive or methodological caution, not a causal study.

2.  **Weak First Stage and Ambiguous Null:** The first-stage F-statistic of 16.1 is modest for a Bartik design with many fixed effects. While the Anderson-Rubin test supports a null, the confidence intervals are wide. The paper cannot rule out economically meaningful effects (positive or negative). The authors should:
    *   Report the effective F-statistic (Montiel Olea & Pflueger, 2013) for robust inference.
    *   Conduct a power analysis or compute the minimum detectable effect (MDE) given the first-stage strength and sample size. This contextualizes the null finding.
    *   Consider aggregating to the state level (as in the original manifest) or using longer differences (e.g., 5-year changes) to strengthen the first stage.

3.  **Incomplete Mechanism and Heterogeneity Analysis:** The paper finds a null effect on employment but a large, marginally significant negative effect on monthly earnings (SDE = -0.38). This puzzling pattern demands exploration. Is it a composition effect (shift to lower-wage jobs)? A reduction in hours? The authors must:
    *   Analyze earnings per worker (or similar) to separate wage from hours/composition changes.
    *   Examine other QWI margins (e.g., job creation/destruction rates, employment by wage quartile, worker age/education) as promised in the manifest. The current sector split is too coarse.
    *   Address multiple testing: apply a correction (e.g., Bonferroni) when interpreting significance across outcomes.

**4. Suggestions**

*   **Clarify the Geographic Link:** The paper assigns patents to the first inventor’s county. Discuss whether this is the locus of economic impact. Firms may hire elsewhere. A robustness check using commuting zones or MSAs could alleviate this concern.

*   **Deepen Heterogeneity Analysis:** The original idea highlighted heterogeneity by education, firm size (small entity), and detailed industry. The current paper only splits into “exposed” and “local service” sectors. Exploit QWI’s demographic breaks (sex/age/education) and patent characteristics (small entity, university-assigned) to answer *who* might benefit or lose. This is a major missed opportunity.

*   **Improve Instrument Presentation:**
    *   Detail the construction of \( z_{at} \): how many examiners per art-unit-year? Show distribution of shocks.
    *   Visualize the Bartik instrument: a map across counties and a time-series plot for select counties would illustrate variation.
    *   Test the “no dominant share” assumption formally (Goldsmith-Pinkham et al., 2020) and report the Herfindahl index of shares.

*   **Strengthen Robustness Checks:**
    *   Test for pre-trends in employment *growth rates*, not just levels at \( t-1 \). An event-study design (aligning on high Bartik shock years) would be more persuasive.
    *   Include time-varying county controls (population, college share) to ensure they don’t absorb the instrument’s variation.
    *   Report results using the “share-exogeneity” approach (Goldsmith-Pinkham et al., 2020) as robustness, testing whether individual technology-share instruments satisfy exclusion.

*   **Refine Narrative and Policy Implications:**
    *   The term “patent payroll illusion” is catchy but potentially overstated. Clarify that the OLS correlation is real; the illusion is its *causal interpretation*.
    *   Discuss the distinction between marginal (examiner-induced) and infra-marginal (breakthrough) patents. The null result applies only to the former.
    *   Acknowledge that employment effects may manifest over longer horizons. Consider longer lags (e.g., 3–5 years) or distributed lag models.

*   **Technical Presentation:**
    *   Fix table formatting (e.g., `\[6pt]` should be `\addlinespace` in booktabs).
    *   Explain the large discrepancy between LIML and 2SLS standard errors in Table 2.
    *   Clarify sample period inconsistencies: abstract says 2004–2012, but text mentions QWI up to 2025.

*   **Address Data Limitations Transparently:** Create a dedicated subsection on limitations, highlighting the grant-based shares issue, the geographic assignment problem, and the potential for spillovers across counties.

**Overall:** The paper addresses a timely question with a clever design, but the endogenous shares flaw is potentially fatal. If the authors can obtain application-level geography or provide a compelling argument for share exogeneity, the paper could become a valuable contribution. The other essential points are serious but addressable. The suggestions, if implemented, would significantly enhance the paper’s rigor and depth
