# Research Plan: The Tenure Shield — Mine-Specific Experience and Injury Risk

## Research Question

Does mine-specific tenure reduce workplace injury risk beyond what general mining experience provides? If so, policies that induce worker turnover (enforcement actions, mine closures, safety citations) generate offsetting safety costs through lost establishment-specific human capital.

## Identification Strategy

### Primary: Within-Injury Experience Decomposition
- **Estimating equation:** Severity_i = β₁ MINE_EXPER_i + β₂ TOT_EXPER_i + γ JOB_EXPER_i + δ_m (mine FE) + θ_t (year-quarter FE) + X_i'λ + ε_i
- **Key coefficient:** β₁ — the return to mine-specific tenure holding total experience constant
- **Variation:** Workers with identical total mining experience but different mine-specific tenure (e.g., 15-year miner who just transferred vs. 15-year miner at same mine for 10 years)
- **Threat:** Selection — workers who stay at one mine longer may differ on unobservables. Addressed by controlling for total experience, occupation, and mine fixed effects.

### Secondary: Arrival Cohort Design (Mine-Level Panel)
- Aggregate to mine-quarter panel. Compute new-arrival share (fraction of workforce with < 1 year mine tenure).
- Regress mine-quarter injury rate on new-arrival share, with mine and year-quarter FEs.
- Exploits within-mine variation in cohort composition over time.

### Tertiary: Inspection-Induced Turnover (IV Approach)
- MSHA inspections with severe S&S findings → worker departures at cited mines → arrivals at destination mines.
- Instrument: severe citation count at neighboring mines as shifter for new-arrival share.
- This is exploratory — will pursue only if first stage is strong (F > 10).

## Expected Effects and Mechanisms

- **Mine-specific tenure:** Negative effect on injury severity/probability. Workers learn mine-specific hazards (roof conditions, ventilation patterns, equipment quirks) that generic training cannot substitute.
- **Magnitude prior:** Literature on firm-specific human capital suggests 1-3% wage returns per year of tenure. Safety returns may be larger because hazard knowledge is more establishment-specific than productivity knowledge.
- **Mechanism:** "The Tenure Shield" — mine-specific human capital acts as protective knowledge. New arrivals face elevated risk because they lack site-specific hazard awareness that accumulates through direct experience.

## Primary Specification

OLS regression of days lost (or injury severity indicator) on MINE_EXPER, controlling for TOT_EXPER, JOB_EXPER, occupation codes, mine FE, year-quarter FE. Cluster standard errors at the mine level.

## Data Sources and Fetch Strategy

### MSHA Open Data (Primary)
All from https://arlweb.msha.gov/OpenGovernmentData/OGIMSHA.asp:

1. **Accidents** (`Accidents.zip`): 271,720 records. Fields: MINE_ID, TOT_EXPER, MINE_EXPER, JOB_EXPER, DEGREE_INJURY, DAYS_LOST, DAYS_RESTRICT, OCCUPATION_CD, ACCIDENT_DT, etc.
2. **Mines** (`Mines.zip`): Mine characteristics (type, status, state, commodity, etc.)
3. **MinesProdQuarterly** (`MinesProdQuarterly.zip`): Quarterly production and employment by mine. Links via MINE_ID.
4. **Inspections** (`Inspections.zip`): Inspection records with S&S findings for IV approach.
5. **Violations** (`Violations.zip`): Individual violation records with S&S designation.

### Fetch approach
- Bulk download ZIP files from MSHA website
- Parse pipe-delimited text files
- Link via MINE_ID across datasets
- No API key needed — fully public data

## Robustness Checks
1. Alternative severity measures: binary (any days lost), log(days_lost + 1), severity category
2. Subsample by mine type (underground vs surface)
3. Subsample by commodity (coal vs metal/nonmetal)
4. Nonlinear tenure effects (spline at 1, 3, 5, 10 years)
5. Placebo: JOB_EXPER should matter less than MINE_EXPER if mechanism is site-specific knowledge
6. Wild cluster bootstrap for inference (mine-level clustering)
