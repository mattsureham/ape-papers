# Lessons: apep_0874 v1

## Discovery
- The supply-side question for SNAP (does benefit generosity attract retailers?) was genuinely unstudied. The idea emerged from recognizing that the APEP SNAP cluster (1729-1745) studied retailer *exits*; the mirror question about *entry* was unasked.
- The USDA SNAP Retailer Historical Database is an underappreciated resource: 703K geocoded records with authorization dates spanning 20 years. It's effectively a census of the food retail universe that interacts with SNAP.

## Data
- USDA FNS download endpoint is unreliable (HTTP/2 stream errors). Always have a fallback: reusing from prior papers or caching.
- County name matching between the SNAP retailer database and ACS yields ~80% match rate. The main loss is from independent cities (Virginia), territories, and military installations. A ZIP-to-county crosswalk or geocoded FIPS lookup would improve this.
- Type mismatches (character vs integer for FIPS codes) between different Census data products are a perennial data.table bug source. Always `as.character()` FIPS codes before merging.

## Method
- Continuous DiD with county SNAP rates works mechanically, but the event study is noisy. With ~2,700 counties, the cross-sectional variation in SNAP rates (~6 pp SD) generates real but modest treatment intensity variation.
- The count model vs rate model discrepancy is important: high-SNAP counties have more stores in the denominator, mechanically attenuating the rate. Present count as primary for extensive margin questions.
- Population weighting dramatically increases the coefficient (from 0.020 to 0.621) — the effect is driven by large urban counties. This is both economically intuitive (fixed costs matter) and statistically important (unweighted estimates average over thousands of rural counties where entry is a rare event).

## Reviews
- All three reviewers flagged the authorization-vs-entry distinction. This is a real limitation that should be discussed honestly. The USDA data cannot distinguish new store openings from existing stores newly seeking SNAP authorization.
- The placebo result (negative, significant) required explanation: it likely reflects pandemic disruption in high-SNAP counties. The opposite sign from the main effect is actually reassuring for identification.
- Reviewers wanted the triple-difference with early EA states. This is a reasonable enhancement for V2 but not feasible in a V1 time frame without substantial additional coding.

## Writing
- The "convenience stores, not supermarkets" finding is the most interesting result. The discussion section should lead with this, grounding it in fixed costs and margins rather than generic "supply-side" language.
- Economic significance framing matters: "0.008 SD" sounds negligible, but "15% increase in the flow of new authorizations nationally" sounds meaningful. Both are correct. Frame honestly.

## For V2
- Implement triple-difference using early EA states
- Add CBP establishment counts as secondary outcome (validates "real entry" vs "SNAP adoption")
- Explore commuting-zone-level aggregation to address spatial spillovers
- Consider Poisson/negative binomial models for count data
- Investigate food desert designation (USDA Food Access Research Atlas) as heterogeneity dimension
