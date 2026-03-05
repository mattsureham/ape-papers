# Research Ideas

## Idea 1: The CROWN Act and Black Worker Outcomes: Does Banning Hair Discrimination Reduce Racial Employment Gaps?

**Policy:** State CROWN Act laws (Creating a Respectful and Open World for Natural Hair) banning employment discrimination based on hair texture and protective hairstyles. 25 states adopted between 2019--2024: California (Jan 2020), New York (Jul 2019), New Jersey (Dec 2019), Colorado (Mar 2020), Virginia (Jul 2020), Washington (Jul 2020), Maryland (Oct 2020), Connecticut (Mar 2021), New Mexico (Apr 2021), Delaware (Dec 2021), Nebraska (Jul 2021), Nevada (Oct 2021), Oregon (Jan 2022), Illinois (Jan 2023), Maine (Mar 2022), Massachusetts (Oct 2022), Louisiana (Aug 2022), Alaska (Sep 2022), Minnesota (Jan 2023), Texas (Sep 2023), Michigan (Jun 2023), Tennessee (2022), Arizona (2024), Kentucky (2024), Arkansas (2024).

**Outcome:** American Community Survey (ACS) 1-year microdata (2015--2024) via Census API: employment status, earnings, occupation (SOC codes), industry (NAICS), hours worked. Current Population Survey (CPS) monthly microdata for higher-frequency dynamics. Both contain race, state, age, education, sex.

**Identification:** Staggered difference-in-differences using Callaway and Sant'Anna (2021) estimator.
- **Triple-difference:** Black × CROWN-state × Post (net out common shocks by using White workers as within-state control)
- **Pre-treatment window:** 2015--2018 for early adopters (4+ years)
- **Post-treatment window:** Up to 5 years for earliest states
- **Built-in placebos:**
  1. White workers (unaffected by hair discrimination)
  2. Non-customer-facing occupations (back-office, remote, manufacturing) vs customer-facing (retail, hospitality, personal services)
  3. Black men vs Black women (women face stronger hairstyle norms)
- **Mechanism decomposition:** (i) extensive margin (employment/participation), (ii) intensive margin (hours, earnings), (iii) occupational upgrading (movement into professional/customer-facing roles), (iv) industry transitions, (v) self-employment (may decrease if formal employment barriers fall)
- **Welfare:** Total earnings gains = (employment effect × average earnings) + (earnings effect × employment base)
- **Inference:** State-level clustering, wild bootstrap for few-treated-cohort robustness, Rambachan-Roth HonestDiD sensitivity

**Why it's novel:** Zero economics papers study the CROWN Act's labor market effects. All existing research is sociological/HR (documenting hair discrimination exists via audit studies showing Black women are 1.5x more likely to be sent home for hair, 2.5x more likely to have hair perceived as "unprofessional"). This paper would be the first to estimate the causal effect of anti-hair-discrimination legislation on Black employment and earnings.

**Feasibility check:**
- Variation: 25 states × staggered adoption 2019--2024 ✓
- Data: Census API (ACS 1-year PUMS) is publicly accessible; CPS microdata available ✓
- Novelty: Not in APEP list; zero Google Scholar hits for "CROWN Act" + "difference-in-differences" ✓
- Sample size: ACS 1-year has ~3.5M respondents; ~12% Black → ~420K Black respondents/year across states ✓
- COVID concern: Triple-diff differences out COVID (affects both races equally); later adopters (2021--2024) provide clean identification ✓

---

## Idea 2: Cleared to Work: State Cannabis Employment Testing Bans and Labor Market Tightness

**Policy:** State laws prohibiting employer pre-employment cannabis/marijuana drug testing. Nevada (Jan 2020), New York (Mar 2020), New Jersey (Feb 2022), Connecticut (Oct 2023), Montana (Jan 2023), Minnesota (Aug 2023), California (Jan 2024), Washington (Jan 2024), Rhode Island (2024). ~10--12 states, staggered 2020--2024.

**Outcome:** CPS monthly (employment, labor force participation, earnings). BLS Quarterly Census of Employment and Wages (QCEW) for establishment-level hiring. OSHA workplace injury data for safety outcomes.

**Identification:** Staggered DiD (CS-2021). Triple-diff with safety-sensitive vs non-safety-sensitive occupations (exempt from testing bans). Placebo: states that legalized cannabis but did NOT ban testing.

**Why it's novel:** Thin economics literature. Most research focuses on cannabis legalization effects on employment; no paper isolates the specific channel of employer testing bans.

**Feasibility check:**
- Variation: Only 10--12 states → BORDERLINE for DiD ≥20 threshold ✗
- Data: CPS/QCEW accessible ✓
- Novelty: Very thin literature ✓
- Power concern: Fewer treated states, very recent adoptions (short post-periods) ✗

---

## Idea 3: Breaking the Anchor: Salary History Bans and Worker-Firm Matching Efficiency

**Policy:** State laws prohibiting employer salary history inquiries during hiring. 21+ states adopted 2017--2020: Massachusetts (Jul 2018), California (Jan 2018), Delaware (Dec 2017), Oregon (Oct 2017), Connecticut (Jan 2019), Hawaii (Jan 2018), Vermont (Jul 2018), New Jersey (Jan 2020), Illinois (Sep 2019), Colorado (Jan 2019), Washington (Jul 2019), Maine (Sep 2019), Maryland (Oct 2020), Virginia (Jul 2020), New York (Jan 2020), Nevada (Oct 2021), plus city-level (NYC 2017, Philadelphia 2017).

**Outcome:** CPS ASEC linked panels (track individuals for 2 years): job-to-job transition rates, wage growth on job switches, occupational match quality (tenure duration). ACS: occupational distribution, industry sorting.

**Identification:** Staggered DiD (CS-2021). Focus on wage growth conditional on job switching (novel estimand vs. existing literature on gender gaps). Placebo: within-firm promotions (unaffected by hiring-stage inquiry).

**Why it's novel:** Existing literature (Bessen et al. 2020, Hansen & McNichols 2020) focuses on gender wage gap. No paper studies matching efficiency -- do workers sort into better-fitting jobs when employers can't anchor on past salary? Estimand: conditional wage growth on job switches, occupational tenure after switches, return-to-job rate.

**Feasibility check:**
- Variation: 21+ states ✓
- Data: CPS linked panels are complex but accessible ✓
- Novelty: Existing literature on wage gaps but NOT matching efficiency angle ✓ (partial)
- Power: CPS panels are smaller; occupational tenure measurement is noisy ✗
- Literature exists → risk of being "incremental" rather than "novel policy" ✗

---

## Idea 4: State Domestic Violence Leave Laws and Female Labor Force Attachment

**Policy:** State laws requiring employers to provide paid/unpaid leave for domestic violence victims. 30+ states adopted between 2004--2020, with substantial staggered variation. Examples: Oregon (2007), Colorado (2013), Connecticut (2010), Illinois (2003), California (2014 amendment), Maine (2006), etc.

**Outcome:** CPS monthly: female employment, hours, earnings, job tenure. ACS: female labor force participation, poverty rates, self-sufficiency. Supplementary: NCVS victimization data, TANF/SNAP participation.

**Identification:** Staggered DiD (CS-2021). Triple-diff with male workers (less directly affected). Mechanism: (i) job retention (reduced separations), (ii) new job entry (safety net enables job search), (iii) earnings stability.

**Why it's novel:** Runge (2011) is the only economics paper; focuses on narrow UI eligibility question. No study examines the broader mandatory leave laws and their effect on female labor force attachment.

**Feasibility check:**
- Variation: 30+ states ✓
- Data: CPS/ACS accessible ✓
- Novelty: Very thin literature ✓
- Power: Domestic violence is low-prevalence → aggregate effects may be small ✗
- Identification: Hard to determine who is "treated" (DV victims not identified in CPS) ✗
