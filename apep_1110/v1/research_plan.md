# Research Plan: The Reformulation Dividend

## Research Question
Did the UK Soft Drinks Industry Levy (SDIL) reduce childhood dental extractions, and does the effect operate through manufacturer reformulation (supply-side) rather than consumer switching (demand-side)?

## Policy Setting
- **Policy:** UK Soft Drinks Industry Levy (SDIL)
- **Announced:** March 2016 budget
- **Implemented:** April 2018
- **Structure:** Two-tier — 18p/litre for 5–8g sugar/100ml, 24p/litre for 8g+
- **Key feature:** 2-year announcement gap triggered massive pre-implementation reformulation. By Feb 2019, only 18% of drinks exceeded 5g/100ml (down from 52% in Sep 2015). Over 80% of calorie reduction came from reformulation, not consumer switching.

## Identification Strategy
**Continuous treatment DiD** exploiting cross-local-authority variation in pre-SDIL sugar exposure:

$$Y_{it} = \alpha_i + \gamma_t + \beta(\text{Post}_t \times \text{Deprivation}_i) + X'_{it}\delta + \varepsilon_{it}$$

- **Unit:** 322 English local authorities (upper-tier/unitary)
- **Treatment intensity:** IMD 2019 deprivation score (continuous, range 5–45). More deprived areas consumed more SSBs pre-treatment → received larger reformulation "dose"
- **Outcome:** Rate of carious tooth extractions per 10,000 children aged 0–19
- **Post:** April 2018 onward (but with anticipation channel from March 2016 announcement)
- **COVID exclusion:** Drop 2020/21 and 2021/22 (hospital activity collapsed)
- **Clustering:** LA level

### Identifying Assumption
Parallel trends: absent the SDIL, the gap in dental extraction rates between high- and low-deprivation LAs would have remained constant. Testable with pre-treatment event study (3 pre-periods: 2015/16–2017/18).

### Falsification Tests
1. **Non-caries extractions** (trauma, orthodontic): should NOT respond to sugar reformulation
2. **Placebo treatment timing:** Assign fake treatment at 2016/17 in pre-period data only
3. **Permutation inference:** Randomly reassign IMD scores across LAs

## Expected Effects
- **Direction:** Negative (reformulation → less sugar → fewer caries → fewer extractions)
- **Magnitude:** Rogers et al. (2024 BMJ) found 12% national reduction using ITS. Cross-LA intensity design should find larger effects in more deprived areas.
- **Mechanism:** Supply-side reformulation (firms changed product recipes) rather than demand-side substitution (consumers switching to water)

## Primary Data Sources
1. **Hospital Episode Statistics (GOV.UK OHID):** Two CSVs covering tooth extractions 0–19 by LA, 2015/16–2024/25
2. **Fingertips API (OHID):** IMD 2019 deprivation (indicator 93553), childhood obesity (indicator 20601)
3. **Water fluoridation status:** PHE/OHID fluoridation data by LA (critical control — fluoridated areas have lower baseline caries)

## Analysis Pipeline
1. `00_packages.R` — Load libraries (fixest, data.table, did, jsonlite)
2. `01_fetch_data.R` — Download GOV.UK CSVs + Fingertips API data
3. `02_clean_data.R` — Merge, construct panel, create treatment intensity variable
4. `03_main_analysis.R` — DiD regressions, event study, main results + diagnostics.json
5. `04_robustness.R` — Falsification (non-caries), permutation inference, alternative specifications
6. `05_tables.R` — Generate all tables including SDE appendix table

## Key Risks
1. **Only 3 pre-periods:** Limited ability to test pre-trends rigorously → will use HonestDiD sensitivity
2. **COVID disruption:** 2 missing years weaken post-treatment identification → careful event study with explicit COVID gap
3. **Deprivation = many channels:** IMD correlates with many things beyond SSB consumption → need to argue reformulation is the specific margin that changed at the SDIL cutoff
