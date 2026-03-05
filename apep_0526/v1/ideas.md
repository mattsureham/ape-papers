# Research Ideas

## Idea 1: Right-to-Try Laws and the Market for Clinical Trials

**Policy:** State Right-to-Try laws allowing terminally ill patients to access investigational drugs outside clinical trials. 42 states enacted laws between May 2014 (Colorado) and October 2018 (Alaska), before the federal Right to Try Act (May 30, 2018). Adoption was rapid and staggered: 5 states in 2014, 15 in 2015, 10 in 2016, 6 in 2017, 3 in 2018. ~9 states/DC relied on the federal law alone (never-treated group through federal passage).

**Outcome:** ClinicalTrials.gov AACT database — the universe of registered clinical trials in the United States. Contains trial-level data on location (facility state), phase, condition, enrollment, sponsor type, start/completion dates. Available via public API (clinicaltrials.gov/api/v2/). Approximately 2,000-2,500 Phase II/III trials start annually in the US, distributed across all 50 states (California: ~1,000/yr; Wyoming: ~25/yr). Panel: state × quarter, 2008Q1–2018Q2.

**Identification:** Staggered DiD using Callaway-Sant'Anna estimator. 38 state-level treatment cohorts (2014-2018). Never-treated group: ~9 states without state laws before the federal act. Pre-treatment: 6+ years (2008-2013). Post-treatment: 1-4 years for early adopters.

**Why it's novel:**
1. **First rigorous causal study of Right-to-Try effects.** Despite 41+ states passing these laws and intense policy debate, no published paper estimates causal effects on clinical trial infrastructure. The literature is entirely descriptive/legal analysis.
2. **Novel data application.** ClinicalTrials.gov has never been used as the primary dataset in a policy evaluation paper. This is "universe" administrative data (all registered US trials).
3. **Tests whether symbolic legislation has real market effects.** Right-to-Try was barely used in practice (<100 patients nationally), yet the pharmaceutical industry expressed concern about enrollment diversion. We test whether these concerns materialized.
4. **Multiple outcome margins:** trial site counts, enrollment speed, trial composition (terminal vs. non-terminal conditions), sponsor behavior (industry vs. academic), and geographic reallocation of trial infrastructure.

**Built-in placebos:**
- Non-terminal condition trials (behavioral health, orthopedic, dermatology — unaffected by Right-to-Try)
- Observational studies (not interventional drug trials)
- Phase I trials (Right-to-Try typically requires Phase I completion, so Phase I enrollment shouldn't be affected)

**Mechanism decomposition:**
- Patient substitution channel: patients divert from trials to Right-to-Try access
- Sponsor reallocation channel: pharmaceutical companies shift trial sites away from Right-to-Try states
- Information/uncertainty channel: law creates regulatory uncertainty that affects site selection
- Enrollment speed channel: even without diversion, the option value of Right-to-Try may slow enrollment

**Welfare/counterfactual:**
- If enrollment declined X%, estimate implied delay in drug development (months)
- Compute welfare cost of delayed drug approval using VSLY framework
- If null: compute MDE and show that concerns about "derailing clinical trials" were empirically unfounded

**Feasibility check:** CONFIRMED.
- ClinicalTrials.gov API tested and returns rich state-level data
- 42 state adoption dates obtained from Triage Cancer (precise month/year)
- State variation in trial counts: CA (1,021), TX (874), CO (425), MT (89), WY (25) Phase II/III trials in 2014
- DiD threshold: 38+ treated states, 6+ pre-periods ✓

---

## Idea 2: Nurse Practitioner Full Practice Authority and Rural Mortality

**Policy:** State laws granting nurse practitioners (NPs) full practice authority (FPA) — the ability to evaluate, diagnose, order tests, and prescribe without physician oversight. 30 states + DC now have FPA, staggered adoption since 1994 (AK, IA, MT, NM, OR first). Major acceleration post-2010 following the IOM recommendation. Recent wave: TX, TN, AL, LA, SC adopted 2023-2024.

**Outcome:** HRSA Area Health Resource Files (primary care provider counts by county), BLS OES (NP employment by state-year), CDC WONDER (age-adjusted mortality by county-year). Panel: state × year, 2000–2024.

**Identification:** Staggered DiD (CS estimator). 25+ treatment cohorts over 30 years. Never-treated: ~20 states still requiring physician oversight. Long pre-treatment for early adopters.

**Why it's novel:** One APEP paper (apep_0089) studied NP scope effects on physician employment. This paper instead focuses on patient health outcomes (mortality) in rural/underserved areas — a direct test of whether FPA closes healthcare access gaps. Long horizons (30+ years for early adopters) are a major advantage per tournament lessons.

**Built-in placebos:** Physician supply, specialist services, urban mortality.

**Feasibility check:** Data available via public APIs (BLS, CDC WONDER, HRSA). 30+ treated states.

---

## Idea 3: IVF Insurance Mandates and Women's Career Trajectories

**Policy:** State laws mandating insurance coverage of fertility treatments (IVF). 22+ states have mandates, staggered since 1987 (IL, MA first). Recent wave: NY (2020), CO (2022), CA (2025). Mandates vary in stringency (cover vs. offer, IVF-specific vs. fertility broadly).

**Outcome:** ACS microdata (female labor force participation, wages, hours by age × state × year). Vital Statistics (maternal age at first birth by state-year). Panel: state × year, 2005–2024.

**Identification:** Staggered DiD. Women aged 25-40 as treated group. Use mandate-type variation (cover vs. offer) for dose-response analysis.

**Why it's novel:** Existing literature (Schmidt 2007, Bitler & Schmidt 2006) focuses on fertility effects. The career trajectory angle — do women who can defer childbearing earn more during peak career years? — is unstudied. This connects IVF access to the gender wage gap.

**Built-in placebos:** Men, women aged 45+, women in small firms (often exempt from mandates).

**Feasibility check:** ACS API tested and returns state-level labor force data. 22+ treated states. Long horizons for early adopters (30+ years).

---

## Idea 4: State Indoor Tanning Bans for Minors and the Tanning Industry

**Policy:** State laws banning indoor tanning for minors under 18. California and Vermont first (2012). Approximately 15-20 states enacted outright bans by 2016, with others requiring parental consent.

**Outcome:** County Business Patterns (establishment counts for NAICS 812199 "Other Personal Care Services"), YRBSS (indoor tanning usage among high school students), CDC WONDER (melanoma incidence by state and age group).

**Identification:** Staggered DiD. Compare establishment counts and youth tanning behavior pre/post ban across states.

**Why it's novel:** No causal evaluation of tanning ban effectiveness using economic methods. Connects public health regulation to industry structure and youth behavior.

**Built-in placebos:** Adults (not subject to minor bans), non-tanning personal care establishments.

**Feasibility check:** CBP and CDC WONDER are publicly available. YRBSS data may have limited state coverage. NAICS 812199 is not tanning-specific (includes other services) — would need to assess signal-to-noise. ~15-20 treated states may be below the DiD threshold of 20.

**RISK:** Measurement challenges (tanning not separable in NAICS), possibly too few treated states for clean DiD, and YRBSS coverage gaps.

---

## Idea 5: State Conversion Therapy Bans and LGBTQ+ Youth Mental Health

**Policy:** State laws prohibiting licensed practitioners from performing conversion therapy on minors. NJ and CA first (2013). Now 22+ states + DC, staggered through 2024.

**Outcome:** YRBSS (suicide attempts, feeling sad/hopeless, among students identifying as LGBTQ+), CDC WONDER (suicide rates by age group and state).

**Identification:** Staggered DiD. LGBTQ+ youth as treated, non-LGBTQ+ youth as within-state control.

**Why it's novel:** Despite widespread policy adoption, no rigorous causal evaluation exists. Direct welfare implications for vulnerable population.

**Built-in placebos:** Non-LGBTQ+ youth, adults, states with bans vs. without.

**Feasibility check:** CDC WONDER suicide data available. YRBSS has sexual identity questions since 2015 but not all states participate — limited panel. ~22 treated states.

**RISK:** YRBSS sexual identity data available for only ~15-20 states in any survey year, biennial frequency limits panel length, and small LGBTQ+ subsamples reduce power.
