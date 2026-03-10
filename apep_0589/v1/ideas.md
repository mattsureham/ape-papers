# Research Ideas

## Idea 1: ERDF Treatment Withdrawal and Regional Convergence: Evidence from Regions Graduating Through the 75% Threshold
**Policy:** EU ERDF Objective 1 allocates the highest co-financing rates (up to 85%) to NUTS-2 regions with GDP per capita below 75% of the EU27 average. Eligibility is recalculated at each 7-year programming period boundary. Regions crossing the 75% threshold between the 2007-2013 and 2014-2020 periods experienced an abrupt funding drop from 85% to 60% or 50% co-financing. ~34 regions graduated, including PL51 (Dolnośląskie, at exactly 75% in 2013), CZ03 (Jihozápad, 74%), CZ02 (Střední Čechy, 77%).
**Outcome:** Regional GDP per capita in PPS (Eurostat tgs00006, 2,843 values confirmed), compensation of employees (nama_10r_2coe, 191K values), employment rates (lfst_r_lfe2emprtn), GVA by sector (nama_10r_2gvagr). ERDF annual payments at NUTS-2 from cohesiondata.ec.europa.eu (13,166 ERDF records confirmed).
**Identification:** Multi-period fuzzy RDD at the 75% GDP/capita threshold. Running variable: 3-year average GDP per capita (PPS) as % of EU27 average. Novel relative to Becker, Egger & von Ehrlich (2010, 2013): exploits the 2007-2013 → 2014-2020 transition as a treatment WITHDRAWAL shock, not static eligibility. Cross-border spillover test: German NUTS-2 neighbors (permanently at 120-185% EU avg) serve as clean untreated controls; spillover exposure constructed as distance-weighted share of economic neighborhood that is ERDF-funded. Built-in placebos: non-graduating regions still below threshold, always-above regions far from cutoff.
**Why it's novel:** Becker et al. (2010, 2013) established the RDD for static eligibility. Three gaps: (1) the graduation shock (treatment withdrawal) has never been studied; (2) cross-national border spillovers are unexplored; (3) multi-period identification using EUR per capita ERDF as running variable has not been applied. Zero APEP papers on EU Structural Funds.
**Feasibility check:** Confirmed: 34 NUTS-2 regions in 70-80% band around 75% threshold (2013); ERDF payment data confirmed at NUTS-2 for 2007-2020; all five primary Eurostat datasets accessible via open APIs; 13,166 ERDF payment records and 2,843 GDP observations verified.

## Idea 2: EU Geo-Blocking Ban and Cross-Border Price Convergence: Triple-Difference Evidence
**Policy:** EU Regulation 2018/302 (December 2018) prohibited nationality-based online discrimination for goods but explicitly excluded audiovisual services, transport, financial services, and healthcare.
**Outcome:** HICP monthly indices (prc_hicp_midx) by COICOP: treated categories (clothing, AV equipment, glassware) vs excluded services (transport, cultural/AV). 12,960 values confirmed. Cross-border e-commerce purchases (isoc_ec_ibuy), 390 values.
**Identification:** Triple-difference: Time (pre/post Dec 2018) × Product (covered goods vs excluded services) × Cross-country price dispersion. The regulatory exclusion structure creates a clean built-in placebo.
**Why it's novel:** No paper uses the regulatory exclusion structure for DDD on HICP price convergence. Commission formal evaluation launched Feb 2025.
**Feasibility check:** Confirmed: 27 countries × 96 months × 5 categories = 12,960 observations; variation confirmed; no existing DDD.

## Idea 3: Staggered PSD2 Transposition and Consumer Internet Banking Adoption
**Policy:** PSD2 (Directive 2015/2366) required banks to open payment account infrastructure to licensed third-party providers. Transposition deadline Jan 2018. Staggered from Oct 2017 (Estonia) to Nov 2019 (Romania).
**Outcome:** Internet banking usage (Eurostat isoc_ci_ac_i), 431 observations. SBS K6419 enterprise counts for fintech entry (128 values).
**Identification:** Staggered DiD using CELLAR SPARQL notification dates. CS-DiD with group-time ATT. 7+ pre-periods, 7+ post-periods. Placebo: non-financial internet usage.
**Why it's novel:** Only existing PSD2 DiD uses single EU-level adoption date, not staggered national transposition.
**Feasibility check:** Confirmed: 23 transposition dates, 258 NIMs verified, 431 outcome values.
