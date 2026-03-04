# Research Ideas

## Idea 1: What's in a Label? Education Priority Zones, School Quality Signals, and Housing Markets in France

**Policy:** France's 2015 Education Priority reform (REP/REP+) redesigned the national map of priority education, assigning ~1,093 school networks to REP or REP+ status based on a social disadvantage index. Some schools gained priority status, some lost it, and some retained it. This was the most significant redrawing of France's education priority map since the original ZEP system in 1981.

**Outcome:** Property transaction prices from DVF (Demandes de Valeurs Foncières) géolocalisé, covering ~30 million transactions from 2014-2024 with exact coordinates and prices.

**Identification:** National-scale boundary RDD using collège catchment areas (carte scolaire). The running variable is distance to the catchment boundary where one side feeds into a REP/REP+ collège and the other into a non-REP collège. The design extends to difference-in-discontinuity (DiDisc) by comparing boundary gaps before vs after the 2015 reform for schools that switched status. Built-in placebos: (a) boundaries between two non-REP collèges (should show no gap); (b) boundaries between two REP collèges (gap should be smaller).

**Why it's novel:** Fack & Grenet (2010, JPUBE) did boundary RDD for school quality → housing in Paris (1997-2004), but with notarial data for one city and no policy shock. This paper extends their design nationally using DVF (all of France, 2014-2024) and exploits the 2015 REP reform as a quasi-experimental shock. The multi-boundary national design provides internal replication across hundreds of boundaries with built-in placebos. The question shifts from "do parents value school quality?" (already answered) to "does a government quality label itself move housing markets, and through what channels?"

**Feasibility check:** Confirmed: (1) DVF géolocalisé available on data.gouv.fr; (2) Carte scolaire géolocalisée des collèges publics available on data.gouv.fr with catchment polygons; (3) REP/REP+ school lists with geocoding available on data.gouv.fr; (4) Brevet results by school (IVAC value-added indicators) published by DEPP. All data is open, no API keys required for core analysis.


## Idea 2: Does Halving Class Sizes Capitalize into Housing Prices? Evidence from France's Dédoublement Policy

**Policy:** Starting September 2017, France halved class sizes (from ~24 to ~12 students) in CP (grade 1) in REP+ elementary schools. This expanded to CP in REP + CE1 in REP+ (2018), then CE1 in REP (2019). By 2019, ~300,000 students were affected at a cost of €1.3 billion.

**Outcome:** Property transaction prices from DVF (2014-2024) near affected elementary schools.

**Identification:** Staggered DiD exploiting the phased rollout: REP+ schools treated in 2017, REP schools in 2018-2019, non-REP schools never treated. Within-commune comparison of properties near REP/REP+ elementary schools vs near non-REP elementary schools. Dose-response: REP+ (2 years treated by 2019) vs REP (1 year treated). Placebo: secondary schools (collèges, lycées) in REP zones that did NOT receive class size halving.

**Why it's novel:** The class size literature (Angrist & Lavy 1999; Krueger 1999) has focused entirely on educational outcomes. No paper examines whether class size reductions capitalize into housing prices—a revealed-preference measure of how parents value this input. The dédoublement evaluation literature (DEPP 2019, 2023) finds mixed educational effects. Whether parents perceive and price the policy regardless of its actual effectiveness is a distinct, important question.

**Feasibility check:** Confirmed: DVF available; REP/REP+ elementary school lists with geocoding available on data.gouv.fr; DEPP publishes school-level enrollment and class size data. The design is DiD rather than RDD, which doesn't match the stated preference but is the natural design for this policy.


## Idea 3: The Private School Escape Valve: How Outside Options Mediate the Capitalization of Education Priority Labels

**Policy:** Same as Idea 1 (REP/REP+ reform 2015), combined with the existing geography of private schools in France (~20% of students attend private, almost entirely publicly funded).

**Outcome:** DVF property prices at REP/non-REP catchment boundaries.

**Identification:** Triple-difference boundary RDD: (1) REP vs non-REP side of boundary; (2) high vs low private school density neighborhoods; (3) before vs after 2015 reform. The hypothesis: where private schools offer an outside option to parents, the REP label should matter less for housing prices, since families can opt out of their assigned public collège. This provides a mechanism decomposition: if the boundary gap shrinks near private schools, the capitalization is driven by assignment (carte scolaire rigidity), not information about neighborhood quality.

**Why it's novel:** Fack & Grenet (2010) documented the private-school attenuation effect cross-sectionally in Paris. This paper tests the mechanism causally: the 2015 reform shock changes labels (and potentially expectations), and the private school density interaction decomposes whether capitalization is about school assignment or neighborhood signals. National scale with hundreds of boundaries, not just Paris.

**Feasibility check:** Confirmed: Same data as Idea 1, plus private school locations from data.education.gouv.fr or INSEE Sirene (API key available). All data open or authenticated and available.


## Idea 4: Gateway to the Elite: How CPGE Proximity Shapes Local Housing Markets in France

**Policy:** Classes Préparatoires aux Grandes Écoles (CPGE) are the 2-year intensive programs that feed into France's elite grandes écoles (ENS, Polytechnique, HEC, etc.). There are ~400 CPGEs across France, concentrated in major cities but with significant quality variation. Some CPGEs are legendary (Louis-le-Grand, Henri-IV, Sainte-Geneviève) while others are marginal. CPGE success rates and placement statistics are published by the Ministry of Education.

**Outcome:** DVF property prices near CPGE-hosting lycées.

**Identification:** Hedonic analysis exploiting CPGE quality measures (grandes écoles admission rates) interacted with proximity. Within-commune variation: properties near high-performing CPGEs vs near low-performing ones, controlling for lycée-level baccalauréat quality. This is closest to the original ENS question—it measures the housing market premium for proximity to the gateway to elite education. Potential instrument: CPGE openings/closures over time as quality shocks.

**Why it's novel:** While school quality → housing is well-studied, the specific channel of elite higher education access through CPGEs has never been examined. CPGEs are uniquely French, require geographic proximity (students often live at home or nearby during the intense 2-year prep), and their quality is publicly observable.

**Feasibility check:** CPGE listings and success rates available from data.education.gouv.fr. DVF available. The main weakness is identification: no sharp cutoff exists, making this primarily a hedonic/IV study rather than a clean RDD. CPGE openings/closures are rare events, limiting the time-series variation.
