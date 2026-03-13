# Research Plan: Did PROGRESA Build Better Villages?

## Research Question
Do conditional cash transfers (CCTs) generate place-based development effects beyond individual human capital gains? We exploit the original 1997 village-level randomization of PROGRESA (320 treatment vs. 186 control localities) to estimate village-aggregate economic development effects 23 years later using INEGI's 2020 locality-level census.

## Identification Strategy
**Intent-to-treat (ITT) comparison** of 320 early-treatment vs. 186 late-treatment localities.

- **Randomization**: 506 rural localities in 7 Mexican states randomly assigned to treatment (May 1998) or control (November 1999), stratified by locality size. Balance confirmed by IFPRI evaluation and Angelucci & De Giorgi (2009, AER).
- **Treatment contrast**: 18-month differential exposure window during critical early period. After November 1999, both groups received the program.
- **Key assumption**: If CCTs trigger cumulative community-level processes (human capital → labor market deepening → business formation), the early-treatment advantage could compound over 23 years.

## Expected Effects
- **Population**: Early-treatment localities may have higher population if CCTs reduce out-migration or attract in-migration
- **Education**: Higher average schooling, lower illiteracy (direct program effect + spillovers)
- **Employment**: Higher EAP share if human capital gains translate to labor market participation
- **Housing**: Better housing quality (electricity, water, drainage) if income effects persist
- **Null hypothesis**: Effects are purely individual — no village-level divergence from 18-month head start

## Primary Specification
Cross-sectional OLS at locality level:
```
Y_i,2020 = α + β * Treatment_i + γ * X_i,1995 + State_FE + ε_i
```
Where Treatment_i = 1 for the 320 early-treatment localities, X_i,1995 are pre-treatment baseline characteristics from the 1995 Population Count, and State FE absorb state-level differences.

With valid randomization, β is identified without controls, but baseline characteristics improve precision.

## Inference
- Heteroskedasticity-robust standard errors (HC2)
- Randomization inference (permutation test, 10,000 draws)
- Multiple hypothesis testing adjustment (Bonferroni, Holm)

## Data Sources
1. **INEGI ITER 2020** (locality-level census): Population, education, employment, housing quality — confirmed HTTP 200
2. **INEGI ITER 1995** (pre-treatment baseline): Population, education — for balance checks
3. **PROGRESA treatment assignment**: From evaluation microdata (IFPRI/CONEVAL/academic replication packages)

## Risks
- **Data access**: PROGRESA treatment assignment may require finding the right academic source
- **Attrition**: Some 1997 localities may not appear in 2020 ITER (merged, depopulated)
- **Spillovers**: Control localities received treatment 18 months later — differential exposure is subtle
- **Power**: 506 localities may be underpowered for small effects
