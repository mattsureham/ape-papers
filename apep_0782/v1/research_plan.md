# Research Plan: The Price of Safety — MSHA's 2007 Penalty Reform and Mine Injury Deterrence

## Research Question

Does raising regulatory fines deter workplace injuries? On March 22, 2007, MSHA published a final rule (72 FR 13621) amending 30 CFR Part 100, raising average proposed penalties from $210 to $884 per violation overnight — a 4.2x increase. The reform disproportionately increased penalties for "Significant and Substantial" (S&S) violations (mean $571 to $2,037, 3.6x). Using 3.06 million violation records linked to 271,000 mine-level accident/injury reports, this paper provides the first causal estimate of whether the across-the-board penalty increase reduced mine-level injuries.

## Identification Strategy

**Continuous-treatment DiD.** Treatment intensity = mean proposed penalty per S&S violation at mine $i$ during the pre-reform period (2004–2006). This captures cross-mine variation in penalty exposure driven by pre-existing violation profiles. Post = April 2007 (Q2 2007 onward).

**Primary specification:**
$$InjuryRate_{it} = \alpha_i + \gamma_t + \beta \cdot (TreatmentIntensity_i \times Post_t) + \varepsilon_{it}$$

where $\alpha_i$ are mine fixed effects and $\gamma_t$ are quarter fixed effects. Standard errors clustered at the mine level.

**Event study:**
$$InjuryRate_{it} = \alpha_i + \gamma_t + \sum_{k \neq 2006} \beta_k \cdot (TreatmentIntensity_i \times \mathbb{1}[Year_t = k]) + \varepsilon_{it}$$

Reference year = 2006. Coefficients $\beta_k$ for $k < 2006$ test pre-trends.

**Key identifying assumption:** Conditional on mine and quarter FEs, pre-reform penalty exposure is not correlated with differential post-reform injury trends for reasons other than the penalty increase.

## Data Sources

### MSHA Accidents (Accidents.zip)
- URL: https://arlweb.msha.gov/OpenGovernmentData/DataSets/Accidents.zip
- 271,720 individual accident/injury records at MINE_ID × date level, 2000–2025
- Variables: MINE_ID, ACCIDENT_DT, DEGREE_INJURY_CD, DAYS_LOST, DAYS_RESTRICT, TRANS_TERM
- Aggregate to mine-quarter panel: injury counts, injury rates

### MSHA Violations (Violations.zip)
- URL: https://arlweb.msha.gov/OpenGovernmentData/DataSets/Violations.zip
- 3.06 million violation records
- Variables: MINE_ID, VIOLATION_OCCUR_DT, SIG_SUB (S&S flag), PROPOSED_PENALTY, SECTION_OF_ACT
- Use to construct pre-reform treatment intensity

### MSHA Mines (Mines.zip)
- URL: https://arlweb.msha.gov/OpenGovernmentData/DataSets/Mines.zip
- Mine characteristics: MINE_ID, MINE_TYPE, STATE, FIPS_CNTY, COAL_METAL_IND, CURRENT_MINE_STATUS, AVG_MINE_HEIGHT, NO_EMPLOYEES

## Sample Construction

1. **Panel period:** 2004Q1 to 2010Q4 (28 quarters: 12 pre, 4 transition, 12 post)
2. **Mine selection:** Active mines with ≥1 S&S violation in 2004–2006 (ensures nonzero treatment intensity)
3. **Treatment intensity:** Total proposed penalties for S&S violations / count of S&S violations at mine $i$ in 2004–2006
4. **Outcome:** Injury count per mine-quarter; injury rate = injuries / employees × 100

## Analysis Plan

### Script 1: 01_fetch_data.R
- Download Accidents.zip, Violations.zip, Mines.zip
- Parse pipe-delimited CSVs
- Save raw R objects

### Script 2: 02_clean_data.R
- Construct mine-quarter panel (2004Q1–2010Q4)
- Calculate treatment intensity per mine
- Merge accidents, violations, mine characteristics
- Create injury rate variable

### Script 3: 03_main_analysis.R
- DiD: injury_rate ~ treatment_intensity × post | mine_FE + quarter_FE
- Event study: yearly interactions, ref = 2006
- Write diagnostics.json

### Script 4: 04_robustness.R
- Alternative clustering (state level)
- Placebo reform in 2004 (pre-period only: 2002–2006, placebo post = 2004)
- Exclude transition quarters (2007Q1–Q2)
- S&S vs non-S&S violations separately

### Script 5: 05_tables.R
- tab1_summary.tex: Summary statistics
- tab2_violations.tex: Pre/post penalty comparison
- tab3_main.tex: Main DiD results
- tab4_eventstudy.tex: Event study coefficients
- tab5_robustness.tex: Robustness checks
- tabF1_sde.tex: Standardized effect sizes

## Hardware Considerations
- Data sizes: Accidents (~50MB zipped), Violations (~200MB+ zipped), Mines (~5MB)
- Panel: ~5,000–10,000 mines × 28 quarters = 140K–280K rows — fits easily in 16GB
- All analysis uses fixest and data.table for efficiency
