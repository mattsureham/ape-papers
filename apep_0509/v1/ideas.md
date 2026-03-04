# Research Ideas — apep_0509

## Idea 1: When Labor Gets Expensive: MGNREGA, Input Substitution, and Crop-Specific Agricultural Productivity

**Policy:** India's Mahatma Gandhi National Rural Employment Guarantee Act (MGNREGA), rolled out in three staggered phases: Phase I (200 districts, Feb 2006), Phase II (+130 districts, Apr 2007), Phase III (all remaining ~310 districts, Apr 2008). Districts assigned based on Planning Commission's backwardness index.

**Outcome:** ICRISAT District Level Database (DLD) via REST API — district-level crop-specific area, production, and yield (kg/ha) for 29 crops across 313 apportioned districts, 1966–2017. Supplemented with ICRISAT fertilizer consumption, cropwise irrigated area, agricultural wages, and rainfall data.

**Identification:** Callaway & Sant'Anna (2021) staggered DiD exploiting the three-phase rollout. Phase I districts (treated 2006) vs not-yet-treated Phase II+III as controls; Phase II (treated 2007) vs not-yet-treated Phase III. Pre-treatment: 2000–2005 (6+ years). Post-treatment: 2006–2017 (11 years). ~313 districts, 20 states.

**Why it's novel:**
- **Crop-specific productivity is unstudied.** Five APEP papers and multiple published studies examine MGNREGA's effects on nightlights, firm counts, and crop diversification. Bhargava (2023, EDCC) studies technology adoption but stops short of productivity. The CDE Delhi WP found null effects on aggregate yields but never disaggregated by crop type. No paper traces the full chain: wage shock → input substitution → crop-specific yield effects.
- **Built-in placebo via crop labor intensity.** Labor-intensive crops (rice, cotton, sugarcane) should show the largest mechanization-induced yield gains. Less labor-intensive crops (wheat, pulses) serve as placebo outcomes. This heterogeneity IS the mechanism test.
- **Dual-channel decomposition.** MGNREGA affects agriculture through (1) wage push → labor scarcity → capital/input substitution, and (2) demand boost → input purchases (fertilizer, irrigation). ICRISAT data on wages, fertilizer consumption, and irrigated area enables estimation of both channels.
- **Long horizon.** 11 years post-treatment captures sustained structural adjustment, not just short-run disruption.
- **Trade-off discovery.** The employment guarantee simultaneously raises labor costs (anti-productivity) and raises demand for modern inputs (pro-productivity). The net effect is empirically ambiguous, making the finding valuable regardless of sign.

**Feasibility check:** ICRISAT DLD API confirmed working (no auth, JSON, 16,146 rows). Census 2001 population data available from ICRISAT for constructing backwardness index/phase assignment. Agricultural wages available through 2013 (first stage). Fertilizer and irrigation data available through 2017–2020. Crop yield data through 2017. All endpoints tested successfully.

---

## Idea 2: Liberating Agricultural Markets: APMC Reforms, Price Transmission, and Farmer Welfare in India

**Policy:** Indian states reformed their Agricultural Produce Market Committee (APMC) acts at different times: Bihar abolished APMC entirely (2006), Kerala never had one, Maharashtra (2006), MP (2007), Rajasthan (2007), Gujarat (2008), Karnataka (2014). Other states maintained restrictive APMC regimes requiring mandatory mandi sale.

**Outcome:** ICRISAT DLD farm harvest prices (17 crops × 313 districts × 50 years), crop area/production, and price dispersion measures. Combined with ICRISAT market infrastructure data.

**Identification:** Staggered DiD using state-level APMC reform dates as treatment. Pre-period: 2000–2005. Post-period: 2006–2016. ~7 reforming states vs ~13 non-reforming states in ICRISAT coverage. Event-study with CS-DiD.

**Why it's novel:** e-NAM platform already studied (apep_0446). But APMC structural reforms (mandi abolition) vs digital platforms are different interventions. The question: does removing mandatory mandi intermediation raise farm-gate prices or expose farmers to monopsonistic traders? Trade-off between market liberalization and price protection.

**Feasibility check:** ICRISAT farm harvest prices endpoint confirmed (15,150 rows, 1966–2016). Reform dates well-documented in government notifications. However, only ~7 reforming states limits treated units below the 20-state DiD threshold. Would need to count districts within reforming states as treated units (state × district nested design). Moderate feasibility risk due to limited state-level variation.

---

## Idea 3: Forests for the Forest Dwellers: India's Forest Rights Act, Tenure Security, and Deforestation

**Policy:** The Scheduled Tribes and Other Traditional Forest Dwellers (Recognition of Forest Rights) Act, 2006. State-level implementation staggered 2008–2015. Individual and community forest rights titles distributed at varying rates across states.

**Outcome:** Hansen et al. Global Forest Watch annual tree cover loss data (30m resolution, 2000–present). State/district-level aggregation of forest loss. Ministry of Tribal Affairs reports on FRA titles distributed by state and year.

**Identification:** Staggered DiD using state-level FRA title distribution intensity × year. States with early/high title distribution vs states with late/low distribution. Pre-period: 2000–2007. Post-period: 2008–2021.

**Why it's novel:** The FRA tenure security → deforestation link is largely unstudied empirically. The theoretical prediction is ambiguous: secure tenure may incentivize conservation (investment motive) or enable land clearing (development motive). This is a trade-off discovery paper. Global Forest Watch provides high-frequency annual outcomes with long pre/post windows.

**Feasibility check:** Global Forest Watch data freely downloadable. However, state-level FRA implementation data requires manual compilation from Ministry reports (PDF). District-level GIS aggregation of tree cover loss needs spatial processing. Feasibility is MODERATE — data assembly requires significant effort. Also, FRA implementation is endogenous (states with more forests implemented faster), requiring careful controls.

---

## Idea 4: Cash and Crops: India's Demonetization Shock During the Rabi Planting Season

**Policy:** India's November 8, 2016 demonetization removed 86% of currency in circulation overnight. This hit exactly during the rabi (winter crop) planting season (November–January), when farmers need cash for seeds, fertilizer, and labor.

**Outcome:** ICRISAT DLD rabi crop area and yields (wheat, chickpea, rapeseed/mustard, barley) in 2016-17 season vs prior years. Agricultural wages, fertilizer purchases. Cross-sectional intensity: district-level pre-demonetization cash dependence (proxied by banking infrastructure from ICRISAT).

**Identification:** Event study with cross-sectional intensity variation. Districts with fewer bank branches per capita (higher cash dependence) should show larger disruption to rabi planting. Triple-diff: cash-dependent districts × post-demonetization × rabi crops (vs kharif crops planted before the shock).

**Why it's novel:** Demonetization's economic effects are studied (Chodorow-Reich et al. 2020 AER; apep_0453 on economic geography). But the agricultural-seasonal channel is novel: the shock hit during the exact planting window. The triple-diff using kharif (pre-shock) vs rabi (post-shock) crops as within-district placebos is a clean design. However, apep_0453 already covers demonetization broadly.

**Feasibility check:** ICRISAT crop data confirmed through 2017 (captures rabi 2016-17). Banking infrastructure data available from ICRISAT. Rainfall data only through 2003 (ICRISAT) — would need alternative source. Very short post-window (1 rabi season) is a significant weakness; tournament judges penalize short horizons. MODERATE feasibility.

---

## Idea 5: Financial Inclusion and Agricultural Investment: Jan Dhan Yojana, Credit Access, and Farm Productivity

**Policy:** Pradhan Mantri Jan Dhan Yojana (PMJDY), launched August 2014, opened 530+ million bank accounts. Not staggered by district, but pre-existing banking infrastructure creates cross-sectional intensity variation: districts with fewer banks saw larger marginal expansions in financial access.

**Outcome:** ICRISAT DLD crop yields, fertilizer consumption, and irrigated area. RBI Basic Statistical Returns for district-level credit and deposits. Pre-treatment banking density (ICRISAT bank data) as intensity measure.

**Identification:** Continuous DiD / intensity design: districts with lower pre-2014 banking density (higher marginal financial inclusion gain from Jan Dhan) × post-2014. Pre-period: 2008–2013. Post-period: 2015–2017. 313 districts.

**Why it's novel:** The financial inclusion → agricultural productivity link is understudied. Jan Dhan expanded bank accounts, but did farmers use new accounts for agricultural credit? The channel: bank accounts → formal credit access → fertilizer/input purchases → yield improvements. The design separates the credit channel from the savings channel using crop-specific input intensity.

**Feasibility check:** ICRISAT data confirmed through 2017. Banking infrastructure data available from ICRISAT. RBI BSR has district-level credit data (confirmed accessible). However, Jan Dhan is not a clean staggered rollout (national launch), so identification relies on intensity variation. The parallel trends assumption — that low-bank and high-bank districts would have followed similar yield trends absent Jan Dhan — needs careful defense. Moderate feasibility.
