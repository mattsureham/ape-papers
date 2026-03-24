# Research Plan: The Two Faces of the State EITC: Racial Employment Gains versus Market Wage Incidence

## Research Question

State EITC supplements are celebrated for expanding employment among disadvantaged workers. But Rothstein (2010, AEJ:EP) showed theoretically that the EITC depresses pre-tax wages — employers capture part of the subsidy. Does this wage incidence differ by race? Do Black workers gain employment but face employer wage extraction, shrinking the net equity benefit?

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD** exploiting 12 state EITC adoptions within the QWI window (2006-2018). Unit of observation: county × industry × race × quarter. Never-treated states (22+) serve as controls.

**Triple-difference (DDD):** Black vs White workers × treated vs control states × pre vs post adoption. This absorbs county-industry-quarter shocks common to both races, and race-specific national trends.

**Key advantages:**
- 600+ treated counties across 12 state cohorts
- 5-15 pre-treatment years per cohort
- Never-treated comparison states
- Race decomposition unavailable in CPS/ACS

## Expected Effects

1. **Employment equity (positive):** State EITCs increase Black employment and hiring rates relative to White workers in treated states — consistent with EITC's labor supply incentive targeting lower-income workers.
2. **Wage incidence (negative):** Market wages (EarnS) in low-wage sectors grow more slowly or fall in treated states for ALL workers — the Rothstein employer-capture channel.
3. **Differential incidence by race (novel):** If Black workers have less labor market power (fewer outside options), wage depression may be larger for Black workers, partially offsetting employment gains.

## Primary Specification

```
Y_{csrq} = α + Σ_g Σ_t ATT(g,t) × 1[G_s=g, Q=t] + γ_{cr} + δ_{iq} + ε_{csrq}
```

Where c=county, s=state, r=race, q=quarter, i=industry, g=treatment cohort. Estimated via `did` R package (Callaway & Sant'Anna).

**DDD specification:**
```
Y_{csriq} = β₁(Treat_s × Post_sq × Black_r) + β₂(Treat_s × Post_sq) + β₃(Treat_s × Black_r) + β₄(Post_sq × Black_r) + γ_{ci} + δ_{rq} + ε
```

## Data Sources

1. **QWI (Quarterly Workforce Indicators):** Azure Parquet at `az://derived/qwi/rh/ns/*.parquet`. 2.16M observations, county × industry × race × quarter, 1990-2025. Variables: Emp (employment), EarnS (avg monthly earnings), HirN (new hires), Sep (separations), TurnOvrS (turnover).

2. **State EITC adoption dates:** Hand-coded from Tax Policy Center / NCSL. 12 states within QWI window: DE, NE, VA (2006), NM (2007), LA, MI (2008), CT (2011), OH (2013), CA (2015), HI, SC (2018).

3. **Low-wage sector restriction:** NAICS 72 (Accommodation/Food), 44-45 (Retail), 62 (Healthcare support).

## Fetch Strategy

1. Load QWI Parquet from Azure using `arrow::open_dataset()`
2. Filter to low-wage sectors, White (A1) and Black (A2) race categories
3. Merge state EITC adoption timing
4. Construct county × industry × race × quarter panel
