# Research Plan: Smoking Triggers Drinking? Cross-Substance Spillovers of State Cigarette Excise Taxes

## Research Question

Do state cigarette excise tax increases cause cross-substance spillovers to alcohol consumption? If so, is alcohol a complement (both decline) or a substitute (alcohol rises)?

## Background

Between 2001 and 2019, 49 US states enacted 143 cigarette excise tax increases ranging from $0.01 to $2.00/pack. Prior literature treats sin taxation of cigarettes and alcohol in isolation. The only prior study (Decker & Schwartz 2000, NBER WP 7535) used 2SLS with 1990s data, pre-dating modern staggered DiD methods. No study decomposes by beverage type or computes the cross-substance welfare adjustment.

## Identification Strategy

**Design:** Staggered DiD using Callaway-Sant'Anna (2021).

**Treatment:** First "large" state cigarette excise tax increase (>= $0.25/pack) during 2001-2019.

**Control groups:** Never-treated states (those that never had a large increase) and not-yet-treated states.

**Specification:**
- Group-time ATTs with event study at horizons -5 to +5 years
- Pre-trend test at leads -5 to -1
- Outcome: per capita ethanol consumption (total, beer, wine, spirits)

**Exposure alignment:** The treatment (state cigarette excise tax increase) directly affects all cigarette consumers within the state through higher prices at point of sale. The outcome (per capita alcohol consumption) is measured at the same geographic level (state) and time resolution (annual). The affected population is the state's adult population — both smokers (who face higher cigarette costs and may adjust alcohol consumption) and non-smokers (who are unaffected by the tax but contribute to the denominator). The per capita measure thus dilutes individual-level effects by the share of smokers (~15-20% of adults), meaning a 10% reduction in alcohol among smokers would appear as only a 1.5-2% aggregate decline. This dilution is a known limitation of state-level data but does not bias the estimate.

**Why this identifies a causal effect:**
1. Tax changes are legislative — staggered across states with heterogeneous timing
2. Tax increases respond to state fiscal needs, not alcohol market conditions
3. Long pre-period (data from 1970) establishes pre-trends
4. Never-treated states provide clean controls
5. Beverage decomposition tests competing mechanisms

## Data Sources

**Primary:**
1. NIAAA Surveillance Report #122 — state-level per capita ethanol consumption by beverage type (beer, wine, spirits, total), 1970-2023, all 50 states + DC
   - URL: https://www.niaaa.nih.gov/sites/default/files/pcyr1970-2023.txt
   - 12,225 lines

2. CDC Tax Burden on Tobacco — state cigarette excise tax rates, 2001-2019
   - API: https://data.cdc.gov/resource/7nwe-3aj9.json

## Expected Effects

**Complement hypothesis:** Cigarettes and alcohol are consumed jointly (bars, social settings). Higher cigarette prices reduce smoking occasions → reduce alcohol consumption. Effect should concentrate in beer (social/bar drinking).

**Substitute hypothesis:** Budget-constrained consumers facing higher cigarette costs substitute toward alcohol. Effect should be diffuse across beverage types.

**Null hypothesis:** Cross-substance elasticity is zero — sin goods are consumed independently.

## Robustness & Placebos

1. **Pre-trends:** Event study with 5 leads (should be flat)
2. **Dose-response:** Continuous treatment (tax change in $/pack) instead of binary
3. **HonestDiD:** Rambachan-Roth sensitivity to pre-trend violations
4. **Alternative thresholds:** $0.50, $0.75, $1.00 cutoffs for "large" increase
5. **Placebo outcome:** Total state population (should be unaffected)
6. **Bacon decomposition:** Verify clean TWFE weights

## Welfare Computation

Using estimated cross-elasticity and alcohol externality estimates ($2.05/drink, Bouchery et al. 2011), compute:
- Spillover-adjusted optimal cigarette tax: tau* = (smoking externality) + (cross-elasticity × drinking externality)
- Revenue implications of accounting for cross-substance effects

## Standardized Effect Size

SDE = beta × SD(tax_change) / SD(ethanol_consumption) for continuous treatment, or beta / SD(Y) for binary treatment.
