# Research Plan: Exchange Rate Shocks and Structural Transformation

## Research Question

Did the January 2015 Swiss franc shock cause permanent structural transformation — shifting employment from manufacturing to services — in municipalities with high pre-shock manufacturing exposure? Or did manufacturing recover, revealing resilience rather than reallocation?

## Policy Context

On January 15, 2015, the Swiss National Bank (SNB) unexpectedly abandoned the EUR/CHF 1.20 floor, causing an instant ~15% franc appreciation. Swiss exporters in machinery, instruments, chemicals, and watchmaking saw products become dramatically more expensive in euro terms. National secondary-sector employment fell 5.1% (1,099K to 1,043K) from 2014 to 2016 before recovering by 2023 (1,085K).

## Identification Strategy

**Continuous-treatment DiD** exploiting cross-municipal variation in pre-shock manufacturing exposure.

- **Treatment exposure:** ManufShare_{m,2014} = secondary sector employment / total employment in municipality m, measured in 2014 (predetermined)
- **Shock:** January 15, 2015 franc appreciation (one-time, sharp, exogenous)
- **Specification:**

  Y_{mt} = alpha_m + gamma_t + sum_{k != 2014} beta_k * (ManufShare_{m,2014} * 1{t=k}) + epsilon_{mt}

  This traces out dynamic effects relative to 2014 (last pre-shock year).

- **Identifying assumption:** Absent the franc shock, municipalities with different manufacturing shares would have followed parallel trends in sectoral employment outcomes. Testable in pre-periods 2011-2014.

## Expected Effects

1. **Secondary sector employment:** Falls differentially in manufacturing-heavy municipalities post-2015. Key question: does it recover by 2019-2023?
2. **Tertiary sector employment:** Rises if reallocation occurs (cleansing hypothesis). Flat or falls if the shock is purely destructive (scarring hypothesis).
3. **Establishment counts:** Entry/exit margin — do manufacturing firms disappear, or do service firms enter?
4. **Employment intensity (FTE/establishment):** Intensive margin — do surviving firms shrink?

## Data

- **Source:** BFS STATENT (Statistik der Unternehmensstruktur) via PXWeb API
- **Table 102:** Municipality x broad sector (primary/secondary/tertiary/total) x year
- **Variables:** Establishments, employees, FTE
- **Coverage:** 2,136 municipalities, 2011-2023 (13 years)
- **Observations:** ~27,768 municipality-years

## Primary Specification

OLS with municipality and year fixed effects. Standard errors clustered at the municipality level.

Main estimand: beta_k coefficients tracing out the dynamic treatment effect for k = 2011, 2012, 2013, 2015, 2016, ..., 2023 (omitting 2014 as the reference year).

## Robustness

1. **Binary treatment DiD:** Define "high manufacturing" as municipalities with >30% secondary share in 2014 (811 municipalities)
2. **Alternative exposure measures:** Employment-weighted vs. establishment-weighted shares
3. **Callaway-Sant'Anna placebo:** Treat the binary split as a single-cohort design
4. **Outcome transformations:** Log employment, employment growth, level changes
5. **Geographic controls:** Canton-year fixed effects (absorbing canton-level shocks)
6. **Trimming:** Exclude very small municipalities (<100 employees)

## Mechanism Tests

- **Reallocation:** Does tertiary employment growth offset secondary employment losses? (within-municipality)
- **Consolidation:** Do establishments decline but FTE/establishment increase? (survivors grow)
- **Persistence:** Is the 2023 sectoral composition different from 2014 in high-exposure municipalities?

## Angle Avoidance

Two existing APEP papers use the franc shock:
- apep_0738: Retail desertification (retail store closures — sectoral outcome)
- apep_0733: Tourism pass-through (hotel prices/occupancy — sectoral outcome)

This paper studies a fundamentally different margin: aggregate manufacturing-to-services reallocation at the municipal level, testing the structural transformation hypothesis.
