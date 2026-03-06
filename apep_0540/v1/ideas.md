# Research Ideas

## Idea 1: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion
**Policy:** The Grand Paris Express (GPE) — 68 new metro stations opening in staggered phases across Ile-de-France from 2024 to 2031. Line 14 extension opened June 2024 (9 stations), Line 15 Sud/Line 16/17 opening 2026-2028, Line 15 Ouest/Est 2028-2031. Key design feature: staggered opening across 4+ lines creates multiple treatment cohorts within the same metropolitan area.
**Outcome:** Demandes de Valeurs Foncieres (DVF) — the universe of French property transactions recorded by notaries, geolocated with latitude/longitude, covering 2020-2025. ~2.4M transactions across IDF, ~600K apartments, ~50K+ within 1km of GPE stations. Mechanism channels: Airparif air quality data (39 stations), SIRENE establishment creation/closure by commune.
**Identification:** Spatial difference-in-differences with staggered treatment timing (Callaway & Sant'Anna 2021). Treatment: property within 0.5/1.0/1.5km of GPE station. Control: properties >2km from any GPE station in same IDF departments. Built-in placebo: Lines opening 2028+ serve as within-project placebos during 2020-2025 sample window. Robustness: Sun & Abraham interaction-weighted estimator, repeat-sales subsample, varying bandwidth rings.
**Why it's novel:** No causal econometric paper on GPE and housing exists. Prior French transit studies use small hedonic samples. DVF provides universe of notarial transactions. Construction-phase vs. opening-phase decomposition is genuinely new — a design feature pioneered by McMillen & McDonald (2004) for Chicago but never applied at this scale.
**Feasibility check:** Confirmed — DVF CSVs downloadable by year/department from files.data.gouv.fr; GPE station GPS coordinates from SmartIDF API (69 stations verified); Airparif API operational; 3-5 pre-treatment years before most openings.

## Idea 2: The Price of Clean Air: Energy Transition and Industrial Employment in French Communes
**Policy:** France's progressive closure of coal-fired and heavy-polluting industrial facilities under the Energie-Climat law (2019) and EU ETS Phase IV (2021-2030). Staggered plant closures across communes create spatial variation in exposure to deindustrialization.
**Outcome:** INSEE BDM employment series at commune/department level; SIRENE establishment creation/closure by sector; DVF property transactions near closed facilities.
**Identification:** Staggered DiD using plant closure dates as treatment timing. Treatment: communes hosting closed facilities. Control: demographically similar communes with no closures. Pre-trends testable over 5+ years before closure.
**Why it's novel:** Most energy transition employment studies focus on coal regions in the US or Germany. French industrial closures under EU ETS have not been studied with commune-level administrative data.
**Feasibility check:** Plant closure dates available from government announcements and Legifrance decrees. SIRENE and DVF data confirmed accessible. Risk: may have too few treated communes if focusing only on coal plants.

## Idea 3: Does Transparency Reduce Corruption? Evidence from France's Open Data Mandate
**Policy:** France's 2016 Loi pour une Republique Numerique mandated progressive open data publication by municipalities above population thresholds (communes >3,500 then >50 then all). Staggered compliance creates variation in fiscal transparency timing.
**Outcome:** Municipal budget data from DGFIP; local election results; DVF property transactions as proxy for local economic activity; SIRENE establishment entries.
**Identification:** Staggered DiD or RDD around population thresholds. Treatment: communes newly publishing open budget data. Control: communes below threshold or not yet compliant. Population threshold enables sharp RDD design.
**Why it's novel:** Open data mandates are widely promoted but rarely evaluated causally. French population thresholds provide clean identification. Most open-data studies are cross-national or use voluntary adoption.
**Feasibility check:** Municipal budget data available from DGFIP open data. Population data from INSEE. Risk: compliance may be gradual and hard to date precisely; effect sizes on corruption proxies may be small.
