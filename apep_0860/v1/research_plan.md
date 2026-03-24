# Research Plan: The Dealer Squeeze — Catalytic Converter Anti-Theft Laws and the Scrap Metal Recycling Industry

## Research Question

Do state catalytic converter anti-theft laws reduce scrap metal dealer activity? We decompose the decline in recycling establishments and employment into: (a) the regulatory compliance effect (laws create paperwork and holding-period costs) and (b) the commodity price effect (palladium prices collapsed from $2,958 to $993, mechanically reducing theft incentives and thus scrap supply).

## Identification Strategy

**Staggered difference-in-differences** using Callaway and Sant'Anna (2021). 33 states enacted catalytic converter anti-theft laws between 2021 and 2024, with the bulk in 2022 (23 states). 19 states + DC remained untreated through 2023. Treatment is defined at the state-year level: a state is treated in the first full year after its law takes effect.

**Key identification assumptions:**
- Parallel trends: absent the law, scrap dealer establishments in treated and control states would have followed parallel paths
- No anticipation: dealers did not exit before the law was enacted
- SUTVA: no cross-state spillovers in scrap dealer activity

**Commodity price decomposition:** Include state × annual palladium price interactions to separate the law effect from the price effect. States with more catalytic-converter-dependent scrap activity should respond more to palladium price changes.

**Exposure alignment:** The treated units are states that enacted catalytic converter anti-theft laws. The directly affected population is scrap metal dealers (NAICS 423930) within those states who must comply with new record-keeping, holding period, and identity verification requirements. Treatment is measured at the state-year level because the laws apply uniformly to all dealers within the state. The outcome (establishment count and employment) captures the extensive margin of dealer activity—firms that remain open versus those that exit due to compliance costs. The intensive margin (transaction volume per dealer) is unobserved in CBP data.

## Data

1. **Census County Business Patterns (CBP)** — state-year establishments, employment, and payroll for:
   - NAICS 423930: Recyclable Material Merchant Wholesalers (primary outcome)
   - NAICS 811111: General Automotive Repair (control industry)
   - NAICS 441310: Automotive Parts Stores (control industry)
   - Years: 2017-2023 (7 years: 4-5 pre-treatment, 1-3 post-treatment)
   - Source: Census Bureau API (confirmed accessible)

2. **Palladium futures prices** — monthly from Yahoo Finance (PA=F), averaged annually
   - Range: 2016-2026 (103 monthly observations)
   - Peak: $2,958 (April 2021), Trough: $993 (January 2024)

3. **State law enactment dates** — compiled from legislative records
   - 33 states enacted laws (2021-2024)
   - Coding: law_year = year of enactment; treatment onset = first full calendar year after enactment

## Primary Specification

Y_{s,t} = α_s + γ_t + β · Law_{s,t} + δ · (PalladiumPrice_t × ScrapIntensity_s) + ε_{s,t}

where Y is log establishments (or employment), α_s are state FE, γ_t are year FE, Law_{s,t} = 1 if state s has enacted a law by year t.

For heterogeneity-robust estimation: Callaway-Sant'Anna with never-treated as control group.

## Expected Effects and Mechanisms

- **Law effect on scrap dealers (β < 0):** Laws create compliance costs (VIN recording, holding periods, photo ID, purchase price thresholds). Marginal dealers exit or reduce operations.
- **Price effect (δ):** Higher palladium prices increase scrap supply and dealer activity (more legitimate business); the price decline mechanically reduces dealer revenue.
- **Interaction:** Laws may bite harder when palladium prices are high (because the regulated market is larger).
- **Control industries:** General auto repair and auto parts stores should NOT respond to catalytic converter laws, serving as placebo outcomes.

## Robustness

1. Event study (dynamic treatment effects via Callaway-Sant'Anna)
2. Placebo outcome: auto repair shops (NAICS 811111)
3. Leave-one-out: drop Texas (first mover) and California (largest state)
4. Wild cluster bootstrap (33 treated clusters)
5. Alternative treatment timing: use law_month to determine treatment year
