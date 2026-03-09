# Research Ideas — apep_0500

## Idea 1: Petro-Federalism and Local Economic Activity: Oil Price Shocks and Nigeria's Revenue Sharing

**Policy:** Nigeria's Federation Account Allocation Committee (FAAC) distributes federal revenue (50-70% from oil) to 36 states + FCT monthly. The 1999 Constitution mandates a 13% derivation principle for oil-producing states. When global oil prices swing, fiscal transfers to states change dramatically—but differentially, because oil-producing states lose (or gain) more through the derivation channel.

**Outcome:** State-level nighttime light intensity from VIIRS Black Marble satellite data (monthly, 2012-2024). Nighttime lights are a well-validated proxy for local economic activity (Henderson, Storeygard, Weil 2012 AER).

**Identification:** Shift-share DiD following Borusyak, Hull, and Jaravel (2022). The "shift" is global Brent crude oil price changes (exogenous to individual Nigerian states). The "share" is each state's baseline FAAC dependency (proportion of revenue from federal oil transfers vs. internally generated revenue). Oil price shocks create differential fiscal impacts across states, with oil-producing states receiving amplified shocks through the 13% derivation.

**Key shocks:** 2014-2016 oil price collapse ($115→$28/bbl), 2020 COVID crash ($65→$20), 2022 spike ($80→$120).

**Why it's novel:** First paper to trace the subnational economic impact of oil price volatility through Nigeria's fiscal transfer system using satellite data. The "fiscal channel" of oil dependence is distinct from the direct "resource curse" channel studied in existing literature. Allows testing whether fiscal transfers amplify or buffer oil shocks at the state level.

**Feasibility check:** CONFIRMED. FRED API returns Brent crude prices ✓. NBS publishes monthly FAAC state-by-state allocations (PDF, parseable) ✓. VIIRS nightlights via R `blackmarbler` package ✓. 37 states × 12 years monthly = ~5,300 state-month observations. Multiple exogenous oil price shocks provide staggered variation. All data freely accessible.

**DiD requirements:** 37 states (all treated with varying intensity), 24+ pre-periods for 2014 crash, 5+ years monthly pre-treatment. Passes ≥20 threshold.

---

## Idea 2: Legislating Peace? Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria

**Policy:** Between 2016 and 2021, 14 Nigerian states adopted anti-open grazing legislation banning free-range cattle herding. Benue (Nov 2017) and Taraba (2017) were early adopters; a wave of southern states followed in 2021 after the Southern Governors' Forum resolution. The policy directly targets the root cause of farmer-herder conflict—competition over grazing land.

**Outcome:** Non-state conflict events (UCDP type 2) at the state-year level. UCDP GED v25.1 has 2,436 non-state violence events for Nigeria (1990-2024), many involving farmer-herder clashes.

**Identification:** Staggered DiD (Callaway-Sant'Anna) exploiting differential adoption timing across states. DDD extension: pastoral-zone LGAs vs. non-pastoral LGAs within states × law adoption × pre/post. Built-in placebo: state-based violence (type 1, Boko Haram) and one-sided violence (type 3) should be unaffected by grazing legislation.

**Why it's novel:** No causal estimate of anti-grazing legislation on pastoral conflict exists. This is a life-and-death policy question: farmer-herder conflict has killed ~2,800 people in the past 5 years. The effect direction is uncertain—laws might reduce conflict by restricting grazing, or INCREASE conflict through enforcement backlash. The federal government banned open grazing nationally in late 2025, making state-level evidence urgently needed.

**Feasibility check:** CONFIRMED. UCDP-GED data downloaded (7,418 Nigeria events) ✓. 14 states with confirmed law adoption dates ✓. Pre-periods: 5+ years for 2017 adopters ✓. CONCERN: Only 14 treated states, below ≥20 DiD threshold. Mitigation: DDD with LGA-level data, wild cluster bootstrap, randomization inference. The question importance may justify the design limitation.

---

## Idea 3: The Economic Shadow of Insecurity: Conflict Types and Local Economic Activity in Nigeria

**Policy:** Nigeria's security response to four distinct waves of organized violence since 2009: Boko Haram insurgency (northeast, 2009-present), farmer-herder conflict (north-central, 2013-present), armed banditry (northwest, 2017-present), and separatist agitation (southeast, 2020-present). Federal and state security deployments created staggered conflict onset and escalation across states at different dates.

**Outcome:** VIIRS nighttime light intensity at state-year level (and LGA level for spatial decomposition).

**Identification:** Staggered DiD using conflict onset/escalation by state from UCDP GED. Treatment defined as first year a state crosses a violence threshold (e.g., >10 conflict events or >50 deaths). 25+ states experienced significant violence onset at different times. Callaway-Sant'Anna estimator handles heterogeneous treatment timing.

**Why it's novel:** The core contribution is TYPE DECOMPOSITION. Do different forms of organized violence have different economic footprints? Boko Haram (territorial, sustained) vs. farmer-herder (seasonal, localized) vs. banditry (predatory, mobile) plausibly have very different impacts on economic activity. UCDP's violence type coding (1=state-based, 2=non-state, 3=one-sided) enables this decomposition. Also estimates RECOVERY DYNAMICS: how quickly do local economies bounce back after violence subsides?

**Feasibility check:** CONFIRMED. UCDP GED ✓ (7,418 events, 39 admin units). VIIRS ✓. 25+ states with violence onset, staggered over 2009-2024 ✓. Placebos: causes of nightlight changes unrelated to violence (e.g., electrification programs, urbanization trends pre-conflict). CONCERN: endogeneity of violence (poorer areas may attract more conflict). Mitigations: state FEs + trends, leave-one-out, instrument with distant conflict shocks.

---

## Idea 4: Cash and Conflict: Did Nigeria's 2023 Naira Redesign Trigger Violence?

**Policy:** In October 2022, the Central Bank of Nigeria announced a redesign of the ₦200, ₦500, and ₦1,000 notes, with a January 31, 2023 deadline to exchange old notes. The rollout was catastrophic: new notes were unevenly distributed, ATMs ran dry, and millions lost access to cash. States experienced dramatically different levels of cash scarcity depending on CBN distribution decisions and banking infrastructure.

**Outcome:** UCDP violence events at state-month level (daily events aggregated to monthly for analysis). Focus on the acute crisis period (January-April 2023) vs. the pre-crisis baseline (2022).

**Identification:** Event study around the January 2023 deadline, with cross-sectional variation from differential cash scarcity across states. Continuous DiD: states with more severe cash shortages (southern states, rural states) should show larger violence increases. The existing APEP paper (apep_0463) studied food market effects—this targets a completely different outcome.

**Why it's novel:** Tests whether monetary policy failures can trigger social instability. The mechanism chain is: cash scarcity → bank riots, protests, stampedes; disrupted livelihoods → opportunistic crime; political anger → targeted violence. Directionally surprising: a technocratic currency reform causing deaths.

**Feasibility check:** PARTIALLY CONFIRMED. UCDP GED has 626 events for Nigeria in 2023 and 490 for 2024, with daily precision enabling event study ✓. Cross-state cash scarcity variation documented in media ✓. CONCERN: Need to construct a credible state-level cash scarcity index (from CBN data or news). Short acute crisis period (Feb-Mar 2023) limits power. Post-period extends through 2024 for medium-term analysis.

---

## Idea 5: Conflict Contagion: Spatial Spillovers of Organized Violence Across Nigerian States

**Policy:** Nigeria's decentralized security architecture (state-level security votes, zonal military commands, state police auxiliaries) governs the response to cross-border conflict spillovers. Since 2009, Boko Haram spread from Borno to five neighboring states; farmer-herder conflict expanded from the Middle Belt southward after 2013; banditry migrated from Zamfara across the northwest after 2017. Security force redeployments between theaters create measurable vulnerability windows with specific dates tied to major military operations (Operation Lafiya Dole 2015, Operation Hadarin Daji 2019, Operation Sahel Sanity 2020).

**Outcome:** State-month violence events from UCDP GED.

**Identification:** Spatial DiD / shift-share design. The "shift" is violence escalation in state A. The "share" is geographic exposure of state B (border length, distance, connectivity). Instrument: use violence from DISTANT conflicts (e.g., Boko Haram for a southwestern state) as exogenous variation—too far for direct spillover but correlated through national security resource reallocation. Alternatively, use military operations in one theater as exogenous shocks that redirect security forces from other regions (creating vulnerability spillovers).

**Why it's novel:** Tests the "security balloon" hypothesis: squeezing conflict in one area pushes it to others. If true, this has profound implications for Nigeria's security strategy—localized operations may be self-defeating. The mechanism decomposition includes: (1) displaced fighters, (2) arms proliferation, (3) security force redeployment, (4) copycat effects. Novel use of multi-insurgency setting as natural experiment.

**Feasibility check:** CONFIRMED. UCDP GED ✓ (7,418 events, georeferenced). Nigerian state boundary data available from GADM/HDX ✓. 36+ state pairs with border adjacency. Long panel: 1990-2024 ✓. CONCERN: Identification of spatial spillovers is inherently challenging—correlated shocks vs. true contagion. Need multiple instruments and extensive falsification.
