# Revision Response Plan (Stage C)

## Review Summary

| Reviewer | Decision | Key Concerns |
|----------|----------|-------------|
| GPT-5.4 R1 | MAJOR REVISION | Missing first stage, TWFE heterogeneity, overclaimed exogeneity, bundled policies |
| GPT-5.4 R2 | MAJOR REVISION | Missing first stage, TWFE heterogeneity, treatment coding, overclaimed conclusions |
| Gemini-3 | MINOR REVISION | First-stage check, wild cluster bootstrap |

## Cross-Reviewer Consensus (Must-Fix)

1. **Missing first stage** (3/3): Show gas tax → pump prices in this sample and timing window
2. **TWFE heterogeneity inconsistency** (2/3): Can't dismiss TWFE for main results but use it for subgroups
3. **Overclaimed conclusions** (2/3): Narrow claims to reduced-form, not "rational attribution"
4. **Missing literature** (2/3): Add de Chaisemartin-D'Haultfœuille, Chetty-Looney-Kroft, Roth et al.

## Revision Plan

### Workstream 1: First-Stage Evidence (NEW R CODE)
- Fetch state-level average retail gasoline prices from EIA API
- Estimate CS-DiD event study on gas prices around tax effective dates
- Show pass-through in Sep-Nov CES window
- Create Figure (new): "First Stage: Effect of Gas Tax Increases on Retail Gasoline Prices"
- Add subsection in Empirical Strategy or Results

### Workstream 2: CS-DiD Subgroup Heterogeneity (REWORK R CODE)
- Replace TWFE interaction terms with separate CS-DiD estimates by subgroup:
  - Democrats vs Republicans vs Independents
  - Below-median vs above-median income
  - Pre-1970 vs post-1970 birth cohort
- Update Figure 5 and heterogeneity text accordingly
- Remove TWFE-based dose-response or acknowledge limitation explicitly

### Workstream 3: Claim Calibration (LATEX EDITS)
- Narrow abstract/conclusion: "no detectable effect" not "consumers rationally distinguish"
- Soften exogeneity language: "plausibly exogenous" not "orthogonal"
- Reframe pre-trends: "no detectable differential pre-trends" not "clean pre-trends"
- Bound external validity: about CES retrospection, not "macroeconomic beliefs" generally
- Acknowledge bundled policies more explicitly

### Workstream 4: Literature & Citations (LATEX EDITS)
- Add de Chaisemartin & D'Haultfœuille (2020) on TWFE bias
- Add Roth (2022/2023) on pre-trend testing limitations
- Add Chetty, Looney & Kroft (2009) on tax salience
- Add Finkelstein (2009) on salience
- Strengthen partisan perceptions literature

### Workstream 5: Minor Robustness (LATEX EDITS)
- Report late-year recoding results explicitly (currently only mentioned)
- Clarify weighting and aggregation choices
- Acknowledge border-state spillovers as limitation

### Not Addressed (Acknowledged as Limitations)
- Individual-level interview dates (unavailable in CES cumulative)
- Google Trends salience data (unavailable)
- Formal adoption hazard model (beyond scope; acknowledge)
- Full treatment bundling classification (acknowledge as limitation)
- Continuous treatment intensity modeling (acknowledge)
