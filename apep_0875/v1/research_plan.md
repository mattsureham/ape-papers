# Research Plan: The Disclosure Chill

## Research Question
Does federal disclosure of program-level debt-to-earnings outcomes cause for-profit educational programs to close, and do these closures reverse when the regulation is repealed? This paper exploits the 2015 debut and 2019 repeal of the Gainful Employment (GE) Rule to estimate the causal effect of regulatory disclosure on program survival, enrollment, and student displacement to public institutions.

## Identification Strategy
**Event study / staggered DiD with within-institution variation.**

The GE Rule created sharp, program-level variation within institutions:
- **Treatment group:** For-profit programs receiving "Fail" or "Zone" GE scores in the July 2015 DOE disclosure
- **Control group 1:** For-profit programs receiving "Pass" scores at the same institution
- **Control group 2:** Comparable programs at public/nonprofit institutions (never subject to GE)

The design is a **triple-difference**: (fail vs. pass programs) × (for-profit vs. public sector) × (pre vs. post 2015).

The 2019 repeal provides a second quasi-experiment: if disclosure drove closures, surviving fail-status programs should rebound post-repeal. If closures were irreversible (sunk exit costs), the repeal will show no effect — revealing an asymmetric "disclosure chill."

**Key threats:**
1. Pre-trends in program exits across pass/fail groups (testable with 2008-2014 data)
2. Secular decline of for-profit sector (controlled by within-institution comparison)
3. Selection into fail status (address via pre-determined CIP-code risk scores)

## Expected Effects and Mechanisms
1. **Program survival:** Fail-status programs should exit at higher rates post-2015. The mechanism is twofold: (a) direct regulatory threat of Title IV loss, and (b) information disclosure causing students/employers to avoid flagged programs.
2. **Enrollment:** Even surviving fail-status programs should see enrollment declines as students sort toward pass-status programs.
3. **Displacement:** Students displaced from closing for-profit programs should appear at nearby public community colleges (county-level substitution).
4. **Asymmetry:** Post-repeal (2019), we expect partial or no recovery — programs that exited cannot easily re-enter, and reputational damage persists.

## Primary Specification
```
Y_{ipct} = α + β₁(Fail_p × Post2015_t) + β₂(Fail_p × Post2019_t) + γ_i + δ_t + θ_c + ε_{ipct}
```
Where i = institution, p = program (CIP × award level), c = CIP code, t = year. Y is program survival (binary), log enrollment, or log completions. Institution FE absorb time-invariant institution quality; year FE absorb macro trends; CIP FE absorb field-specific trends.

Standard errors clustered at the institution level (~2,000 for-profit institutions).

## Data Sources and Fetch Strategy
1. **IPEDS (Azure):** `az://raw/ipeds/ipeds.duckdb` — c_a (completions, 6.6M rows), ef_a (enrollment, 2.8M rows), hd (institution directory, 162K rows). Query via DuckDB/Arrow in R.
2. **GE Disclosure Files:** Download from FSA IFAP website (https://studentaid.gov/data-center/school/ge). Program-level D/E ratios, pass/fail/zone status, 2015-2017.
3. **Geographic matching:** hd table has institution latitude/longitude for county-level enrollment substitution analysis.

## Robustness Checks
- Callaway-Sant'Anna for staggered treatment timing (some programs fail in 2015, others in 2017)
- Placebo test: apply "fail" classification to pre-2015 years
- Leave-one-CIP-out sensitivity
- McCrary-style test for manipulation of D/E ratios near thresholds
- Donut specification excluding programs near the pass/fail boundary
