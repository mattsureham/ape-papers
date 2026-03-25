# Research Plan: apep_0894

## Research Question

What are the labor market effects on payday lending industry workers when consumer finance regulations restrict their industry? Specifically, how did the CFPB's 2017 payday lending rule (compliance date August 19, 2019) affect employment, hiring, separations, and earnings in the non-depository credit intermediation sector (NAICS 522)?

## Identification Strategy

**Continuous difference-in-differences** exploiting county-level variation in pre-existing payday lending establishment density.

- **Treatment intensity:** County-level payday lending establishment count per capita in 2017 (pre-announcement) from County Business Patterns, NAICS 522390 (Activities Related to Credit Intermediation).
- **Treatment timing:** Q3 2019 (compliance date August 19, 2019).
- **Reversal test:** Partial rescission of ability-to-repay provision effective September 3, 2020 (Q3 2020). If the compliance shock caused employment decline, the rescission should predict recovery.
- **Unit of observation:** County × quarter.
- **Fixed effects:** County FE + quarter FE.
- **Clustering:** State level.

### Primary specification

```
Y_ct = α_c + γ_t + β₁(Density_c × Post2019Q3_t) + β₂(Density_c × PostRescission2020Q3_t) + ε_ct
```

Where Y is employment (EmpEnd), hires (HirN), separations (Sep), or earnings (EarnS) in NAICS 522; Density is 2017 payday establishment density; Post indicators mark the compliance and rescission dates.

### Exposure alignment

The treatment variable (2017 NAICS 522390 establishment density) is measured at the county level. The outcome (NAICS 522 employment) is also at the county level. The policy (CFPB rule) is federal with uniform timing, so there is no staggered adoption. The identifying variation comes from cross-county differences in pre-existing exposure: counties with higher payday density had more of their credit-sector employment potentially subject to the rule. Workers directly affected are those employed in payday lending storefronts (NAICS 522390), which are a subset of the broader NAICS 522 category. The continuous treatment intensity design assumes that the employment effect scales linearly with payday density.

### Key threats and responses

1. **NAICS 522 includes banks:** Placebo test on NAICS 5221 (Depository Credit Intermediation — banks, unaffected by payday rule).
2. **COVID-19 (Q1 2020):** Primary estimates use Q3–Q4 2019 only (2 clean post quarters). Extended specification includes COVID controls.
3. **Parallel trends:** Event study with leads and lags to verify pre-treatment trends are flat.
4. **Confounders:** Control for county-level unemployment rate, population, and industry composition.

## Expected Effects and Mechanisms

- **Employment:** Decline in high-density counties post-compliance. The rule was projected to eliminate 60–70% of payday loans, forcing store closures.
- **Separations:** Spike in high-density counties as stores close.
- **Hiring:** Decline as industry contracts.
- **Earnings:** Ambiguous — could rise if low-wage workers exit first, or decline if remaining workers have reduced bargaining power.
- **Reversal:** Partial recovery in high-density counties after rescission.

## Data Sources

1. **QWI (Quarterly Workforce Indicators):** Azure Blob Storage, `derived/qwi/sa/n3/*.parquet`. Filter industry = '522' (Credit Intermediation) and '5221' (Depository Credit, placebo). County × quarter × industry panel, 2014–2022.
2. **County Business Patterns (CBP):** Census.gov, 2017 full file. NAICS 522390 establishment counts by county for treatment intensity.
3. **BLS/BEA controls:** County unemployment rates, population (if needed).

## Paper Structure (AER: Insights)

1. Introduction — the puzzle: consumer protection has unmeasured costs on regulated-industry workers
2. Institutional Background — CFPB rule, compliance date, rescission
3. Data and Empirical Strategy
4. Results — main DiD, event study, reversal test
5. Robustness — placebo (banks), leave-one-state-out, alternative density measures
6. Conclusion
