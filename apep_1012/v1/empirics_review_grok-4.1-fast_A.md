# V1 Empirics Check — x-ai/grok-4.1-fast (Variant A)

**Model:** x-ai/grok-4.1-fast
**Variant:** A
**Date:** 2026-03-26T21:15:56.910062

---

### 1. Idea Fidelity
The paper faithfully pursues the original idea manifest. It employs staggered private-employer BTB adoptions across the 16 specified states (2010-2020) as the treatment variation, using the QWI county×race×quarter panel (rh/ns stratification) for outcomes including log employment (Emp), all hires (HirA), new hires (HirN), and full-quarter employment (EmpS). The core identification is a triple-difference (treated state × post × Black), with pre-trend tests via event study, leave-one-out robustness, and a public-sector placebo, directly testing for widening of the Black-White employment gap via statistical discrimination. Minor deviations include primary reliance on TWFE rather than Callaway-Sant'Anna (CS) as the lead estimator (CS/Sun-Abraham appears as a supplement) and analysis of log levels (equivalent to log ratios for small effects) rather than explicit ratios. The hiring-flow decomposition and QWI novelty are central, with no missing key elements.

### 2. Summary
This paper examines whether staggered state-level Ban-the-Box (BTB) laws, which delay private-employer criminal history inquiries, widened the Black-White employment gap through statistical discrimination, using a triple-difference design on high-frequency QWI county×race administrative data. It finds precisely estimated near-null effects on log Black relative to White employment (-0.35 log points, SE=0.23), with somewhat larger (but still insignificant at 5%) effects on hiring flows, ruling out economically large adverse impacts. The QWI panel enables novel decomposition of hiring versus incumbent margins and demonstrates the dataset's value for race-disaggregated policy evaluation.

### 3. Essential Points
1. **Lead Estimator and Staggered Timing Bias**: The main results rely on TWFE triple-difference (\cref{eq:main}), which is inappropriate for staggered adoption due to negative weighting of late-treated units against early-treated (Goodman-Bacon 2021). The Sun-Abraham/CS supplement in \cref{tab:csdid} is incomplete (placeholders only) and relegated to a subsection, with vague reporting (e.g., "implied triple-difference of -0.005"). Promote CS-DiD to the lead estimator, fully populate all tables/figures with group-time ATTs, event-study aggregations, and cohort-specific estimates. Report dynamic triple-differences (e.g., Black minus White ATTs). Without this, results are not credible for publication.

2. **Parallel Trends Evidence**: Claims of "clean pre-trends" are asserted (e.g., "zero of eleven pre-treatment event-study coefficients...significant") but not shown: no event-study plot or table appears in the main text, only a textual summary in the appendix. Provide full event-study figures/tables for the triple-difference (Black-White gap) in TWFE and CS-DiD, with formal pre-trend tests (e.g., joint F-test). Clarify if trends hold conditionally on controls; if violated, the design fails.

3. **Control Group Validity**: Never-treated states (no private BTB) are appropriate, but 21 have public-sector BTB, potentially contaminating controls if public-sector reforms spill over (e.g., via norms). The public placebo is promising but uses a pseudo-2016 treatment excluding private-BTB states—re-run as a clean never-treated vs. public-only comparison. Tabulate state characteristics (e.g., Black pop share, crime rates, pre-trends) to assess balance.

These must be addressed; failure warrants rejection.

### 4. Suggestions
**Data and Sample**: Expand \cref{tab:summary} to include pre- vs. post-treatment means by treatment arm/race, and Black share of county employment (to contextualize ratio variation). Report suppression rates for Black cells (QWI disclosure avoidance could bias toward larger counties). Consider weighting by county Black employment to emphasize economically meaningful cells, and test sensitivity to the 80% non-suppression rule (e.g., drop at 90%). The 2005-2023 window is strong (ample pre-period), but extend pre-trends to 2000Q1 if QWI allows, matching the manifest.

**Empirical Implementation**: For CS-DiD, use Callaway-Sant'Anna (2021) with never-treated controls, aggregating via simple or employment-weighted average ATT (report both). Include Sun-Abraham event-study paths for Black and White separately, differencing to visualize the triple-diff dynamic. Cluster SEs at state×race in CS-DiD; supplement TWFE with Hainmueller-Xu-Kim (2024) robust diagnostics. In \cref{tab:robustness}, fix "Wild cluster bootstrap p-value: 99.000" (typo?) and add event-time aggregation tests (e.g., Rambachan-Roth 2023 for bounds). Report all CIs explicitly in main tables.

**Mechanisms and Heterogeneity**: The hiring decomposition is a highlight—elevate with a formal test (e.g., HirN vs. EmpS difference, SE via delta method). Pursue suggestive heterogeneity: split by Black population share (as teased), county crime rates (from FBI UCR), or industry exposure (QWI allows 6-digit NAICS; subset private-sector dominated). Test young Black men proxy (e.g., interact with state youth shares). Explore offsets: correlate estimates with state felony rates (Shannon et al. 2017) or incarceration shares.

**Threats and Placebos**: Strengthen concurrent policies: control for state×trend or include leads/lags for minimum wage/Medicaid changes, interacting with Black. Add synthetic controls (Arkhangelsky et al. 2021) at state×race level as robustness. For spillovers, exclude border counties or use county-distance weights.

**Presentation and AER:Insights Fit**: Add 2-3 figures: (i) event-study triple-diff plot, (ii) leave-one-out scatter, (iii) map of treatment timing. Shorten intro/discussion (merge institutional background); move standardized effects (\cref{tab:sde}) to appendix. Title evocative but soften "That Wasn't" to avoid overclaiming nullity. Emphasize contribution: first QWI-race BTB paper, bounds on Doleac-Hansen (2020). Relate more to Agan et al. (2018) audits—why null aggregate despite micro-evidence? Policy takeaway solid but nuance: BTB safe but not transformative.

**Broader Impact**: Manifest pitches QWI as "general-purpose tool"—add appendix application (e.g., EITC racial effects preview) to showcase. Code/repo transparency excellent; ensure replication package includes exact BTB dates, QWI query, and Stata/R code for CS-DiD.

Overall, strong potential: credible data, clean design, policy relevance. With CS-DiD fixes and visuals, suitable for AER:Insights.
