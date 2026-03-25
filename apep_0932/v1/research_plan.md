# Research Plan: apep_0932

## Research Question

Did New Deal work relief (WPA/FERA) narrow or widen the Black-White occupational mobility gap? Federal law prohibited racial discrimination in WPA access, but local administrators controlled eligibility. Taylor, Schaller, and Fishback (2024, NBER w32681) document Black men had systematically worse WPA access using county-level data. We ask the individual-level question: conditional on county WPA spending intensity, did Black workers experience smaller occupational gains than comparable white workers?

## Identification Strategy

**Difference-in-differences-in-differences (DDD):**
- First difference: 1940 (post-New Deal) vs 1930 (pre-New Deal) occupational score
- Second difference: High vs low WPA spending counties (county-level Fishback data)
- Third difference: Black vs White workers within the same county

Pre-trend validation: 1920→1930 occupational trajectories (pre-Depression baseline) should be parallel across high/low WPA counties, separately by race.

**Key identifying assumption:** Within-county, within-decade, the Black-White differential in occupational mobility would have evolved identically across high- and low-WPA counties absent the program.

## Expected Effects and Mechanisms

Two competing hypotheses:
1. **Federal floor hypothesis:** WPA provided stable employment to Black workers locked out of private labor markets, especially in the South → narrowing the racial gap in high-WPA counties
2. **Local gatekeeping hypothesis:** Southern administrators diverted WPA jobs to white workers, amplifying existing discrimination → widening the racial gap in high-WPA counties

The sign of β₃ (Black × High-WPA × Post) identifies which force dominates.

## Primary Specification

```
ΔOccScore_i = α + β₁(HighWPA_c) + β₂(Black_i × HighWPA_c) + γ_c + δ_X + ε_i
```

Where:
- ΔOccScore_i = OCCSCORE_1940 - OCCSCORE_1930 for individual i
- HighWPA_c = county WPA+FERA spending per capita (continuous or tercile)
- γ_c = county fixed effects (absorb β₁)
- δ_X = individual 1930 controls (age, nativity, initial occupation FE)

Cluster SEs at county level (~3,000 clusters).

## Data Sources

1. **IPUMS MLP v2 crosswalk** (`az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet`, 175.6M rows)
   - Triple-link: 1920→1930→1940 (36.8M individuals)
2. **1920 Census** (`az://raw/ipums_fullcount/us1920c.parquet`, 4.8 GB)
3. **1930 Census** (`az://raw/ipums_fullcount/us1930d.parquet`, 5.6 GB)
4. **1940 Census** (`az://raw/ipums_fullcount/us1940b.parquet`, 6.4 GB)
5. **Fishback county WPA/FERA spending** (NBER public repository, ~3,000 county rows)

Total in-memory requirement: ~30-40 GB for full panel construction → 128 GB RAM critical.

## Fetch Strategy

- Census data + MLP crosswalk: DuckDB queries against Azure Blob parquet files
- Fishback WPA data: Download from NBER/ICPSR public archive (CSV)
- Construct panel via DuckDB joining MLP crosswalk histid columns to census HISTID columns

## Robustness

1. Pre-trend: 1920→1930 occupational change by race × WPA tercile (should be null)
2. South vs non-South heterogeneity (gatekeeping strongest in South)
3. Continuous WPA treatment (spending per capita) vs tercile
4. Leave-one-state-out
5. Placebo: women (largely excluded from WPA work relief)
6. Alternative outcomes: INCWAGE (1940 only), geographic mobility, employment status
