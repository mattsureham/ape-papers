# Research Ideas

## Idea 1: Does Government Consolidation Cost Democracy? Voter Turnout Effects of Swiss Municipal Mergers

**Policy:** Swiss municipal mergers (Gemeindefusionen), 2000–2024. Switzerland's municipality count fell from ~2,900 (2000) to ~2,100 (2024), driven by 352 distinct merger events that dissolved 931 municipalities. Mergers were voluntary (not federally mandated) but often incentivized by cantonal programs (Fribourg 2000, Ticino 2003, Valais 2005). Merger dates are precisely recorded in the BFS Historisiertes Gemeindeverzeichnis (SMMT/AGVCH mutations API).

**Outcome:** Municipal-level voter turnout in federal referenda from the `swissdd` R package (municipal results since 1981). Switzerland holds 4+ federal votes per year, providing high-frequency democratic participation data for all municipalities. Secondary outcomes: blank ballot shares, participation in cantonal elections, and number of candidates in municipal elections (from cantonal sources).

**Identification:** Staggered DiD exploiting the 352 merger events spanning 2000–2024. Treatment is the merger event; units are municipalities harmonized to their eventual merged entity (pre-merger: aggregate constituent municipalities; post-merger: observe the combined entity). Use Callaway & Sant'Anna (2021) estimator for heterogeneous treatment timing. Municipality and canton×year fixed effects absorb time-invariant characteristics and canton-level shocks.

**Why it's novel:**
- First large-scale causal study of democratic effects of voluntary municipal consolidation (N≈930 dissolved municipalities vs. ~1,170 never-merged controls)
- Existing literature (Lassen & Serritzlew 2011, JPubE) studied Denmark's single compulsory 2007 reform — fundamentally different from staggered voluntary mergers
- Swiss direct democracy provides the world's richest democratic participation data (4+ federal votes/year at municipal level since 1981)
- Can decompose mechanisms: size channel (smaller→larger community), identity/belonging (absorbed vs. absorbing municipality), closeness (competitive vs. lopsided votes), Gemeindeversammlung vs. ballot-box cantons
- Trade-off narrative: efficiency gains (fiscal literature) vs. democratic costs — a first-order policy question for any country considering consolidation

**Feasibility check:**
- ✅ Treatment variation: 352 merger events, 931 dissolved municipalities, staggered 2000–2024
- ✅ Outcome data: swissdd provides municipal referendum results 1981–present (tested: API confirmed working)
- ✅ Treatment dates: AGVCH mutations API returns precise merger dates (CSV format, tested and confirmed working with 2,525 rows for 2000–2024)
- ✅ Population/controls: BFS PXWeb provides municipal population 2010–2024 (confirmed working, 2,302 communes)
- ✅ Not overstudied: Swiss merger studies exist in regional journals but no AER/QJE-level paper on democratic effects using staggered design
- ⚠️ Endogeneity: Voluntary mergers create selection concerns. Addressed via: (a) pre-trend tests in event study, (b) cantonal merger incentive programs as instruments, (c) matching on pre-merger characteristics


## Idea 2: Cantonal Energy Law Reform and Building Renovation Activity

**Policy:** Comprehensive cantonal energy law reforms (Energiegesetz). Eight cantons modernized their energy legislation at different times: GR(2010), BE(2011), AG(2012), BL(2016), BS(2016), LU(2017), FR(2019), AI(2020). These reforms tightened building energy efficiency standards (insulation, heating system requirements for new builds and major renovations).

**Outcome:** Building permit data (Baugesuche/Baubewilligungen) from BFS and cantonal OGD portals (confirmed: BL has commune-level data 1991–2024). BFS PXWeb building stock data by canton, heating energy source, and renovation period. Secondary: energy consumption per capita from BFE.

**Identification:** Staggered DiD across 8 cantons adopting energy law reforms 2010–2020. Unit: canton-year (or commune-year for cantons with commune-level building data). CS-DiD estimator. Canton and year FEs.

**Why it's novel:**
- Energy building codes are a massive global policy lever (buildings = 40% of energy use) but cantonal variation in adoption is understudied
- Can decompose: new construction vs. renovation, residential vs. commercial, heating system switching
- Different from existing APEP Swiss papers on energy referendums (apep_0088) — this is about regulatory codes, not voter attitudes

**Feasibility check:**
- ✅ Staggered adoption: 8 cantons over 10 years
- ✅ Building data: BL confirmed commune-level 1991–2024; BFS PXWeb confirmed working
- ⚠️ Only 8 treated cantons — may face power concerns. Clustering at canton level with only 8 treated units requires RI/wild bootstrap.
- ⚠️ Building data at commune level only available for some cantons


## Idea 3: Municipal Tax Competition and Population Sorting — Evidence from Steuerfuss Changes

**Policy:** Annual municipal tax multiplier (Steuerfuss) changes across Swiss municipalities. The Steuerfuss ranges from ~50% to ~150% of the base cantonal tax rate, and municipalities adjust it annually. Sharp changes (>10 percentage points) create quasi-experimental variation.

**Outcome:** Municipal population change, age composition, and income proxies from BFS PXWeb (2010–2024). Tax capacity per capita (Steuerkraft) from cantonal financial statistics (ZH confirmed from 1990). Property prices from cantonal sources.

**Identification:** Event study DiD around large discrete Steuerfuss changes. Treatment: municipality experiences a ≥10pp Steuerfuss increase or decrease. Staggered timing across municipalities and years. Controls: municipalities with stable tax rates in the same canton. Municipality and canton×year FEs.

**Why it's novel:**
- Tiebout sorting tested at unprecedented granularity (2,100+ municipalities with annual tax rate data)
- Swiss setting is ideal: small municipalities, high mobility, transparent tax information
- Can test asymmetry: do tax increases push people out faster than tax decreases attract them?
- Can decompose: sorting by age (retirees most mobile?), income (high earners most responsive?), nationality (Swiss vs. foreign)

**Feasibility check:**
- ✅ Tax data: ZH has full time series from 1990 (confirmed); BL from 1975; multiple cantons
- ✅ Population: BFS PXWeb commune-level 2010–2024
- ⚠️ Well-studied topic (Schmidheiny 2006; Brülhart et al. 2012) — novelty must come from scale and mechanism decomposition
- ⚠️ Endogeneity of tax changes (tax rates respond to population, not just vice versa). Needs strong instrumentation.


## Idea 4: Cantonal Financial Management Reform and Fiscal Discipline

**Policy:** Cantonal adoption of accrual-based financial management (harmonisiertes Rechnungslegungsmodell, HRM2). Cantons transitioned from cameralistic (cash-based) to accrual accounting at staggered dates: AR(2012), BS(2012), BL(2017), BE(2022), with additional cantons in between. HRM2 increases transparency and makes deficits more visible.

**Outcome:** Municipal fiscal indicators from cantonal OGD portals: debt ratios, investment rates, surplus/deficit per capita, self-financing ratios. ZH has 15+ fiscal indicators at commune level (confirmed working). BL has line-item financial data from 2014 (confirmed).

**Identification:** Staggered DiD across cantons adopting HRM2. All municipalities within an adopting canton are treated simultaneously. Unit: commune-year. CS-DiD estimator. Municipality and year FEs.

**Why it's novel:**
- Accounting transparency as a causal lever for fiscal discipline is largely untested
- Can test: does making deficits visible → austerity? Or does transparency → more efficient spending without austerity?
- Links to public finance theory (fiscal rules, transparency, voter information)

**Feasibility check:**
- ✅ Staggered adoption: 4+ cantons at different times
- ✅ Fiscal data: ZH and BL confirmed with rich commune-level indicators
- ⚠️ Only 4 cantons explicitly listed — need to verify more cantons adopted HRM2 (most did eventually)
- ⚠️ Institutional reform → effects may be slow/subtle, requiring long post-periods


## Idea 5: Cantonal Physician Admission Restrictions and Healthcare Access

**Policy:** Cantonal physician admission moratoria (Zulassungsstopp/Zulassungssteuerung). After the federal moratorium expired (partially in 2011, fully in 2013), cantons gained authority to restrict new physician office openings. Several cantons implemented cantonal moratoria: BE(2014), AG(2018), AI(2021), with additional cantons at various dates.

**Outcome:** Physician density per 1,000 inhabitants from BFS PXWeb (confirmed: cantonal data 2017–2022, 34 geographic units, by specialty and age). ZH has commune-level physician counts from 1990 (confirmed). Health insurance premiums from BAG. Patient travel patterns from OBSAN.

**Identification:** Staggered DiD across cantons implementing physician admission restrictions. Unit: canton-year (or commune-year for ZH). CS-DiD estimator. Canton and year FEs.

**Why it's novel:**
- Supply-side healthcare regulation is understudied relative to demand-side (insurance expansion)
- Can test: do admission restrictions reduce physician supply? Or do physicians simply locate in unrestricted neighboring cantons (spatial substitution)?
- Switzerland's small size makes cross-cantonal substitution a first-order concern — a patient in one canton can easily see a physician across the border
- Connects to US literature on certificate-of-need (CON) laws but with much cleaner variation

**Feasibility check:**
- ✅ Policy variation exists with staggered timing
- ✅ Physician data: BFS PXWeb confirmed (2017–2022 by canton); ZH commune-level from 1990
- ⚠️ Only 3 cantons listed — need to verify how many implemented restrictions
- ⚠️ BFS physician panel only covers 6 years — limited for event study with late adopters
- ⚠️ Healthcare market is complex; isolating the admission restriction effect from other reforms is challenging
