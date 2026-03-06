# Reply to Reviewers — Round 1

## Response to GPT-5.4 (R1) — Reject and Resubmit

**1. Treatment mismeasurement from within-state rollout**
We agree this is the central design limitation. We have elevated this from a peripheral caveat to a prominent interpretive qualification in the abstract, introduction, conclusion, and limitations section. The conclusion now explicitly states: "the null could partly reflect treatment mismeasurement rather than a true absence of crime effects." County-level rollout data are not available in the SNAP Policy Database, precluding a direct fix.

**2. Short effective post-treatment window under not-yet-treated controls**
Addressed. The empirical strategy section now explicitly notes that "post-treatment event-time coefficients at long horizons are identified only for early-adopting cohorts" and that "the 2005 cohort contributes no post-treatment estimates." Figure notes updated accordingly.

**3. Pre-trends: need joint test and sensitivity analysis**
Acknowledged. The event study discussion now reports individual coefficients with p-values and explains the multiple-testing context more transparently. HonestDiD sensitivity analysis was attempted but the pre-trend pattern (alternating signs) did not support bounded trend deviation analysis.

**4. State-level aggregation masks local effects**
Agreed and prominently discussed. The abstract now ends with: "The state-level estimand and treatment measurement cannot rule out localized effects in high-SNAP communities."

**5. CS vs Sun-Abraham divergence**
Now explained: different aggregation schemes give different implicit weights to cohort-time cells, producing the quantitative gap while preserving the qualitative null conclusion.

**6. "Missouri outlier" language too strong**
Removed throughout. Replaced with language acknowledging different estimands and geographic resolution.

**7. Data source (Disaster Center vs official UCR)**
Acknowledged as a limitation. The Disaster Center compilation draws from official UCR publications and is widely used, but we note that rebuilding from official FBI/NACJD files would strengthen data credibility.

## Response to GPT-5.4 (R2) — Reject and Resubmit

**1. Treatment definition consistency**
Fixed. Both main text and appendix now explicitly state that `ebtissuance` records statewide policy status, making "first ebtissuance=1" synonymous with "statewide implementation."

**2. Pre-trends inconsistency between main text and appendix**
Fixed. Main text now reports the specific marginally significant pre-period coefficients (t=-1, t=-5) rather than asserting "no pre-trends." Language is consistent throughout.

**3-5. Same concerns as R1 (treatment mismeasurement, aggregation, data source)**
Addressed as described above.

## Response to Gemini-3-Flash — Major Revision

**1. MDE/burglary power reconciliation**
Fixed in abstract and conclusion. Both now explicitly state that the burglary MDE of 9.2% cannot exclude the 7.9% Wright et al. estimate.

**2. SNAP participation intensity**
Acknowledged as an important limitation. State-year SNAP participation data would enable a more powerful intensity-weighted design. Flagged for future research.

**3. Reporting bias discussion**
A valid point. The limitations section notes that UCR data rely on voluntary reporting, though EBT should primarily affect crime incidence rather than reporting behavior.
