# Research Plan: Taxing Banks, Starving Firms

## Research Question

Did Hungary's 2010 bank levy — the largest in the EU at 0.7% of GDP — cause a collapse in private credit supply? If so, what was the credit supply multiplier: how many forints of lost credit resulted from each forint of levy revenue?

## Policy Setting

**Act XC of 2010** (September 2010): Progressive bank levy on adjusted total assets.
- 0.15% on the first HUF 50 billion of adjusted assets
- 0.53% on assets exceeding HUF 50 billion
- Revenue: ~HUF 180 billion/year (~0.7% of GDP)
- Motivation: Pure fiscal extraction (post-crisis revenue), not Pigouvian risk tax
- 2013: MNB launches Funding for Growth Scheme (FGS) — zero-cost SME refinancing as countermeasure
- 2016: Levy halved

## Identification Strategy

**Cross-country Difference-in-Differences** with monthly frequency.

- **Treatment:** Hungary (September 2010 bank levy introduction)
- **Controls:** Czech Republic, Poland, Slovakia, Austria — similar post-crisis trajectories, no comparable bank levy
- **Data:** ECB Balance Sheet Items (BSI) statistics — monthly outstanding NFC loans by country, 2005-2020
- **Backup:** World Bank domestic credit to private sector (% GDP), annual

### Why this works:
1. Sharp treatment timing (September 2010, legislated in months)
2. Monthly data enables precise event study with 60+ pre-periods
3. Control countries share EU/CEE institutional framework, similar post-GFC recovery path
4. Two built-in reversal tests: FGS (2013) and levy halving (2016)

### Key threats:
1. **N=1 treated country** — address with SCM, permutation/placebo tests, leave-one-out
2. **Concurrent shocks** — Hungary had IMF program (2008-2010), but this preceded the levy; EU sovereign debt crisis affected periphery more than CEE
3. **Demand vs supply** — the levy directly taxes bank assets (supply-side), but we cannot fully separate demand. FGS reversal (supply-side intervention) helps: if credit rebounds after FGS, supply channel is validated.

## Expected Effects

- **Primary:** Large negative effect on NFC credit outstanding (Hungary vs controls)
- **Mechanism test:** Credit rebounds after 2013 FGS (supply-side intervention)
- **Second reversal:** Partial recovery after 2016 levy halving
- **Magnitude:** Idea manifest documents 45% credit/GDP collapse vs steady growth in controls

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot \text{HU}_c \times \text{Post}_t + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: log outstanding NFC loans in country $c$, month $t$
- $\alpha_c$: country fixed effects
- $\gamma_t$: month fixed effects
- $\text{HU}_c$: indicator for Hungary
- $\text{Post}_t$: indicator for September 2010 onward

Event study variant with leads and lags for pre-trend assessment.

## Data Sources

1. **ECB Statistical Data Warehouse (SDW)** — BSI series: outstanding amounts, loans to NFCs, by country. SDMX REST API, no auth required.
2. **World Bank Development Indicators** — Domestic credit to private sector (% GDP). Annual. API, no auth.
3. **Eurostat** — GDP, bank assets, financial services confidence. JSON-stat API via `eurostat` R package.

## Robustness

1. Synthetic Control Method (SCM) using `Synth` or `augsynth`
2. Permutation/placebo tests: assign treatment to each control country
3. Leave-one-out: drop each control country
4. Alternative outcome: total domestic credit (not just NFC loans)
5. Alternative normalization: credit/GDP instead of log levels
6. FGS reversal as "anti-treatment" validation

## Feasibility Assessment

- **Data confirmed:** ECB BSI publicly available via SDMX API
- **Sample size:** 5 countries × 180 months = 900 country-months
- **Treated units:** 1 (Hungary) — acknowledged limitation, mitigated by design
- **Pre-periods:** 60+ months (2005-2010)
- **Effect size:** Enormous (45% relative to controls) — statistical power not a concern
