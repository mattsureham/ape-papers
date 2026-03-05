# Research Ideas

## Idea 1: Does Insurance Make Markets Resilient? Flood Re and English Property Values

**Policy:** Flood Re, the UK government-backed reinsurance scheme launched in April 2016. Flood Re caps flood insurance premiums for eligible residential properties via Council Tax band-linked pricing (£46-£540/year). Eligibility: residential properties built before January 1, 2009 with Council Tax bands A-H. ~350,000 properties benefit. Before Flood Re, insurers could refuse coverage or charge prohibitive premiums for flood-risk properties, creating a "flood discount" in house prices that reflected both physical risk AND insurance market failure.

**Outcome:** HM Land Registry Price Paid Data — 24M+ residential transactions (1995-2025) with postcode, price, property type, new-build flag, and transaction date. Linked to Environment Agency "Risk of Flooding from Rivers and Sea — Postcodes in Areas at Risk" dataset (CSV, ~4.7MB, postcode-level 4-band flood risk categories: High/Medium/Low/Very Low).

**Identification:**
- **Main DiD:** Properties in flood-risk postcodes (High/Medium risk) vs. non-flood-risk postcodes, before vs. after April 2016.
- **Triple-diff:** Flood-risk × post-2016 × pre-2009-build (Flood Re eligible) vs. post-2009-build (Flood Re ineligible). The post-2009 builds face identical flood risk but CANNOT access Flood Re — this is the killer placebo.
- **Dose-response:** Flood Re premiums vary by Council Tax band, creating within-flood-zone variation in the subsidy's generosity relative to property value.
- **Event study:** Dynamic treatment effects showing gradual capitalization of insurance access.
- **Repeat sales:** Within-property price trajectories for properties that transacted both before and after 2016.

**Why it's novel:** Substantial literature on flood risk and property values (Bin & Polasky 2004; Beltrán et al. 2018 JUE; Atreya et al. 2013), but almost no causal evidence on whether INSURANCE ACCESS (as opposed to physical risk) drives flood-risk property discounts. Flood Re is a clean quasi-experiment that changed insurance availability without changing physical flood risk. The fundamental question — "How much of the disaster-risk discount reflects market failure vs. rational risk pricing?" — speaks to insurance economics, climate adaptation, and housing policy.

**Feasibility check:**
- Variation: 350,000 eligible properties in flood-risk zones; hundreds of thousands of transactions in affected postcodes
- Data accessible: Land Registry PPD confirmed (yearly CSVs, ~150MB each). EA flood risk postcodes confirmed (CSV, postcode-level, no auth). New-build flag confirmed in Land Registry column 6.
- Not overstudied: Searched Google Scholar for "Flood Re property prices" — 2 working papers, no top-journal publication
- Sample size: Millions of transactions in control group; estimated 50,000-100,000+ transactions in flood-risk postcodes over 2010-2025
- Pre-period: 6+ years (2010-2016); Post-period: 9+ years (2016-2025)


## Idea 2: Twenty is Plenty? Road Safety Effects of Wales's Universal Speed Limit Reduction

**Policy:** On 17 September 2023, Wales changed the default speed limit on restricted (residential) roads from 30mph to 20mph. This affected approximately 13,000km of roads. England, Scotland, and Northern Ireland did NOT change their default speed limits. In 2024, selective reversions began (some roads reverted to 30mph), creating a second quasi-experiment.

**Outcome:** STATS19 road accident data (1979-2024, available via `stats19` R package). Includes collision severity, casualty count, road speed limit, geographic coordinates (10m resolution), local authority, and road type. Covers all of Great Britain (England, Scotland, Wales).

**Identification:**
- **Main DiD:** Welsh restricted roads vs. English restricted roads, pre vs. post September 2023.
- **Triple-diff:** Wales × residential roads × post-Sept-2023 (main roads/motorways in Wales are exempt from the 20mph change — built-in placebo).
- **Spatial RDD:** Collisions near the England-Wales border, comparing Welsh side (20mph) vs. English side (30mph).
- **Reversion DDD:** Roads that reverted to 30mph in 2024 vs. roads that stayed 20mph — do casualties increase on reverted roads?

**Why it's novel:** The most controversial transport policy in recent UK history. Official monitoring reports show raw casualty reductions, but no rigorous causal study with England as a control group exists. The reversion quasi-experiment is entirely unstudied. Academic interest is high (PMC 2024 article, Senedd Research reports), but the identification gap is wide open.

**Feasibility check:**
- Variation: Entire Welsh road network vs. English road network; 22 Welsh local authorities × 130+ English LAs
- Data accessible: STATS19 2023-2024 confirmed downloadable. Speed limit field validated for Sept-Dec 2023 (DfT manually corrected ~120 records)
- Not overstudied: Descriptive government monitoring only. No DiD published.
- Sample size: ~100,000+ collisions per year across GB; several thousand on Welsh 20/30mph roads
- Pre-period: 4+ years (2019-2023); Post-period: 2.3 years (Sep 2023-Dec 2025, though only 2024 data available now)
- Risk: Short post-window (mitigated by immediate mechanical effect of speed on severity)


## Idea 3: When It Rains, It Crimes? Granular Weather Shocks and Street-Level Offending in England

**Policy:** None (natural variation). Uses exogenous rainfall shocks from ~1,000 EA tipping-bucket gauges (15-minute accumulation data) as instruments for outdoor human activity.

**Outcome:** UK Police API street-level crime data (2010-2025) by LSOA/month. Includes crime category, location, and outcome. Linked to EA rainfall gauge readings and Land Registry PPD for property crime context.

**Identification:**
- **IV design:** Daily/monthly rainfall deviations from long-run station means → crime rates within Police Force Areas.
- **Panel FE:** Station-month panel with station and month-of-year FE to absorb geography and seasonality.
- **Mechanism decomposition:** Outdoor crimes (robbery, vehicle, public order) vs. indoor crimes (domestic, fraud, cyber) as built-in placebo.
- **Nonlinear dose-response:** Extreme rainfall events (>95th percentile) vs. moderate rain vs. dry days.

**Why it's novel:** Weather-crime literature exists (Jacob et al. 2007; Ranson 2014; Heilmann & Kahn 2019) but primarily uses US data with coarse weather measures. UK data uniquely offers: (a) 15-minute rainfall gauge resolution, (b) exact street-level crime coordinates, (c) 15-year panel. Could identify the "deterrence-by-weather" margin: how much crime is purely opportunistic?

**Feasibility check:**
- Variation: ~1,000 rainfall stations × 15 years × 12 months
- Data accessible: EA rainfall API confirmed (no auth). Police API confirmed (no auth, 15 req/s rate limit). Both tested.
- Not overstudied: No UK-specific study with this granularity
- Sample size: Millions of crime records, thousands of station-months
- Risk: May be seen as incremental to weather-crime literature; "technically competent but not exciting"


## Idea 4: The Price of Clean Air: Spatial Capitalization of England's Clean Air Zones

**Policy:** Clean Air Zones (CAZs) in Bath (March 2021), Birmingham (June 2021), Portsmouth (November 2021), Bristol (November 2022), Bradford (September 2022), Sheffield (February 2023). CAZs charge non-compliant vehicles to enter designated urban zones.

**Outcome:** Land Registry PPD for property transactions near CAZ boundaries. Companies House bulk data for firm entry/exit within vs. outside zones.

**Identification:**
- **Staggered DiD:** 6 cities with different adoption dates × postcode-level property prices.
- **Boundary RDD:** Compare property prices just inside vs. just outside CAZ boundaries using spatial distance to boundary.
- **Built-in placebo:** Properties near CAZ boundaries in cities that announced but then cancelled CAZs (e.g., Greater Manchester scrapped its CAZ in 2022).

**Why it's novel:** London's congestion charge has been studied (Percoco 2014; Green et al. 2020), but the new wave of CAZs outside London is unstudied. The boundary RDD is clean: air quality improves discontinuously at the zone edge, but proximity to city center varies smoothly.

**Feasibility check:**
- Variation: 6 cities (BELOW 20-unit threshold for standard staggered DiD — major concern)
- Data accessible: Land Registry confirmed. CAZ boundary polygons available from local council websites.
- Not overstudied: Very little on non-London CAZs
- Sample size: ~10,000-20,000 near-boundary transactions across 6 cities
- Risk: Only 6 treated units makes staggered DiD unreliable; boundary RDD requires exact polygons; very recent policy (3-5 year post-window)


## Idea 5: Austerity and Anarchy? Police Budget Cuts and Local Crime in England

**Policy:** Post-2010 austerity reduced central government grants to English police forces by ~20% in real terms (2010-2019). The cuts varied across police force areas because some forces were more dependent on central government funding (vs. locally-raised council tax precepts). Forces with higher grant dependence experienced larger effective budget cuts.

**Outcome:** Police API crime data by LSOA/month (2010-2019, pre-COVID). NOMIS employment data. Companies House firm formation/dissolution.

**Identification:**
- **Shift-share IV:** "Shift" = national austerity cut. "Share" = pre-2010 grant dependence ratio per police force area. Forces more reliant on central grants received proportionally larger cuts.
- **Dose-response DiD:** Police force areas ranked by size of real budget cut × time.
- **Placebo:** Non-acquisitive crimes (e.g., domestic incidents, fraud) less sensitive to visible policing presence.

**Why it's novel:** Draca et al. (2011) study police and crime in London using terror-alert deployments. Mello (2019) studies US police. UK austerity as a shock to policing across 43 force areas is studied by some UK researchers but no clean causal identification using shift-share IV has been published in a top journal.

**Feasibility check:**
- Variation: 43 police force areas × 9 pre-COVID years
- Data accessible: Police API confirmed. Police funding data published by Home Office.
- Not overstudied: Some UK policy reports, but no top-journal publication with this design
- Sample size: 43 forces × 108 months; millions of crime records
- Risk: Shift-share concerns (endogenous shares); existing UK policy literature; lesson from tournament: shift-share needs exceptional diagnostics
