# Research Plan: apep_1025

## Research Question

Do state-level consumer neonicotinoid restrictions affect bird populations? This paper isolates the **residential pesticide channel** — consumer-only bans that exempt agricultural use — from the broader neonicotinoid debate, which has focused almost exclusively on farming applications.

## The Puzzle

Neonicotinoids are the world's most widely used insecticides, and their role in insect and bird population declines is intensely debated. But the debate conflates two distinct exposure channels: agricultural seed treatments covering millions of acres, and consumer applications to suburban lawns and gardens. Twelve U.S. states restricted only the consumer channel (2016–2024), creating a natural experiment that separates residential from agricultural exposure for the first time.

## Identification Strategy

**Staggered DiD** using Callaway and Sant'Anna (2021):
- **Treatment**: State enacts consumer neonicotinoid restriction
- **Unit**: BBS route × year
- **Outcome**: Log abundance of insectivorous birds per route
- **Built-in placebo**: Non-insectivorous birds (raptors, waterfowl, granivores) — unaffected by insect availability
- **Clustering**: State level (50 states)

### Treatment Timing (7 cohorts)
| Year | States |
|------|--------|
| 2016 | MD, CT |
| 2018 | ME |
| 2019 | VT |
| 2021 | MA |
| 2022 | NJ, NY, RI |
| 2023 | CO, NV |
| 2024 | CA, WA |

### Key Advantages
1. **Massive pre-period**: BBS runs since 1966 — up to 50 years pre-treatment
2. **500+ treated routes** across 12 states
3. **Mechanism-matched placebo**: Non-insectivorous species should be unaffected by neonicotinoid-driven insect changes
4. **Route-level granularity** with observer and weather controls

## Expected Effects and Mechanisms

If consumer neonicotinoids harm bird populations through the insect prey channel:
- Insectivorous bird counts should increase in treated states after bans
- Non-insectivorous birds should show no change (placebo)
- Effects may take 1–3 years to materialize (insect recovery → bird breeding success)

The effect could be null if: (a) consumer neonicotinoid use is too small relative to agricultural use, (b) substitution to other pesticides offsets gains, or (c) bird population dynamics respond too slowly to detect in this window.

## Primary Specification

```
Y_{r,t} = α_r + α_t + β × Treated_{s(r),t} + X_{r,t}γ + ε_{r,t}
```
where r indexes routes, t indexes years, s(r) maps routes to states. X includes observer experience (years on route), weather conditions. CS estimator aggregates cohort-specific ATTs.

## Data Sources

1. **USGS Breeding Bird Survey (BBS)**: Route-level annual bird counts, 1966–2024. ~3,000 routes, 50 stops per route, 700+ species. Access via ScienceBase bulk download or `bbsAssistant` R package.

2. **Bird dietary classification**: AOU species codes × primary diet guild (insectivore, granivore, omnivore, raptor, waterfowl). From Birds of the World / published ecological literature.

3. **State policy dates**: Legislative research to confirm enactment and effective dates for all 12 states.

## Fetch Strategy

1. Download BBS route-level data from ScienceBase (CSV files)
2. Construct route × year panel with total counts by dietary guild
3. Merge state treatment indicators based on route state codes
4. Construct observer experience variable from observer history

## Robustness Checks

1. **Triple-difference**: Insectivorous × treated × post (non-insectivorous as control group)
2. **Event study**: Dynamic treatment effects showing pre-trends and post-treatment dynamics
3. **Heterogeneity**: By urbanization (suburban routes should show larger effects)
4. **Leave-one-state-out**: Jackknife across 12 treated states
5. **Wild cluster bootstrap**: For inference with 50 clusters
