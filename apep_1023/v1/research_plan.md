# Research Plan: Redemption Deserts — SNAP Retailer Loss and Benefit Takeup

## Research Question

Does the loss of SNAP-authorized retailers reduce SNAP participation among eligible households — not through benefit cuts but through destruction of redemption infrastructure? When physical access to the benefit system disappears, do eligible households simply stop using SNAP?

## Motivation

The SNAP participation literature focuses almost entirely on demand-side barriers: stigma, information, transaction costs (Currie 2003, Ganong & Liebman 2018, Finkelstein & Notowidigdo 2019). No paper tests whether the *supply* of redemption locations affects takeup. Yet the SNAP retailer network contracted sharply: the 2018 depth-of-stock rule (tripling minimum inventory from 12 to 36 items) contributed to ~15,000 net retailer losses, concentrated among small-format stores in low-income neighborhoods. The proposed 2025 rule estimates 5,000 more exits.

This is the retail analog of the "clinic distance" literature in health economics: if losing a nearby health clinic reduces healthcare utilization among the insured, losing a nearby SNAP retailer should reduce benefit redemption among the eligible.

## Identification Strategy

**Two-instrument LIML estimation.**

**Endogenous variable:** Net SNAP retailer exits per census tract per year (count of retailer authorizations ending minus new authorizations beginning).

**Instruments:**

1. **Corporate chain shocks (IV1):** Exogenous retailer closures driven by national corporate decisions unrelated to local SNAP conditions:
   - Family Dollar: ~400 closures in 2019 (post-Dollar Tree merger restructuring)
   - Walmart Express/Neighborhood Market: 154 exits in 2016
   - A&P: bankruptcy liquidation of ~300 stores in 2015
   - Exposure: tract-level pre-shock count of SNAP-authorized stores from each chain

2. **Shift-share from 2018 stocking rule (IV2):** Pre-2018 small-format retailer share (stores with <36 stocking items, the Bartik "share") × post-2018 indicator (the "shift"). Tracts with higher pre-reform small-format share experienced more retailer exits after 2018. Validate following Borusyak, Hull, and Jaravel (2022): exogeneity of national stocking rule is the shift; variation comes from cross-tract differences in pre-period small-format exposure.

**Identifying assumption:** Corporate chain closures and the national stocking-rule change affect local SNAP participation *only* through their effect on the number of SNAP-authorized retailers (exclusion restriction). County × year FE absorb local economic shocks.

**Overidentification test:** Hansen J-test for overidentifying restrictions — both instruments should produce consistent estimates.

## Expected Effects and Mechanisms

**Primary hypothesis:** Losing SNAP-authorized retailers reduces tract-level SNAP participation rates. Expected magnitude: small-to-moderate (SDE 0.02–0.10). The mechanism is increased transaction costs: eligible households must travel further to redeem benefits, some give up.

**Mechanisms to test:**
1. **Distance channel:** Effect should be larger in tracts with lower vehicle access (ACS B08141)
2. **Substitution channel:** Effect should be smaller in tracts where remaining retailers are nearby
3. **Concentration channel:** Effect should be larger when the exiting retailer was the *only* or *last* SNAP retailer in the tract

## Primary Specification

$$\text{SNAP Rate}_{ct} = \beta \cdot \widehat{\text{RetailerExits}}_{ct} + \gamma X_{ct} + \alpha_k + \delta_t + \varepsilon_{ct}$$

Where $c$ indexes census tracts, $t$ indexes years, $k$ indexes counties. $X_{ct}$ includes tract-level poverty rate, population, and demographic controls from ACS. Standard errors clustered at county level.

## Data Sources and Fetch Strategy

| Data | Source | Years | Unit | Fetch Method |
|------|--------|-------|------|-------------|
| SNAP participation | ACS 5-year B22003 | 2013–2022 | Tract | Census API (`tidycensus`) |
| SNAP retailers | USDA SNAP Retailer Historical Data | 2012–2023 | Store | Direct download (CSV) |
| Food insecurity | CDC PLACES | 2019–2022 | Tract | CDC API |
| Vehicle access | ACS B08141 | 2013–2022 | Tract | Census API |
| Poverty rate | ACS B17001 | 2013–2022 | Tract | Census API |

**SNAP Historical Database** contains 703K retailer records with authorization start/end dates, store type, and geocoded location. This is the core treatment variable.

## Robustness Checks

1. Reduced form: direct effect of corporate shocks on SNAP participation (intent-to-treat)
2. Leave-one-chain-out: drop each corporate shock separately
3. Alternative outcome: CDC PLACES food insecurity prevalence
4. Placebo: effect on non-SNAP poverty rate (should be null)
5. Alternative clustering: state level, commuting zone level
6. Callaway-Sant'Anna for staggered retailer exits (if reframed as DiD)
