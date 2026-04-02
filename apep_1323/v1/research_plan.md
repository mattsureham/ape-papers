# Research Plan: Nigeria's Cashless Policy and the Formalization Dividend

## Research Question
Does mandating penalties on large cash transactions accelerate electronic payment adoption and formalize economic activity? We exploit Nigeria's 2012–2014 staggered cashless policy rollout across 37 states.

## Policy Background
The Central Bank of Nigeria (CBN) introduced penalties on cash deposits/withdrawals exceeding ₦500,000 (individuals) and ₦3,000,000 (corporates):
- **Wave 1 (Jan 2012):** Lagos State (pilot)
- **Wave 2 (Jul 2013):** Rivers, Anambra, Abia, Kano, Ogun States + FCT (7 units)
- **Wave 3 (Jul 2014):** All remaining 30 states

## Identification Strategy
Staggered difference-in-differences exploiting the three-wave rollout. Callaway–Sant'Anna (2021) estimator with "never-yet-treated" as comparison group (Wave 3 units serve as not-yet-treated for Wave 1 and Wave 2 effects).

**Key assumption:** Parallel trends — absent the cashless policy, early-adopter states would have followed similar trends in electronic payments and economic activity as later-adopter states.

**Threats:**
- Lagos is the commercial capital; selection into Wave 1 is non-random. Robustness: drop Lagos, use only Waves 2 vs 3.
- Oil price shocks differentially affect oil-producing states. Control: include oil-state interactions.
- The nationwide Wave 3 rollout leaves no pure control. Focus: Waves 1–2 with Wave 3 as not-yet-treated.

## Expected Effects and Mechanisms
1. **E-payment adoption:** POS/ATM/mobile transaction volumes should increase in treated states relative to controls.
2. **Formalization:** If cash penalties push informal transactions into formal channels, state Internally Generated Revenue (IGR) should rise through broader tax base.
3. **Channel decomposition:** POS (retail) vs mobile (P2P) vs ATM tells us which margin adjusts.

## Primary Specification
$$Y_{s,t} = \alpha_s + \gamma_t + \text{ATT}(g,t) + \varepsilon_{s,t}$$
where $g \in \{2012, 2013, 2014\}$ is group (wave), estimated via Callaway–Sant'Anna with state and year fixed effects.

## Data Sources
1. **CBN e-payment statistics** — Quarterly national aggregates by channel (ATM, POS, mobile, web). Published in CBN Statistical Bulletin.
2. **NBS state-level IGR** — Annual state Internally Generated Revenue. Published by National Bureau of Statistics.
3. **World Bank financial inclusion indicators** — Account ownership, mobile money, financial access.
4. **DMSP-OLS/VIIRS nightlights** — State-level annual luminosity as economic activity proxy (backup if IGR data limited).

## Fetch Strategy
1. CBN Statistical Bulletin tables (Excel/CSV) for e-payment volumes 2009–2018
2. NBS IGR data by state from nigerianstat.gov.ng
3. World Bank API for financial inclusion indicators (NGA)
4. If state-level payment data unavailable, use nightlights + national-level payment data as aggregate evidence

## Exposure Alignment
The treatment is defined at the country level: Nigeria adopted the cashless policy in 2012, and outcomes (bank branches, ATMs per 100k) are measured at the country level. The exposure is direct — all commercial banks operating in Nigeria face the cash penalty regime. The cross-country comparison ensures treatment geography matches outcome geography. Within Nigeria, the three-wave staggered rollout means exposure intensity varies by state and year, but our cross-country design treats Nigeria as uniformly treated from 2012 — this is conservative, as it averages over partially-treated early years.

## Limitations (stated upfront)
- Wave 1 (Lagos) is endogenous — Lagos was chosen as pilot precisely because of its commercial importance
- Only 37 clusters → will use wild cluster bootstrap for inference
- National Wave 3 rollout eliminates pure controls post-2014
- IGR measurement may reflect collection effort changes, not just formalization
