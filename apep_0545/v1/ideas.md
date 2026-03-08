# Research Ideas

## Idea 1: The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage (idea_0450)

**Policy:** 12 US federal regulatory agencies (EPA, OSHA, FDA, NHTSA, FAA, FRA, MSHA, CPSC, FMCSA, PHMSA, NRC, CFTC) with distinct safety mandates. Analysis period 1994-2020, spanning six presidential administrations including three explicit deregulatory agendas. Trump EO 13771 (2017-2020) — which required 2 regulations eliminated for each new one — provides a critical natural experiment: did regulatory burden coverage actually produce deregulation even under an administration structurally committed to it?

**Outcome:** Federal Register API — rulemaking volume (n_rules, n_proposed, n_significant economically significant rules, pages_total) at agency-quarter level. Confirmed data: EPA ~10,000+ documents; OSHA 2,388; NHTSA 5,432; significant rules vary 4-121/year across agencies. Secondary: QuantGov RegData binding regulatory restrictions count in CFR by agency, 1970-2022.

**Identification:** Two-way FE panel regression at agency-quarter level (12 agencies × 108 quarters = 1,296 obs). Treatment variables constructed from GDELT GKG: (1) sector-specific safety incident coverage using themes CRISISLEX_C07_SAFETY, WB_2083_OCCUPATIONAL_HEALTH_AND_SAFETY, AVIATION_INCIDENT, etc. lagged one quarter; (2) regulatory burden coverage using EPU_CATS_REGULATION articles with negative tone. Asymmetry test: H₀: β₁ = |β₂| vs. H₁: β₁ > |β₂|. IV identification: competing news events (major elections, natural disasters, geopolitical crises in unrelated domains) crowd out sector-specific coverage, providing exogenous variation in salience. Eisensee-Strömberg competing-news IV applied to regulatory rulemaking for the first time.

**Why it's novel:** Availability cascade theory (Kuran-Sunstein 1999) has been theorized but never tested cross-sectorally. Existing work: (1) single-incident case studies; (2) country-level regressions without asymmetry tests; (3) sector-specific time series without cross-sectoral comparison. The ES IV has been applied to disaster relief, foreign aid, elections — never to federal rulemaking. Trump EO 13771 provides a unique test of whether deregulatory political commitment can overcome media-driven salience dynamics.

**Feasibility check:** Confirmed — Federal Register API returns real data (EPA 1,881 docs in 2010); GDELT GKG confirms all required themes present; 1,296-obs panel with meaningful variation in significant rules across agencies (EPA: 70-121/yr, OSHA: 4-20/yr). Not overstudied — no cross-sectoral test exists. READY grade.

---

## Idea 2: The Regulatory Ratchet in Building Safety — Champlain Towers and Asymmetric State Response (idea_0444)

**Policy:** Champlain Towers South collapse (June 24, 2021, Surfside FL, 98 deaths) as exogenous shock. Florida SB 4-D (signed May 2022) required milestone structural inspections for condominiums ≥3 stories. At least 13 states introduced or passed similar legislation 2022-2024 (NJ, VA, CO, CT, GA, HI, IL, MD, MA, NY, SC, TN, FL). ~37 states took no action. Asymmetry test: compare incident coverage → safety legislation versus regulatory burden coverage → ADU/zoning deregulation.

**Outcome:** Time-to-bill and time-to-law for structural inspection legislation (CAI Advocacy tracker + LegiScan API). State building permit volume (Census BPS annual files, all 50 states, confirmed). ADU/zoning deregulation passage as asymmetry test (YIMBY Action tracker + NCSL Housing database).

**Identification:** Tokyo Olympics (July 23 – August 8, 2021) as IV — crowded out Surfside collapse coverage in early weeks; pre-scheduled, exogenous to state regulatory preferences. States with higher Olympics coverage → less Surfside salience → slower/less structural inspection legislation. Run two parallel regressions: (a) incident coverage → structural inspection mandate adoption; (b) regulatory burden coverage → ADU/zoning deregulation. Ratchet confirmed if (a) significant, (b) ≈ 0.

**Why it's novel:** First application of Eisensee-Strömberg IV to building code adoption. Asymmetry test in building safety context has not been done. Olympics IV is cleanly applicable to post-disaster regulatory ratchet studies.

**Feasibility check:** 13 treated states; ~37 never-treated. GDELT DOC API confirmed live. Census BPS confirmed. Main concern: only 13 treated units limits precision. READY grade but smaller N than Idea 1.

---

## Idea 3: News Floods and Housing Supply — Testing the Deregulatory Media-to-Policy Channel (idea_0445)

**Policy:** Media salience of housing regulatory burden (GDELT articles tagged with housing affordability + regulatory framing) as treatment, 2018-2024. Deregulatory outcomes: ADU streamlining (CA SB 9/10, OR, WA, MN, ME, MA, MT, CT, VT and 8 more); zoning reform (MT SB 382, RI, FL, UT); parking mandate removal (CA AB 2097, OR, MA, MN). 15-20 states passed major deregulatory laws; ~30 did not.

**Outcome:** State-level building permit authorizations (Census BPS annual files, 50 states, 2010-2023, confirmed). Passage of deregulatory housing legislation (YIMBY Action tracker + NCSL Housing + LegiScan). Local permit counts via BPS MSA annual data.

**Identification:** ES IV: competing news intensity (major elections, natural disasters, geopolitical crises) predicts lower housing regulation coverage in same month, exogenously. First stage: high competing news → lower housing regulation salience. Second stage: lower salience → less deregulatory legislative activity. Key test: compare IV coefficient for incident-coverage → safety regulation (from companion paper) against burden-coverage → deregulation (this paper). If (a) >> 0 and (b) ≈ 0, ratchet confirmed. The deregulatory mirror of Eisensee-Strömberg.

**Why it's novel:** Causal effect of media coverage on deregulation has never been tested. Housing supply literature (Gyourko-Molloy-Saiz; Hsieh-Moretti) identifies costs of regulation but not the media-salience channel. A well-executed null confirms the systematic democratic bias.

**Feasibility check:** 50 states × 7 years = 350 state-year obs. GDELT live, Census BPS confirmed, LegiScan documented. Natural companion to Idea 1 — both arms of the asymmetry test. READY grade. Best paired with Idea 1 or 2.
