# Research Ideas

## Idea 1: How Many Generics Does It Take? Event-Study Estimates of Sequential Competitor Entry on U.S. Drug Prices
**Policy:** The FDA generic drug approval process creates sequential market entry events. Each ANDA approval adds a new manufacturer to a drug market at a specific, dateable moment. 37,025 ANDA products in the Orange Book, with 13,862 sequential entry events across 1,375 drug ingredients. Policy debate is live: FDA/FTC/CMS disagree on whether accelerating generic approvals (GDUFA) effectively reduces prices or whether prices only fall after a threshold number of competitors.
**Outcome:** CMS NADAC (National Average Drug Acquisition Cost) — weekly drug-level pricing data, 2013-2025. 1.5M+ records per annual file. NDC-level prices with brand/generic classification.
**Identification:** Stacked event study by entry position (N=2, 3, ..., 10). Each drug ingredient serves as its own control. Drug fixed effects absorb time-invariant characteristics; calendar-week fixed effects absorb aggregate trends. 12-week pre-event window tests no-anticipation. 24-week post-event window captures competitive adjustment. CS-DiD for robustness. 13,862 entry events provide massive statistical power.
**Why it's novel:** All existing studies (Reiffen & Ward 2005; Caves et al. 1991; ASPE 2021) use cross-sectional methods comparing drugs with different numbers of competitors — conflating market-size SELECTION with COMPETITION effects. No published event study tracks the same drug's price before and after each sequential entrant. The paper traces the full marginal competition curve non-parametrically.
**Feasibility check:** Confirmed. Orange Book data downloaded and parsed (37,025 ANDAs). NADAC CSV downloaded (1.5M records). openFDA API confirmed for NDC-to-ANDA crosswalk. 13,862 entry events across 1,375 drug ingredients.

## Idea 2: Follow the Money or Follow the Crime? Police Resource Reallocation After Civil Asset Forfeiture Reform
**Policy:** 37 states + DC reformed civil asset forfeiture laws (2014-2024) with heterogeneous intensity: 4 abolished, 16 required criminal conviction, 16 raised burden of proof, 8 added anti-circumvention provisions.
**Outcome:** FBI UCR Arrests by Age, Sex, and Race (1974-2021, ICPSR 102263). Agency-level arrests by offense type: drug vs. property vs. violent crime.
**Identification:** CS-DiD with treatment intensity coded on 4-point scale. 13 never-reformed states as controls. The substitution question: when forfeiture revenue disappears, do police shift enforcement from drug crimes to property/violent crimes?
**Why it's novel:** Existing research asks "does reform increase crime?" (answer: no). No one has asked the resource reallocation question — a revealed-preference test of police incentive responsiveness.
**Feasibility check:** Confirmed. Institute for Justice reform database publicly available. Jacob Kaplan's UCR files on ICPSR (open access). 37 treated states, 13 controls.

## Idea 3: Deregulating Hospital Entry: Certificate of Need Repeals and the Quality-Competition Tradeoff
**Policy:** 15 states fully repealed Certificate of Need (CON) laws for hospitals (staggered 1983-2023), plus 4 recent partial repeals (FL, NC, SC, MT in 2019-2023).
**Outcome:** CMS Hospital Compare (5,426 hospitals, quality ratings 1-5 stars, mortality/safety/readmission measures). Census BDS for establishment births/deaths in NAICS 622.
**Identification:** CS-DiD with two strategies: (A) long-run full repeals (15 treated vs. 35 regulated), (B) recent partial repeals with within-state DDD across deregulated vs. still-regulated service lines. Quality-competition tradeoff as welfare object.
**Why it's novel:** The 2025 NBER review (Courtemanche & Garuccio, w34026) explicitly calls for better causal methods. No CS-DiD in published literature. No paper uses CMS Hospital Compare star ratings as outcomes.
**Feasibility check:** Confirmed. CMS Hospital Compare API returns 5,426 hospitals. Census BDS returns state-level firm dynamics through 2023.
