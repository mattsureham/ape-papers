# Research Plan: Breaking Eggs — The Production and Price Effects of State Cage-Free Mandates

## Research Question

Do state-level cage-free egg mandates reduce in-state egg production, and does this production displacement raise consumer egg prices? This paper exploits the staggered adoption of cage-free mandates across 10 US states (2022–2026) to estimate causal effects on egg production and prices.

## Identification Strategy

**Staggered DiD with Callaway–Sant'Anna (2021) estimator.**

- **Treatment:** State enactment of laws requiring all shell eggs sold in-state to come from cage-free housing systems, with binding compliance deadlines.
- **Cohorts (5):**
  - 2022: California (Prop 12)
  - 2023: Massachusetts (Q3)
  - 2024: Washington, Oregon, Nevada
  - 2025: Colorado, Arizona, Michigan, Utah
  - 2026: Rhode Island (not-yet-treated, serves as control during sample)
- **Control group:** ~20 states without cage-free mandates (Iowa, Indiana, Ohio, Pennsylvania, Georgia, etc.)
- **Fixed effects:** State + month-year (absorbs national shocks like avian influenza)
- **Inference:** Clustered at the state level; wild cluster bootstrap for robustness given 30 clusters

## Expected Effects and Mechanisms

1. **Production displacement:** Mandates raise per-hen housing costs. States with mandates should see flock reductions as producers exit or relocate to non-mandate states. CA already shows 44% layer reduction (2024→2025).
2. **Price pass-through:** Reduced local production + higher production costs → higher retail egg prices in mandate states. Degree of pass-through depends on market structure and interstate trade.
3. **Productivity effect:** Cage-free systems may affect eggs-per-layer (hens may produce differently in cage-free environments).

## Primary Specification

```
Y_{st} = α_s + γ_t + β·Mandate_{st} + ε_{st}
```

Using Callaway–Sant'Anna `att_gt()` for group-time ATTs, aggregated by:
- Simple average (overall ATT)
- Event-study (dynamic effects relative to mandate effective date)
- Group-specific (cohort heterogeneity)

## Data Sources

### 1. USDA NASS — Chickens and Eggs Report (monthly)
- **Variables:** Average number of layers (thousands), total egg production (million eggs), eggs per 100 layers
- **Coverage:** ~30 reporting states, monthly, 2010–2025
- **Access:** USDA NASS QuickStats API (`https://quickstats.nass.usda.gov/api/`)
- **API key:** `USDA_NASS` in `.env`

### 2. BLS — Average Price Data
- **Variables:** Average retail price per dozen eggs (Grade A, large)
- **Series:** APU0000708111 (US city average), regional series
- **Coverage:** Monthly, 2010–2025
- **Access:** BLS Public Data API (`https://api.bls.gov/publicAPI/v2/timeseries/data/`)

### 3. Placebo Outcome
- Hatching egg production (exempt from cage-free mandates) — from USDA NASS

## Robustness Checks

1. Event-study pre-trends (7+ pre-periods)
2. Leave-one-out (drop CA, which dominates treatment)
3. Placebo outcome: hatching eggs (should not respond to cage-free mandates)
4. Wild cluster bootstrap p-values
5. Bacon decomposition to check TWFE bias
6. Sun–Abraham estimator as alternative
