# Research Plan: The Scarlet Score

## Research Question

Does public disclosure of program-level quality scores permanently damage enrollment at for-profit college programs, even after the regulatory threat is rescinded? If so, does the reputational damage selectively displace minority students?

## Policy Background

The Obama-era Gainful Employment (GE) rule (34 CFR Part 668, effective July 2015) required for-profit and vocational programs to meet Debt-to-Earnings (D/E) thresholds. On **January 9, 2017**, the Department of Education published official D/E rates for ~11,521 programs at ~1,500 institutions. Approximately 800 programs were labeled "failing" (annual D/E > 12%) and ~1,400 were in the "zone" (8–12%).

The Trump administration paused enforcement in **June 2017** and formally rescinded the rule in **July 2019**. This creates a unique two-shock natural experiment:
- **Shock 1 (Jan 2017):** Information revelation — public labeling of failing programs
- **Shock 2 (Jun 2017):** Regulatory threat removal — enforcement pause

## Identification Strategy

**Primary design:** Event study DiD comparing "failed" programs (D/E > 12%) to "passed" programs (D/E < 8%) at for-profit institutions. Within-institution comparisons (institutions with both passing and failing programs) absorb all institution-level confounders.

**Two-stage decomposition:**
1. Post-publication effect (Jan 2017): captures combined reputational + regulatory channel
2. Post-rollback effect (Jun 2017): persistence = reputational scar; reversal = regulatory fear only

**Identifying assumption:** Absent score publication, enrollment trends at failing vs. passing programs would have been parallel (2013–2016). Scores are based on 2012–2013 graduate cohort earnings, predetermined relative to enrollment in 2013–2016.

**Supplementary RDD:** D/E rate as continuous running variable near the 12% failure threshold for local linear estimates.

## Expected Effects and Mechanisms

- **Publication effect:** Negative impact on completions/enrollment at failing programs (information revelation deters prospective students)
- **Persistence after rollback:** If the "scarlet score" hypothesis holds, enrollment does not recover — information, once public, cannot be retracted
- **Racial composition:** Failing programs may lose minority students disproportionately if minority applicants are more responsive to quality signals or if community colleges absorb displaced students

## Primary Specification

$$Y_{pjt} = \alpha_{pj} + \gamma_t + \beta_1 \cdot \text{Fail}_p \times \text{Post}_{t \geq 2017} + \beta_2 \cdot \text{Fail}_p \times \text{Rollback}_{t \geq 2018} + X_{jt}\delta + \varepsilon_{pjt}$$

Where:
- $p$ = program (CIP code × institution), $j$ = institution, $t$ = year
- $\text{Fail}_p$ = 1 if D/E > 12% in Jan 2017 publication
- $\beta_1$ = total effect of score publication (reputational + regulatory)
- $\beta_2$ = additional effect of rollback; if $\beta_2 \approx 0$, the "scarlet score" persists
- Program-institution FE absorb all time-invariant program characteristics
- Year FE absorb national trends in for-profit enrollment
- Cluster SEs at institution level (programs within institution may be correlated)

## Data Sources

1. **GE D/E Rates:** data.ed.gov — "GE 2017 Final D/E Rates" (11,521 programs, OPEID + CIP + D/E rate + pass/fail/zone)
2. **IPEDS (Azure):** `az://apepdata/raw/ipeds/ipeds.duckdb`
   - `c_a`: Completions by 6-digit CIP × race × year (program-level outcomes)
   - `hd`: Institution metadata (control=3 for for-profit, closure year)
   - `effy`: 12-month enrollment headcount
   - `sfa`: Pell Grant recipient counts
3. **Crosswalk:** OPEID → IPEDS unitid via College Scorecard

## Analysis Scripts

- `00_packages.R` — Load libraries
- `01_fetch_data.R` — Download GE scores from data.ed.gov, query IPEDS from Azure
- `02_clean_data.R` — Merge GE scores with IPEDS, construct treatment variables, build panel
- `03_main_analysis.R` — Event study DiD, two-stage decomposition, within-institution specification
- `04_robustness.R` — Placebo tests (passing programs near threshold), RDD at 12%, leave-one-out, wild cluster bootstrap
- `05_tables.R` — All tables including SDE appendix
