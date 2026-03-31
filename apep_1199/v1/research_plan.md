# Research Plan: Privatizing the Pipes

## Research Question

Does privatizing municipal water and sanitation services reduce waterborne disease hospitalizations? Brazil's 2020 Marco Legal do Saneamento (Law 14,026) triggered the largest sanitation privatization wave in history, shifting 350+ municipalities from public to private providers between 2020 and 2022. We estimate the causal effect on waterborne disease hospitalizations (ICD-10 A00-A09) using Callaway-Sant'Anna staggered DiD.

## Identification Strategy

**Treatment:** Municipality's first year under a private sanitation provider, identified from SNIS provider data transitions (natureza_juridica field shifting from public to private legal entity).

**Staggered timing from BNDES block auctions:**
- Wave 1: Alagoas Block A (Sep 2020) — 13 municipalities
- Wave 2: CEDAE/Rio de Janeiro (Apr 2021) — 29 municipalities
- Wave 3: Corsan/Rio Grande do Sul (Dec 2022) — 317 municipalities

**Key identifying assumption:** Parallel trends in waterborne disease hospitalization rates between privatized and never-privatized municipalities, conditional on municipality and year fixed effects. The BNDES block auction structure strengthens this — municipalities were bundled into regional blocks for competitive bidding, limiting individual municipality selection into treatment timing.

**Threats and responses:**
1. COVID confounding (law passed July 2020): Year FE absorb common COVID shocks; robustness check on Corsan-only 2022 subsample (post-COVID)
2. Selection into privatization: Block auctions bundled municipalities; balance tests on pre-treatment covariates
3. Anticipation effects: Allow for 1-year anticipation in CS estimator

## Expected Effects and Mechanisms

**Primary hypothesis:** Privatization reduces waterborne disease hospitalizations through increased capital investment in water treatment and sewage infrastructure.

**Mechanism chain:**
1. Privatization → increased investment (testable via SNIS investment data)
2. Investment → improved service quality (testable via sewage collection/treatment rates)
3. Better service → fewer waterborne diseases (primary outcome)

**Heterogeneity:** Under-5 children most vulnerable to waterborne disease — expect larger effects for youngest age groups.

**Effect direction:** Based on Galiani, Gertler & Schargrodsky (2005) finding that Argentine water privatization reduced child mortality by 5-7%, we expect a negative effect (reduction in hospitalizations), likely moderate (SDE -0.05 to -0.15).

## Primary Specification

Callaway-Sant'Anna (2021) staggered DiD:
- Unit: municipality (i)
- Time: year (t), 2015-2023
- Treatment: first year of private provider
- Outcome: waterborne disease hospitalization rate per 100K population
- Comparison group: not-yet-treated + never-treated
- Clustering: municipality level
- Pre-periods: 5-6 years (2015-2020 depending on cohort)

## Exposure Alignment

Treatment is assigned at the municipality level (the same unit as the outcome). A municipality's sanitation provider is a municipal-level service — water distribution networks and sewage collection systems are municipality-specific infrastructure. The BNDES block auctions transferred the entire water and sanitation concession for each municipality in the block. Therefore, the treatment unit (municipality's provider status) maps directly to the outcome unit (municipality-level hospitalization rate). All residents of a privatized municipality are exposed to the new private operator's water and sewage services, and the hospitalization outcome is measured by patient's municipality of residence.

## Data Sources

1. **DATASUS SIH** (BigQuery: `basedosdados.br_ms_sih.aihs_reduzidas`): 207M hospital records 2009-2025. Filter to ICD-10 A00-A09 (intestinal infectious diseases). Aggregate to municipality-year waterborne hospitalization counts.

2. **SNIS Provider Data** (BigQuery: `basedosdados.br_mdr_snis.prestador_agua_esgoto`): 125K rows 1995-2022. Identifies provider legal nature (public/private) and investment data. Used to construct treatment variable and mechanism tests.

3. **IBGE Municipal Population** (BigQuery or IBGE API): Municipality-year population for rate construction.

## Fetch Strategy

All three datasets accessible via Google BigQuery with existing ADC credentials. Query plan:
1. Query SNIS for provider transitions (identify treatment timing)
2. Query DATASUS SIH for waterborne hospitalizations by municipality-year
3. Query IBGE population estimates
4. Merge and construct analysis panel in R
