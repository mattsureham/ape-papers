# Research Plan: Graduating from the Tax Nursery

## Research Question

Romania repeatedly lowered its micro-enterprise turnover ceiling (EUR 1M → 500K → 250K → 100K), forcing graduation from a 1–3% turnover tax to the 16% corporate income tax (CIT). Each threshold reduction created a new bunching point where firms had incentives to suppress revenue. This paper estimates bunching at each successive threshold, quantifying the "graduation tax" — the implicit tax on growth created by discontinuous jumps in tax liability at the micro-enterprise ceiling.

## Policy Background

Romania's micro-enterprise regime taxes turnover at 1–3% (varying over time) instead of 16% CIT on profits. The regime applies to firms below a turnover ceiling that has changed multiple times:

| Year | Threshold (EUR) | Turnover Tax Rate | Key Change |
|------|-----------------|-------------------|------------|
| 2013–2015 | 65,000 | 3% | Low ceiling, narrow regime |
| 2016 | 100,000 | 3% → 1% (no employees), 2% (employees) | Rate cut + slight ceiling raise |
| 2017 | 500,000 | 1–3% (by employee count) | Major expansion |
| 2018 | 1,000,000 | 1% (≥1 employee), 3% (0 employees) | Peak expansion |
| 2020 | 1,000,000 | Mandatory for eligible firms | Made mandatory |
| 2023 | 500,000 | 1% (≤60 employees), 3% (0 employees) | Contraction begins |
| 2024 | 500,000 | 1% (1–49 employees), 3% (0 employees) | Further rate adjustments |

The key identifying variation: threshold changes at 100K, 500K, and 1M EUR create sharp incentives for firms near each boundary.

## Identification Strategy

**Method: Bunching estimation** (Kleven 2016; Chetty et al. 2011; Kleven and Waseem 2013)

At each threshold, firms face a discrete jump in effective tax rates upon "graduating" from the micro-enterprise regime to CIT. Rational firms bunch below the threshold to avoid graduation. The excess mass below the threshold relative to a counterfactual smooth distribution identifies the behavioral response.

**Key design features:**
1. **Multiple thresholds** across time provide internal replication
2. **Cross-country comparison** (Romania vs. peer EU countries without such regimes) validates that bunching is policy-driven
3. **Temporal variation** — firms that were below one threshold may be above a lower one after reform, creating a "forced graduation" natural experiment

## Data Strategy

### Primary: Eurostat Structural Business Statistics (SBS)
- Dataset: `sbs_sc_sca_r2` — Annual enterprise statistics by size class and NACE activity
- Turnover size classes align with Romanian thresholds: <50K, 50–100K, 100–250K, 250–500K, 500K–1M, 1M–2M
- Country-level panels 2008–2023 for Romania + EU comparators (Bulgaria, Hungary, Czech Republic, Poland)
- Variables: number of enterprises, turnover, value added, employment by size class

### Secondary: Eurostat Business Demography
- Dataset: `bd_9ac_l_form_r2` — Enterprise births, deaths, survival by size class
- Captures entry/exit responses (firms dying vs. splitting to stay below threshold)

### Tertiary: OECD Revenue Statistics
- Tax revenue by category for Romania — validates aggregate revenue implications of bunching

## Expected Effects

1. **Excess mass below threshold**: Firms bunch just below each micro-enterprise ceiling
2. **Missing mass above**: Deficit of firms in the bracket just above the threshold
3. **Asymmetric response to contraction vs. expansion**: When threshold drops (2023), firms that were previously "safe" must actively shrink — potentially larger real response than when threshold rises
4. **Heterogeneity by sector**: Service firms (more flexible revenue) should bunch more than manufacturing

## Primary Specification

For each threshold k in year t:
- Estimate counterfactual firm count distribution using polynomial fit to non-threshold brackets
- Calculate excess bunching ratio b = (actual − counterfactual) / counterfactual at the threshold bracket
- Standard errors via bootstrap over bracket counts

Cross-country triple-difference:
- Romania vs. peer countries × threshold bracket vs. non-threshold brackets × pre vs. post reform

## Robustness
1. Placebo thresholds at non-policy brackets
2. Alternative peer countries
3. Pre-trend tests on firm distributions before threshold changes
4. Donut-hole specifications excluding the threshold bracket
