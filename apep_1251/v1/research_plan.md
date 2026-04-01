# Research Plan: Certify to Protect? Part 139 Airport Certification and Wildlife Strike Outcomes

## Research question

Did the FAA's 2004 expansion of Part 139 airport certification to newly regulated Class III commuter airports reduce damaging wildlife strikes, or did it mainly change reporting behavior?

## Policy and treatment definition

The February 10, 2004 final rule revising 14 CFR Part 139 extended airport-certification requirements, including wildlife hazard management under 14 CFR 139.337, to airports serving scheduled operations with 10-30 passenger aircraft. The official FAA regulatory evaluation appendix for the final rule lists 37 Class III airports that were newly certificated under the rule. I will encode that Class III roster directly from the FAA appendix and treat those airports as exposed. Because compliance ran through June 2007, the baseline design will use a common treatment date of 2007 and drop the transition years 2004-2006.

## Identification strategy

The core design is a long-panel airport-year difference-in-differences:

- Treated units: the 37 Class III airports listed in the FAA appendix.
- Control units: U.S. airports in the FAA wildlife-strike database that were never Part 139 Class III airports and have current `Part_139_Class == 0`, with a pre-period strike history that makes them comparable to treated airports.
- Pre-period: 1990-2003.
- Transition period dropped: 2004-2006.
- Post-period: 2007-2024.

The estimand is the average post-certification change at newly certificated airports relative to never-certificated airports, netting out airport fixed effects and common year shocks.

## Why this design can answer the reporting objection

Certification could increase reporting even if actual wildlife risk does not change. The paper therefore needs multiple outcomes:

1. Total reported strikes per airport-year.
2. Damaging strikes per airport-year.
3. Damage share among reported strikes.
4. Substantial-or-worse strikes per airport-year.
5. Repair-cost and flight-effect measures where available.

If certification mainly improves reporting, total reported strikes may rise without corresponding declines in damaging strike intensity. If certification improves on-airport wildlife management, damaging strikes and damage shares should fall.

## Primary specification

Main count specification:

```text
Y_at = beta * Treated_a * Post_t + alpha_a + gamma_t + e_at
```

where `Y_at` is an airport-year count outcome such as damaging strikes. I will estimate:

- `fepois()` Poisson fixed-effects models for count outcomes.
- `feols()` linear fixed-effects models on rates/shares as robustness.

Inference:

- Cluster at the airport level.
- Report wild-cluster bootstrap p-values as a robustness check because the treated group is modest.

## Event-study and robustness plan

- Event-study with the transition years omitted and 2003 as the last clean pre-period.
- Alternative control group using historically limited-certificated or currently Part 139 airports where feasible.
- Balanced-panel robustness restricting to airports with observed pre- and post-period strike reporting.
- Sensitivity to excluding airports with extremely high pre-period strike counts.
- Placebo outcomes: non-damaging strike counts and low-severity reports.

## Data sources and fetch strategy

### 1. FAA Wildlife Strike Database

Source: FAA wildlife site API.

- Base API: `https://wildlife.faa.gov/WildlifeAdmin/api/Service/`
- Authentication headers are exposed by the public frontend and allow public-database access.
- Endpoint: `searchDatabase/`
- Strategy: request the full public database for 1990-2024 and save raw JSON plus a cleaned strike-level parquet.

### 2. FAA airport metadata

Source: same FAA API.

- Endpoint: `GetAirports`
- Use fields including airport code, city, state, coordinates, and current `Part_139_Class`.

### 3. FAA certification-status list

Source: FAA Part 139 certification-status workbook.

- Use the current workbook as a metadata cross-check, not as the historical treatment roster.

### 4. Historical treated roster

Source: FAA regulatory-evaluation appendix for the 2004 final rule.

- Encode the 37 Class III airports from the appendix into a local CSV in `data/raw/`.
- This is a transcription of an official FAA source, not an invented list.

## Expected effects and mechanisms

- Ambiguous effect on total reported strikes because better compliance may raise reporting.
- Negative effect on damaging strikes if wildlife hazard assessments, plans, and training reduced real collision severity.
- Negative effect on damage share if certification improved mitigation conditional on strike occurrence.

## Main implementation decisions

- Unit of analysis: airport-year.
- Geography: U.S. airports only.
- Inclusion rule: airports with valid FAA airport codes and at least one observed strike report.
- Zero handling: build a complete airport-year panel for treated and control airports after defining the analysis sample.
- Exposure alignment: treatment is assigned at the airport level, so the estimand is a change in strike outcomes per treated airport-year, not per flight. Because a full airport-level operations denominator is not available in the assembled panel, identification relies on comparing airports with pre-period strike histories and on fixed effects rather than scaling by traffic volume.

## Method notes

- Count outcomes are better matched to Poisson FE than OLS on sparse counts.
- The treated group is only 37 airports, so custom inference is not optional.
- The key design threat is reporting intensity, which is why the decomposition between total reports and damaging outcomes is central rather than auxiliary.
