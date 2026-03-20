# Research Plan: Fiscal Windfalls and Violence Against Women

## Research Question

Do exogenous fiscal windfalls reduce gender-based violence by expanding female public-sector employment? Brazil's FPM (Fundo de Participação dos Municípios) transfer system creates sharp discontinuities at 17 population thresholds, generating ~20% jumps in per-capita transfers. These windfalls fund municipal health posts and schools that hire predominantly female workers (80%+ of community health agents and teachers), potentially improving women's outside options and reducing intimate partner violence.

## Identification Strategy

**Multi-cutoff Sharp RDD** exploiting Brazil's FPM population coefficient thresholds (Decreto-Lei 1.881/81, Lei Complementar 91/1997). The running variable is municipality population (from IBGE census estimates), with 17 discrete thresholds that determine the FPM coefficient and hence per-capita transfer amounts. Following Cattaneo et al. (2016) and the existing FPM-RDD literature (Brollo et al. 2013, Corbi et al. 2019, Litschig & Morrison 2013), I normalize populations to distance from the nearest threshold and pool all cutoffs.

**Key identifying assumption:** Municipalities cannot precisely manipulate their official population estimates (determined by IBGE, not self-reported). McCrary density test confirms no bunching.

**Causal chain:**
1. FPM threshold → higher per-capita transfers (first stage, well-established)
2. Higher transfers → more female public-sector employment in health/education (mechanism)
3. More female employment → reduced domestic violence (reduced form)

## Expected Effects and Mechanisms

- **Direction:** Negative effect of fiscal windfalls on domestic violence
- **Mechanism:** Female employment in health and education improves women's outside options (Aizer 2010 AER household bargaining framework). Economic independence reduces dependence on abusive partners. Additionally, health workers may improve reporting/detection.
- **Magnitude:** Expect moderate effects. Aizer (2010) finds 9% decline in DV hospitalizations per SD increase in female/male wage ratio. FPM jumps are ~20% of per-capita transfers, a meaningful fiscal shock.

## Primary Specification

```
Y_{it} = α + τ·D(pop_i > threshold) + f(pop_i - threshold) + X_i'β + ε_{it}
```

Where:
- Y_{it} = domestic violence rate (SINAN notifications per 100K women) or female homicide rate (SIM)
- D = indicator for population above nearest threshold
- f(·) = local linear polynomial in normalized population
- X_i = covariates (region FE, year FE for panel, GDP per capita)
- Bandwidth: CCT optimal (Calonico, Cattaneo, Titiunik 2014)

Multi-cutoff pooling: normalize distance to nearest threshold, include threshold fixed effects.

## Data Sources

1. **FPM coefficients:** Tesouro Nacional SICONFI / STN (published coefficients by population bracket)
2. **Population:** IBGE census estimates (annual, by municipality)
3. **Violence (SINAN):** DATASUS FTP — VIOLBR09.dbc through VIOLBR23.dbc (2009-2023)
4. **Mortality (SIM):** DATASUS FTP — female homicides by ICD-10 (X85-Y09)
5. **Employment (RAIS):** Base dos Dados or Ministério do Trabalho — formal employment by municipality, sex, sector (CNAE 85 education, 86 health)
6. **Controls:** IBGE municipal characteristics (GDP, urbanization, etc.)

## Tables Plan (5 tables + SDE appendix)

1. **Table 1:** Summary statistics by treatment status (above/below nearest threshold)
2. **Table 2:** First stage — FPM per capita transfers at thresholds
3. **Table 3:** Reduced form — Domestic violence notifications and female homicides
4. **Table 4:** Mechanism — Female formal employment in health/education
5. **Table 5:** Robustness — Placebo cutoffs, bandwidth sensitivity, male-on-male violence placebo

## Risks and Mitigations

- **RAIS data access:** If full microdata unavailable, use CAGED or Base dos Dados aggregates by municipality×sector×sex
- **SINAN underreporting:** Violence notifications grew dramatically over time (capacity expansion). Use cross-sectional RDD within years to avoid confounding with reporting trends. Also use SIM homicide data (hard outcome, less reporting bias).
- **Small municipalities:** Most FPM thresholds are at small population levels (10K-156K). Violence counts may be noisy. Use Poisson/negative binomial specification for count data.
