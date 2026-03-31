# Research Plan: The Absorption Shock — Housing Lotteries and School Quality in Brazil's MCMV Program

## Research Question

When large subsidized housing projects deliver thousands of new residents to peripheral urban neighborhoods, what happens to school quality in receiving communities? Brazil's Minha Casa Minha Vida (MCMV) Faixa 1 program allocated 6.1 million housing units through municipal lotteries across 58,000+ projects (2009–2023), creating sudden enrollment shocks in nearby schools. We ask whether these lottery-induced population influxes improved or degraded educational quality — measured by IDEB scores (a composite of standardized test performance and pass rates) — in schools that absorbed the new arrivals.

## Identification Strategy

**Municipality-level staggered DiD.** Treatment is defined as a municipality receiving its first large MCMV Faixa 1 project delivery (≥500 units) in year *t*. The staggered rollout across ~5,500 municipalities provides identifying variation.

- **Pre-period:** 2005–2007 IDEB waves (before MCMV launch in 2009)
- **Post-period:** 2009–2023 IDEB waves
- **Estimator:** Callaway & Sant'Anna (2021) — heterogeneity-robust, avoids TWFE pitfalls
- **Clustering:** Municipality level
- **Dose-response:** Continuous treatment version using log(units delivered) as treatment intensity

## Expected Effects and Mechanisms

**Primary hypothesis:** MCMV deliveries reduce school quality in receiving neighborhoods through a **dilution mechanism** — sudden enrollment increases strain fixed school resources (teachers, infrastructure, materials) without proportional increases in inputs.

**Alternative mechanisms:**
1. **Composition effect:** New residents may come from lower-SES backgrounds, mechanically lowering average scores without changing school effectiveness
2. **Peer effects:** Concentrated poverty from Faixa 1 residents may generate negative peer spillovers
3. **Supply response:** Municipalities may respond by hiring teachers or building new schools, potentially offsetting dilution

**Direction:** Expect moderate negative effects on IDEB scores (SDE ~ −0.05 to −0.15), larger in municipalities with smaller initial school networks.

## Primary Specification

Y_{it} = α_i + γ_t + β · MCMV_Treated_{it} + X'_{it}δ + ε_{it}

Where:
- Y_{it} = average IDEB score for municipality *i* in wave *t*
- MCMV_Treated_{it} = 1 if municipality *i* received ≥500 MCMV Faixa 1 units by wave *t*
- α_i = municipality FEs
- γ_t = wave FEs
- X_{it} = time-varying controls (log enrollment, teacher-student ratio)

## Data Sources and Fetch Strategy

1. **IDEB scores** — BigQuery: `basedosdados.br_inep_ideb.escola` (2005–2023, ~80K schools/wave)
2. **Censo Escolar** — BigQuery: `basedosdados.br_inep_censo_escolar.escola` (enrollment, teachers, infrastructure)
3. **MCMV project data** — dadosabertos.cidades.gov.br (58,300+ projects with municipality codes, delivery dates, unit counts)

**Merge strategy:** Municipality code (código IBGE) links all three datasets.

## Exposure Alignment

Treatment is defined at the municipality level: a municipality is "treated" in the IDEB wave when it has received its first MCMV FAR contract. The treated population is all public school students in the municipality. The outcome (municipality-average IDEB) captures the aggregate effect on the school system. This design measures the intent-to-treat effect of MCMV contracting on city-wide school quality, not the local effect on schools immediately adjacent to housing projects. The municipality-level aggregation dilutes localized enrollment shocks, so estimated effects represent an upper bound on the aggregate null and a lower bound on neighborhood-specific impacts.

## Robustness Checks

1. Event-study plot with pre-trend coefficients
2. Callaway-Sant'Anna vs. stacked DiD comparison
3. Leave-one-out jackknife by state
4. Placebo: private schools (less affected by enrollment shocks from Faixa 1 population)
5. Dose-response: log(units) as continuous treatment
6. Heterogeneity: small vs. large municipal school networks
