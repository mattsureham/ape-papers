# Research Plan: apep_1333

## Research Question
Do marine protected areas increase fish abundance and species richness in California kelp forest ecosystems? Specifically, does the strict no-take designation (State Marine Reserves) produce larger ecological dividends than limited-take areas (State Marine Conservation Areas)?

## Policy Setting
California's Marine Life Protection Act (MLPA, 1999) created 124 MPAs in three staggered waves:
- **Central Coast:** 29 MPAs, September 2007
- **South Coast:** 50 MPAs + 2 closures, January 2012
- **North Coast:** 20 MPAs + 7 closures, December 2012

MPAs range from no-take State Marine Reserves (SMRs) to limited-take SMCAs. The network covers ~16% of CA state waters, up from <3%.

## Identification Strategy
**Staggered spatial difference-in-differences (BACI design):**

Y_{st} = α_s + δ_t + β(MPA_s × Post_t) + X_{st}'γ + ε_{st}

where s indexes monitoring sites and t indexes survey years.

Three waves provide temporal variation for Callaway-Sant'Anna heterogeneous treatment effect estimation. Key design features:
1. **Dose-response:** Compare no-take SMR vs limited-take SMCA effects
2. **Placebo species:** Pelagic/migratory fish (e.g., yellowtail, barracuda) that transit through MPAs — should show null effect
3. **Spillover test:** Fish density at near-boundary reference sites vs distant reference sites
4. **Event-study:** Pre-trend tests for each cohort

## Expected Effects and Mechanisms
- **Fish density:** Positive effect, larger for no-take reserves. Mechanism: reduced fishing mortality → larger, older fish → exponential fecundity-size relationship
- **Species richness:** Moderate positive effect via recovery of depleted species
- **Size structure:** Shift toward larger individuals (fewer harvested fish)
- The "reserve dividend" — strict protection compounds over time as age/size structure recovers

## Primary Specification
Callaway-Sant'Anna (2021) estimator with site-level clustering. Three cohorts defined by MPA implementation wave. Never-treated reference sites as comparison group. Outcome: log fish density per transect (counts/60m²).

## Data Sources
1. **Reef Check California (RCCA):** Primary. >110 sites, >1,000 surveys, 35 indicator fish species, 2006-present. Available at data.reefcheck.us or California data portal.
2. **CA MPA shapefiles (ds582):** MPA boundaries for treatment assignment. data.ca.gov.
3. **CDFW MPA metadata:** Protection level (SMR vs SMCA), implementation dates.

## Exposure Alignment
Treatment is precisely defined at the site level: Naples Reef and Isla Vista Reef fall within MPA boundaries designated September 2007 under the Central Coast MLPA. The treatment geography (MPA boundary) matches the outcome geography (monitoring transects within sites). Fish are resident reef species with limited home ranges (typically <1 km for most kelp forest species), so treatment exposure at the transect level corresponds to the actual fishing restriction. The seven control sites are mainland kelp forest reefs in the Santa Barbara Channel that remained outside all MPA boundaries. Channel Islands sites are excluded from the main analysis because they received earlier federal protection (2003), confounding the state designation timing.

## Robustness
- Wild cluster bootstrap (few treated-site clusters per cohort)
- Leave-one-out by site
- Placebo species test
- HonestDiD sensitivity to parallel trends violations
- Balanced panel restriction
