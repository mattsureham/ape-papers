# Research Ideas

## Idea 1: Pills and Diplomas — PDMP Mandates and College Completion

**Policy:** State mandatory Prescription Drug Monitoring Program (PDMP) consultation laws. 40+ states enacted requirements that prescribers must check the PDMP before prescribing controlled substances (primarily opioids). Staggered adoption from 2007 (Nevada) through 2019, with the main wave in 2012-2017. Dates well-documented in Buchmueller & Carey (2018, AEJ:EP), Gunadi (2023, BMC Public Health).

**Outcome:** IPEDS higher education data (Azure: `raw/ipeds/ipeds.duckdb`). Institution-level panel with 7,000+ schools, 2000-2024. Primary outcomes: first-year retention rates (ef_d), graduation rates at 150% normal time (gr), fall enrollment (ef_a), and completions by CIP code (c_a). Institution characteristics from hd (state, sector, level, HBCU, Carnegie classification).

**Joker Dataset:** CDC drug poisoning mortality from data.cdc.gov (jx6g-fdh6): state × age group (15-24 years) × year, 1999-2015, with deaths, population, and crude death rates. Programmatic Socrata API. Supplemented by VSRR (xkb8-kh2a) for state × drug-type-specific overdose deaths, 2015-2025 (synthetic opioids/fentanyl vs. prescription opioids).

**Identification:** Callaway & Sant'Anna (2021) staggered DiD. Treatment = state enacts mandatory PDMP consultation. Unit = institution (mapped to state via hd table). Pre-treatment: 5+ years for most treated cohorts. Never-treated states (8-10) serve as controls. Cluster SEs at state level.

**Why it's novel:**
- PDMP literature focuses on prescribing patterns, overdose deaths, and labor markets. Nobody has examined college outcomes.
- Higher-ed literature studies financial aid, tuition, and admissions. Nobody has linked health crisis policy to retention/graduation.
- The substitution hypothesis creates a belief-changing twist: PDMPs may push users from prescriptions to illicit fentanyl, *worsening* outcomes for the most affected students rather than improving them.
- Built-in placebos: institutions serving primarily older/graduate students should show no effect.

**Feasibility check:**
- ✅ State variation: 40+ treated states, 8-10 never-treated controls, staggered over a decade
- ✅ IPEDS data confirmed accessible (DuckDB, 1.2 GB, all tables tested locally)
- ✅ CDC data confirmed accessible (Socrata API, state × age group × year)
- ✅ Not in APEP (apep_0056 studied PDMP → overdose deaths, apep_0085 studied PDMP → employment — neither links PDMPs to higher education)
- ✅ Power: ~3,000+ 4-year institutions × 15+ years = 45,000+ observations

---

## Idea 2: High on Enrollment — Recreational Cannabis and College Composition

**Policy:** State recreational cannabis legalization. Staggered adoption from 2012 (CO, WA) through 2024. 24 states + DC as of 2024. Clear effective dates for both legalization and retail sales start.

**Outcome:** IPEDS enrollment data (ef_a) by race/ethnicity, gender, full-time/part-time status. Also ef_b (enrollment by age), retention (ef_d), and completions (c_a).

**Joker Dataset:** State cannabis tax revenue data from state fiscal agencies (publicly available) as a measure of commercial cannabis market size/exposure intensity. Alternatively, dispensary counts by state from state licensing databases.

**Identification:** CS-DiD with staggered legalization dates. Treatment = legalization effective date (or retail sales start date). Unit = institution. Cluster at state level.

**Why it's novel:**
- Existing cannabis-education literature focuses on high school outcomes. College-level effects are understudied.
- The composition angle (who enrolls, not just how many) is unexplored: does legalization shift enrollment toward part-time? Change racial gaps? Affect 2-year vs. 4-year differently?
- APEP has cannabis papers (0026, 0082, 0110) but all study employment, self-employment, or traffic — none study education outcomes.

**Feasibility check:**
- ✅ 24+ treated states, staggered over 12 years
- ✅ IPEDS data confirmed
- ✅ Cannabis tax revenue: publicly available from state fiscal offices (manual collection)
- ⚠️ Moderately studied in working papers (Anderson, Hansen, Rees have tangential work)
- ✅ Power: adequate with 24 treated states

---

## Idea 3: Narcan on Campus — Naloxone Access Laws and College Retention

**Policy:** State naloxone access laws (standing orders allowing pharmacists to dispense naloxone without individual prescription). 40+ states adopted between 2013-2018. Some states also enacted Good Samaritan laws protecting overdose reporters.

**Outcome:** IPEDS retention rates (ef_d), graduation rates (gr), enrollment (ef_a). Focus on 4-year institutions and community colleges separately.

**Joker Dataset:** Same CDC overdose data as Idea 1 (jx6g-fdh6 for 1999-2015 age-specific; VSRR for 2015-2025 drug-specific). The mechanism story is reversed: naloxone SAVES lives → students who would have died survive to graduate.

**Identification:** CS-DiD with staggered naloxone access law dates. Treatment = state enacts standing order or third-party prescription law. Unit = institution. Never-treated states as controls.

**Why it's novel:**
- Naloxone literature examines overdose survival and moral hazard (do users take more risks?). Nobody asks: does naloxone access improve educational attainment by keeping students alive?
- The "lives saved → degrees earned" mechanism is visceral and policy-relevant.
- Complements Idea 1 (PDMP reduces supply; naloxone reduces lethality of demand-side response).

**Feasibility check:**
- ✅ 40+ states with staggered adoption
- ✅ IPEDS data confirmed
- ✅ CDC data confirmed
- ⚠️ Naloxone laws often coincide with other opioid policies (PDMPs, pill mill laws) — disentangling will require careful specification
- ✅ Power: 40+ treated states

---

## Idea 4: ACA Dependent Coverage and the 26th Birthday Cliff in College Completion

**Policy:** ACA Section 1001 (September 23, 2010): young adults can stay on parents' health insurance until age 26. Applied nationally (not staggered), but 19 states had PRIOR dependent coverage mandates with varying age cutoffs (23, 24, 25, 26). The federal ACA extended to all states, creating a DDD design: (state with prior mandate vs. without) × (age near 26 vs. older) × (before vs. after 2010).

**Outcome:** IPEDS fall enrollment (ef_a, ef_b by age), retention (ef_d), completions (c_a). Focus on institutions with older student populations (community colleges, for-profit schools, part-time programs).

**Joker Dataset:** College Scorecard API (api.data.gov) — institution-level completion rates by age group, earnings after graduation, and student demographics. Provides a downstream labor market outcome beyond just completion.

**Identification:** Triple-difference (DDD): states that gained dependent coverage in 2010 (no prior mandate) vs. states that already had it × near-26 vs. older students × pre/post 2010. This is stronger than simple DiD because the ACA was national.

**Why it's novel:**
- ACA dependent coverage is well-studied for health insurance take-up, health utilization, and labor supply. But college completion effects are unexplored.
- The "26th birthday cliff" creates a natural age discontinuity: students aging out of coverage face a discrete insurance shock. Do they drop out?
- College Scorecard earnings data adds downstream wage effects of interrupted education.

**Feasibility check:**
- ✅ 19 prior-mandate states provide cross-state variation
- ✅ IPEDS data confirmed (ef_b has enrollment by age)
- ✅ College Scorecard: free API with key, institution-level
- ⚠️ DDD design is complex; effect sizes may be small
- ⚠️ Hard to isolate the 26-year-old age cliff in IPEDS data (age bins may be too coarse)

---

## Idea 5: Endowment Shocks and Institutional Resilience — The 2008 Crash in University Finance

**Policy:** 2008-2009 financial crisis as a "natural experiment." University endowments lost 20-30% in FY2009 (some lost 50%+). The shock was plausibly exogenous to individual institutions and differentially affected universities based on endowment size and asset allocation.

**Outcome:** IPEDS finance tables (f1a for public, f2 for private nonprofit) — endowment values, revenue, expenditures. Student outcomes: financial aid (sfa), tuition changes (ic_ay), enrollment (ef_a), retention (ef_d), graduation (gr).

**Joker Dataset:** Form 990 data from the IRS (via ProPublica Nonprofit Explorer API) — endowment returns, investment income, spending from endowment. Provides institution-specific endowment shock magnitude.

**Identification:** Instrumental variable: pre-crisis endowment/expenditure ratio (2007) interacted with aggregate market return as an instrument for endowment shock magnitude. Alternatively, continuous DiD: dose = percentage endowment loss × post-2008.

**Why it's novel:**
- Brown, Dimmock, Kang, and Weagley (2014, JFE) studied endowment returns. But nobody has linked institution-specific endowment shocks to STUDENT outcomes (retention, completion) with the full IPEDS panel.
- Tests whether "endowment-rich" universities insulate students from financial shocks vs. passing them through as tuition hikes and aid cuts.
- The 2020 COVID shock provides an out-of-sample replication.

**Feasibility check:**
- ✅ IPEDS finance tables have endowment values (f1a.f1h01/f1h02, f2.f2h01/f2h02) from 2002-2023
- ✅ No staggering needed (cross-sectional variation in shock magnitude)
- ⚠️ Form 990 data requires ProPublica API or IRS bulk downloads — needs testing
- ⚠️ Somewhat studied (Brown et al. 2014; Conti, Delargy & Nolan 2019) — need clear differentiation
- ✅ Power: 1,500+ private institutions with endowment data
