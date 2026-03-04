# Initial Research Plan — apep_0506

## Research Question

Does electing a wealthier politician cause better or worse local economic development? We exploit the quasi-random assignment of close elections in Indian state assemblies where candidates with substantially different wealth levels barely win or lose.

## Identification Strategy

**Design:** Sharp regression discontinuity at the vote margin = 0 threshold.

For each constituency-election (2004–2024), we identify the top-2 vote-getters, determine who is wealthier using mandatory affidavit data, and define the running variable as the vote margin of the wealthier candidate. When this margin is positive, the wealthier candidate won; when negative, the poorer candidate won. The sharp discontinuity at zero identifies the causal effect of electing the wealthier candidate.

**Key assumptions:**
1. No precise manipulation at the threshold (standard McCrary test)
2. Potential outcomes are continuous at the threshold
3. Local randomization: all covariates are balanced at the cutoff

## Expected Effects and Mechanisms

**Ambiguous sign (genuinely uncertain):**

- **Resource channel (+):** Wealthy politicians have connections, self-fund visible projects, attract private investment
- **Elite capture channel (−):** Wealthy politicians redirect spending to own interests, less responsive to poor voters
- **Competence channel (+/−):** Business experience may improve governance, but inherited wealth may signal no skill premium
- **Corruption channel (?):** May need to steal less (already rich) or steal more (better at it)

The theoretical ambiguity is a feature: the sign of the effect discriminates between competing models of political selection and accountability.

## Primary Specification

```
Y_{c,t+k} = α + β · 1(WealthierWins_c,t) + f(Margin_c,t) + γ_s + δ_t + ε_{c,t}
```

Where:
- Y = outcome (nightlights, MGNREGA spending, education metrics)
- c = constituency, t = election year, k = years after election (1–5)
- 1(WealthierWins) = indicator that the wealthier of the top-2 candidates won
- f(Margin) = flexible polynomial/local linear in running variable
- γ_s = state fixed effects, δ_t = election year fixed effects

**Bandwidth:** MSE-optimal (Calonico, Cattaneo, Titiunik 2014). Report sensitivity across multiple bandwidths (±2%, ±5%, ±10%).

**Inference:** Robust bias-corrected confidence intervals (rdrobust package in R).

## Planned Robustness Checks

1. **McCrary density test:** No manipulation at the cutoff
2. **Covariate balance:** Party, criminality, education, incumbency smooth at cutoff
3. **Placebo cutoffs:** Test at ±2%, ±5% (should find null)
4. **Placebo outcomes:** Rainfall, temperature (should find null)
5. **Bandwidth sensitivity:** Half, double, and CCT-optimal
6. **Polynomial order:** Local linear, local quadratic
7. **Donut RDD:** Exclude observations within ±0.5% margin
8. **Subsample stability:** By state, by decade, by party configuration
9. **Alternative wealth measures:** Log assets, wealth ratio, wealth rank
10. **Controlling for confounders:** Party FE, criminal status, education

## Outcome Categories (Multi-Margin)

| Category | Measure | Source | Coverage |
|----------|---------|--------|----------|
| Economic activity | Nightlights (DMSP/VIIRS) | NOAA | Annual, 1992–2021 |
| Government spending | MGNREGA expenditure, person-days | nrega.nic.in | 2006–present |
| Education | School enrollment, infrastructure | UDISE+ | 2012–present |
| Rent-seeking | Winner asset growth (next election affidavit) | MyNeta | 2004–present |
| Political | Re-election probability, vote share change | Lok Dhaba | 2004–present |

## Data Sources

1. **Lok Dhaba (TCPD):** State assembly election results — candidate name, constituency, votes, party. Download as CSV.
2. **MyNeta.info (ADR):** Candidate affidavits — total assets, liabilities, movable/immovable property, criminal cases, education. Scrape or use existing GitHub datasets.
3. **NOAA DMSP/VIIRS:** Annual nightlights composites for constituency-level aggregation.
4. **DataMeet/ECI:** Assembly constituency boundary shapefiles for GIS aggregation.
5. **MGNREGA MIS (nrega.nic.in):** Block/GP-level expenditure data.
6. **UDISE+ (udiseplus.gov.in):** School-level education data.

## Power Assessment

- ~4,120 state assembly constituencies × ~4–5 election cycles (2004–2024) = ~20,000 constituency-elections
- Close elections (|margin| < 5%): ~3,000–4,000 observations
- Within CCT-optimal bandwidth: ~1,000–2,000 observations
- Prakash et al. (2019 JDE) published with ~1,200 observations in a similar design
- Estimated MDE with N=1,500 near cutoff: ~0.05–0.10 SD in nightlights
