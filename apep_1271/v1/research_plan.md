# Research Plan: Mandated to Stay

## Research Question
Do state paid sick leave mandates reduce labor market turnover in food service, and through which specific worker-flow channels?

## Hypothesis
Paid sick leave mandates prevent "presenteeism quits" — workers who would otherwise separate because working sick is intolerable. This should produce a specific four-way flow signature:
1. **Separations** decline (fewer quits from presenteeism pressure)
2. **New hires** decline (less replacement hiring needed)
3. **Recalls** unchanged (employer callbacks are orthogonal to sick leave)
4. **Stable employment** increases (more workers stay beyond a full quarter)

The recalls prediction is the sharpest test: if mandates simply reduce churn generally, recalls should also decline. If the mechanism is specifically about preventing voluntary separations, recalls (employer-initiated rehires) should be unaffected.

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD** exploiting 9 state-level mandate waves:

| State | Effective Date | Treatment Quarter |
|-------|---------------|-------------------|
| CT | Jan 1, 2012 | 2012Q1 |
| CA | Jul 1, 2015 | 2015Q3 |
| MA | Jul 1, 2015 | 2015Q3 |
| OR | Jan 1, 2016 | 2016Q1 |
| VT | Jan 1, 2017 | 2017Q1 |
| AZ | Jul 1, 2017 | 2017Q3 |
| WA | Jan 1, 2018 | 2018Q1 |
| MD | Feb 11, 2018 | 2018Q1 |
| NJ | Oct 29, 2019 | 2019Q4 |

**Unit of analysis:** County × quarter
**Comparison group:** Not-yet-treated and never-treated counties
**Clustering:** State level (~20 states), with wild cluster bootstrap for robustness

## Data
**Source:** Census QWI (Quarterly Workforce Indicators), LEHD program
**Azure path:** `derived/qwi/sa/n3/{state}.parquet` (sex × age × 3-digit NAICS × county)
**Coverage:** All 51 states, 2005-2022, quarterly

**Key variables:**
- `HirN` — New hires (first time at this employer)
- `HirR` — Recalls (returning to prior employer) — computed as HirA - HirN
- `Sep` — Separations
- `EmpS` — Stable employment (employed both start and end of quarter)
- `TurnOvrS` — Turnover rate
- `EarnHirNS` — New hire earnings

**Sample:** NAICS 722 (food service) primary; NAICS 44-45 (retail) as placebo/comparison sector
**Restriction:** Counties with food service employment > 50 in all quarters

## Expected Effects and Mechanisms
- Separations: **negative** (−2-5% reduction) — fewer presenteeism quits
- New hires: **negative** (−1-4%) — less replacement hiring
- Recalls: **null** — orthogonal to sick leave mechanism
- Stable employment: **positive** (+1-3%) — more quarter-spanning tenure
- Turnover rate: **negative** (−1-3pp)

## Age Heterogeneity
Young workers (19-24) have lowest voluntary sick leave coverage pre-mandate → should show largest effects. QWI age codes: A02 (14-18), A03 (19-21), A04 (22-24), A05 (25-34), A06 (35-44), A07 (45-54), A08 (55-64), A09 (65+).

## Primary Specification
```r
# Callaway-Sant'Anna ATT(g,t) estimation
cs_att <- att_gt(
  yname = "sep_rate",
  tname = "quarter_num",
  idname = "county_fips",
  gname = "treatment_quarter",
  data = panel,
  control_group = "notyettreated",
  clustervars = "state_fips"
)
```

## Exposure Alignment
Treatment is assigned at the state level (state enacts paid sick leave mandate). The outcome data (QWI) is at the county-quarter-industry level. All counties within a treated state receive the same treatment timing. The key alignment concern is that mandates often include firm-size exemptions (CT: 50+ employees; MA: 11+ employees; MD: 15+ employees). Because QWI aggregates all establishments within a county regardless of size, the county-level treatment indicator overstates exposure in counties with many small (exempt) firms. This likely attenuates estimates toward zero. The paper discusses this as a limitation and notes that the true effects may be larger than detected.

Workers directly affected: food service employees in covered establishments who did not previously have voluntary paid sick leave access. Pre-mandate coverage was approximately 50% in food service nationally, so the mandate is binding for roughly half of food service workers in treated states.

## Robustness
1. Never-treated only as control group
2. Wild cluster bootstrap (state level)
3. Retail sector (NAICS 44-45) as placebo sector
4. Exclude CT (earliest adopter, different scope — service workers only, 50+ employees)
5. HonestDiD sensitivity analysis for pre-trend violations
6. Pre-trend event study plots

## Existing APEP Papers on Paid Sick Leave
- apep_0001: Work hours (low-wage service) — different outcome
- apep_0704: Retention dividend — related but doesn't decompose QWI flows
- apep_0787: Workplace injury rates — different outcome
Our contribution: four-way QWI flow decomposition revealing the specific mechanism
