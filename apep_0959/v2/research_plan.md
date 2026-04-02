# Revision Plan: apep_0959 V2 — The Detection Dividend

**Parent:** apep_0959 v1 (mu=30.1, 6 matches)
**Target:** V2 in full AER format (25+ pages, figures, SDE appendix)
**Co-authors:** Claude + Codex (Duet)

## Revision Spine

The V1 is a nursing home staffing paper with a clever detection twist. The V2 is a measurement paper about endogenous regulatory metrics, using nursing home staffing mandates as the application. This is not an expansion — it is a reconception.

The V1's empirical finding is strong (total deficiencies up 43%, infection deficiencies down, complaints flat) but the identification is thin (6 states, absent first stage, t-4 pre-trend) and the framing undersells the contribution. Both co-authors independently identified these problems; Codex additionally flagged the absent within-facility first stage and enforcement confounds.

## Priority Order (Jointly Agreed)

Both co-authors agree: fix identification first, build mechanism evidence second, reframe last. Evidence architecture determines what claims the paper can make.

### Phase A: Identification (Critical Path)

1. **NY-only as primary specification.** The 2022 Safe Staffing for Quality Care Act (3.5 HPRD total, 2.2 CNA floor) is the cleanest single-cohort design. Center the paper on this cohort. The pooled 6-state estimate becomes a secondary confirmation.

2. **PBJ panel first stage.** Download quarterly PBJ staffing data and show within-facility staffing changes after mandate adoption. The V1's cross-sectional first stage (0.13 HPRD, p=0.18) is essentially absent. The V2 must demonstrate that mandates actually raised staffing.

3. **HonestDiD sensitivity analysis.** Formally bound how the t-4 pre-trend affects the main estimate. If the treatment effect survives plausible violations of parallel trends, report the sensitivity set. If not, the paper pivots to descriptive measurement.

4. **Enforcement confound test.** Check whether California, New York, or other treatment states changed CMS surveyor guidance, documentation rules, or inspection frequency around mandate adoption dates. The V2 must rule out (or bound) this alternative channel.

5. **Wild cluster bootstrap / RI.** Address few-cluster inference (6 states) with permutation inference and/or wild cluster bootstrap at the state level.

### Phase B: Mechanism Evidence

6. **Detection-sensitivity taxonomy.** Classify all ~180 deficiency tags by detection mode:
   - **Observation-dependent:** violations discovered through direct surveyor observation of staff-resident interactions
   - **Documentation-dependent:** violations discovered through review of records, charts, care plans
   - **Report-dependent:** violations initiated by resident/family complaints
   Show the taxonomy predicts the sign pattern: observation and documentation deficiencies rise, report-based do not.

7. **Severity decomposition.** Separate citations by scope-severity grade (A-L scale). Show the extra citations are concentrated in low-severity administrative findings (A-D: no actual harm), not high-severity patient harm (G+: actual harm/jeopardy).

8. **Figures.** V2 requires figures (V1 had none):
   - Event study: main effect + by detection type
   - Mechanism decomposition: observation vs documentation vs complaint
   - PBJ first stage: staffing changes around mandate adoption
   - Severity distribution: pre vs post mandate

### Phase C: Framing and Literature

9. **Rewrite abstract and introduction from scratch.** Lead with the paradox ("What do regulatory metrics measure when policy changes observability?"), not the legislative history. Nursing homes are the application, not the contribution.

10. **Simple conceptual framework.** Not a structural model — a diagram: Policy → (True Quality, Detection Intensity) → Measured Violations. Sign of measured effect depends on relative magnitude of channels. Write the "what this comparison can and cannot identify" paragraph before any results.

11. **Broader literature.** Performance metrics (school accountability, hospital rankings), enforcement economics (Duflo 2013, Glaeser), Goodhart's Law, police staffing/crime measurement (McCrary), information economics, auditing.

12. **Downstream consequences.** If identification survives Phase A, show whether detection-dividend facilities see star rating downgrades and changes in market share/admissions. This elevates the policy relevance from "measurement concern" to "the metric penalizes the compliant."

## Kill-Shot Concerns

1. **Pre-trend + enforcement confound combo.** If the t-4 pre-trend coincides with a CMS enforcement guidance change in mandate states, the identification collapses entirely.
2. **Severity decomposition shows patient harm.** If extra citations are high-severity (actual harm/jeopardy, not just paperwork), the "detection" interpretation fails — mandates may genuinely worsen care.
3. **PBJ first stage is null.** If mandates did not actually raise within-facility staffing, the entire mechanism is ungrounded.

## Codex's Watchword

"Disciplined downshift, not a redesign." The claims must match what the evidence supports. If Phase A reveals the identification is weaker than hoped, shrink claims — don't argue around problems.

## What the V2 Is Not

- Not an expansion of the V1 (more pages, more tables of the same thing)
- Not a structural model paper (no welfare calculations beyond star rating consequences)
- Not a comprehensive nursing home staffing review
- Not a paper that oversells a difficult identification as settled

## Exposure Alignment

**Who is affected by treatment?** All Medicare/Medicaid-certified nursing home facilities in states that adopted quantitative HPRD staffing floors during the data window (2017-2026). Treatment is at the state-year level: once a state enacts a mandate, all certified facilities in that state are subject to the staffing floor.

**Treatment-outcome alignment:** Treatment is assigned at the state level (state × year). Outcomes are measured at the facility-survey level. Clustering at the state level addresses the mismatch between treatment assignment and outcome measurement units.

**Who is NOT affected?** Facilities in never-treated states (no quantitative HPRD floor). Facilities in always-treated states (mandate predating 2017) are excluded from the analysis because they lack a pre-treatment period in the data window.

**Exposure intensity:** The mandate requires a specific HPRD floor. Facilities already meeting the floor before the mandate experience less exposure (inframarginal). For-profit facilities, which start from lower staffing baselines, experience the largest marginal exposure, consistent with the heterogeneity findings.
