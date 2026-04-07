# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-04-07T21:49:48.536334

---

# Referee Report

**Manuscript:** The Consolidation Tax: How Bank Mergers Widen Racial Mortgage Gaps
**Date:** October 26, 2023

## 1. Idea Fidelity

The paper largely adheres to the core conceptual framework outlined in the Original Idea Manifest, specifically the use of merger-induced branch closures as an instrumental variable to identify causal effects on racial mortgage disparities. The data sources (FDIC SOD, FDIC History, HMDA) match the manifest specifications. However, there are notable deviations in the empirical implementation that weaken the identification strategy relative to the proposal. First, the Manifest proposed **MSA-year fixed effects** to absorb market-wide shocks; the paper implements **state-year fixed effects**, which is a coarser control structure less aligned with local banking market definitions. Second, the Manifest emphasized **tract-level variation** ("geocoded... merged with HMDA... census tract"); the paper aggregates to the **county-year level**, sacrificing within-county precision. Third, while the Manifest highlighted the use of expanded HMDA fields (DTI, LTV, AUS) to decompose gaps into risk-based vs. unexplained components, the empirical strategy relies primarily on aggregate denial rate gaps rather than loan-level controls that would leverage these new fields fully. These deviations move the paper away from the high-precision identification strategy originally envisioned.

## 2. Summary

This paper estimates the causal effect of bank merger-induced branch closures on racial disparities in mortgage lending, finding that closures widen the Black-White denial gap by approximately 1.7 percentage points. Using an instrumental variables approach where merger exposure instruments for branch closures, the author argues that physical branch loss disproportionately harms minority borrowers reliant on relationship-based lending. The results suggest a "consolidation tax" where efficiency gains from mergers come at the expense of equitable credit access.

## 3. Essential Points

1.  **Geographic Aggregation and Fixed Effects:** The shift from the proposed MSA-year fixed effects and tract-level analysis to state-year fixed effects and county-level aggregation significantly weakens the identification strategy. Banking markets are local (MSA or county), not state-level. State fixed effects fail to absorb local economic shocks (e.g., a housing boom in one MSA but not another within the same state) that could correlate with both merger activity and lending outcomes. The paper acknowledges this limitation in Section 3.4 but treats it as secondary; it should be central to the identification discussion. Reverting to MSA-year FE or justifying why state FE is sufficient given the local nature of branch competition is critical.
2.  **Underutilization of HMDA Loan-Level Controls:** The Manifest justified the project based on the 2018 HMDA expansion (DTI, LTV, AUS), promising a decomposition of denial gaps into risk-based and unexplained components. However, the main specification (Table 2) uses aggregate county-level denial gaps without controlling for applicant risk characteristics. This leaves open the possibility that branch closures change the *composition* of applicants (e.g., only higher-risk Black applicants apply after a closure) rather than the treatment of comparable applicants. To claim a causal effect on *disparities* rather than *selection*, the author must utilize the loan-level data to control for DTI, LTV, and credit score proxies.
3.  **Instrument Validity and Merger Endogeneity:** The exclusion restriction relies on the assumption that merger exposure is orthogonal to local lending conditions. While the paper argues mergers are driven by bank-level strategy, mergers are often strategic entries into specific high-growth or consolidating markets. If banks merge to enter markets with specific demographic trajectories (e.g., gentrifying areas), the instrument violates the exclusion restriction. The OLS vs. IV sign reversal (Table 3) is attributed to "gentrification," but this narrative requires stronger evidence. Without ruling out that mergers target specific types of counties (beyond state trends), the causal claim remains vulnerable to selection bias.

## 4. Suggestions

The following recommendations are intended to strengthen the empirical strategy and align the execution more closely with the promising identification framework outlined in the project manifest. These suggestions focus on refining the fixed effects, leveraging the full richness of the HMDA data, and bolstering the validity of the instrumental variable.

**Refining the Fixed Effects and Geographic Unit**
The current use of state-year fixed effects is too broad for a study on local banking competition. A merger in Cook County, Illinois, should not be compared to a merger in a rural Illinois county while absorbing the same state shock. I strongly recommend transitioning to **MSA-year fixed effects**. This aligns with the standard literature on banking competition (e.g., *Nguyen 2019*, *Erel 2011*) and better captures the relevant market structure. If data limitations prevent MSA FE (e.g., non-MSA counties), consider **county fixed effects** combined with year fixed effects, as attempted in Table 4, but address the weak first-stage issue there. You might explore a hybrid approach: state-year FE for the main sample but demonstrating robustness with MSA-year FE on the subsample of metropolitan counties. Additionally, reconsider the **county-level aggregation**. The Manifest promised tract-level variation. Even if the instrument is county-level, the outcome could be measured at the tract level (e.g., tract-level denial rates). This would increase statistical power and allow you to examine heterogeneity based on distance to the closed branch, which is crucial for the "relationship destruction" mechanism.

**Leveraging Loan-Level HMDA Controls**
The 2018 HMDA expansion is the key novelty of this project, yet the main results do not fully exploit it. Currently, you compare raw denial rates. A more compelling strategy would be a loan-level regression where the outcome is denial (0/1) and controls include **DTI, LTV, income, and AUS recommendation**. This would allow you to estimate whether the racial gap widens *conditional on creditworthiness*.
*   *Specific Suggestion:* Estimate a linear probability model at the loan level: $Denial_{ilt} = \beta \cdot Closure_{ct} \times Black_{i} + \gamma X_{i} + \delta_{ct} + \epsilon_{ilt}$, where $X_i$ includes DTI and LTV. If the interaction term remains significant after controlling for $X_i$, you have stronger evidence of disparate treatment rather than compositional selection.
*   *Decomposition:* Use the AUS recommendation variable. If Black applicants are more likely to be denied despite having a "Approve" AUS recommendation in closure-heavy areas, this is direct evidence of human discretion or channel substitution effects overriding algorithmic approval. This directly addresses the "composition vs. treatment" concern raised in Essential Point 2.

**Strengthening the Instrument Validity**
The argument that mergers are orthogonal to local conditions needs more rigorous testing beyond balance tests on observables.
*   *Merger Motivation Controls:* Include controls for county-level economic growth (e.g., house price appreciation, income growth) in the first stage. If merger exposure predicts closures even after controlling for local economic vitality, it strengthens the claim that closures are driven by corporate overlap rather than local performance.
*   *Placebo on Non-Merged Banks:* Construct a placebo test using only loans originated by banks *not* involved in the merger. If the racial gap widens even for non-merged lenders in high-exposure counties, it supports the "competition reduction" channel (fewer competitors allow all lenders to tighten standards). If the effect is only present for the merging bank, it supports the "relationship destruction" channel. Distinguishing these adds significant depth to the mechanism section.
*   *Refinance vs. Purchase:* Consider using home refinance loans as a placebo outcome. Refinance borrowers are existing homeowners with established equity and potentially less reliance on new branch relationships compared to purchase borrowers. If the effect is concentrated in purchase loans, it supports the access channel.

**Clarifying the Mechanism**
The paper posits two mechanisms: relationship destruction and competition reduction. The current heterogeneity analysis (minority share, branch density) is suggestive but not definitive.
*   *Distance Measure:* If you can geocode the closed branches and the applicants (HMDA has tract codes), calculate the distance from each applicant to the nearest closed branch. Interact this distance with the Black indicator. The effect should decay with distance if relationship loss is the driver. This would be a powerful test using the geocoded data promised in the Manifest.
*   *Digital Substitution:* The discussion on digital banking is qualitative. You could test this by interacting closure exposure with county-level broadband access or FinTech lending share. If the closure effect is muted in high-broadband areas, it suggests digital substitution is possible but unevenly distributed.

**Addressing Sample Selection and Generalizability**
The sample is restricted to 20 states (70% of originations). While practical, this raises generalizability concerns.
*   *Representativeness:* Provide a table comparing the 20 states to the excluded 30 states on key metrics (branch density, racial composition, merger activity). If the excluded states are systematically different (e.g., more rural, less concentrated), note this as a boundary condition for the findings.
*   *Time Period:* The sample ends in 2023. Given the lag in HMDA data availability, this is understandable, but acknowledge the potential impact of the 2020-2021 interest rate shock. Did mergers accelerate during the low-rate period? Adding year-specific merger activity controls might help isolate the closure effect from the rate environment.

**Presentation and Clarity**
*   *Table 1 (Summary Stats):* Ensure the "N" row clearly distinguishes between county-year observations and loan-level observations if you switch specifications. Currently, it implies county-year only.
*   *Event Study (Figure 4):* The confidence intervals widen significantly in later periods. Consider collapsing periods $t+3$ and $t+4$ to improve precision in the visual presentation.
*   *Terminology:* The term "Consolidation Tax" is evocative but ensure it is clearly defined economically. Is it a deadweight loss or a transfer? The paper implies a transfer (from borrowers to bank efficiency), but clarify this in the welfare discussion.

By implementing these suggestions, particularly the shift to MSA-level fixed effects and the utilization of loan-level risk controls, the paper would move from a suggestive correlation to a robust causal estimate that fully capitalizes on the unique data opportunities outlined in the original proposal. The core idea is strong; the execution needs to match the precision of the identification strategy promised in the manifest.
