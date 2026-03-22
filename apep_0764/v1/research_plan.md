# Research Plan: The Formalization Paradox — Intermittent Contracts, Worker Welfare, and Brazil's 2017 Labor Reform

## Research Question

Brazil's 2017 labor reform (Lei 13.467/2017) introduced intermittent contracts ("trabalho intermitente") — formal employment with no guaranteed minimum hours. By 2022, over 600,000 workers held intermittent contracts, representing a dramatic expansion of formal employment. But at what cost? Intermittent workers earn ~35% less than regular formal workers and work ~40% fewer hours. Does formalizing workers through flexible contracts actually improve their economic welfare, or does it create a new underclass of formally employed but precariously positioned workers?

This paper estimates the causal effect of intermittent contract adoption on municipality-level labor market outcomes using a sector-intensity difference-in-differences design.

## Identification Strategy

**Sector-Intensity DiD (Bartik-style).** The reform was national (all sectors, all municipalities, same date: November 11, 2017), but adoption of intermittent contracts varied dramatically across sectors due to differences in production technology and labor demand patterns. Air transport adopted at 4.3% of hirings; agriculture at 0.2% — a 30x variation.

**Treatment variable:** Municipality-level exposure = employment-weighted average of 2019 CNAE 2-digit sector intermittent adoption rates, using pre-reform (2016) employment structure as weights. This yields 5,532 municipalities with exposure scores ranging from 0.08% to 2.64%.

**Event study specification:**
$$Y_{mt} = \alpha_m + \gamma_t + \sum_{k \neq 2016} \beta_k \cdot \text{Exposure}_m \times \mathbb{1}(t = k) + \varepsilon_{mt}$$

where $Y_{mt}$ is the outcome in municipality $m$ and year $t$, $\alpha_m$ are municipality FEs, $\gamma_t$ are year FEs. We expect $\beta_k \approx 0$ for $k \in \{2014, 2015\}$ (pre-trends) and non-zero effects for $k \geq 2018$.

**Key identification assumptions:**
1. Pre-reform (2016) sector composition is predetermined
2. Sectors with different intermittent adoption rates would have had parallel trends absent the reform
3. No municipality-level confounders correlated with sector composition that affect outcomes differentially post-2017

**Validation:**
- Event study pre-trend coefficients
- Placebo: use pre-reform sector growth rates as alternative "exposure" — should show no effects
- Robustness to excluding top/bottom exposure municipalities
- Alternative clustering (state-level)

## Expected Effects and Mechanisms

**Primary outcomes (municipality-year level from RAIS):**
1. Average formal wages → Expected: negative (composition effect from lower-paid intermittent workers)
2. Formal employment count → Expected: positive (formalization of previously informal workers)
3. Share of workers with intermittent contracts → Expected: positive (mechanical)

**Mechanism decomposition:**
- Composition effect: new intermittent workers pull down average wages
- Spillover effect: regular formal workers also affected (competitive pressure)
- Substitution effect: intermittent contracts displace informal employment

**Secondary outcomes (from IBGE SIDRA / PNAD Contínua):**
- Informality rate → Expected: negative (substitution from informal to formal)
- Total employment → Expected: ambiguous (depends on whether new formal = net new or substitution)

## Primary Specification

Cross-sectional Bartik DiD at municipality-year level:

$$\ln(\text{AvgWage}_{mt}) = \alpha_m + \gamma_t + \beta \cdot \text{Exposure}_m \times \text{Post}_t + X'_{mt}\delta + \varepsilon_{mt}$$

- Clustering: state level (27 states)
- Alternative: municipality clusters with Conley SEs for spatial correlation
- Weight: pre-reform municipality employment

## Data Sources and Fetch Strategy

### Primary: RAIS via Google BigQuery
- Table: `basedosdados-dev.br_me_rais.microdados_vinculos`
- 2.07 billion worker-year records, 2010-2022
- Query: aggregate to municipality-CNAE-year cells (average wage, employment count, intermittent share)
- Access: BigQuery ADC credentials (project: scl-librechat)

### Secondary: IBGE SIDRA API
- PNAD Contínua quarterly labor force data
- Table 4097: state-quarter employment by formality status
- API endpoint: `https://apisidra.ibge.gov.br/`

### Geographic: Municipality crosswalks
- IBGE municipality codes (5,570 municipalities)
- State-municipality mapping for clustering

## Hardware Considerations
- BigQuery queries aggregate before download (no need to process 2B rows locally)
- Final dataset: ~5,532 municipalities × 13 years = ~72K rows
- Well within memory constraints
