# Research Ideas

## Idea 1: Can't Ask, Won't Tell: Salary History Bans, Hiring Wages, and the Gender Earnings Gap

**Policy:** State salary history ban laws prohibiting employers from asking job applicants about previous compensation. Staggered adoption from October 2017 (Oregon, Delaware) through January 2024 (Minnesota). Twenty jurisdictions (19 states + DC) have enacted bans covering private employers: OR (Oct 2017), DE (Dec 2017), DC (Nov 2017), CA (Jan 2018), MA (Jul 2018), VT (Jul 2018), CT (Jan 2019), HI (Jan 2019), IL (Sep 2019), ME (Sep 2019), WA (Jul 2019), AL (Sep 2019), NJ (Oct 2019), NY (Jan 2020), VA (Jul 2020), MD (Oct 2020), CO (Jan 2021), NV (Oct 2021), RI (Jan 2023), MN (Jan 2024).

**Outcome:** Census QWI (Quarterly Workforce Indicators) — universe-scale employer-employee data covering all UI-covered employment. Key variables: average monthly earnings for full-quarter workers (EarnS), average monthly earnings for NEW hires (EarnHirNS), employment counts (Emp), new hire counts (HirN), separations (Sep). Available by state × quarter × sex × industry, 2010-2024.

**Identification:** Triple-difference (DDD) design:
- Difference 1: Ban states vs. not-yet-treated states (cross-state variation)
- Difference 2: Post-ban vs. pre-ban quarters (time variation)
- Difference 3: New hire earnings vs. continuing worker earnings (within-state mechanism)

The DDD kills the key confound: statewide economic trends that differentially affect treated states. The salary history ban should compress the gender gap in NEW HIRE wages (where salary history would have been used in negotiation) but NOT in continuing worker wages (where salary history is irrelevant). Male workers serve as an additional same-system placebo.

Primary estimator: Callaway-Sant'Anna (2021) for heterogeneous treatment timing. TWFE as comparison.

**Why it's novel:**
1. **Universe-scale data** — QWI covers all UI-covered employment (~150M workers), not CPS samples (~200K). The existing literature (Hansen & McNichols 2020; Bessen, Denk & Meng 2020; Sinha 2023) uses CPS or job posting data, which are much smaller.
2. **Separate new hire earnings** — QWI uniquely reports earnings for new hires (EarnHirNS) vs. continuing workers (EarnS). This enables the DDD design that directly tests the mechanism channel: salary history bans should operate through the hiring margin.
3. **Modern staggered DiD** — Existing papers use TWFE, which is biased with staggered adoption. CS-DiD with 20 treated jurisdictions and 7+ years of post-data for early adopters.
4. **Industry heterogeneity** — QWI by industry × sex enables testing whether bans help women more in male-dominated industries (construction, finance, tech) where the gender pay gap is largest.

**Feasibility check:** ✓ QWI API tested and returns EarnS, EarnHirNS, HirN, Sep by state × quarter × sex × industry. Data spans 2010-Q2 through 2024-Q3. Twenty treated jurisdictions. 20+ pre-periods for early adopters. CENSUS_API_KEY configured.

---

## Idea 2: Does Legalizing Drug Checking Save Lives? Fentanyl Test Strip Decriminalization and Drug-Specific Mortality

**Policy:** State laws removing fentanyl test strips (FTS) from drug paraphernalia definitions. Rapid staggered adoption: ~15 states by end of 2021, ~35 by end of 2022, ~45 by end of 2023.

**Outcome:** CDC WONDER Multiple Cause of Death data. Drug-specific overdose mortality by state × year, decomposed by drug involvement codes: T40.4 (synthetic opioids/fentanyl), T40.5 (cocaine), T43.6 (psychostimulants/methamphetamine), cross-tabulated to isolate accidental fentanyl exposure (cocaine + fentanyl co-occurrence) vs. intentional fentanyl use.

**Identification:** Staggered DiD (CS-DiD). Treatment = state legalization of fentanyl test strips. Outcome = drug-specific mortality rates. The key mechanism decomposition: FTS should reduce deaths from ACCIDENTAL fentanyl contamination (cocaine users, meth users testing their supply) but NOT deaths from intentional fentanyl/opioid use. This drug-type decomposition is the novel contribution.

**Why it's novel:** One existing paper (2025) finds 7% overall mortality reduction using TWFE. My contribution: (1) drug-type mechanism decomposition revealing WHERE test strips save lives; (2) CS-DiD correction; (3) built-in placebo via intentional opioid-only deaths. First-order stakes (100K+ overdose deaths/year).

**Feasibility check:** CDC WONDER provides state × year mortality by drug codes. 35+ treated states. Annual frequency limits event-study precision. Rapid adoption (most states in 2022-2023) bunches treatment timing, reducing variation. The bunching is a concern — may limit power of staggered design.

---

## Idea 3: When Insurers Can't Discriminate: State Insulin Copay Caps and the Diabetes Burden

**Policy:** State laws capping insulin copayments, typically at $25-$100/month for insured patients. Staggered adoption: Colorado (Jan 2020, first), Virginia (Jan 2021), ~25 states by 2024. Federal $35 cap for Medicare (IRA, Jan 2023) creates a natural comparison.

**Outcome:** CDC WONDER diabetes mortality (ICD-10 E10-E14) by state × year. BRFSS: self-reported cost-related medication non-adherence, diabetes status, health outcomes. Medicaid SDUD: insulin prescriptions per state × quarter.

**Identification:** Staggered DiD with CS-DiD estimator. DDD: (cap state × post × commercially insured pop). Placebo: non-insulin diabetes medications (metformin), which are already cheap and unaffected by caps. Federal Medicare cap in 2023 provides a natural second treatment for event study validation.

**Why it's novel:** Health Affairs (2024) studied Colorado alone. Annals of Internal Medicine (2024) did pre-post with one control group. No multi-state CS-DiD evaluation of MORTALITY outcomes (most existing work studies utilization/spending, not health).

**Feasibility check:** ~25 treated states. CDC WONDER provides annual diabetes mortality by state. BRFSS annual data by state. But: caps primarily affect commercially insured; CDC mortality doesn't distinguish by insurance. BRFSS cost barrier questions may not be asked in all states every year. Data granularity concerns moderate feasibility.

---

## Idea 4: The Democratic Price of Convenience: Automatic Voter Registration and the Turnout Paradox

**Policy:** State automatic voter registration (AVR) laws that register citizens at DMV encounters unless they opt out. Oregon (2016, first), followed by ~22 states by 2024.

**Outcome:** CPS Voting and Registration Supplement (biennial, November of even years): voter registration rate, turnout rate, registration-turnout gap. EAC Election Administration and Voting Survey: administrative registration and turnout data.

**Identification:** Staggered DiD. The hypothesis: AVR increases REGISTRATION (mechanical — people are registered without action) but may NOT increase TURNOUT (the newly registered are those who didn't seek to register, suggesting low political engagement). If confirmed, the "registration-turnout gap" widens, challenging the assumption that registration barriers are the primary obstacle to participation.

**Why it's novel:** Existing literature (Bennion & Nickerson 2011, Griffin et al. 2020) is mostly descriptive or uses early adopters. No multi-state CS-DiD evaluation. The "turnout paradox" framing — that reducing registration costs doesn't reduce voting costs — connects to a deep theoretical question about the nature of political participation costs.

**Feasibility check:** 22 states, strong N. BUT: CPS data is biennial (2014, 2016, 2018, 2020, 2022), giving at most 5 time periods. This severely limits event-study validation (cannot detect pre-trends with only 2-3 pre-treatment observations for many states). Administrative data (EAC EAVS) is also biennial. Annual data is unavailable for turnout at the state level except in election years. The temporal sparsity is a SERIOUS feasibility concern.

---

## Idea 5: Clean Energy Mandates and the Cost of Electricity: State Renewable Portfolio Standards and Ratepayer Burden

**Policy:** State Renewable Portfolio Standards (RPS) mandating utilities to source a minimum percentage of electricity from renewables. ~30 states have RPS, staggered adoption from late 1990s to present. Key variation: mandatory RPS increases (ratchet-ups) that raise the required renewable share over time. E.g., California increased from 20% (2010) to 33% (2020) to 60% (2030).

**Outcome:** EIA State Energy Data System (SEDS): electricity prices by state × year, residential/commercial/industrial. EIA Form 861: utility-level data. FRED: state electricity CPI.

**Identification:** Staggered DiD exploiting RPS ratchet-ups (not initial adoption, which is distant and confounded). The treatment is the INCREASE in the RPS target, creating intensive margin variation. DDD: (RPS state × post-ratchet × residential vs. industrial) tests whether costs are passed through differentially.

**Why it's novel:** Existing literature (Greenstone & Nath 2020, Barbose et al. 2016) mostly studies initial RPS adoption or uses cross-sectional variation. The ratchet-up design with modern CS-DiD is novel. The distributional question (who bears the cost — residential ratepayers or industrial users?) is policy-relevant for the energy transition debate.

**Feasibility check:** 30+ states with RPS (strong N). BUT: coding the exact ratchet-up dates and target levels for each state requires careful legislative research. EIA SEDS data is annual and publicly available. The main concern: electricity prices are determined by many factors (natural gas prices, weather, grid infrastructure), and the RPS ratchet-up is just one input. State × year fixed effects may absorb much of the variation.
