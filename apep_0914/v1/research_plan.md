# Research Plan: From Field to Factory — AAA Cotton Displacement and Long-Run Black Occupational Scarring, 1930–1950

## Research Question
Did the Agricultural Adjustment Act's acreage reduction program (1933–1936) cause long-run occupational scarring for Black farm workers in the cotton South, and did the Second Great Migration attenuate or amplify this effect?

## Identification Strategy
**Triple-differences (DDD):** Compare occupational score changes (1930→1940→1950) for Black vs. white farm workers across counties with varying AAA acreage reduction intensity.

Specification:
```
occscore_it = α + β₁(AAA_c × Black_i × Post_t) + β₂(AAA_c × Post_t)
            + β₃(Black_i × Post_t) + γ_i + δ_t + ε_it
```

Key coefficient: β₁ captures the differential occupational effect of AAA intensity on Black (vs. white) farm workers after the program.

**Pre-trend validation:** 1930 wave is the genuine pre-treatment baseline. The 1920→1930 change (using 1920-1930 link if available) or cross-sectional 1930 balance tests serve as pre-treatment checks.

## Expected Effects and Mechanisms
1. **Direct displacement (1930→1940):** Higher AAA intensity → larger occupational gains for white farm workers (who mechanized) but smaller gains for Black workers (who were displaced from sharecropping into lower-paid agricultural labor or unemployment)
2. **Migration channel (1940→1950):** Black workers in high-AAA counties more likely to migrate North; Northern migrants gain ~5-6 additional occupational score points vs. Southern stayers
3. **Occupational scarring:** Net 20-year effect for Black workers in high-AAA counties is negative relative to white workers — the "scarring" from initial displacement persists despite partial recovery through migration

## Primary Specification
- **Unit:** Individual × wave (3 waves: 1930, 1940, 1950)
- **Treatment:** County-level AAA acreage reduction payments per farm acre (continuous, 1933-1936)
- **Outcome:** Occupational income score (occscore)
- **Fixed effects:** Individual FE (γ_i), wave FE (δ_t), state × wave FE
- **Clustering:** County of 1930 residence (~1,200 counties)
- **Sample:** Black and white farm workers in 11 cotton-belt Southern states, linked across 1930-1940-1950 censuses

## Data Sources
1. **MLP Triple-Linked Panel:** `az://derived/mlp_panel/linked_1930_1940_1950.parquet`
   - 144,759 Black farm workers + 687,395 white farm workers
   - Variables: occscore_1930/1940/1950, farm_1930, race_1930, mover_40_50, statefip_1930, countyicp_1930

2. **AAA County Payments:** ICPSR #2603 (Fishback-Kantor-Wallis)
   - County-level AAA acreage reduction payments per farm acre, 1933-1936
   - Public dataset, downloadable

## Robustness Checks
- Leave-one-state-out
- Alternative AAA intensity measures (total payments vs. per-acre)
- Placebo: non-cotton crops (tobacco, rice counties) where AAA had different structure
- Wild cluster bootstrap for inference with ~1,200 county clusters
- Controlling for other New Deal programs (WPA, CCC spending)

## Mechanism Tests
1. Migration as mediator: Does AAA intensity predict Black out-migration 1940→1950?
2. Destination decomposition: Northern movers vs. Southern stayers occupational gains
3. Railway employees: Railways = 28% of central employees; AAA may differently affect railroad-adjacent vs. remote counties
