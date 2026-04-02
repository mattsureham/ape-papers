# Research Plan: The Digital Border Dividend — Estonia's e-Residency and Cross-Border Firm Formation

## Research Question

Does eliminating administrative border costs through digital governance infrastructure causally increase firm formation, or does it merely relocate existing entrepreneurial activity? Estonia's December 2014 launch of the world's first e-Residency program — allowing non-citizens to register and manage Estonian firms fully online for EUR 100 — provides a unique natural experiment.

## Identification Strategy

### Primary: Augmented Synthetic Control Method (ASCM)

Single-treated-unit design with Estonia as the treated unit and a donor pool of 8–9 European small open economies (Latvia, Lithuania, Finland, Czech Republic, Poland, Denmark, Sweden, Norway). Pre-treatment period: 2006–2014. Post-treatment: 2015–2022.

**Why SCM over simple DiD:** With N=1 treated unit, standard clustered inference is impossible. SCM provides a data-driven counterfactual and permutation-based inference (placebo tests reassigning treatment to each donor country).

### Secondary: Baltic DiD

Estonia vs Latvia and Lithuania (2006–2022). Pre-2014 parallel trends justified by shared EU accession (2004), similar post-Soviet institutional development, and synchronized business cycles. This provides a transparent robustness check on the SCM results.

### Mechanism Decomposition

Using e-Residency Dashboard aggregate statistics, decompose total Estonian firm formation into:
1. **e-Resident firms** (~20% of new registrations by 2024)
2. **Domestic firms** (remaining registrations)

If the effect is pure relocation, we should see (a) no increase in domestic firms and (b) declines in neighbor registrations proportional to Estonian gains. If the effect is net creation (the "digital border dividend"), domestic firms should be flat or rising and neighbor declines should be smaller than Estonian gains.

## Expected Effects

- **Large positive effect** on total Estonian business density (smoke test: +54%)
- **Moderate positive** on domestic firm formation (digital infrastructure spillovers)
- **Small negative or null** on neighbor business density (limited displacement)
- **Mechanism:** e-Resident firms account for most of the divergence, but domestic spillovers exist through ecosystem effects (fintech, service providers)

## Primary Specification

$$Y_{it} = \alpha_i + \lambda_t + \delta \cdot \text{Post}_t \cdot \text{Estonia}_i + \epsilon_{it}$$

Where $Y_{it}$ is new business registration density (per 1,000 working-age population) in country $i$ and year $t$. For SCM: minimize pre-treatment RMSPE using business density, GDP per capita, trade openness, internet penetration, and regulatory quality as predictors.

## Data Sources

1. **World Bank World Development Indicators (API)**
   - `IC.BUS.NDNS.ZS`: New business density (per 1,000 working-age pop), 2006–2022
   - `IC.BUS.NREG`: New business registrations (absolute), 2006–2022
   - Covariates: GDP per capita (`NY.GDP.PCAP.KD`), trade openness (`NE.TRD.GNFS.ZS`), internet users (`IT.NET.USER.ZS`), regulatory quality (`RQ.EST`)

2. **Estonia e-Residency Dashboard** (public aggregate statistics)
   - Total e-residents, firms created, revenue generated
   - Annual or quarterly breakdowns

3. **Statistics Estonia PxWeb API**
   - Enterprise stock by county/size (ER028)

## Robustness

1. **Placebo SCM:** Reassign treatment to each donor country; Estonia should have the largest post-treatment gap
2. **Pre-treatment balance:** Compare pre-trend RMSPE ratios
3. **Leave-one-out SCM:** Drop each donor to check sensitivity
4. **Alternative outcomes:** GDP per capita, employment rate (should show smaller or null effects — e-Residency firms are often shell-like)
5. **Alternative treatment dates:** Placebo tests at 2012 and 2013

## Exposure Alignment

The treatment (e-Residency program) applies uniformly to the entire country of Estonia from December 2014. All potential firm registrants — both Estonian residents and foreign nationals — are exposed. The treatment is measured at the country-year level, matching the outcome's unit of observation (country-year business density). There is no sub-national or firm-level treatment variation; the design exploits cross-country variation between Estonia (fully treated post-2014) and control countries (untreated). The outcome (new business density per 1,000 working-age population) directly captures the margin the policy targets: administrative barriers to firm creation.

## Key Risks

- **Small N:** Mitigated by SCM + permutation inference
- **Concurrent reforms:** Estonia had other digital governance initiatives (X-Road, digital ID). Addressed by noting these predate 2014 and show no pre-trend break
- **Measurement:** World Bank data may include e-Resident firms mechanically. Decomposition addresses this
- **External validity:** Estonia is uniquely digital-native; mechanism may not generalize
