# Research Plan: When the Anchor Drops

## Research Question

Do bankruptcy-driven supermarket exits cause nearby bank branches to close? The paper studies whether the loss of a high-foot-traffic grocery anchor produces an "anchor-tenant cascade" that unravels local banking access as well as food access.

## Main Outcome and Unit of Analysis

The main unit of analysis is a bank branch-year from the FDIC Summary of Deposits (SOD), 2005-2024. The primary outcome is an indicator for branch exit by the next annual snapshot. Secondary outcomes are log deposits and a closure-by-three-years indicator.

## Treatment Definition

Treatment is exposure to a bankruptcy-linked supermarket exit within one mile of the bank branch. I will construct annual supermarket presence from the SNAP Retailer Historical Database, identify large-chain bankruptcies and restructurings named in the idea manifest, and mark a branch as exposed when a nearby supermarket affiliated with a bankrupt chain disappears from the SNAP panel.

The one-mile radius is the main specification because the hypothesis is a pedestrian and trip-chaining foot-traffic spillover. I will keep 0-0.5 mile and 1-2 mile bands for heterogeneity and decay tests.

## Identification Strategy

### Primary Design

The primary design is a stacked event-study / difference-in-differences around bankruptcy-linked supermarket exits:

\[
Y_{bct} = \sum_{k \neq -1} \beta_k \mathbf{1}\{t - T_{bc} = k\} + \alpha_b + \alpha_{ct} + \varepsilon_{bct}
\]

where \(b\) indexes bank branches, \(c\) counties, and \(T_{bc}\) is the first nearby bankruptcy-linked supermarket exit. Branch fixed effects absorb permanent location quality; county-by-year fixed effects absorb local macro conditions and banking trends. Event-time coefficients test for pre-trends and dynamic post-exit responses.

### Comparison Group

The preferred comparison group is bank branches in the same county that are 2-5 miles from the exiting supermarket and never within one mile of a bankruptcy-linked exit in the event window. This ring design tightens local comparability while preserving exposure contrast.

### Endogeneity Control

Generic supermarket exits are endogenous to neighborhood decline, so the paper will not treat them as causal evidence unless they can be tied to an external chain-level bankruptcy or restructuring shock. The bankruptcy-linked reduced form is therefore the causal core. If enough chain-bankruptcy variation survives the data cleaning step, I will also estimate an IV-style first stage where bankruptcy exposure predicts nearby supermarket exit, but the paper does not depend on that extension.

## Expected Effects and Mechanisms

The main prediction is that nearby bank branches become more likely to close after an anchor supermarket exit because they lose foot traffic, transaction demand, and cross-shopping visits. Effects should be stronger for:

- Small-deposit branches
- Branches in lower-density retail corridors
- The 0-0.5 mile exposure band relative to 1-2 miles

If the effect is present on branch closure but weak on deposits, that would point to extensive-margin rationalization rather than gradual attrition. If deposits fall first and closures follow, that supports a demand/traffic mechanism.

## Data Sources

### FDIC Summary of Deposits

- Annual branch-level panel, 2005-2024
- Variables needed: branch identifiers, institution name, latitude/longitude, county FIPS, deposits, open/close status
- Access path: FDIC SOD public API or downloadable annual files

### SNAP Retailer Historical Database

- Historical authorized retailer panel with address, geocodes, store name, and SNAP authorization status
- Used to identify supermarket presence, chain affiliation, and annual exits

### Supporting Data

- Bankruptcy event dates and affected chains from public filings / court dockets / major press coverage
- County Business Patterns or Census business data for placebo/market-structure controls if needed

## Fetch Strategy

Machine constraints are `APEP_MAX_RAM_GB=8` and `APEP_CPU_CORES=8`, so the raw branch and retailer panels will be handled out-of-core with DuckDB/Arrow where possible. I will:

1. Download or query annual FDIC SOD branch files into `data/raw/fdic/`.
2. Download SNAP historical retailer data into `data/raw/snap/`.
3. Build a cleaned supermarket-only retailer panel and a branch panel with stable branch IDs.
4. Perform spatial joins using `sf` after filtering to supermarket candidates and annual nearby pairs, not on the full Cartesian product.

## Primary Specification

The headline estimate will be the post-exit effect from a branch-level stacked event study using branch and county-year fixed effects with standard errors clustered by county. The main table will report:

- Event-study pre-trend test
- Average post-exit effect on branch closure
- Effect on log deposits
- Heterogeneity by distance band and baseline branch size

## Method Notes

- The paper's estimand is local to bankruptcy-linked supermarket exits, not all grocery exits.
- The design does not identify welfare effects on households directly; it identifies the branch-survival effect on nearby banking infrastructure.
- If pre-trends fail or the retailer-chain classification is too noisy, the idea should be retired rather than padded with descriptive regressions.
