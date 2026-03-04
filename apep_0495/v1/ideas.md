# Research Ideas

## Idea 1: The Hidden Tax on School Quality: How VAT on Private Fees Reshapes England's State School Housing Premium

**Policy:** UK government imposed 20% VAT on private school fees from January 1, 2025. Labour won the July 4, 2024 election on a manifesto including this policy; Budget confirmation October 30, 2024; implementation January 1, 2025. This is a sharp, nationally uniform ~20% price shock to private education — the first of its kind in a developed economy.

**Outcome:** House prices near high-quality state schools (Land Registry Price Paid Data, 24M+ transactions from 1995, monthly, postcode-level). Secondary outcomes: transaction volumes, time-on-market.

**Identification:** Triple-difference (DDD) design:
- Dimension 1 (treatment intensity): Baseline private school pupil share by Local Authority / LSOA (from DfE GIAS + ISC census)
- Dimension 2 (mechanism channel): Proximity to Outstanding/Good-rated state schools vs. proximity to Requires Improvement/Inadequate state schools
- Dimension 3: Pre vs post-VAT announcement (July 2024) / implementation (January 2025)

The DDD isolates the school-quality channel: in high-private-school areas, properties near good state schools should see price increases relative to those near weak state schools, and this differential should emerge only after the policy shock. Areas with no private schools serve as a placebo (zero treatment intensity).

**Why it's novel:**
1. First paper to exploit the UK private school VAT as a natural experiment
2. Tests and extends Fack & Grenet (2010)'s prediction that private schools attenuate state school quality capitalization — we observe the reverse: when private schooling becomes MORE expensive, state school quality should capitalize MORE
3. Reveals general equilibrium effects of education policy on housing markets
4. Decomposes anticipation (election → budget → implementation) from realization effects

**Feasibility check:**
- Land Registry PPD: confirmed accessible, monthly, postcode-level (tested URL: pp-2024.csv returns 200)
- GIAS (edubase): confirmed accessible with date-stamped CSV (tested: edubasealldata20260303.csv returns 200) — includes school type, postcode, Ofsted rating for all ~65,000 schools
- DfE School Performance Tables: available via explore-education-statistics.service.gov.uk (KS2/KS4 data downloadable)
- postcodes.io: confirmed working (tested EC1A1BB → Islington)
- ONS NSPL: bulk download for postcode-to-LSOA linkage
- Pre-treatment: 10+ years (2015–2024); post-treatment: 14 months (Jan 2025 – Feb 2026)
- Sample: millions of housing transactions × treatment variation across ~300 LAs


## Idea 2: Crowding In or Pricing Out? Private School VAT and State Sector Pressure in England

**Policy:** Same 20% VAT on private school fees (January 2025).

**Outcome:** State school enrollment pressure, class sizes, and pupil-teacher ratios (DfE annual school census), plus secondary school entry applications (via School Capacity data published by DfE). Additional: private school closures/mergers tracked via GIAS open/close dates and Companies House (SIC 85 education).

**Identification:** DiD with continuous treatment intensity:
- Treatment: LA-level baseline private school pupil share
- Pre/post: Before and after January 2025
- Outcome: Annual measures of state school capacity utilization

**Why it's novel:** Tests the government's prediction of ~37,000 pupils switching to state sector. Quantifies the "absorption cost" of the policy on state school quality.

**Feasibility check:**
- DfE School Census data: annual, publicly available at school level
- GIAS: school open/close dates, pupil numbers
- Companies House: SIC 85 entries/exits
- **Major weakness:** Annual data = only 1 post-treatment observation (2025/26). Insufficient for credible DiD. Would need to wait for 2026/27+ data.
- **Power concern:** With only 1 post-treatment year, pre-trends cannot be validated against post-treatment dynamics.


## Idea 3: Does Making Private School More Expensive Reduce Inequality? Evidence from England's VAT Shock

**Policy:** Same 20% VAT on private school fees.

**Outcome:** House price dispersion within LAs — specifically, the ratio of prices near top-performing state schools to LA median prices. This measures whether the policy increases spatial inequality by concentrating demand in specific neighborhoods.

**Identification:** Event study around announcement/implementation dates:
- Treatment intensity: LA-level private school share
- Outcome: Within-LA price dispersion (P90/P10, Gini, or top-school premium)
- Pre-treatment: 10 years of monthly data

**Why it's novel:** Tests whether removing a private market safety valve actually increases spatial inequality — a prediction from Tiebout sorting models.

**Feasibility check:**
- Same data as Idea 1 (Land Registry + GIAS)
- **Concern:** This is a secondary outcome that could be incorporated into Idea 1 rather than a standalone paper. Less likely to stand alone as a top-journal publication.


## Idea 4: The Announcement Premium: How Fast Do Housing Markets Capitalize Education Policy?

**Policy:** Same UK private school VAT, but exploiting the multi-stage information revelation: (i) Labour manifesto (early 2024), (ii) election victory (July 4, 2024), (iii) Budget confirmation (October 30, 2024), (iv) implementation (January 1, 2025).

**Outcome:** House prices near top state schools (Land Registry PPD).

**Identification:** High-frequency event study around each information shock:
- Daily/weekly property transactions around each date
- Treatment intensity: proximity to Outstanding state schools × local private school density
- Prediction market data (Polymarket/PredictIt odds on Labour win) as a continuous treatment probability

**Why it's novel:** Tests the efficient markets hypothesis in housing: do prices respond to policy announcements immediately, or with delay? The multi-stage revelation creates a unique test.

**Feasibility check:**
- Land Registry data is monthly (not daily) — transaction dates are available but reported monthly
- **Major weakness:** Transaction volumes at the weekly level in specific postcodes may be too thin for event-study precision
- Could be folded into Idea 1 as a subsection rather than standalone


## Idea 5: From Fees to Footfall: How Private School VAT Reshapes Local Economies

**Policy:** Same 20% VAT on private school fees.

**Outcome:** Local economic activity — firm formation/closure (Companies House), commercial property transactions (Land Registry), local employment (NOMIS). Mechanism: private schools are anchor institutions; reduced enrollment → reduced spending → local economic effects.

**Identification:** DiD with treatment intensity = number of private school pupils per 1,000 population by LA.

**Why it's novel:** Studies the local economic multiplier of private schooling.

**Feasibility check:**
- Companies House, Land Registry commercial, NOMIS: all accessible
- **Major weakness:** Mechanism is speculative and diluted. Private school spending as share of local economy is small in most areas. Effect size likely below detection threshold.
- **Measurement mismatch risk:** This is exactly the type of "treatment on diluted outcome" that judges penalize (like UC → limited company formations).


## Recommended Idea

**Idea 1** is clearly the strongest:
1. Clean triple-difference identification with built-in placebos
2. Massive public dataset (millions of transactions)
3. Direct test of a precise theoretical prediction (Fack & Grenet 2010)
4. First-mover advantage on a major, high-profile policy
5. Multiple verification strategies (anticipation effects, mechanism chain)

Elements from Ideas 3 and 4 (inequality effects, announcement timing) can be incorporated as sections within the Idea 1 paper, making it richer without diluting the core contribution.
