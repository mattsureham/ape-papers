# Research Plan: The Stamp Duty Cliff

## Research Question

Does Australia's first home buyer stamp duty exemption threshold distort house prices and buyer behavior? Specifically: (1) How much excess bunching occurs at the stamp duty exemption threshold? (2) Did the July 2023 NSW threshold increase from A$650K to A$800K shift the bunching mass? (3) Do buyers near the threshold downgrade property quality (smaller lots, different property types) to stay below the cap — a "quality squeeze" channel?

## Identification Strategy

**Multi-cutoff bunching design** following Kleven (2016) and Best & Kleven (2018 REStud).

1. **Cross-sectional bunching:** Estimate excess mass at the NSW $800K threshold (post-July 2023) using the Chetty et al. (2011) / Kleven-Waseem (2013) framework. The counterfactual distribution is estimated from a polynomial fit excluding the bunching region.

2. **Difference-in-bunching:** Compare the price distribution around $800K BEFORE (Jan 2022 - Jun 2023) and AFTER (Jul 2023 - Dec 2024) the threshold change. The increase in bunching mass identifies the stamp duty incentive.

3. **Quality composition test:** Within the bunching region ($750K-$800K), test whether lot sizes, property types (house vs. unit), and area characteristics shifted post-reform — evidence of quality downgrading.

4. **Multi-state comparison:** QLD raised its threshold to $700K in June 2024; VIC kept $600K/$750K stable. These serve as additional cutoffs and control.

## Expected Effects and Mechanisms

- **Price bunching:** Transactions should cluster just below $800K post-reform. The stamp duty saving at $800K is ~A$31,000 — a massive notch.
- **Quality squeeze:** Buyers who would have purchased $820K-$850K properties may negotiate down to $800K by accepting smaller lots or switching from houses to units.
- **Seller response:** Some sellers may list at exactly $800K to attract first-home buyers.
- **Round-number confound:** $800K is a round number. The difference-in-bunching design (comparing pre/post reform) eliminates this since round-number bunching exists in both periods.

## Primary Specification

For each cutoff c (e.g., $800K):

1. **Estimate counterfactual density:** Fit 7th-degree polynomial to histogram counts in price bins ($5K width), excluding the bunching region [c-δ, c].
2. **Excess mass:** b̂ = (observed - counterfactual) / counterfactual height at threshold.
3. **Difference-in-bunching:** Δb̂ = b̂_post - b̂_pre, with bootstrap standard errors.
4. **Quality regression:** Within bunching region, regress lot_size on post_reform × near_threshold, with property type and LGA fixed effects.

## Data Source and Fetch Strategy

**Primary:** NSW Valuer General Bulk Property Sales Information
- URL: https://valuation.property.nsw.gov.au/embed/propertySalesInformation
- Format: CSV, ~294MB, ~2.16M records (residential, 6+ years)
- Fields: sale price, contract date, area/lot size, property type, postcode, LGA, zoning
- Access: Free, no registration required

**Secondary (robustness):**
- ABS Lending Indicators (monthly, aggregate)
- Victorian Property Sales Report (if accessible)

## Key Risks

1. **Round-number bunching at $800K:** Mitigated by difference-in-bunching design
2. **Compositional changes over time:** Mitigated by LGA fixed effects and property type controls
3. **COVID/interest rate confounds:** Mitigated by comparing within the same macro environment (2022-2024)
4. **First-home-buyer identification:** The data may not flag FHB status directly. Use property type and price range as proxies, plus the bunching response itself as revealed preference.
