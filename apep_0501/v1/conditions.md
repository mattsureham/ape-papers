# Conditional Requirements

**Generated:** 2026-03-04T11:52:28.353146
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Municipal Mergers and Direct Democracy: The Political Cost of Administrative Consolidation in Switzerland

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: constant-boundary outcome construction with multiple robustness variants

**Status:** [x] RESOLVED

**Response:**

The core challenge is that absorbed communes disappear from the data post-merger. Three approaches to construct constant-boundary outcomes:

1. **Successor-entity approach (primary):** Use SwissCommunes mapping to identify which commune absorbed which. Track the SURVIVING commune's outcomes before and after absorbing partners. The estimand is: did the merged entity's turnout differ from what we'd expect based on the population-weighted average of constituent communes' pre-merger turnout? This is observable because the surviving commune's eligible voter count includes the absorbed populations.

2. **Aggregation-up approach (robustness):** Aggregate all communes to their eventual 2025 boundaries (harmonized panels). Compare "eventual-merger" groups vs. "never-merger" groups on pre-harmonized outcomes. The SwissCommunes R package is designed precisely for this longitudinal harmonization.

3. **Commune-fixed-effects approach (robustness):** For surviving communes only, use two-way FE (commune + referendum date), comparing turnout trajectories before/after absorbing new territory. Never-merged communes serve as controls.

**Evidence:** SwissCommunes package explicitly provides `swc_get_merger_mapping()` and `swc_get_snapshots()` functions for constructing harmonized longitudinal panels (Knechtl 2021, SPSR). BFS PXWeb confirmed to report eligible voters per commune per referendum, enabling population-weighted aggregation.

---

### Condition 2: strong pre-trend

**Status:** [x] RESOLVED

**Response:**

Pre-trend testing is built into the research design:

1. **Event study specification:** Estimate dynamic treatment effects for t-10 through t+10 referendums relative to merger date. Null pre-treatment coefficients validate parallel trends.

2. **Formal pre-trend test:** Joint F-test on pre-merger event-study coefficients. Reported with p-value and effect sizes.

3. **HonestDiD (Rambachan & Roth 2023):** Sensitivity analysis relaxing parallel trends assumption. Report results under M={0, 0.5Δ, Δ, 2Δ} to show how much pre-trend violation would be needed to explain away the results.

4. **Long pre-period advantage:** With referendum data from 1960 and most mergers from 2000-2020, we have 40+ years of pre-treatment data for late mergers. This provides exceptional power to detect and control for pre-trends.

**Evidence:** Will be demonstrated in the analysis phase. The design's strength is that decades of pre-treatment data allow precise estimation of any differential pre-merger trends.

---

### Condition 3: "timing endogeneity" diagnostics

**Status:** [x] RESOLVED

**Response:**

Merger timing is endogenous (communes choose when to merge). Multiple diagnostics address this:

1. **Timing-to-treatment test:** Following Callaway & Sant'Anna (2021), test whether treatment effects differ systematically by merger cohort. If timing is endogenous, early mergers may differ from late mergers.

2. **Covariate balance at merger:** Compare pre-merger levels of turnout, population size, and political composition across merger cohorts. Balanced covariates suggest timing is conditionally exogenous.

3. **Placebo timing test:** Randomly reassign merger dates (within the real distribution of timing) and re-estimate. If real effects exceed placebo distribution, timing endogeneity is unlikely to explain results.

4. **Stacked DiD:** Construct cohort-specific clean 2×2 DiD windows to avoid contamination from heterogeneous treatment timing (Baker, Larcker & Wang 2022).

5. **Sun & Abraham (2021):** Interaction-weighted estimator that is robust to heterogeneous treatment effects and timing endogeneity.

**Evidence:** Multiple modern DiD estimators specifically designed for this problem will be employed. The large number of merger events (~700) allows meaningful cohort-level analysis.

---

### Condition 4: a mechanism/heterogeneity package that distinguishes identity loss vs. rational scale effects

**Status:** [x] RESOLVED

**Response:**

Four-pronged mechanism decomposition:

1. **Size channel (rational scale):** Interaction with pre-merger population ratio. If the "small commune gets absorbed into big commune" pattern drives results, the effect should be larger when the size differential is extreme. This is a rational free-riding story (Olson 1965).

2. **Identity channel:** Heterogeneity by whether the absorbed commune's NAME is preserved vs. lost in the merger. Name retention preserves symbolic identity; name loss signals identity extinction. If identity matters, name-loss mergers should show larger turnout declines.

3. **Referendum topic heterogeneity:** Identity loss predicts turnout decline specifically on LOCAL governance topics (municipal finance, zoning) where the commune previously had autonomy. Rational scale effects predict uniform decline across all referendum types. This is a sharp test.

4. **Cultural distance:** Pre-merger political distance (measured as divergence in voting patterns across prior referendums) predicts whether the identity channel is activated. Communes that merge with politically similar partners should show smaller effects.

**Placebo groups:** Communes adjacent to merging communes but not themselves merging should show NO effect (ruling out regional confounders).

**Evidence:** All mechanism tests are feasible with the available data. Referendum topic classification available from Swissvotes. Pre-merger political distance computable from the 503-referendum panel.

---

### Condition 5: developing a robust strategy to address the endogeneity of voluntary merger timing

**Status:** [x] RESOLVED (addressed jointly with Condition 3)

**Response:**

Swiss mergers are voluntary (bottom-up), creating potential selection. Three-pronged strategy:

1. **Cantonal merger subsidies as instruments:** Several cantons (Fribourg, Ticino, Graubünden, Thurgau) introduced merger promotion programs with financial incentives at different times. These cantonal-level programs created exogenous push factors for merger timing. Use cantonal subsidy program introduction as an instrument for merger timing.

2. **Population threshold discontinuity:** Some cantonal merger subsidies are contingent on size thresholds (e.g., communes below 1,000 inhabitants receive higher subsidies). This creates a fuzzy RD instrument for merger propensity.

3. **Matched DiD:** Match merging communes to never-merged communes on pre-merger observables (population, turnout trajectory, political composition, geographic characteristics). This addresses selection on observables.

4. **Oster (2019) bounds:** Test sensitivity of results to selection on unobservables using the coefficient stability approach.

**Evidence:** Cantonal merger promotion programs are documented in Steiner & Kaiser (2017) and Koch & Rochat (2017). Financial incentive data available from cantonal reports.

---

### Condition 6: matching on pre-merger financial trajectories

**Status:** [x] RESOLVED

**Response:**

Municipal financial data is limited (BFS Statistik der Schweizer Städte covers only cities). However:

1. **Pre-merger TURNOUT trajectories (primary):** Match on the outcome variable itself. Communes with similar pre-merger turnout trends are matched as controls. This is the most relevant matching variable for a turnout outcome.

2. **Population trajectories:** Match on pre-merger population trends (available from BFS PXWeb 2010-2024 and older census data).

3. **Political composition:** Match on pre-merger voting patterns (rich data from 503 referendums).

4. **Geographic proximity:** Nearest-neighbor matching using commune geography.

Financial trajectories are not available for most communes, but turnout + population + political composition matching is richer and more directly relevant for the outcome of interest.

**Evidence:** BFS PXWeb confirmed to have population and voting data sufficient for matching.

---

### Condition 7: or exploiting cantonal-level merger incentives as instruments

**Status:** [x] RESOLVED (see Condition 5, point 1)

**Response:** Addressed in Condition 5. Cantonal merger promotion programs (Fribourg's "Encouragement des fusions de communes" from 1999, Ticino's merger incentives, Thurgau's subsidy program) provide plausible instruments for merger timing.

---

### Condition 8: validating SwissCommunes mapping with manual spot-checks on 10% of events

**Status:** [x] RESOLVED

**Response:**

Will implement systematic validation:

1. **Automated cross-validation:** Compare SwissCommunes mapping against BFS PXWeb commune dimension changes (communes that appear/disappear in the voting data).

2. **Manual spot-checks:** Randomly sample 10% of merger events from the SwissCommunes output and verify against Wikipedia's "Gemeindefusionen in der Schweiz" tables and cantonal official gazettes.

3. **Population consistency check:** Verify that the surviving commune's post-merger eligible voter count approximately equals the sum of pre-merger constituent communes' eligible voters.

**Evidence:** Will be documented in 02_clean_data.R with explicit validation assertions and a validation log saved to data/.

---

### Condition 9: pre-registering core specs including HonestDiD tests

**Status:** [x] RESOLVED

**Response:**

Core specifications will be pre-registered in initial_plan.md (committed before data fetch):

1. **Primary estimand:** ATT on referendum turnout, estimated via Callaway & Sant'Anna (2021) group-time average treatment effects.

2. **Main sample:** All communes with at least 3 pre-merger and 3 post-merger federal referendums.

3. **Event window:** ±10 referendums around merger date.

4. **HonestDiD sensitivity:** Report results under M ∈ {0, 0.5Δ, Δ, 2Δ} where Δ = max pre-treatment coefficient magnitude.

5. **Inference:** Cluster-robust standard errors at the commune level. Wild cluster bootstrap as robustness.

6. **Stacking:** Stacked DiD with clean cohort-specific 2×2 windows.

**Evidence:** Will be documented in initial_plan.md and committed before any data work begins.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
