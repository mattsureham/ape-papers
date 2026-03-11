# Initial Research Plan: The Erasmus Drain

## Research Question
Does the Erasmus+ programme's expansion exacerbate regional human capital divergence within the EU? Specifically, do NUTS2 regions with historically high net Erasmus outflows experience declining tertiary-educated population shares and weaker youth labor market outcomes when the programme budget doubles?

## Identification Strategy
**Shift-share (Bartik) instrumental variable** following Borusyak, Hull, and Jaravel (2022).

- **Unit of observation:** NUTS2 region × year (approximately 230 regions, 2014–2022)
- **Endogenous variable:** Net Erasmus outflow rate (outflows minus inflows per 1,000 population aged 20–29)
- **Instrument:** Z_i,t = Σ_j s_{ij,0} × G_{j,t}
  - s_{ij,0} = pre-period (2014–2016) share of region i's total Erasmus outflows directed to destination j
  - G_{j,t} = total Erasmus inflows to destination j in year t (leave-one-out: excluding flows from region i)
- **Fixed effects:** NUTS2 region FE + year FE (panel specification)
- **Clustering:** Two-way by NUTS2 region and year; also report Conley spatial HAC

### Exclusion Restriction
Destination regions' Erasmus absorption growth is driven by university capacity, institutional agreements, and the EU-wide budget doubling — not by labor market conditions in each specific sending region. The leave-one-out construction (BHJ 2022) removes mechanical correlation between region i's own flows and the instrument.

### Exposure Alignment
- **Who is treated:** Young adults (18–30) who participate in Erasmus+ mobility from their home region
- **Primary estimand population:** NUTS2 working-age population aged 25–34 (post-Erasmus age)
- **Placebo/control population:** Older cohorts (35–64) whose human capital stock predates the Erasmus expansion
- **Design:** IV panel regression (not DiD), exploiting continuous cross-regional variation in predicted Erasmus exposure

## Expected Effects and Mechanisms
1. **Primary:** Regions with higher predicted net outflows see declining tertiary education shares among 25–34 year-olds (brain drain)
2. **Mechanism — non-return:** If students don't return after Erasmus, the sending region permanently loses human capital
3. **Mechanism — labor market:** Reduced human capital → lower youth employment and labor force participation
4. **Heterogeneity:**
   - Effects concentrated in peripheral regions (Southern Italy, Eastern Poland, rural Romania) with fewer pull-back factors
   - Effects larger in regions with lower GDP per capita (fewer reasons to return)
   - Effects larger for net-sending vs. net-receiving regions

## Primary Specification
Y_{it} = α_i + λ_t + β · NetOutflow_{it} + X_{it}'γ + ε_{it}

Instrumented with Z_{it}. Two-way clustered SEs (region + year).

## Data Sources
1. **Erasmus flows:** Zenodo DOI 10.5281/zenodo.16737523 — 2.2M movements, NUTS3-geolocated, 2014–2023
2. **Outcomes:** Eurostat — tertiary education share (edat_lfse_04), employment (lfst_r_lfe2emp), LFP (lfst_r_lfp2act) at NUTS2
3. **Controls:** Eurostat — GDP per capita (nama_10r_2gdp), population (demo_r_pjanaggr3)

## Planned Robustness Checks
1. Leave-one-out Bartik (BHJ 2022) — equivalent shock-level regression
2. Placebo: older cohorts (35–64) — should show null effect
3. Pre-trend test: instrument should not predict pre-period outcome changes
4. Randomization inference: permute destination growth shocks across destinations
5. Alternative pre-period windows (2014–2015 vs. 2014–2017)
6. Exclude COVID years (2020–2021) as robustness
7. Conley spatial HAC standard errors (various distance cutoffs)
8. Overidentification: split destinations into EU15 and EU13 sub-instruments

## Power Assessment
- 230 NUTS2 regions × 9 years = ~2,070 region-year observations
- Treatment is continuous (not binary), so MDE depends on instrument strength
- Budget doubling provides a large shock (78% increase in programme funding)
- Pre-period bilateral structure is well-established (6 years pre-treatment)
- Expected F-statistic > 10 given the strong first stage from bilateral network variation
