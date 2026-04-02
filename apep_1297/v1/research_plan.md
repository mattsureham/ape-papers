# Research Plan: The Developer's Ceiling — Price Bunching at Ireland's Help to Buy Cap

## Research Question

Does Ireland's Help to Buy (HTB) tax relief scheme distort new-build housing prices, and who captures the subsidy — buyers or developers? The HTB provides first-time buyers up to €30K in income tax refunds for new-build properties priced at or below €500K, creating a sharp eligibility notch. If developers price-to-the-cap, the subsidy is partially captured by the supply side through inflated prices rather than reducing the effective cost for buyers.

## Identification Strategy

**Bunching design** (Kleven 2016; Kleven and Waseem 2013):

1. **Primary test:** Estimate excess mass in the new-build price distribution just below the €500K threshold. Under no behavioral response, the price distribution should be smooth through €500K. Bunching below reveals that agents (developers/buyers) distort prices to maintain eligibility.

2. **Difference-in-bunching:** The July 2020 enhancement increased max relief from €20K (5% of price) to €30K (10% of price), raising the incentive to remain below €500K. If bunching increases after July 2020, this confirms the distortion is causally linked to HTB generosity.

3. **Built-in placebo:** Second-hand properties are ineligible for HTB. Any bunching at €500K in the second-hand market would indicate round-number heaping, not policy response. The smoke test reports bunching ratio of 0.55 for second-hand (no excess mass), validating the design.

4. **Heterogeneity:** Dublin vs. non-Dublin (price levels differ), house vs. apartment (different developer types), different distance-to-cap windows.

## Expected Effects and Mechanisms

- **Price distortion:** Developers cluster new-build prices at or just below €500K to maintain buyer eligibility. Predictions: excess mass below threshold, missing mass above.
- **Incidence:** The subsidy is split between buyers and developers. If bunching is sharp, developers capture much of the transfer by pricing higher than they otherwise would — a *developer's ceiling* effect where the cap becomes the price.
- **Intensity response:** Bunching should increase after July 2020 when relief became more generous (higher stakes of losing eligibility).
- **Dublin concentration:** In Dublin where market prices often exceed €500K, more transactions are "at risk" of crossing the threshold, so bunching should be stronger.

## Primary Specification

Excess mass estimation using the polynomial bunching estimator:
- Fit polynomial (order 7) to the observed price distribution excluding the bunching window [€480K, €520K]
- Estimate counterfactual density
- Excess mass = (observed - counterfactual) / counterfactual in the bunching region
- Bootstrap standard errors (500 replications)
- Robustness: vary polynomial order (5-9), bunching window width, bin size

## Data Source and Fetch Strategy

**Property Price Register (PPR):** Public register of all residential property transactions in Ireland since January 2010. Available as CSV download from propertypriceregister.ie.

- **Fields:** Date of sale, price, address, county, new/second-hand, VAT status
- **Sample:** All transactions 2010-2023 (PPR covers from 2010, HTB starts 2017)
- **Key variable construction:**
  - `new_build`: indicator from PPR "Description of Property" field
  - `price`: in euros (VAT-inclusive for new builds)
  - `post_htb`: indicator for transactions after January 2017
  - `post_enhancement`: indicator for transactions after July 2020
  - `county`: for Dublin/non-Dublin heterogeneity

**Pre-treatment period (2010-2016):** Serves as placebo — no HTB, so no bunching expected at €500K for new builds either.
