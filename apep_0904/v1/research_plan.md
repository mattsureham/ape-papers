# Research Plan: The Cost of Red Tape by Revealed Preference

## Research Question

How much do federal contracting officers distort contract values to avoid procurement compliance costs? Using bunching estimation at the Simplified Acquisition Threshold (SAT), this paper recovers the structural compliance cost of full-and-open competition requirements through revealed preference.

## Identification Strategy

**Multi-threshold bunching migration (Kleven 2016).** The SAT determines whether a contract follows Simplified Acquisition Procedures (below) or full-and-open competition (above). Three successive SAT increases create bunching migration experiments:

1. **$100K → $150K** (2006): Bunching should migrate from $100K to $150K
2. **$150K → $250K** (Aug 2020): Bunching should migrate from $150K to $250K
3. **$250K → $350K** (Oct 2025): Out-of-sample prediction

The excess mass below each threshold, and its migration when the threshold moves, identifies the compliance cost of full-and-open competition by revealed preference: the marginal contracting officer's willingness to distort contract size to avoid regulatory burden.

## Key Design Features

- **Internal replication**: Same estimator at 3 different thresholds
- **Migration test**: When the threshold moves, the bunching mass should follow — validating the structural interpretation
- **Placebo thresholds**: Round numbers ($200K, $300K, $500K) should show smaller density spikes without policy-driven excess
- **Heterogeneity**: Defense vs civilian agencies; service vs construction contracts

## Data

**USAspending.gov / FPDS-NG API**: Universe of unclassified federal contracts, FY2008–FY2025. ~5.87M contract actions per year. Key fields: award amount, NAICS, agency, solicitation procedure, extent competed, number of offers, set-aside type, date.

**Strategy**: Query contracts in the $25K–$500K range by fiscal year. Bin into $5K intervals. Estimate excess mass at each threshold.

## Primary Specification

Bunching estimation following Chetty et al. (2011) and Kleven & Waseem (2013):
- Fit polynomial to the density of contract values, excluding the bunching region
- Estimate excess mass b = (B - B_counterfactual) / B_counterfactual
- Structural compliance cost C ≈ b × Δz, where Δz is the bunching window width

## Expected Effects

- Substantial bunching below each active SAT (b > 0)
- Bunching migration when thresholds change (excess mass moves to new threshold)
- Greater bunching for service contracts (more splittable) than construction
- Greater bunching in civilian agencies (DOD has different threshold culture)

## Robustness

- Varying polynomial order (5th to 9th)
- Varying bunching window width
- McCrary-style density test
- Placebo thresholds
- Leave-one-agency-out
