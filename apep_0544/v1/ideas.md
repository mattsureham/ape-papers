# Research Ideas

## Idea 1: Cutting the Pipeline: The 2022 Russian Gas Shock and Differential De-Industrialization Across European Manufacturing
**Policy:** Russia's 2022 gas supply cutoff to Europe reduced pipeline deliveries from ~155 bcm (2021) to near zero by 2023. Pre-war Russian gas dependence varied from 0% (Norway) to 75% (Finland) across EU countries. TTF wholesale prices spiked 11x (30 to 342 EUR/MWh).
**Outcome:** Eurostat STS_INPR_M monthly industrial production indices across ~25 EU countries and ~20 NACE manufacturing sectors. 12.7M total observations, monthly frequency from 2015-2024. Supplementary: producer prices (STS_INPR_M PRC_PRR), import substitution (Comext bilateral trade).
**Identification:** Continuous-treatment DiD exploiting country-level Russian gas share (2021) x sector-level gas intensity interaction. Triple fixed effects: country x sector, country x month, sector x month. The key coefficient captures whether more gas-dependent countries saw larger production declines in more gas-intensive sectors. Country x time FE absorb aggregate fiscal/sanctions responses; sector x time FE absorb global demand shifts. Built-in placebo: non-gas-intensive sectors (e.g., transport equipment) in high-dependence countries should show zero effect.
**Why it's novel:** Bachmann et al. (2022, Econometrica) simulated 0.2-3% GDP loss from a Russian gas embargo but used CGE models, not ex-post data. Dozens of descriptive pieces (ECB, Bruegel, VoxEU) document the shock. Zero papers exploit the country x sector double variation in a formal DiD. This is the first clean causal estimate of energy dependence as industrial vulnerability.
**Feasibility check:** Confirmed: Eurostat APIs return data (smoke test: 1,368 data points for 5 sectors x 8 countries x 36 months). Germany chemicals -18.2%, Poland chemicals +11.7% — the gradient is clean. 31 countries with Russian gas import data. No APEP overlap.

## Idea 2: The Economic Integration Lottery: How Immigration Judge Leniency Shapes Local Labor Markets
**Policy:** Within each EOIR immigration court, asylum cases are quasi-randomly assigned to judges with 56-percentage-point within-court disparity in grant rates. 2.7M asylum cases across ~735 judges and ~500 counties (2001-2024).
**Outcome:** County-level BLS QCEW employment and wages, linked to EOIR court x judge assignments. Census ACS for demographic composition.
**Identification:** Judge leniency IV (UJIVE estimator). Instruments for local asylum grant rates. Separates legal status from immigration itself — holds immigrant population roughly fixed and asks whether granting work authorization causally changes local labor markets.
**Why it's novel:** Judge variation is well-documented (GAO 2008, 2017; TRAC 2024) but completely unexploited for economic outcomes. First stage is enormous (56 pp vs. ~5 pp for bankruptcy judges). Zero papers link EOIR to QCEW.
**Feasibility check:** EOIR case data confirmed (4.24 GB, DOJ FOIA Library). BLS QCEW free API. TRAC judge reports available. READY status.

## Idea 3: Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention
**Policy:** 22 U.S. states adopted Extreme Risk Protection Order (ERPO) laws (1999-2024), enabling temporary firearm removal from at-risk individuals. 28 never-treated states + 6 anti-ERPO states as controls.
**Outcome:** CDC "Mapping Injury" dataset (Socrata API, 51 jurisdictions x 6 years x 6 outcomes). CDC WONDER 1999-2020 for extended panel. Key outcome: total suicide rate (not just firearm suicide).
**Identification:** Callaway-Sant'Anna staggered DiD with 22 treated states. Tests whether ERPO laws reduce total suicides or merely shift method (means substitution). Built-in placebo: non-firearm suicide should increase if substitution is complete; total suicide should fall if ERPOs save lives.
**Why it's novel:** RAND 2024 review found all existing multi-state ERPO studies have "serious or critical methodological concerns" from naive TWFE. No proper CS-DiD exists. The means-substitution question is the elephant in the room.
**Feasibility check:** CDC data confirmed accessible. 22 treated states provides strong power. No APEP overlap. READY status.
