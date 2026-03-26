# Research Plan: State UI Duration Cuts and the Education Gradient in Re-employment Wages

## Research Question

Do state-level reductions in maximum unemployment insurance benefit duration (2011–2014) induce faster re-employment at lower wages for less-educated workers relative to more-educated workers? This tests whether UI duration moral hazard operates through replacement-rate incentives (stronger for low-education) or through optimal search/human-capital-depreciation channels (stronger for high-education).

## Identification Strategy

**Staggered difference-in-differences** using Callaway and Sant'Anna (2021).

- **Treatment:** Seven states cut maximum UI benefit duration from 26 weeks to 12–23 weeks between 2011 and 2014: Florida (July 2011, 12–23 weeks), South Carolina (June 2011, 20 weeks), Missouri (July 2011, 20 weeks), Michigan (August 2011, 20 weeks), Georgia (July 2012, 14–20 weeks), North Carolina (July 2013, 12–20 weeks), Arkansas (January 2014, 16 weeks).
- **Control:** 43 states maintaining 26-week maximum throughout the sample period.
- **Unit of observation:** State × education group × quarter.
- **Triple-difference:** State cut × education level (≤HS vs. BA+) × time, to test the education gradient.

**Key assumption:** Absent the duration cuts, employment and earnings trends would have evolved in parallel across cut and non-cut states, within education groups.

## Expected Effects and Mechanisms

1. **Moral hazard channel (Chetty 2008):** If UI duration primarily subsidizes continued search, cutting duration forces faster job acceptance. Less-educated workers face higher replacement rates → stronger incentive distortion → larger response to cuts. Prediction: larger employment gains and wage declines for ≤HS group.

2. **Human capital depreciation channel (Schmieder et al. 2016):** If longer UI allows better match quality by preventing skill decay, cutting duration may hurt more-educated workers whose skills are more match-specific. Prediction: larger wage declines for BA+ group.

3. **Liquidity constraint channel (Chetty 2008):** Less-educated workers are more liquidity-constrained, so duration cuts may force premature job acceptance regardless of moral hazard. This amplifies the education gradient.

## Primary Specification

$$Y_{s,e,t} = \alpha_{s,e} + \gamma_{e,t} + \sum_k \beta_k^e \cdot \mathbb{1}[t = G_s + k] + \varepsilon_{s,e,t}$$

where $s$ indexes states, $e$ education groups, $t$ quarters, and $G_s$ is the treatment quarter for cutting states. Callaway-Sant'Anna group-time ATTs aggregated to event-study coefficients by education group.

**Outcomes:**
- Average monthly earnings for new hires (EarnHirAS)
- Hire rate (HirA / total employment)
- Separation rate
- Full-quarter employment stability

**Clustering:** State level (50 clusters).

## Data Source and Fetch Strategy

**Primary data:** QWI Sex × Education panel from Azure Blob Storage.
- Path: `az://apepdata/derived/qwi/se/ns/*.parquet`
- 356K+ rows, covering state × quarter × education × sex × NAICS sector
- Coverage: 2009–2020 (pre/post window for all 7 cut states)

**Treatment coding:** From DOL UI Significant Provisions reports and NELP policy tracker. Exact effective dates for each state's duration cut.

**Covariates:** State unemployment rate (FRED/BLS), state GDP growth, industry composition.

## Robustness

1. Event-study pre-trend tests (unconditional)
2. HonestDiD/Rambachan-Roth sensitivity analysis
3. Wild cluster bootstrap (7 treated clusters)
4. Leave-one-out (drop each cutting state)
5. Placebo: states that considered but did not pass UI cuts
6. Alternative control groups: not-yet-treated vs. never-treated
7. Dose-response: larger cuts (NC, FL: 12 weeks) vs. smaller cuts (MI, MO: 20 weeks)
