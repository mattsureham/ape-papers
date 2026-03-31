# Research Plan: When the Banks Broke — The Panic of 1907, Banking Network Exposure, and Individual Occupational Scarring

## Research Question

Did the Panic of 1907 cause persistent occupational scarring for workers in banking-dependent sectors? Using the IPUMS Machine Learning Linked Panel (MLP) of 15.4 million prime-age men tracked individually from 1900 to 1910, this paper tests whether workers in states with severe banking panics experienced larger occupational income declines than identical workers in less-affected states.

## Identification Strategy

**First-difference with state-level treatment intensity.**

- **Unit of observation:** Individual worker i, linked across 1900 and 1910 censuses
- **Outcome:** Change in occupational income score (occscore) from 1900 to 1910
- **Treatment:** State-level Panic of 1907 severity, coded from published historical sources. The Panic originated in New York trust companies (Oct 1907) and cascaded through the correspondent banking network to 246 national banks suspended nationwide.
- **Key interaction:** Banking-dependent sectors (manufacturing, trade, services) vs. agriculture — workers in banking-dependent sectors in high-panic states should show larger scarring
- **Controls:** 1900 age, race, nativity, marital status, literacy, initial occupation, state FE
- **Falsification:** Agricultural workers (less banking-dependent) should show smaller effects; literacy/demographics should not predict treatment intensity conditional on state FE

## Expected Effects

1. Workers in high-panic states experience larger occscore declines (negative β)
2. Effects concentrate in manufacturing/trade (banking-dependent) vs. agriculture
3. Younger workers show larger scarring (less established careers)
4. Home ownership as mechanism: panic → bank failures → lost savings → forced occupational downshift

## Data Sources

1. **IPUMS MLP 1900-1910** (`az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet` + `az://raw/ipums_fullcount/us1900m.parquet` + `az://raw/ipums_fullcount/us1910m.parquet`) — 33.9M linked records, 15.4M prime-age men
2. **State-level banking panic severity** — coded from Wicker (2000), Moen & Tallman (1992), Sprague (1910): NY, NJ, CT, PA, MA, RI, MD as "core panic" states; remaining states coded by reported bank suspensions
3. **1900 Census full-count** — individual characteristics (age, race, occupation, literacy, nativity)
4. **1910 Census full-count** — post-crisis occupational outcomes

## Fetch Strategy

1. Query MLP crosswalk from Azure via DuckDB (33.9M records)
2. Join with 1900 and 1910 full-count census data on Azure
3. Construct state-level treatment from published historical data (hardcoded from literature)
4. No external API calls needed — all data on Azure
