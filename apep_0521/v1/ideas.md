# Research Ideas

## Idea 1: When the Checkpoint Vanishes: Constitutional Carry Laws, Gun Violence, and Police Safety

**Policy:** Constitutional carry (permitless concealed carry) laws adopted by 29 states between 2003–2024, with the bulk of staggered adoption from 2010–2024. These laws eliminate the requirement to obtain a government-issued permit before carrying a concealed firearm, removing regulatory checkpoints (background checks, training requirements, identity verification) that applied to carry permits.

**Distinct from shall-issue:** Prior literature (Donohue, Aneja, Weber 2019) studies the shall-issue transition (discretionary → guaranteed permits). Constitutional carry removes permits entirely — a qualitatively different deregulation affecting a different margin of potential carriers.

**Outcome:** CDC WONDER Underlying Cause of Death (1999–2023) via API: state×year firearm deaths by intent (homicide ICD-10 X93-X95, suicide X72-X74, accidental W32-W34), plus non-firearm equivalents as placebos. FBI LEOKA via Crime Data Explorer API: state×year officer felonious/accidental deaths and assaults (1974–2023). FBI UCR/NIBRS via Crime Data Explorer API: state×year violent crime. FBI NICS: state×month background checks.

**Identification:** Staggered DiD using Callaway-Sant'Anna (2021) with 22+ treated states and ~20 never-treated controls. Panel: 2000–2023. Pre-treatment periods: 10+ years for most cohorts. Treatment timing is driven by state legislature ideology, not local crime conditions — plausibly exogenous to county-level outcomes conditional on state and year FEs.

**Why it's novel:**
1. First comprehensive causal study of constitutional carry (as opposed to shall-issue)
2. Police officer safety angle is genuinely untouched in the literature
3. Multi-margin: civilian mortality (3 intents) + police deaths + crime + gun demand
4. Built-in placebos: non-firearm homicides, non-firearm suicides
5. Welfare framework: deaths × VSL vs. regulatory compliance costs removed
6. 22+ treated states with 10+ years of pre-data = extremely well-powered

**Feasibility check:** Confirmed — CDC WONDER API provides state×year mortality by ICD-10 code. FBI Crime Data Explorer provides UCR and LEOKA data. NICS data publicly available by state×month. All data are public, free, and API-accessible. 22 treated states (through 2022 data) with staggered timing from 2010–2022. At least 20 never-treated control states.

---

## Idea 2: Ghost Towns of Justice: Prison Closures and the Local Economy

**Policy:** Over 174 state prisons closed across the US between 2000–2024, with major closure waves in New York (24+ prisons 2011–2024), Texas, North Carolina, Georgia, Connecticut. Prison closures are driven by state-level policy decisions (declining incarceration, budget reform) and are plausibly exogenous to local county economic conditions.

**Outcome:** County-level employment (QCEW), unemployment (BLS LAUS), population (Census estimates), per capita income (BEA REIS). Treatment identified from sharp drops in NAICS 922 (Justice/Public Order) employment in QCEW county data.

**Identification:** Event-study DiD. Identify "closure counties" as those experiencing ≥50% decline in state government correctional employment. Compare to matched non-closure counties using CS-DiD.

**Why it's novel:** Improves on Chirakijja (2023, Econ Letters) which found limited spillovers over 2011–2016. We extend to 2024, use CS-DiD (vs. matching+TWFE), and add welfare analysis.

**Feasibility check:** QCEW data confirmed available at county × NAICS level. Concern: NAICS 922140 may be suppressed in small counties (BLS confidentiality). Fallback: use broader NAICS 922 or state government employment. Number of closure events: ~100+ counties over 20 years.

---

## Idea 3: Betting Against Yourself: Mobile Sports Betting Legalization and Consumer Financial Distress

**Policy:** 38 states + DC have legalized sports betting since PASPA was struck down in May 2018, with 30+ offering mobile/online betting. Staggered adoption from 2018–2024 creates excellent DiD variation. Mobile betting is the critical margin — it removed the friction of going to a physical sportsbook.

**Outcome:** Consumer financial distress: FRBNY Consumer Credit Panel (state-level aggregates of delinquency, bankruptcy), US Courts bankruptcy filings by state, CFPB consumer complaint database (state-level gambling/debt complaints).

**Identification:** Staggered DiD on mobile sports betting launch dates (distinct from legalization dates — some states legalized but delayed mobile launch). 30+ treated states, staggered 2018–2024.

**Why it's novel:** Most sports betting research focuses on gambling behavior (handle, revenue). The consumer finance channel — whether frictionless betting access increases household financial distress — is understudied. APEP paper 0038 studied employment effects; this is a different margin entirely.

**Feasibility check:** Bankruptcy filing data (US Courts PACER) is public by district/quarter. CFPB complaint data is downloadable. FRBNY CCP aggregates are available. Mobile launch dates are well-documented. 30+ treated states = well-powered design.
