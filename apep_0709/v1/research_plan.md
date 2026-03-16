# Research Plan: Markets Under Fire

## Research Question
Does jihadist violence raise food prices in Burkina Faso? The geographic spread of Sahel insurgency from Mali (2016–2023) created staggered conflict exposure across ~66 WFP-monitored markets. We estimate the causal effect of conflict onset on monthly staple food prices using a Callaway–Sant'Anna staggered DiD design.

## Identification Strategy
**Treatment:** A market becomes treated in the first month a UCDP conflict event occurs within 50km. The stagger comes from the geographic diffusion of violence outward from the Mali border — Sahel region first (2016), then Est/Nord (2017), then progressively southward through 2022.

**Identifying assumption:** Conditional on market and time fixed effects, the timing of conflict onset is driven by geographic proximity to Mali and terrain, not by pre-existing food price levels or trends.

**Why credible:** Violence originated outside Burkina Faso (2012 Mali crisis → AQIM/JNIM) and spread along geographic/military corridors, not in response to local food market conditions. We verify this with event-study pre-trends showing no differential price movements before conflict arrives.

## Expected Effects and Mechanisms
1. **Market disruption channel:** Conflict disrupts transport, destroys market infrastructure, displaces traders. Expect larger effects on bulky, locally-produced cereals (millet, sorghum) than compact imported goods (rice).
2. **Supply contraction:** Farmer displacement reduces local production → prices rise for locally-sourced commodities.
3. **Demand shock:** Population displacement may reduce demand in conflict zones but increase it in refuge destinations.

**Primary prediction:** Conflict raises cereal prices by 10–30%, with heterogeneity by commodity tradability.

## Primary Specification
Callaway–Sant'Anna (2021) ATT(g,t) estimator:
- Unit: market × commodity × month
- Outcome: log(price) in CFA francs/kg
- Treatment: first UCDP event within 50km radius
- Control group: never-treated markets (southern/central)
- Clustering: market level
- Event study: 24 months pre/post leads and lags

## Robustness
1. Sun–Abraham interaction-weighted estimator
2. Varying treatment radius (30km, 75km, 100km)
3. Intensity measure: cumulative events or fatalities within radius
4. Placebo: imported rice (less affected by local disruption)
5. Wild cluster bootstrap (few clusters concern)

## Data Sources
1. **WFP Global Food Prices** (via HDX): 54,907 obs, 66 markets, 12 commodities, monthly 1992–2025. No auth required. CSV download from data.humdata.org.
2. **UCDP GED v24.1**: 1,504 geo-coded conflict events for Burkina Faso (2016–2023). Direct CSV download from ucdp.uu.se.

## Fetch Strategy
- WFP: Direct CSV download from HDX API
- UCDP: Direct CSV download from UCDP data page
- Both datasets are small (<100MB combined), no Azure needed
