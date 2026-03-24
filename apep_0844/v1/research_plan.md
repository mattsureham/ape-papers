# Research Plan: apep_0844

## Research Question

When states cut appropriations to public universities, who bears the cost? Standard accounts focus on tuition increases and enrollment declines, but aggregate enrollment at public 4-year institutions barely changed through the Great Recession despite 30-50% funding cuts. This paper asks whether the true cost is hidden in *enrollment composition*: do funding cuts displace low-income (Pell) and minority students, replacing them with full-tuition out-of-state students?

## Identification Strategy

**Bartik IV:** Instrument state-level appropriation shocks using the interaction of pre-period state higher-education budget shares (2003) with national fiscal shocks (state tax revenue declines driven by the Great Recession). States with larger initial higher-ed budget shares experienced larger cuts because higher education is the "balance wheel" of state budgets — it gets cut first when revenues fall.

- **First stage:** Bartik shock → per-student state appropriations
- **Second stage:** Per-student appropriations → (i) in-state tuition, (ii) Pell grant recipient share, (iii) enrollment composition by race/ethnicity, (iv) out-of-state enrollment share

**Key assumption:** National recession shocks are exogenous to individual institutions' enrollment composition changes, conditional on institution and year fixed effects.

**Clustering:** State level (~50 clusters).

## Expected Effects and Mechanisms

1. **Tuition passthrough:** $0.40-0.60 tuition increase per $1 appropriation cut (consistent with prior OLS estimates)
2. **Pell share decline:** As tuition rises, Pell-eligible students face larger net price increases (Pell grants are capped) → lower enrollment of low-income students
3. **Out-of-state substitution:** Institutions compensate lost state revenue by recruiting out-of-state students who pay 2-3x tuition → mechanical composition shift
4. **Racial composition:** Given income-race correlation, expect decline in Black and Hispanic enrollment shares

The core finding: **total enrollment is stable because institutions substitute student types, not because cuts are harmless.**

## Primary Specification

```
Y_{it} = α + β * StateApprop_{it} + X_{it}γ + μ_i + τ_t + ε_{it}

Instrumented: StateApprop_{it} = π * BartikShock_{st} + X_{it}δ + μ_i + τ_t + v_{it}

BartikShock_{st} = HEBudgetShare_{s,2003} × NationalFiscalShock_t
```

Where:
- Y_{it}: tuition, Pell share, enrollment composition at institution i in year t
- μ_i: institution fixed effects
- τ_t: year fixed effects
- X_{it}: state-level controls (unemployment, population, median income)
- Clustered SEs at state level

## Data Source and Fetch Strategy

**IPEDS on Azure:** `az://apepdata/raw/ipeds/ipeds.duckdb`
- Tables: `ic` (institutional characteristics, tuition), `sfa` (student financial aid, Pell), `ef` (fall enrollment by race), `f_f1a` (finance, state appropriations), `hd` (header, institution metadata)
- Years: 2003-2022 (~20 years)
- Sample: Public 4-year institutions (control=1, Carnegie class filtering)

**State fiscal data:** FRED API or Census Bureau state government finance data for Bartik shock construction.

**Workflow:**
1. Query IPEDS DuckDB for all public 4-year institutions
2. Merge institutional characteristics, finance, enrollment, financial aid tables
3. Construct Bartik instrument from pre-period budget shares × national shocks
4. Run 2SLS with institution and year FE
5. Heterogeneity: flagship vs. regional comprehensive vs. community college

## Robustness

- OLS baseline for comparison
- Reduced-form (Bartik → outcomes directly)
- Leave-one-state-out
- Pre-trend event study using Bartik shock intensity
- Alternative instrument: state unemployment rate × initial HE budget share
- Subsample: exclude states with tuition freezes/caps
