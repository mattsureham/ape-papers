# Research Ideas

## Idea 1: Slower Streets, Safer Streets? The Causal Effect of Wales's 20mph Default Speed Limit on Road Casualties and Property Values

**Policy:** On September 17, 2023, Wales became the first UK nation to lower the default speed limit on restricted roads from 30mph to 20mph (Restricted Roads (20 mph Speed Limit) (Wales) Order 2022). England retained the 30mph default. The Welsh policy generated massive public backlash (a petition with 469,571 signatures — the largest Senedd petition ever), and partial reversals began in 2024 with individual roads being reclassified back to 30mph. Despite this political salience, no rigorous causal evaluation has been published — only descriptive monitoring from Transport for Wales.

**Outcome:** (1) Road casualties by severity (fatal, serious, slight) from STATS19 data — available through 2024, monthly date resolution, police-force-level identification of Welsh vs English areas. (2) Residential property prices from HM Land Registry Price Paid Data — to estimate the hedonic capitalization of speed reductions (quieter streets → premium vs. longer commutes → discount).

**Identification:** Multi-layered design:
- **Primary DiD:** Wales (22 LAs) vs. England (~300 LAs) before/after September 2023, with month and LA fixed effects. Treatment: Welsh LA × post-September-2023. ~56 pre-treatment months (2019–2023:08) and ~15 post-treatment months (2023:09–2024:12).
- **Spatial RDD:** Compare near-border Welsh LAs to near-border English LAs — restricting to LAs within 50km of the Wales-England border for tighter geographic controls.
- **Built-in placebo:** A-roads and motorways (speed limits 40–70mph, exempt from the 20mph default change). If the DiD shows effects on 20/30mph roads but not on 40+mph roads, this rules out confounders affecting all road types.
- **Mechanism decomposition:** Casualties by road user type (pedestrian, cyclist, car occupant), by time of day (school hours, evening, night), by severity, by urban/rural classification.

**Why it's novel:** Despite being the most politically contentious transport policy in recent UK history and despite descriptive evidence of a ~28% casualty reduction on affected roads, no peer-reviewed causal evaluation exists. The academic gap is enormous. The economic angle — property value capitalization of speed changes — has never been estimated for a universal speed limit reform.

**Feasibility check:** Confirmed: STATS19 R package downloads 2022–2023 data with police_force identification of Welsh/English areas, speed_limit field (20/30/40/50/60/70), monthly date resolution, ~3,300 Welsh collisions/year vs ~67,000 English. Land Registry PPD available by year at postcode level. GOV.UK published 2024 STATS19 annual report confirming data availability.


## Idea 2: The Empty Homes Tax: Council Tax Premiums and Housing Vacancy in England

**Policy:** The Localism Act 2012 gave English billing authorities discretionary power to charge up to 50% extra council tax on properties empty for 2+ years, effective April 2013. The Rating (Property in Common Occupation) and Council Tax (Empty Dwellings) Act 2018 raised caps to 100% (2+ years), 200% (5+ years), 300% (10+ years). By 2023/24, 292 of 296 billing authorities charged a premium — but adoption timing varied, creating staggered treatment.

**Outcome:** Empty dwelling counts from DLUHC Council Tax Base returns (published annually, LA-level) + Land Registry property prices + NOMIS labour market data.

**Identification:** Staggered DiD across ~296 English billing authorities. Treatment: adoption of empty homes premium. Need to construct adoption dates from annual CTB returns (first year each LA reports applying a premium). Callaway & Sant'Anna estimator for staggered timing.

**Why it's novel:** No causal evaluation of this policy despite widespread adoption. The housing crisis makes this politically relevant — can financial penalties reduce vacancy?

**Feasibility check:** CTB data downloadable from DLUHC. Land Registry confirmed. Key risk: most LAs adopted quickly (2013–2015), limiting stagger variation. Need to verify whether annual CTB returns allow identification of premium adoption year.


## Idea 3: Planning Protection or Housing Blockade? Article 4 Directions and Office-to-Residential Conversions in England

**Policy:** In 2013, England introduced permitted development rights (PDR) allowing office-to-residential conversions without full planning permission. Many LAs subsequently adopted "Article 4 directions" to withdraw this right, requiring full planning permission for conversions. Adoption was staggered across LAs, mainly 2013–2020.

**Outcome:** Housing supply (planning applications data from planning.data.gov.uk), office supply, property prices (Land Registry), firm formation/dissolution (Companies House).

**Identification:** Staggered DiD comparing LAs that adopted Article 4 vs those that didn't. Treatment: Article 4 direction comes into force. planning.data.gov.uk hosts a comprehensive dataset of Article 4 directions with dates and areas.

**Why it's novel:** Cheshire (2022, Real Estate Economics) estimated a 50% price premium for offices gaining conversion rights, but no study examines the economic effects of Article 4 restrictions on housing supply, commercial activity, and property markets.

**Feasibility check:** Article 4 direction dataset downloadable from planning.data.gov.uk (CSV). Land Registry and Companies House confirmed accessible. Risk: Article 4 covers specific geographic areas within LAs (not whole LAs), complicating LA-level DiD.


## Idea 4: When It Rains, It Crimes? Extreme Rainfall and Street Crime in England

**Policy:** Extreme rainfall events serve as plausibly exogenous shocks to outdoor activity. The Environment Agency Rainfall API records ~1,000 gauges at 15-minute intervals across England, with data available from 2008 to present. Specific extreme events (e.g., Storm Desmond December 2015, Storm Ciara February 2020, July 2021 floods) provide clear treatment dates.

**Outcome:** Street-level crime from Police API bulk data (LSOA × month), disaggregated by crime type (outdoor crimes like robbery, burglary, vehicle theft vs indoor crimes).

**Identification:** IV/event study — extreme rainfall deviations from historical LSOA-month means. Rainfall is a shifter of outdoor activity. First stage: rainfall → outdoor activity. Second stage: outdoor activity → crime. Alternative: direct rainfall → crime estimation exploiting high-frequency variation.

**Why it's novel:** US literature (Jacob & Lefgren 2003; Ranson 2014) studies weather and crime but the UK's unique combination of EA rainfall (15-min resolution) and Police API (LSOA-month) enables much finer geographic and temporal matching.

**Feasibility check:** Both EA Rainfall API and Police API confirmed working (no keys needed). Risk: Police API historical depth is ~3 years via API (bulk download from data.police.uk goes back to 2010). Temporal mismatch: rainfall is 15-min but crime is monthly — need to aggregate carefully.


## Idea 5: Cumulative Impact Assessments and the Night-Time Economy: Alcohol Licensing Restrictions and Local Crime

**Policy:** Under the Licensing Act 2003, LAs can adopt "Cumulative Impact Assessments" (CIAs) — areas where new alcohol premises licence applications face a rebuttable presumption of refusal. CIAs have been adopted by dozens of LAs at different times since 2003, with the Policing and Crime Act 2017 formalizing the process.

**Outcome:** Alcohol-related crime (Police API), business formation/dissolution in hospitality SIC codes (Companies House), property values (Land Registry).

**Identification:** Staggered DiD. Treatment: LA adopts CIA. Compare CIA-adopting LAs to non-adopting LAs, before/after adoption.

**Why it's novel:** CIAs are a direct restriction on alcohol availability with clear economic trade-offs: less crime vs. less economic activity. No rigorous causal evaluation exists.

**Feasibility check:** Police API and Companies House confirmed accessible. Key risk: identifying comprehensive CIA adoption dates across all LAs — no single central database exists. May need to compile from individual LA licensing statements.
