# Research Ideas

## Idea 1: Do Administrative Borders Tax Electricity? A Multi-Border Spatial RDD of Swiss Cantonal Energy Policy

**Policy:** Swiss cantons enacted comprehensive energy law reforms at different times between 2010 and 2020. Eight cantons adopted major reforms: GR (2010), BE (2011), AG (2012), BL (2016), BS (2016), LU (2017), FR (2019), AI (2020). These laws include cantonal energy fund levies, renewable energy promotion charges, and building efficiency mandates that create sharp regulatory discontinuities at cantonal borders.

**Outcome:** ElCom municipal electricity tariffs, available via LINDAS SPARQL — 745,458 observations across 2,712 municipalities, 2011–2026. Critically, tariffs decompose into: energy cost, grid usage, federal aid fee (Netzzuschlag), and cantonal/municipal charges (Abgaben). This decomposition enables a mechanism test.

**Identification:** Multi-border spatial RDD. For each cantonal border, compare tariff levels in municipalities just inside vs. just outside the border. The design exploits the staggered timing: before a canton adopts its energy law, the border discontinuity should be smaller; after adoption, the "charges" component should jump. Combine spatial RDD with event-study (spatial DiD). Built-in placebo: the federal aid fee (Netzzuschlag) is nationally uniform and should show zero discontinuity at every cantonal border. Multi-cutoff design across ~50 cantonal border pairs provides internal replication.

**Why it's novel:** Farsi et al. (2025) is the only Swiss energy spatial RDD, but they exploit the cultural (language) border, not policy borders. No paper uses cantonal POLICY variation + ElCom tariff data + spatial RDD. This fills a first-order gap: how much of Switzerland's enormous municipal electricity price variation (10–50 Rp/kWh) is driven by cantonal policy vs. geographic/cost fundamentals?

**Feasibility check:** Confirmed: ElCom SPARQL returns clean CSV with municipality IDs, tariff components, and 16 years of data. swissBOUNDARIES3D provides municipal polygons for computing distance to cantonal borders. Cantonal energy law dates available from Fedlex SPARQL and rcds/swiss_legislation. No API keys needed.

---

## Idea 2: Building Energy Mandates and Fossil Fuel Commodity Substitution — MuKEn 2014 at Swiss Cantonal Borders

**Policy:** MuKEn 2014 (Mustervorschriften der Kantone im Energiebereich) requires that when replacing a fossil heating system, buildings must meet minimum renewable energy thresholds (10–100% depending on canton). Crucially, three cantons rejected MuKEn 2014 entirely: Aargau (AG), Bern (BE), and Solothurn (SO). Other cantons adopted it between 2016 and 2023. This creates sharp borders where municipalities face different heating replacement mandates.

**Outcome:** Two complementary measures: (a) heating system composition from cantonal GWR (building register) extracts — several cantons publish municipal-level data (Basel-Landschaft, Zug confirmed), and (b) ElCom electricity tariffs as a demand-side proxy (heat pump adoption increases electricity consumption).

**Identification:** Spatial RDD at three key borders — BL (adopted 2020)/SO (rejected), ZH (adopted 2022)/AG (rejected), FR (adopted 2020)/BE (rejected). Treatment: MuKEn 2014 adoption mandating renewable heating replacement. Running variable: distance to cantonal border. Built-in placebo: new construction (regulated similarly under both MuKEn 2008 and 2014) vs. heating replacements (only MuKEn 2014 adds requirements).

**Why it's novel:** No existing paper estimates the causal effect of building energy codes on fossil fuel commodity demand using spatial RDD. The commodity substitution channel (oil/gas → electricity via heat pumps) is a first-order energy transition question. The rejection by 3 cantons creates clean counterfactual borders.

**Feasibility check:** Confirmed: BL publishes municipal GWR with heating data. ZH has excellent open data infrastructure. ElCom tariffs available for all municipalities. Key risk: municipal-level heating data may not be available for ALL relevant border cantons — requires verification of SO, AG, BE cantonal open data.

---

## Idea 3: Water Royalties and Hydroelectric Electricity Pricing in Swiss Mountain Cantons

**Policy:** Swiss cantons charge Wasserzins (water royalties) to hydroelectric operators — CHF per kW of installed capacity. Federal maximum: 110 CHF/kW since 2015 (previously 80 CHF/kW). Total annual revenue ~550M CHF. Highly concentrated: Valais (160M), Graubünden (120M), Ticino (55M). In some mountain municipalities, Wasserzins provides 40–50% of fiscal revenue.

**Outcome:** ElCom municipal electricity tariffs, specifically the energy component (reflects production costs including Wasserzins). Secondary outcome: municipal tax rates (Steuerfuss), since Wasserzins revenue may substitute for tax revenue.

**Identification:** Spatial RDD at borders between high-Wasserzins mountain cantons (VS, GR, TI) and neighboring cantons. The 2015 federal maximum increase from 80 to 110 CHF/kW provides temporal variation for a spatial DiD.

**Why it's novel:** Betz et al. (2021) model Wasserzins pass-through but use firm-level cost data, not consumer prices. Avenir Suisse argues Wasserzins cannot pass through in competitive markets. This paper would provide the first causal estimate of Wasserzins pass-through to retail electricity prices using the spatial border discontinuity.

**Feasibility check:** Confirmed: ElCom data available, boundary data available. KEY WEAKNESS: Most cantons charge the federal maximum of 110 CHF/kW, so cross-border rate variation may be limited. The 2015 reform provides a time shock but affected all cantons similarly. Power concerns are real — this design may be underpowered.

---

## Idea 4: Cantonal Organic Farming Subsidies and Agricultural Commodity Production

**Policy:** Swiss agricultural policy has a two-tier structure. Federal direct payments include an organic farming contribution (Bio-Beiträge). Some cantons supplement this with additional organic farming subsidies, advisory services, or marketing support. The cantonal variation in organic promotion intensity creates different incentives at cantonal borders.

**Outcome:** BFS PXWeb municipal agricultural data (table px-x-0702000000_104): farms by type (organic vs. conventional), agricultural land area (arable, grassland, permanent crops), livestock numbers. Available 1975–2024 at municipal level for 2,301 geographic units.

**Identification:** Spatial RDD at cantonal borders between cantons with strong vs. weak organic promotion. Running variable: distance to cantonal border. Outcome: organic farm share, crop mix, farm consolidation.

**Why it's novel:** The organic transition is a major agricultural commodity question. Whether public subsidies drive organic adoption or merely subsidize inframarginal farmers remains debated. Swiss cantonal borders provide quasi-experimental variation.

**Feasibility check:** Confirmed: BFS agricultural data available at municipal level. KEY WEAKNESS: Cantonal organic subsidy variation is not well-documented in structured data — would need to manually compile cantonal programs. The federal component dominates (CHF 1,600/ha for grassland, CHF 1,200/ha for open arable), so cantonal supplements may be too small to detect.

---

## Idea 5: TRAF 2020 Tax Reform and Switzerland's Commodity Trading Sector

**Policy:** The TRAF reform (Tax Reform and AHV Financing), effective Jan 1, 2020, abolished preferential tax statuses (holding, domiciliary, mixed companies) that commodity trading firms relied on. Cantons responded by cutting headline corporate tax rates to remain competitive. The rate cuts varied dramatically: Geneva cut from 24.2% to 13.99%, Vaud from 21.37% to 14%, while Zug (already at ~11.8%) made minimal changes.

**Outcome:** Enterprise statistics (STATENT) from BFS — firm counts, employment, and value added at municipal level. Supplemented by SHAB commercial register entries for new incorporations.

**Identification:** Spatial RDD at borders between cantons with large tax cuts (GE, VD, BS) and cantons with smaller cuts (ZH, ZG). The treatment is the magnitude of the cantonal tax rate reduction. Running variable: distance to cantonal border.

**Why it's novel:** Switzerland hosts ~500+ commodity trading firms controlling ~35% of global crude oil trade. TRAF 2020 was the largest reform to their tax environment in decades. No paper has estimated the spatial reallocation effects.

**Feasibility check:** KEY WEAKNESS: Commodity trading firms are few in number (~500), spatially concentrated (Geneva, Zug, Lugano), and may not be identifiable in BFS enterprise data without NOGA industry code granularity. Power is the primary concern. This is a "cool policy, impossible measurement" trap.
