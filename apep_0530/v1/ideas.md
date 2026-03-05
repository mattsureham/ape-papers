# Research Ideas

## Idea 1: Speed Limits and Road Fatalities: A Boundary Discontinuity at French Department Borders

**Policy:** In July 2018, France reduced the speed limit on secondary roads (routes departementales) from 90 to 80 km/h nationwide. In December 2019, the Loi d'Orientation des Mobilites (LOM) authorized departmental councils to restore 90 km/h. By 2023, 52 of 96 metropolitan departments had reversed the policy on all or part of their road networks. Some departments (e.g., Allier: entire 5,284 km network) restored 90 km/h on all departmental roads; others (e.g., Haut-Rhin: only 16 km) made minimal changes.

**Outcome:** BAAC (Bulletins d'Analyse des Accidents Corporels) --- universe of police-recorded road traffic accidents in France, 2005--2024, geolocated with GPS coordinates. Available as annual CSV files on data.gouv.fr. Includes severity (fatal, serious injury, minor), road type, time, weather, vehicle type, and location characteristics. ~60,000 accidents/year.

**Identification:** Spatial regression discontinuity (boundary discontinuity design) at department borders where one side has restored 90 km/h and the other retains 80 km/h. Running variable: distance to the department border (in km). Treatment: being on the "90 km/h" side. Focus on "full-restoration" departments (those that restored 90 km/h on all departmental roads) paired with "80 km/h" neighboring departments. The key identifying assumption is that all confounders (geography, demographics, road quality, driving culture) change smoothly at the border, while the speed limit changes discontinuously.

**Why it's novel:** Existing studies use interrupted time-series at the national level (Nallet et al. 2024, Journal of Safety Research) or simple group comparisons (ONISR reports comparing "group 80" vs "group 90" departments). No study has exploited the spatial discontinuity at department borders, which provides a cleaner causal estimate by comparing otherwise-similar locations that differ only in speed limit policy. The boundary design also enables welfare analysis: the implied value of a statistical life (VSL) from the speed-safety trade-off.

**Feasibility check:**
- Variation: Confirmed. 52 departments have restored 90 km/h (many fully). Numerous border pairs where policy differs.
- Data: Confirmed. BAAC 2005-2024 available as CSV on data.gouv.fr (dataset: "Bases de donnees annuelles des accidents corporels"). Department border shapefiles from IGN/ADMIN-EXPRESS. List of departments that restored 90 km/h from ONISR evaluations and media compilations.
- Novelty: Confirmed. No existing RDD/BDD study of French speed limit reversals. Nallet et al. (2024) used time-series only.
- Sample size: ~60,000 accidents/year in France; restricting to secondary roads outside urban areas and within 20 km of relevant borders likely yields thousands of observations per year, with 5+ years of post-reversal data (2020-2024).


## Idea 2: When Zones Disappear: Priority Neighborhood Redesignation and Property Value Responses in France

**Policy:** In 2014, France completely redrew its priority neighborhood map under the Loi Lamy. The old geography (751 Zones Urbaines Sensibles/ZUS, created 1996) was replaced by 1514 Quartiers Prioritaires de la Politique de la Ville (QPV), based on a new income-poverty criterion. This created three natural groups: (a) areas that gained priority status (not in ZUS, now in QPV), (b) areas that lost priority status (were in ZUS, not in QPV), and (c) areas that retained status (in both ZUS and QPV).

**Outcome:** DVF (Demandes de Valeurs Foncieres) --- universe of property transactions in France, available 2014-2025 on data.gouv.fr. Includes transaction price, address, property type, size, number of rooms. Geolocated version also available. ~3 million transactions/year.

**Identification:** Spatial RDD at the boundaries of gained/lost/retained zones. Running variable: distance to the zone boundary. Compare property values just inside newly designated QPV vs just outside; separately compare values inside de-designated zones (lost ZUS) vs just outside. The before/after component (DVF spans 2010-2025) enables a boundary-DDD design: spatial discontinuity x temporal shock of re-zoning. Built-in placebo: areas that retained status should show no discontinuous change at the boundary around 2014.

**Why it's novel:** Most place-based policy studies examine the introduction of benefits. Studying both the gain AND loss of priority status tests for hysteresis and asymmetry in policy effects. Does losing designation cause prices to fall (reduced investment) or rise (reduced stigma)? The asymmetry result would be a mechanism contribution. The QPV/ZUS transition has not been studied with DVF transaction-level data.

**Feasibility check:**
- Variation: Confirmed. ZUS and QPV shapefiles both available on data.gouv.fr. The set difference identifies gained/lost/retained areas.
- Data: Confirmed. DVF available as bulk CSV on data.gouv.fr. QPV shapefiles (dataset: "Quartiers prioritaires de la politique de la ville"). ZUS shapefiles also available.
- Novelty: Confirmed. No RDD study of the 2014 QPV/ZUS transition using DVF.
- Sample size: ~3M transactions/year; DVF includes geolocated version; thousands of transactions near QPV/ZUS boundaries.


## Idea 3: Speed Cameras and the Kangaroo Effect: Micro-Geographic Evidence from France's Automated Enforcement Network

**Policy:** France has deployed ~3,400 automated speed cameras (radars automatiques) since 2003. Each camera enforces a speed limit at a precise GPS-located point along the road. Drivers are known to decelerate before cameras and accelerate afterward (the "kangaroo effect"), potentially displacing accidents rather than reducing them.

**Outcome:** BAAC geolocated accidents (same as Idea 1) matched to the road network. Additionally, radar locations dataset on data.gouv.fr provides GPS coordinates, installation dates, road identifier, speed limit enforced, and camera type (fixed, section, red light).

**Identification:** Spatial RDD along the road network: compare accident rates in road segments just upstream vs just downstream of each speed camera. Running variable: signed distance along the road from the camera location (negative = upstream/approaching, positive = downstream/departing). Each camera provides a local RDD. With 3,400+ cameras, this is a massively replicated multi-cutoff RDD with enormous statistical power.

**Why it's novel:** Most speed camera studies use before/after comparisons at camera locations (time-series). The spatial displacement effect ("kangaroo" or "halo" pattern) has been discussed but rarely quantified with precise micro-geographic data. France's open data ecosystem uniquely enables this: exact camera locations with installation dates + exact accident locations. The multi-camera design provides internal replication and allows heterogeneity analysis by camera type (fixed vs section), road type, and speed limit.

**Feasibility check:**
- Variation: Confirmed. 3,400+ cameras with GPS coordinates and installation dates on data.gouv.fr.
- Data: Confirmed. BAAC accidents geolocated + radar locations CSV both on data.gouv.fr. Road network from OpenStreetMap or ROUTE500 (IGN).
- Novelty: Confirmed. No large-scale spatial displacement study using French open data. Existing French camera studies are aggregate before/after designs.
- Sample size: 3,400 cameras x 20 years of BAAC data (2005-2024). Each camera-year is an observation unit. Massive replication across the entire road network.


## Idea 4: Council Size and Local Spending: Multi-Cutoff Evidence from 35,000 French Communes

**Policy:** French law mandates council size based on commune population, creating sharp thresholds. For example: 7 councillors for communes <100 inhabitants, 11 for 100-499, 15 for 500-1499, 19 for 1500-2499, 23 for 2500-3499, and so on (Code general des collectivites territoriales, Article L2121-2). Each threshold creates a discontinuous increase in the number of elected representatives.

**Outcome:** DGFiP commune budget data (comptes individuels des communes), publicly available. Includes total spending, investment spending, operating spending, debt, and tax rates. INSEE commune population data from the census.

**Identification:** Multi-cutoff RDD with commune population as the running variable. At each threshold, council size increases discontinuously. The effect of an additional council seat on local spending composition can be estimated at each cutoff separately, then pooled. Built-in placebos: cutoffs where council size changes by the same amount should show similar effects; cutoffs where other policies also change (e.g., the 1,000-inhabitant threshold for proportional voting) may show different effects, allowing decomposition.

**Why it's novel:** Eggers et al. (2018 AJPS) used French population thresholds to study compound treatments and sorting, but focused on validating the RDD design rather than estimating substantive fiscal effects. The effect of council size on spending composition has been studied in Italy (Gagliarducci & Nannicini) and Brazil but not in France with its unique 35,000-commune landscape. The multi-cutoff design with 8+ thresholds provides exceptional internal replication.

**Feasibility check:**
- Variation: Confirmed. 8+ population thresholds with different council sizes. ~35,000 communes provide large sample near each cutoff.
- Data: Confirmed. DGFiP commune budgets available on data.gouv.fr. INSEE commune population available via API/bulk.
- Novelty: Partially confirmed. Council size effects on spending not studied in France, but the general RDD-at-population-thresholds design is very well-known.
- Sample size: ~35,000 communes; thousands near each threshold. Multiple elections and fiscal years.


## Idea 5: Rent Control at City Borders: Capitalization Evidence from France's Encadrement des Loyers

**Policy:** Under the Loi ALUR (2014) and subsequent decrees, several French cities implemented rent caps (encadrement des loyers): Paris (2015, suspended Nov 2017 by court, reimplemented July 2019), Lille (2017, suspended 2020, reimplemented 2020), and others (Lyon, Bordeaux, Montpellier from 2021-2022). The policy caps rents at a reference level + 20% in designated zones. The cap applies within municipal boundaries but not in adjacent communes.

**Outcome:** DVF property transactions in Paris and surrounding communes (Montreuil, Ivry-sur-Seine, Saint-Denis, Boulogne-Billancourt, etc.). ~100,000+ transactions/year in Ile-de-France.

**Identification:** Spatial RDD at the Paris municipal boundary. Running variable: distance to the boundary. Compare property prices just inside Paris (rent-controlled) vs just outside (not controlled). The Paris case is particularly powerful because: (a) the policy was implemented (2015), suspended (2017), and reimplemented (2019), creating a natural "on-off-on" experiment; (b) the municipal boundary is arbitrary for housing markets (same metro, same labor market). Can estimate capitalization effects separately for each policy phase.

**Why it's novel:** Rent control capitalization has been studied in San Francisco (Diamond et al. 2019 AER) and Berlin (Mense et al. 2019) but not in Paris using DVF universe transaction data. The "on-off-on" quasi-experiment is unique --- no other rent control study has this triple policy variation. Can test whether the suspension reversed capitalization effects (hysteresis test).

**Feasibility check:**
- Variation: Confirmed. Paris boundary is sharp. Three policy phases (2015-2017, 2017-2019, 2019-present).
- Data: Confirmed. DVF covers all Ile-de-France transactions. Geolocated version available. Paris boundary shapefile from IGN.
- Novelty: Partially confirmed. Some French studies of Paris rent control exist (e.g., Chapelle & Eymeoud) but the spatial RDD at the boundary + on-off-on design is novel.
- Sample size: ~100,000+ transactions/year in Ile-de-France; thousands within narrow bandwidth of the Paris border.
