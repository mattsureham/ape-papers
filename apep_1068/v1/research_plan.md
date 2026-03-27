# Research Plan: Last Hired, Not First Fired

## Research Question

Did the occupational gains achieved by Black Great Migration participants during the 1920s boom survive the Great Depression? The canonical "last hired, first fired" narrative predicts Depression-era losses should have disproportionately eroded Black migrant gains. This paper provides the first individual-level test using a three-decade linked census panel (1920-1930-1940).

## Identification Strategy

**Shift-share IV.** For each Southern origin county *c*, construct:

Z_c = Σ_d [RailDist_{c,d}^{-1} × BlackPop_{d,1910}]

where *d* indexes Northern destination cities, RailDist is the pre-1910 railroad distance, and BlackPop_{d,1910} is the 1910 Black population stock.

- **Shares:** Railroad distance from origin to destination (built 1870-1910, predetermined)
- **Shifts:** 1910 Black population in destination cities (predates 1920s wave)
- **First stage:** Z_c predicts individual migration propensity
- **Second stage:** Instrumented migration → occupational change 1930→1940

**Exclusion story:** Railroad connections built 40+ years prior to the 1930s Depression affect 1930-1940 occupational change only through their effect on 1920s migration decisions. Conditional on destination fixed effects and origin-county characteristics, the instrument is uncorrelated with Depression-era economic shocks.

**Estimand:** LATE for compliers — the Depression-era occupational resilience of those whose migration was induced by better railroad access to destinations with established Black communities.

## Expected Effects and Mechanisms

**Primary hypothesis:** Migration gains persist through the Depression (β > 0 or β ≈ 0 in the 1930-1940 change equation), contradicting "last hired, first fired."

**Mechanism 1 (Structural access):** Northern industrial labor markets offered fundamentally different occupational ladders than Southern agriculture. Even during contraction, these structural advantages persist.

**Mechanism 2 (Seniority accumulation):** By 1930, migrants had ~10 years of Northern work experience. Seniority protections in unionized industries shielded established workers.

**Mechanism 3 (Network insurance):** Established ethnic networks in destination cities provided job information and mutual aid during the Depression.

**Alternative (last hired, first fired):** If racial discrimination intensified during scarcity, migrants would lose gains disproportionately → β < 0.

## Primary Specification

**OLS baseline:**
Δocc_{i,1930→1940} = α + β₁ × Migrate_i + β₂ × Δocc_{i,1920→1930} + γ × X_i + δ_origin + ε_i

**IV (2SLS):**
- First stage: Migrate_i = π₀ + π₁ × Z_{county(i)} + π₂ × X_i + δ_origin + v_i
- Second stage: Δocc_{i,1930→1940} = α + β × Migrate_hat_i + γ × X_i + δ_origin + ε_i

**Covariates (X_i):** Age in 1920, literacy, farm status in 1920, marital status in 1920, baseline occscore in 1920.

**Clustering:** Origin county (939 clusters).

**Placebo:** White Southern migrants (39,178) — same design, same Depression exposure, but without racial "last hired, first fired" discrimination.

## Robustness

1. Alternative occupational measures (SEI instead of occscore)
2. Exclude return migrants (8.2% return rate)
3. Origin-state × destination-state fixed effects
4. Leave-one-out IV (drop each destination city)
5. Reduced-form (ITT) estimates
6. Heterogeneity by destination industry composition

## Data Source and Fetch Strategy

**Primary:** Azure MLP panels — `derived/mlp_panel/linked_1920_1930_1940.parquet` (34.7M rows total, 12,427 Black S→N migrants)

**Secondary:** `derived/mlp_panel/linked_1920_1930.parquet` for two-decade sample (28,049 Black S→N migrants)

**Railroad distance instrument:** Need to construct from Donaldson & Hornbeck (2016) railroad network data. Will use county centroids and pre-1910 railroad network to compute shortest-path distances.

**Fetch strategy:** DuckDB queries against Azure Blob parquet files. No downloads needed for the main panel.
