# Research Plan: The Oversight Premium — Council Size Thresholds and Infant Mortality in Brazil

## Research Question

Does increasing legislative representation causally reduce infant mortality? Brazil's Constitution mandates minimum city council sizes (vereadores) at sharp population thresholds, creating a multi-cutoff regression discontinuity design across 5,570 municipalities. This paper estimates the "oversight premium" — the marginal health return to additional legislative seats — using DATASUS vital statistics microdata on ~1.3M annual births.

## Identification Strategy

**Design:** Multi-cutoff RDD exploiting constitutional population thresholds that mechanically determine minimum council sizes.

**Institutional setting:** Brazilian Constitution Article 29, I (amended by EC 58/2009) sets minimum vereador counts by population brackets:
- ≤15,000: 9 seats
- 15,001–30,000: 11 seats
- 30,001–50,000: 13 seats
- 50,001–80,000: 15 seats
- 80,001–120,000: 17 seats
- 120,001–160,000: 19 seats
- 160,001–300,000: 21 seats
- 300,001–450,000: 23 seats
- 450,001–600,000: 25 seats
- Higher brackets continue up to 55 seats

**Running variable:** Municipal population from IBGE census/estimates (used by TSE for seat allocation).

**Treatment:** Additional council seats at each threshold. Municipalities just above a threshold receive 2 more vereadores than those just below.

**Key assumption:** Municipalities cannot precisely manipulate their IBGE population count at the threshold. Validated by McCrary density test at each cutoff.

## Expected Effects and Mechanisms

**Hypothesis 1 (Oversight channel):** More vereadores increase oversight of municipal health spending (Fundo Municipal de Saúde), leading to better primary care, prenatal coverage, and lower infant mortality. Effect: negative (fewer deaths).

**Hypothesis 2 (Fragmentation channel):** More vereadores create legislative gridlock, increase rent-seeking, and dilute accountability. Effect: null or positive (more deaths).

**Mechanism tests:**
- Municipal health expenditure per capita (SIOPS)
- Primary care coverage (Estratégia Saúde da Família)
- Prenatal visit adequacy (SINASC)
- Low birth weight incidence (placebo: should not respond to governance)

## Primary Specification

**Pooled multi-cutoff RDD:**
$$Y_{mt} = \alpha + \tau \cdot T_{mt} + f(Pop_{mt} - c_k) + \gamma_k + \epsilon_{mt}$$

Where:
- $Y_{mt}$: infant mortality rate in municipality $m$, year $t$
- $T_{mt}$: indicator for being above threshold $k$
- $f(\cdot)$: local polynomial in normalized population distance
- $\gamma_k$: cutoff fixed effects
- Standard bandwidth selection via Calonico, Cattaneo, Titiunik (2014)

**Individual cutoff estimates** for the 3-5 thresholds with sufficient observations within optimal bandwidth.

## Data Sources and Fetch Strategy

1. **DATASUS SIM** (Mortality Information System): Municipality-level infant deaths by year. FTP download from datasus.saude.gov.br.
2. **DATASUS SINASC** (Live Birth Information System): Municipality-level live births with prenatal care variables. Same FTP source.
3. **IBGE Population Estimates**: Annual municipal population estimates (2001-2020). API via sidrar R package or direct download.
4. **TSE Election Data**: Actual council sizes by municipality and election year. API download from dados.tse.jus.br.
5. **SIOPS** (Health Budget Transparency): Municipal health expenditure data. Download from sage.saude.gov.br.

**Period:** 2001-2020 (covering multiple election cycles: 2000, 2004, 2008, 2012, 2016, 2020).

## Robustness

1. McCrary density test at each threshold
2. Covariate balance at cutoffs (GDP per capita, urbanization, education)
3. Donut RDD (excluding ±1% of threshold)
4. Alternative bandwidths (50%, 100%, 150% of CCT optimal)
5. Placebo cutoffs at non-threshold population values
6. Individual vs. pooled cutoff estimates
7. Alternative polynomial orders (local linear, local quadratic)
