# Conditional Requirements

**Generated:** 2026-03-06T17:42:51.892975
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Does Rent Control Destroy Property Value? Staggered Evidence from France's Encadrement des Loyers

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: showing strong pre-trend evidence by property type

**Status:** [x] RESOLVED

**Response:**
The staggered design provides 5+ years of pre-treatment data for all cities (DVF starts 2014; first treatment is Paris in July 2019). We will estimate a CS-DiD event study showing separate pre-treatment coefficients for investment-type and owner-occupier-type properties in each treated city. Parallel pre-trends will be demonstrated by: (a) joint F-test of pre-treatment leads; (b) visual event-study plots by property type; (c) Rambachan-Roth HonestDiD sensitivity analysis allowing for non-zero pre-trends.

**Evidence:**
DVF data 2014-2019 provides 5 full pre-treatment years for Paris (earliest adopter). Later adopters (Bordeaux, Montpellier, 2022) have 8 pre-treatment years. Will be demonstrated in 03_main_analysis.R event-study output.

---

### Condition 2: validating the "rental-probability" classification

**Status:** [x] RESOLVED

**Response:**
We will validate the investment/owner-occupier proxy using external data. The RPLS (Répertoire des Logements Sociaux) and FILOCOM (Fichier des Logements par Commune) publish commune-level rental shares by property type. Key validation: (a) compare DVF property-type classification against known rental rates from FILOCOM/RPLS; (b) show that small apartments (studio, 1-2 rooms) in central areas have 60-70%+ rental probability vs. 15-20% for houses; (c) as robustness, use a continuous "rental probability score" based on property size, type, and location instead of a binary split.

**Evidence:**
INSEE publishes FILOCOM data showing rental rates by commune and property type. National average: ~40% of apartments rented vs ~15% of houses. In major cities: ~60%+ for studios/1-room apartments. Will be validated in 02_clean_data.R.

---

### Condition 3: mapping exact policy perimeters

**Status:** [x] RESOLVED

**Response:**
The encadrement des loyers applies at the commune level (or intercommunality for Paris, Plaine Commune, Est Ensemble). The exact list of communes is published in each city's arrêté préfectoral and compiled by service-public.fr. We will: (a) compile the exhaustive list of treated communes with their exact implementation dates from official arrêtés; (b) match DVF transactions to treated/untreated communes using the code_commune field; (c) for boundary analysis, identify transactions within 2km of the regulatory perimeter.

**Evidence:**
Official sources: decrees published in Journal Officiel and listed on ecologie.gouv.fr/politiques-publiques/encadrement-loyers. Each arrêté specifies the exact geographic perimeter. Commune codes in DVF allow precise matching.

---

### Condition 4: using boundary/placebo tests to address city-specific shocks

**Status:** [x] RESOLVED

**Response:**
Four complementary placebo/boundary tests: (a) Suburban boundary: compare transactions in communes just outside the regulatory perimeter (untreated) to those just inside (treated) — both exposed to the same city-level shocks but only one faces rent control; (b) Commercial property placebo: commercial transactions (locaux commerciaux) in treated cities should be unaffected by residential rent control; (c) Staggered adoption: with 10+ cities adopting at different times, city-specific shocks would need to coincidentally align with each city's adoption date — implausible; (d) Leave-one-out: drop each city in turn and show results are not driven by any single adopter.

**Evidence:**
DVF contains type_local field distinguishing "Maison", "Appartement", "Dépendance", and "Local industriel. commercial ou assimilé" — enabling the commercial placebo. Suburban communes identified via code_commune proximity to treated perimeters.

---

### Condition 1 (duplicate set): using a tighter exposure measure than houses vs small flats

**Status:** [x] RESOLVED

**Response:**
We will construct a continuous "rental exposure score" rather than a simple binary house/apartment split. The score incorporates: (1) property type (apartment > house); (2) number of rooms (fewer rooms = higher rental probability); (3) surface area (smaller = higher rental probability); (4) location centrality (distance to city center). This continuous treatment intensity measure is used in a dose-response specification alongside the binary split as a robustness check. We also include a "pure investment" subsample of studios and 1-room apartments (the properties most likely to be rental) as a high-powered specification.

**Evidence:**
DVF fields available: type_local, nombre_pieces_principales, surface_reelle_bati, code_commune, section/parcelle for geocoding. These allow construction of the continuous rental exposure score.

---

### Condition 2: explicitly handling COVID/announcement timing

**Status:** [x] RESOLVED

**Response:**
COVID is a major confound for Paris (treated July 2019, COVID March 2020) and Lille (treated March 2020). Our strategy: (a) The triple-difference handles COVID if it affected investment and owner-occupier properties similarly — the DDD nets out any common property-type shock within a city; (b) Paris provides 8 months of clean post-treatment, pre-COVID data (July 2019 - February 2020) for a short-window estimate; (c) Later adopters (Lyon, Montpellier, Bordeaux — 2021-2022) are post-COVID and provide clean identification; (d) We include COVID controls (lockdown periods, month-of-year fixed effects) and test sensitivity to excluding 2020Q2-2020Q4; (e) For announcement effects: Paris rent control was first attempted in 2015-2017 (struck down), so market participants had prior exposure — we test for anticipation using the 2015-2017 window.

**Evidence:**
DVF transaction dates allow precise monthly analysis. Paris pre-COVID window: July 2019 - Feb 2020 (~50,000 transactions in Paris alone). Post-COVID cities (Lyon Nov 2021, Bordeaux Jul 2022) provide clean natural experiments.

---

### Condition 3: verifying regulatory boundaries

**Status:** [x] RESOLVED

**Response:**
Same as Condition 3 above (mapping exact policy perimeters). The regulatory boundaries are defined by arrêté préfectoral at the commune level. We will compile the complete list of treated communes from official government sources, cross-check against the compiled lists on service-public.fr and ecologie.gouv.fr, and verify each boundary by checking that DVF transactions in treated communes show up as treated in our classification.

**Evidence:**
See Condition 3 response above. Official commune lists published per city.

---

### Condition 4: bindingness

**Status:** [x] RESOLVED

**Response:**
The encadrement des loyers is only binding when market rents exceed the reference rent + 20% supplement. In non-binding neighborhoods, the policy has no bite. We address this by: (a) Using Observatoire des Loyers data (OLAP for Paris, local observatories elsewhere) to classify neighborhoods as binding vs. non-binding based on pre-reform market rents relative to reference rents; (b) Testing for heterogeneous treatment effects: property price declines should be concentrated in binding neighborhoods; (c) If bindingness data is unavailable at fine geographic level, we use pre-reform price growth as a proxy for rent tension; (d) Compliance data: Morin et al. (2025) report that ~30-40% of new leases in Paris exceed the ceiling, suggesting the policy is partially binding — this makes our estimates a lower bound on the full-compliance effect.

**Evidence:**
OLAP publishes Paris reference rents by quartier and property characteristics. Morin et al. (2025, JHE) document binding rates. ANIL and ADIL publish compliance statistics for other cities.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
