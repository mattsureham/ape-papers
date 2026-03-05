# Research Ideas

## Idea 1: Does Geographic Targeting of Housing Subsidies Matter? Evidence from France's PTZ Reform

**Policy:** In 2018, the French Finance Law halved the Prêt à Taux Zéro (PTZ) subsidy for new construction in zones B2/C from 40% to 20% of the purchase price, while maintaining it at 40% in zones A/Abis/B1. The Pinel tax incentive for rental investment was simultaneously restricted to zones A/Abis/B1. This represented a deliberate spatial reallocation of ~€3.5 billion/year in housing subsidies away from "loose" markets toward "tight" markets. The reform intensified in 2020 (full PTZ elimination in B2/C for new construction), creating a multi-stage natural experiment.

**Outcome:** (1) DVF property transactions — universe of ~3.5M sales/year across all French communes from 2014-2025, covering prices, volumes, property types, and locations. (2) Sitadel construction permits — commune-level new housing starts (logements commencés) from 2013+. (3) INSEE BDM — commune-level population flows, demographics.

**Identification:** Staggered-intensity DiD. Treatment: ~21,000 communes in zones B2/C that lost PTZ/Pinel. Control: ~5,000 communes in zone B1 (next-tightest classification). Event study 2014-2025 with multiple shocks: 2018 halving, 2020 elimination, 2024 partial restoration. Border discontinuity analysis comparing communes on the B1/B2 boundary within the same département.

**Why it's novel:** (1) First study of France's 2018 PTZ geographic restriction using universe transaction data. The closest comparator is Hilber & Turner (2014, ECMA) on US mortgage interest deduction capitalization — this is the mirror test: what happens when subsidies are REMOVED? (2) Multi-shock design with a reversal (2024 restoration) provides rare identification value. (3) Built-in placebo: commercial/industrial property transactions (not eligible for PTZ) should be unaffected. (4) Mechanism decomposition: price capitalization, construction supply response, first-time buyer sorting, population flows.

**Feasibility check:** Confirmed: DVF open data on data.gouv.fr (2014-2025 CSV), ABC zone classification on data.gouv.fr (commune-level xlsx), Sitadel on SDES (2013+ CSV). No France-specific APEP paper covers PTZ reform. Hilber & Turner studied US MID but no comparable French study exists with universe data.

---

## Idea 2: The Rental Ban Penalty: Energy Labels and Housing Asset Values in France

**Policy:** France's Loi Climat (2021) made DPE (Diagnostic de Performance Énergétique) labels legally binding and introduced a staggered rental ban: G-rated properties (>450 kWh/m²/year) banned from rental since January 2023, F-rated from 2028, E-rated from 2034. This creates a multi-cutoff regulatory threshold directly affecting property use rights.

**Outcome:** DVF property transactions matched to ADEME's DPE database (publicly available on data.gouv.fr since 2021). Sales prices by DPE rating, transaction volumes, time-to-sale.

**Identification:** Sharp regression around the G threshold (450 kWh/m²/year) combined with DiD: compare G-rated vs. F-rated properties before/after January 2023 enforcement. Additional power from anticipation analysis: F-rated properties should show price declines approaching the 2028 ban. Multi-cutoff design (G/F/E) provides internal replication.

**Why it's novel:** The UK EPC paper (apep_0477, #2 on leaderboard) studied information disclosure effects. This is fundamentally different: France imposed a REGULATORY BAN on rental, eliminating the use value of G-rated investment properties. The mechanism is asset stranding, not information provision.

**Feasibility check:** DVF is accessible. DPE database is on data.gouv.fr (ADEME). Matching by address is feasible but adds complexity. G-rated properties comprise ~7% of housing stock (~2M units). Post-period is 2.5 years (short but the effect should be immediate and sharp). NOT studied in APEP.

---

## Idea 3: SRU Social Housing Quotas and Private Housing Markets

**Policy:** The Loi SRU (2000) requires municipalities >3,500 inhabitants in urban areas to maintain ≥25% social housing (raised from 20% by Loi Duflot in 2013). The 2013 reform tripled financial penalties for non-compliance. Municipalities below the threshold face annual penalties proportional to their gap.

**Outcome:** DVF property transactions in SRU-eligible communes; social housing construction data from RPLS (Répertoire des Logements Locatifs des Bailleurs Sociaux).

**Identification:** DiD comparing communes newly pushed into non-compliance by the 2013 threshold change (between 20-25% social housing) vs. communes above 25%. Pre-period challenge: DVF only starts 2014, limiting pre-treatment data for the 2013 reform. Alternative: study the 2022 Loi 3DS exemptions (communes in "zones détendues" exempted from SRU).

**Why it's novel:** Diamond & McQuade (2019, AER) studied US LIHTC and property values. France's mandatory quotas with financial penalties represent a fundamentally different institutional mechanism.

**Feasibility check:** DVF from 2014 is available. SRU compliance data is on data.gouv.fr. But DVF pre-period for the 2013 reform is very limited (1 year). The 3DS exemptions are cleaner but also recent (2022). RISK: limited pre-treatment for key variation.

---

## Idea 4: Flood Risk Designation and Housing Price Capitalization

**Policy:** Plans de Prévention des Risques d'Inondation (PPRi) designate flood risk zones in communes. Staggered adoption since 1995 across ~17,000 communes. Each plan creates red zones (no construction allowed), blue zones (construction with restrictions), and white zones (unaffected).

**Outcome:** DVF matched to PPRi zone maps (available through Géorisques/GASPAR database). Property prices by zone designation.

**Identification:** Triple-difference: commune × flood zone designation × time (pre/post PPRi approval). Within-commune comparison of transactions in newly designated risk zones vs. unaffected zones controls for all commune-level trends.

**Why it's novel:** Rich international literature on flood risk and housing prices, but none using France's PPRi natural experiment with universe transactions. The within-commune design controls for many confounds.

**Feasibility check:** DVF accessible. GASPAR database (PPRi dates) accessible. BUT: matching transactions to specific PPRi zones requires GIS overlay of PPRi maps with cadastral parcels — technically complex. Most PPRi were approved before DVF (2014) so limited "new" plan approvals. RISK: GIS complexity and limited post-2014 variation.

---

## Idea 5: Encadrement des Loyers: Staggered Rent Control and Housing Sales

**Policy:** Rent control (encadrement des loyers) implemented in Paris (2015, suspended 2017, reintroduced 2019), Lille (2020), Lyon/Villeurbanne (2021), Bordeaux/Montpellier (2022), and several Paris suburbs (2021-2024).

**Outcome:** DVF sales prices in rent-controlled cities vs. comparable uncontrolled cities. Transaction volumes.

**Identification:** Staggered DiD using Callaway-Sant'Anna across cities. Paris on-off-on provides a unique reversal natural experiment.

**Why it's novel:** Diamond, McQuade & Qian (2019, AER) studied San Francisco rent control. French setting features staggered adoption AND a judicial reversal in Paris. DVF provides universe data.

**Feasibility check:** DVF accessible. Rent control adoption dates well documented. BUT: only ~10-15 treated cities — too few clusters for reliable inference. Judges penalize "few-cluster designs" explicitly. RISK: insufficient treated units.
