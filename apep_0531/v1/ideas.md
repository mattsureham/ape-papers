# Research Ideas

## Idea 1: Soft Power and Crime: The Effect of Police Community Support Officer Cuts on Neighbourhood Safety in England

**Policy:** England's police forces lost ~56% of Police Community Support Officers (PCSOs) between 2010 and 2025 due to austerity, from 17,253 FTE to ~7,500 FTE. PCSOs are unarmed civilian officers focused on community engagement, visible patrol, and local intelligence. Crucially, the cuts varied enormously by force: some forces (e.g., Norfolk) eliminated PCSOs entirely while others maintained numbers. This cross-force variation in PCSO cuts provides a dose-response treatment for studying the crime effects of community-oriented policing.

**Outcome:** Police-recorded crime by type (violence, burglary, shoplifting, anti-social behaviour, criminal damage) by police force area, 2007-2024. Primary source: ONS Police Force Area data tables + Home Office police recorded crime open data tables. Secondary: data.police.uk bulk downloads for monthly granularity.

**Identification:** Dose-response DiD across 43 English and Welsh police force areas, 2007-2024. Treatment intensity = change in PCSO FTE per 100,000 population (force-level, annual). Control for simultaneous changes in sworn officer FTE to isolate the PCSO-specific effect. Pre-treatment period (2007-2009) predates austerity. CS-DiD with staggered intensity or TWFE with continuous treatment.

**Why it's novel:**
1. Only one causal study on PCSOs and crime exists (Ariel, Weinborn & Sherman 2016 — an RCT in one city's hot spots). No study has exploited the national cross-force variation.
2. Decomposes police workforce into community officers (PCSOs) vs. sworn officers — testing whether the TYPE of policing matters, not just the quantity.
3. The mechanism is theoretically distinct: PCSOs deter through visible presence and community trust (Becker deterrence vs. procedural justice), not arrest capacity.
4. The variation is driven by central government funding formulas and PCC budget allocation decisions, not local crime trends.

**Feasibility check:** Confirmed. Home Office workforce ODS file (2007-2025, by force/type/year) downloads at <2 MB. ONS PFA crime tables available. 43 forces, 18 years, continuous dose variation. Ariel et al. (2016) RCT in Peterborough provides micro-foundation; this paper tests external validity at national scale.


## Idea 2: Universal Credit and Crime: A Modern Difference-in-Differences Analysis at Fine Geographic Scale

**Policy:** Universal Credit replaced 6 legacy benefits and rolled out to Jobcentres/LAs in waves from 2013-2018. DWP published rollout dates at the Jobcentre level. Over 300 LA areas were treated at different times.

**Outcome:** Police-recorded crime by LSOA from data.police.uk bulk downloads (Dec 2010-2024). Decompose by crime type: burglary, shoplifting, violent crime, anti-social behaviour.

**Identification:** Staggered DiD using Callaway-Sant'Anna, exploiting the Jobcentre-level rollout schedule mapped to LAs. ≥200 treated units, 3+ pre-treatment years.

**Why it's novel:** d'Este and Harvey (2024, JLEO) studied this with standard TWFE at constituency level. This paper improves: (a) CS-DiD corrects for heterogeneous treatment effects, (b) LSOA-level granularity (33,000 units vs ~500 constituencies), (c) mechanism decomposition via crime types and the 5-week-wait channel, (d) HonestDiD sensitivity analysis.

**Feasibility check:** Confirmed. UC rollout dates from DWP/House of Commons Library. Police bulk data from Dec 2010. BUT: novelty margin is moderate — d'Este & Harvey 2024 already published the core finding (UC increases property crime). The improvement is methodological, not conceptual.


## Idea 3: When It Rains, Crime Pours: Rainfall Shocks and Criminal Activity in England

**Policy:** Not a policy — a natural experiment. England's ~1,000 EA rainfall gauges provide 15-minute rainfall accumulation data, which can be linked to LSOA-level crime from the Police API. Extreme rainfall is plausibly exogenous (conditional on geography/season).

**Outcome:** Daily/weekly crime by LSOA from data.police.uk bulk downloads. Decompose: outdoor crime (robbery, theft from person, vehicle crime) vs. indoor crime (domestic violence, burglary).

**Identification:** IV/event study. Extreme rainfall events (deviations from station-month normals) as instruments for outdoor activity/mobility. High-frequency panel: station × week, 2010-2024.

**Why it's novel:** Weather-crime links are studied, but not with England's uniquely granular rainfall gauge network (15-min resolution) linked to LSOA crime data. The indoor/outdoor decomposition tests routine activity theory directly.

**Feasibility check:** Both EA rainfall API and Police API confirmed working. Spatial matching required (stations → nearest LSOAs). NOT a DiD design — would need to argue this as a natural experiment/IV. Identification is credible but less sharp than staggered DiD.


## Idea 4: Public Space Protection Orders and the Displacement of Anti-Social Behaviour

**Policy:** PSPOs were introduced by the Anti-social Behaviour, Crime and Policing Act 2014, replacing older DPPOs. LAs can designate areas where specified activities (drinking, rough sleeping, etc.) are prohibited. Hundreds of LAs have adopted PSPOs at different times since 2014.

**Outcome:** Anti-social behaviour incidents and crime by LSOA from data.police.uk. Also: displacement to adjacent areas.

**Identification:** Staggered DiD at LA level. Treatment = PSPO adoption. ≥100 treated LAs, pre-period from 2010.

**Why it's novel:** PSPOs are widely used but never rigorously evaluated. The displacement question (do PSPOs just push ASB elsewhere?) is policy-relevant and testable with LSOA-level data.

**Feasibility check:** WEAK. Central register of PSPO adoption dates does not exist. Would require scraping council websites or London Gazette notices. Data construction burden is high and may be infeasible.


## Idea 5: The Price of Police Precepts: Locally-Set Policing Levies and Crime in England

**Policy:** Each of England's 41 Police and Crime Commissioners sets an annual council tax precept for policing. Precept levels vary across force areas and change annually. Central government caps limit increases but PCCs retain discretion within bounds.

**Outcome:** Crime by type by police force area from ONS PFA tables, 2012-2024.

**Identification:** Dose-response DiD exploiting annual precept variation across 41 PCC areas. Treatment = £/household precept level (continuous). Force + year FEs.

**Why it's novel:** Direct test of whether locally-determined police funding affects crime. The precept is a margin of local fiscal discretion in a centralized system.

**Feasibility check:** Precept data published by Home Office. 41 PCC areas, 12+ years. BUT: severe endogeneity concern — PCCs set precepts in response to local crime conditions. Without an instrument, identification is questionable. Capping rules could provide a quasi-experiment (forces at the cap vs. below), but this may not yield enough variation.
