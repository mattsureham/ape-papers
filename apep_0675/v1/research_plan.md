# Research Plan: Taxing the Thermostat

## Research Question
What is the pass-through rate and household demand elasticity for carbon taxes on heating fuels across Europe? Is the €65-87B EU Social Climate Fund correctly calibrated?

## Identification Strategy

### A. Pass-Through Analysis
Event study around 5 staggered carbon tax introductions (Ireland 2010, France 2014, Portugal 2015, Germany 2021, Austria 2022). Treatment variable: tax wedge from Eurostat nrg_pc_202 (I_TAX minus X_TAX component). Outcome: total gas price. Country FE + half-year FE.

### B. IV Demand Elasticity
IV regression: log(gas consumption) on log(gas price), instrumenting with the tax component of the gas price. The tax component satisfies the exclusion restriction: set by policy, not demand conditions. Control for heating degree days (HDD) to isolate price from weather effects.

### C. Energy Poverty DiD
CS-DiD using carbon tax adoption timing. Outcome: share of households unable to keep home warm (ilc_mdes01). Heterogeneity by income quintile.

## Expected Effects
- Pass-through: 80-100% (taxes on inelastic goods typically pass through)
- Demand elasticity: -0.2 to -0.5 (short-run; heating is inelastic but not perfectly so)
- Energy poverty: positive effect, larger in lower-income countries

## Primary Specification
```
log(Q_it) = α + β·log(P_it) + γ·HDD_it + δ_i + θ_t + ε_it
```
IV: P_it instrumented by TAX_it

## Data Sources
1. **nrg_pc_202**: Gas prices for household consumers, semi-annual, 36 countries, 2007-2025. Decomposed: energy, network, taxes/levies.
2. **nrg_d_hhq**: Household gas consumption, annual, 2010-2023.
3. **ilc_mdes01**: Energy poverty indicator (inability to keep home warm), 2003-2025.
4. **nrg_chdd_a**: Heating degree days by country, annual.

## Treated Countries & Timing
| Country | Policy | Start | Rate |
|---------|--------|-------|------|
| Ireland | Carbon tax | 2010 | €15→48.50/tCO2 |
| France | CCE | 2014-H2 | €7→44.60/tCO2 (frozen 2019) |
| Portugal | Carbon tax | 2015 | €5-7/tCO2 |
| Germany | BEHG | 2021-H1 | €25→45/tCO2 |
| Austria | CO2 price | 2022-H1 | €30→55/tCO2 |

## Never-Treated Controls
Poland, Italy, Czech Republic, Romania, Hungary, Bulgaria, Slovakia, Croatia, Greece, Lithuania, Latvia, Estonia, Malta, Cyprus + non-EU (Serbia, Turkey, etc.)
