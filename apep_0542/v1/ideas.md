# Research Ideas

## Idea 1: When the Train Doesn't Come: The Property Value Destruction of HS2's Northern Cancellation
**Policy:** On 4 October 2023, PM Rishi Sunak announced the surprise cancellation of HS2 Phase 2 (Birmingham to Manchester/Leeds), destroying anticipated travel-time reductions of 30-50 minutes for 6 planned station areas and ~26 communities along the safeguarded route corridor. Phase 2a had received Royal Assent just 2 years prior; HS2 Ltd was actively acquiring properties. Phase 1 (London-Birmingham) continues under construction.
**Outcome:** HM Land Registry Price Paid Data — universe of residential property transactions in England and Wales since 1995 (24M+ transactions). Postcode-level geocoding via ONS NSPL enables distance-to-station measurement. Secondary: NOMIS employment data, Companies House firm formation.
**Identification:** Event-study DiD around the October 4, 2023 announcement. Treated: properties within X km (1, 2, 5, 10 km rings) of cancelled Phase 2 stations. Controls: (1) Phase 1 corridor properties (London-Birmingham, still proceeding) — same project, different treatment; (2) same-region properties far from route. Distance gradient provides built-in dose-response falsification. 12+ quarters pre-period (2020-Q3 2023) for parallel trend validation.
**Why it's novel:** No academic paper estimates the property value effects of HS2 Phase 2 cancellation. Infrastructure cancellation is vastly understudied vs. construction — this flips the transit capitalization literature to test whether anticipatory premiums were real by observing their destruction. Phase 1 as within-project control is uniquely powerful.
**Feasibility check:** Confirmed: Land Registry bulk CSV download works (921K transactions for 2024). Confirmed: 6 cancelled stations, ~26 community areas spanning 7 counties. Confirmed: no existing academic event study. ~50K annual transactions within 10km of cancelled stations.

## Idea 2: Does Regulating Private Landlords Raise Property Values? Selective Licensing in England
**Policy:** Under Part 3 of the Housing Act 2004, 100+ English local authorities adopted selective licensing of private rented housing at staggered dates since 2006, imposing minimum standards and fees (GBP 500-750 per property).
**Outcome:** HM Land Registry Price Paid Data (primary); UK Police API anti-social behaviour incidents (secondary).
**Identification:** Staggered DiD (Callaway & Sant'Anna) across 100+ treated LAs. Placebo tests using LAs that consulted but did not adopt; heterogeneity by scheme type (borough-wide vs targeted).
**Why it's novel:** Existing evaluations focus only on mental health outcomes in London. No published econometric study of selective licensing on property prices nationally.
**Feasibility check:** Confirmed: 100+ LAs adopted; Land Registry data accessible; angle avoidance needed vs apep_0472 (crime displacement from same policy).

## Idea 3: Speed Kills Less at 20mph: The Welsh Default Speed Limit and Road Casualties
**Policy:** On September 17, 2023, Wales lowered the default urban speed limit from 30mph to 20mph. England retained 30mph. Within-Wales variation: North Wales 94% conversion, Gwent far less.
**Outcome:** STATS19 collision-level microdata (fatal/serious/slight, geolocated, all GB police forces since 1979). R package `stats19` provides automated download.
**Identification:** Triple strategy: (A) Cross-border DiD (Welsh vs English border LAs); (B) Spatial RDD at England-Wales border; (C) Within-Wales dose-response across police force areas.
**Why it's novel:** Government monitoring reports use simple before-after comparisons. No published peer-reviewed paper applies DiD or RDD to the Wales 20mph policy.
**Feasibility check:** Confirmed: STATS19 data freely accessible; clear England-Wales border variation; short post-period (~2.5 years) is a limitation.
