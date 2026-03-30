# Research Plan: The Stranded Signal

## Research Question

Do binding 100% clean energy standards (CES) accelerate coal generator retirements, or do market forces (cheap gas, renewables) already drive the same outcome? Using generator-level EIA data, this paper isolates the SIGNALING effect of an elimination mandate above and beyond the market forces that were already shutting coal plants.

## Named Object

**The stranded signal:** 100% CES is a state-level declaration that fossil generation will be eliminated. This signal strands existing coal assets not just economically (cheap gas) but politically (regulatory certainty removes the option value of waiting). The paper tests whether this signal accelerates retirements beyond what market forces alone predict.

## Identification Strategy

**Design:** Callaway-Sant'Anna (2021) staggered DiD.

**Unit of observation:** Coal generator-year (EIA-860 inventory). ~3,400 coal generators observed annually 2008-2024.

**Treatment:** Year the generator's state enacts a binding 100% CES. 20+ treated states, staggered 2015-2024. Hawaii (2015), California (2018), Washington/New York (2019), Virginia/Maine (2020), New Mexico/Colorado/Oregon (2019-2021), Illinois/NC (2021), RI/CT/MD (2022), MN/MI (2023).

**Never-treated:** ~25 states without 100% CES (TX, WY, WV, IN, OH, etc.). These states contain substantial coal capacity, providing a strong control group.

**Primary outcome:** Binary retirement indicator (status transitions from OP/SB to RE). Secondary: planned retirement date shifts, capacity factor changes (EIA-923).

**Pre-treatment:** 5-10 years depending on adoption cohort. Earliest (HI 2015) has 7+ years.

**Covariates:** Nameplate capacity (MW), vintage (operating year), heat rate, coal type (bituminous/sub-bit), environmental controls (FGD, SCR), regulated vs restructured market, state natural gas price.

## Mechanism Tests

1. **Demand-pull vs regulatory-push:** Do retirements correlate with in-state renewable capacity additions? Interact CES with lagged renewable growth.
2. **Replacement fuel:** EIA-923 decomposition of lost coal generation into gas, wind, solar, imports.
3. **Regulated vs merchant:** IOU generators need PUC approval to retire; merchant generators decide privately. CES signal should matter more for regulated utilities (removes regulatory uncertainty).

## Placebo Tests

1. **Gas generators:** CES targets zero-carbon, not zero-fossil. But gas is a bridge fuel. Gas retirements should NOT accelerate under CES (or show weaker effects).
2. **Non-binding RPS states:** States with incremental RPS (not 100% CES) should show weaker retirement acceleration.
3. **Pre-trend:** Event study coefficients flat before CES enactment.

## Data Sources

| Source | What | Access |
|--------|------|--------|
| EIA-860 (bulk) | Generator inventory: plant, capacity, fuel, status, dates | Free, eia.gov |
| EIA-923 (API/bulk) | Monthly generation by fuel type | Free, EIA API |
| EIA-861 | State retail electricity prices | Free |
| NCSL/DSIRE | CES enactment dates by state | Free, public |
| EIA natural gas | State-level gas prices | Free, EIA API |

## Data Fetch Strategy

1. Download EIA-860 bulk ZIP files (2008-2024) — generator inventory
2. Download EIA-923 for monthly generation data (API or bulk)
3. Compile CES enactment dates from idea manifest + NCSL database
4. Build generator-year panel with retirement events and characteristics

## Kill-Shot Concerns

1. **Market forces dominate.** If cheap gas and renewable economics already explain all retirements, CES adds nothing. Test: compare retirement rates in CES states vs non-CES states with similar gas prices and renewable penetration.
2. **Small treated sample.** If few coal generators are in CES states, the design is underpowered. Test: count generators in treated states.
3. **Announcement vs enactment.** CES legislation is debated publicly before enactment. If markets anticipate, pre-trend may not be flat. Test: event study with leads.

## Primary Specification

Callaway-Sant'Anna:
- Group: year of state CES enactment
- Treatment: post-CES indicator
- Outcome: binary retirement (main), capacity factor (secondary)
- Controls: MW capacity, vintage, heat rate, FGD, gas price, restructured market
- Clustering: state level
