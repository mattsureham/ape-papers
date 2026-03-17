# Research Plan: Alien Land Laws and Japanese Occupational Sorting

## Research Question
Did state-level Alien Land Laws (enacted 1921-1923) cause Japanese immigrants to exit agriculture and move into higher-skilled occupations? What does the individual-level occupational transition reveal about forced sorting and its human capital consequences?

## Identification Strategy
Staggered difference-in-differences using individual-level linked census panels:
- **Treatment:** State enacts an Alien Land Law between 1920 and 1930 census waves (WA 1921, TX 1921, LA 1921, NM 1922, OR 1923, ID 1923, MT 1923)
- **Control:** Japanese in never-treated states (CO, UT, NY, IL, NV, WY, NE, and others without ALLs)
- **Pre:** 1920 census (pre-treatment for newly treated states)
- **Post:** 1930 census (post-treatment)
- **Unit:** Individual linked across censuses

Note: California enacted its ALL in 1913 (strengthened 1920), Arizona in 1917. These are ALREADY treated by 1920, so California/Arizona Japanese are excluded from the main DiD to avoid bias from prior treatment.

**Key falsification:** White workers in the same states serve as a placebo group. If ALLs (which targeted only "aliens ineligible for citizenship") drive the result, white workers should show no farm exit differential — or the opposite pattern. Smoke test confirms: white farm exit was 32.4% in treated vs 37.4% in never-treated (opposite of Japanese).

## Expected Effects and Mechanisms
- **Farm exit:** Japanese in treated states should be more likely to leave farming between 1920-1930.
- **Occupational upgrading:** Farm exiters should move to higher OCCSCORE occupations (manufacturing, retail, services).
- **Mechanism 1 (Direct displacement):** ALLs directly prohibit land ownership/leasing, forcing farmers off land.
- **Mechanism 2 (Forced sorting):** Displaced farmers invest in non-agricultural human capital, potentially gaining occupational status.
- **Heterogeneity:** Effects should be strongest for farm owners (directly affected) vs. farm laborers (indirectly affected through labor market thinning).

## Primary Specification
Individual-level DiD:
```
Y_{i,t} = β * (Japanese_i × NewlyTreated_s × Post_t) + Individual FE + State×Year FE + ε_{i,t}
```
Where Y is farm exit indicator, OCCSCORE change, or indicator for specific occupation transitions.

With only 2 periods (1920, 1930), this simplifies to first-differenced estimation:
```
ΔY_i = β * (Japanese_i × NewlyTreated_s) + State FE + ε_i
```

## Data Source and Fetch Strategy
**Primary:** MLP linked panels on Azure
- `derived/mlp_panel/linked_1920_1930.parquet` — 1920-1930 linked individuals
- `derived/mlp_panel/linked_1920_1930_1940.parquet` — triple panel for persistence

**Variables needed:** HISTID, YEAR, STATEFIP, RACE/NATIVITY (to identify Japanese), OCC1950, OCCSCORE, FARM, CLASSWKR, AGE, SEX, IND1950

**Fetch strategy:** Use DuckDB to query Azure parquet files directly, filtering to relevant states and race/nativity groups. Subsample white workers (4.15M is too large — take random 5% sample for placebo analysis).
