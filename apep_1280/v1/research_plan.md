# Research Plan: The Floor Lifts All Boats? Minimum Wages and the Racial Labor Income Gap

## Research Question

Does raising the minimum wage narrow the Black-White total labor income gap? We decompose the effect into two channels: (a) earnings-per-worker compression (MW raises wages at the bottom where Black workers are concentrated) and (b) employment retention (MW may reduce Black employment disproportionately). The net effect on total labor income is ambiguous ex ante.

## Policy Background

State minimum wages diverged sharply from the federal floor ($7.25/hr) beginning around 2012. By 2020, 13+ states had implemented substantial MW increases (California to $15, New York to $15, Washington to $13.50, etc.) while 17+ states remained at $7.25 (TX, TN, SC, AL, MS, etc.). This staggered adoption provides the core identifying variation.

## Identification Strategy

### Primary: Callaway-Sant'Anna (2021) Staggered DiD

Treatment cohort = year-quarter when state MW first exceeds 115% of federal floor. 13+ treated states vs. 17+ never-treated states as control. QWI provides 20+ pre-treatment quarters for parallel trends validation.

### Triple-Difference (DDD)

- Tier 1: MW-exposed industries (NAICS 44-45 retail, 72 food service, 56 admin support) vs. unexposed high-wage industries (52 finance, 54 professional services)
- Tier 2: treated vs. control states
- Tier 3: post-MW hike vs. pre

This separates MW effects from state-level trends common to all industries.

### Decomposition

For the racial gap:
- Total wage bill ratio: log(WageBill_Black / WageBill_White)
- Employment ratio: log(Emp_Black / Emp_White)
- Earnings-per-worker ratio: log(EarnS_Black / EarnS_White)

Accounting identity: WageBill ratio = Employment ratio × Earnings-per-worker ratio (in logs: sum).

## Expected Effects

1. **Earnings compression**: MW increases should narrow Black-White earnings-per-worker gap in low-wage industries (positive effect on ratio)
2. **Employment**: Ambiguous — classical model predicts disemployment, monopsony model predicts possible employment gains
3. **Net labor income**: Depends on relative magnitudes — the key contribution
4. **Placebo**: Null effect expected in high-wage industries (52, 54)

## Data Sources

1. **QWI Race×Industry (rh/n3)** — Azure: `az://derived/qwi/rh/n3/*.parquet`
   - 51 states, county×quarter×3-digit NAICS×race
   - Variables: Emp, EarnS, HirA, HirN, Sep
   - Race: A1 (White alone), A2 (Black alone)
   - Years: 1995–2024
   
2. **State Minimum Wage History** — Vaghul & Zipperer (2021) dataset via Washington Center for Equitable Growth, supplemented by DOL

## Fetch Strategy

1. Read QWI parquet files from Azure via DuckDB (already stored)
2. Construct state minimum wage history from published sources
3. Build county×quarter×industry×race panel restricted to target industries
