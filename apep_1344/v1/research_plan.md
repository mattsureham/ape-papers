# Research Plan: The Potency Arms Race

## Research Question

Did generic manufacturer competition on opioid *potency* — specifically Mallinckrodt's 2008 launch of high-dose immediate-release oxycodone (20mg, 40mg, 80mg) — drive county-level potency escalation and overdose mortality? The opioid economics literature treats generic supply as a homogeneous volume problem. This paper shows that manufacturers competed on product variety and dose strength, and that this "potency arms race" propagated differentially through pre-existing distributor-manufacturer supply chain relationships.

## Identification Strategy

**Shift-share (Bartik) IV.**

- **Share:** County-level Mallinckrodt market share in oxycodone in 2006 (pre-expansion). Determined by which distributors served each county and those distributors' pre-existing purchasing relationships with Mallinckrodt. In 2006, Mallinckrodt sold only 5 oxycodone strengths (all ≤30mg), so the pre-period share reflects logistics/distribution infrastructure, not high-dose demand.

- **Shift:** Mallinckrodt's national product line expansion in 2007-2008, adding 20mg, 40mg, and 80mg immediate-release oxycodone formulations. This was a corporate headquarters decision driven by generic market strategy, not county-level conditions.

- **First stage:** Counties with higher 2006 Mallinckrodt oxycodone share experienced larger increases in average pill potency (MME/pill). The smoke test shows monotonic quintile spreads: Q1=−2.51, Q2=−1.76, Q3=−0.73, Q4=−0.23, Q5=+0.12 MME change (2006-2009).

- **Exclusion restriction defense:** Pre-period Mallinckrodt share reflects distributor logistics networks (which wholesalers serve which counties), not county opioid demand characteristics. I will show: (1) 2006 Mallinckrodt share is uncorrelated with pre-period overdose levels, demographic characteristics, and economic conditions; (2) placebo with hydrocodone potency (Mallinckrodt did not expand hydrocodone product lines); (3) leave-one-state-out stability.

## Expected Effects and Mechanisms

- **Primary:** Higher 2006 Mallinckrodt share → larger increase in county-level oxycodone potency (MME/pill) post-2008
- **Secondary (reduced form):** Higher predicted potency → higher overdose mortality
- **Mechanism:** Generic manufacturers competed on dose strength rather than price. High-dose pills (40mg, 80mg) offered pharmacies higher value per unit without abuse-deterrent properties, creating a "potency escalation" dynamic through standard IO competitive forces.
- **Null possibility:** If distributor switching is rapid, pre-period shares may not predict post-period exposure. This would show up as a weak first stage.

## Primary Specification

**First stage:**
ΔPotency_c = α + β × MallinckrodtShare2006_c + X_c'γ + State_FE + ε_c

**Second stage (reduced form for mortality):**
ΔOverdose_c = α + δ × PredictedΔPotency_c + X_c'γ + State_FE + ε_c

Where:
- ΔPotency_c = change in average MME/pill in county c (2006 to 2009)
- MallinckrodtShare2006_c = Mallinckrodt's share of oxycodone pills in county c in 2006
- X_c = county controls (population, income, % uninsured, physician density)
- Clustering: state level (50 clusters)

## Data Sources

1. **DEA ARCOS** (Azure: `raw/arcos/arcos_transactions.parquet`): 178M transaction-level opioid shipments 2006-2012. County-distributor-manufacturer-drug-year detail.
2. **CDC WONDER**: County-level overdose mortality (drug poisoning deaths, ICD-10 X40-X44, X60-X64, X85, Y10-Y14). Via CDC WONDER API.
3. **Census/ACS**: County-level controls (population, median income, % uninsured, poverty rate). Via Census API or tidycensus.

## Robustness Checks

1. Hydrocodone placebo (Mallinckrodt did not expand hydrocodone product lines)
2. Leave-one-state-out first-stage stability
3. Balance test: 2006 Mallinckrodt share vs pre-period county characteristics
4. Alternative potency measures (high-dose share ≥20mg instead of MME/pill)
5. Dynamic specification: year-by-year interaction of 2006 share × post indicators
6. Borusyak-Hull-Jaravel recentered instrument (shift-share best practice)

## Key Risk

The main risk is that pre-period Mallinckrodt share correlates with unobserved county characteristics that independently predict potency trends. The balance test and hydrocodone placebo are critical for addressing this.
