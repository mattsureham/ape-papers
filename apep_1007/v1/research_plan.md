# Research Plan: Banking the Unbanked by Mandate

## Research Question

Did the EU Payment Accounts Directive (2014/92/EU) — which mandated basic bank accounts for all EU residents — causally increase financial inclusion? Or did the mandate merely formalize a convergence trend driven by fintech and mobile banking?

## Policy Background

Directive 2014/92/EU (PAD) was adopted in July 2014 with a transposition deadline of September 18, 2016. It requires every member state to ensure consumer access to a basic payment account with core features (direct debits, card payments, online banking) at reasonable cost.

**Key institutional feature**: Only 9 of 27 member states transposed on time. The remaining 18 faced European Commission infringement proceedings. Transposition dates span from August 2015 (France) to December 2017 (Romania, Spain). This staggered adoption creates the identifying variation.

**Never-treated controls**: Hungary, Czech Republic, Slovakia, and Slovenia had pre-existing basic account laws before the directive, serving as never-treated units.

## Identification Strategy

**Estimator**: Callaway-Sant'Anna (2021) group-time ATT, aggregated to dynamic event-study and overall ATT. This is the modern baseline for staggered DiD.

**Treatment**: Year of PAD transposition into national law, sourced from CELLAR SPARQL (national implementation measures with notification dates).

**Comparison groups**: Not-yet-treated and never-treated (HUN, CZE, SVK, SVN).

**Pre-treatment parallel trends**: Assessed via event-study coefficients and HonestDiD sensitivity analysis (Rambachan-Roth bounds).

**Clustering**: Country-level (conservative; ~24 clusters). Wild cluster bootstrap for robustness.

## Data Sources

### Primary Outcome: ECB Payment Statistics
- **Series**: Number of payment accounts per capita (annual, 2010-2024)
- **Source**: ECB Statistical Data Warehouse (SDW), SDMX REST API
- **Coverage**: All EU member states, annual frequency
- **Pre-periods**: 5-7 years depending on treatment cohort (sufficient for CS-DiD)

### Secondary Outcome: World Bank Global Findex
- **Series**: Account ownership % (FX.OWN.TOTL.ZS), 5 waves (2011, 2014, 2017, 2021, 2024)
- **Coverage**: 24 EU countries, 120 observations
- **Role**: Direct measure of account ownership; sparse but interpretable

### Treatment Variable: CELLAR SPARQL
- **Query**: National implementation measures for CELEX 32014L0092
- **Fields**: Country, notification_date, entry_into_force_date
- **Pre-existing laws**: HUN (2009), CZE (2010), SVK (2009), SVN (2012) → never-treated

### Mechanism / Higher-Frequency: ECB MIR
- **Series**: Monthly deposit rates by country (2012-2024)
- **Role**: Test whether new accounts changed deposit market competition

## Expected Effects and Mechanisms

**Primary hypothesis**: PAD transposition increases payment account holdings, particularly in countries with low baseline inclusion (Romania, Bulgaria, Greece).

**Mechanisms to test**:
1. **Extensive margin**: More people hold accounts (primary)
2. **Intensive margin**: Deposit rates change (competition effect)
3. **Heterogeneity**: Effect concentrated in low-baseline countries

**Named concept**: "The Mandate Gap" — the difference between having a legal right to a bank account and actually exercising it. If the mandate creates accounts but not usage, the policy creates formal inclusion without substantive inclusion.

## Primary Specification

```
Y_{ct} = α_c + α_t + τ^{g,t} · D_{ct} + ε_{ct}
```

Where:
- Y_{ct} = payment accounts per capita in country c, year t
- D_{ct} = 1 if country c has transposed PAD by year t
- τ^{g,t} = group-time ATT (Callaway-Sant'Anna)
- Clustered at country level

## Exposure Alignment

The treatment (PAD transposition) operates at the country level: once a member state transposes the directive into national law, all financial institutions in that country are required to offer basic payment accounts. The unit of observation in the Eurostat data is country-year, which aligns directly with the treatment assignment level. All individuals aged 16-74 within a country are equally exposed to the policy change, as the directive applies universally to all legal residents regardless of financial situation or nationality. The treatment is binary (transposed vs. not transposed) and absorbing (once transposed, the law remains in effect).

## Robustness Checks

1. **Placebo outcomes**: Internet usage for non-financial purposes (should not respond to PAD)
2. **Alternative estimator**: Sun-Abraham (sunab) for comparison
3. **HonestDiD sensitivity**: Bound effects under PT violations
4. **Wild cluster bootstrap**: Given ~24 clusters
5. **Leave-one-out**: Drop each major country to check sensitivity
6. **Pre-existing law countries**: Test that never-treated show no effect at the directive deadline

## Feasibility Assessment

- **Treated units**: ~20 countries (exceeds 20-unit minimum)
- **Pre-periods**: 5-7 years with ECB data (exceeds 5-period minimum)
- **Data access**: All sources open, no API keys required
- **Novelty**: No published causal evaluation of PAD exists
- **Policy relevance**: Informs global financial inclusion mandates (India Jan Dhan, US BankOn)
