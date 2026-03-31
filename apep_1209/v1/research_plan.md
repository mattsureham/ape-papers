# Research Plan: The Dispensary Next Door

## Research Question
Do cannabis dispensaries impose neighborhood externalities on property values? Existing evidence suffers from endogenous site selection — dispensaries choose locations strategically. Illinois's cannabis license lotteries (2021-2023) provide the first genuinely random variation in which neighborhoods gain a dispensary, enabling credible estimates of the causal effect on nearby housing prices.

## Identification Strategy
**Lottery-based reduced form / IV design.** Illinois allocated 185 adult-use dispensary licenses through four computerized lotteries (2021-2023). Conditional on qualifying (scoring 85%+ of 250 application points), license assignment was random within each BLS region. This means dispensary locations are as-good-as-random conditional on BLS region.

**Primary specification:** Staggered DiD comparing property transactions near newly opened lottery-assigned dispensaries (0–0.25 miles) to transactions at moderate distance (0.5–1.5 miles) within the same BLS region/zip cluster. Treatment timing = dispensary opening date. Ring-based design following Linden & Rockoff (2008 AER) and Pope (2008 JUE).

**Key equation:**
log(price_ijt) = α_j + γ_t + β · Near_i · Post_it + X_i'δ + ε_ijt

where j indexes dispensary-cluster, t indexes quarter, Near_i = 1[distance < 0.25 mi], Post_it = 1[sale after dispensary opens].

**Why lottery is key:** Without the lottery, dispensary site selection is endogenous — operators choose locations based on expected demand, zoning, demographics. The lottery breaks this: conditional on applicant pool, which proposed location actually gets a license is random.

## Expected Effects and Mechanisms
- **Amenity/disamenity channel:** Dispensaries may attract foot traffic, noise, odors (negative) or signal neighborhood vitality and retail investment (positive).
- **Crime channel:** Drug retail may attract crime (negative) or replace illegal markets (positive/null).
- **Expected direction:** Prior non-causal literature finds small negative effects (-1% to -3%) for nearby properties. With the lottery removing selection, the true causal effect may be closer to zero.

## Primary Specification
- Unit: property transaction within Cook County
- Treatment: sale within 0.25 miles of a lottery-assigned dispensary, post-opening
- Control: sale 0.5-1.5 miles from same dispensary
- Fixed effects: dispensary-cluster + year-quarter
- Clustering: at dispensary level (~36 clusters in Chicago)
- Heterogeneity: by neighborhood income, property type

## Data Sources
1. **Dispensary locations:** IDFPR adult-use dispensary license data + geocoding
2. **Property transactions:** Cook County Assessor's Office (Socrata API: data.cookcountyil.gov) — PIN-level with sale price, date, geocoordinates
3. **Crime data:** Chicago Police Department incidents (Socrata API: data.cityofchicago.org) — 8.5M geocoded records (secondary outcome)
4. **Controls:** Census ACS 5-year ZCTA-level demographics

## Fetch Strategy
1. Scrape/download IDFPR dispensary license list with addresses
2. Geocode dispensary addresses to lat/lon
3. Query Cook County property sales via Socrata API (2018-2025)
4. Query Chicago crime incidents via Socrata API (2018-2025)
5. Query ACS demographics at ZCTA level via Census API
