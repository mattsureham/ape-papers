# Research Plan: apep_1162

## Research Question

Does cutting employer payroll taxes create jobs when wage rigidity blocks pass-through to workers? Belgium's 2016–2018 tax shift reduced employer social security contributions (SSC) from 32.4% to 25% — among the largest payroll tax cuts in OECD history — while automatic wage indexation and sectoral bargaining prevented any reduction in gross wages. This creates a clean test: when wages cannot adjust downward, does a 23% reduction in the employer SSC rate translate into employment growth, or do firms absorb the windfall as higher profits?

## Identification Strategy

**Primary design: Cross-country difference-in-differences.** Belgium (treated) vs. Netherlands, Germany, and Luxembourg (controls). Pre-treatment: 2013-Q1 to 2016-Q1 (13 quarters). Post-treatment: 2016-Q2 to 2019-Q4 (15 quarters, truncated before COVID).

**Secondary design: Triple-difference.** Country × sector labor intensity × time. Sectors with higher employer SSC burdens (labor-intensive: construction, hospitality, manufacturing) face proportionally larger cost reductions. This provides within-Belgium sector-level variation, addressing the concern of having only one treated country.

**Robustness: Synthetic control method.** Construct a synthetic Belgium from EU peers to assess whether the country-level result holds under alternative counterfactual construction.

## Expected Effects and Mechanisms

**Mechanism — the "rigidity windfall":** Belgium's automatic wage indexation and sectoral collective agreements prevent employers from passing SSC cuts through to lower gross wages. The full cost reduction accrues to employers. Theory predicts employment increases if labor demand is elastic at the margin. But if the binding constraint is product demand (not labor cost), employment may not respond — firms simply enjoy higher profit margins.

**Expected effects:**
- Non-wage labor costs: sharp decline in Belgium relative to controls (first stage, confirmed in smoke test)
- Wages: no change (blocked by indexation — this is the mechanism)
- Employment: ambiguous — depends on labor demand elasticity vs. demand constraints
- Sector heterogeneity: larger effects in labor-intensive sectors if demand elasticity matters

## Primary Specification

$$Y_{cst} = \alpha + \beta_1 \cdot \text{Belgium}_c \times \text{Post}_t + \beta_2 \cdot \text{Belgium}_c \times \text{Post}_t \times \text{LaborIntensity}_s + \gamma_{cs} + \delta_{st} + \epsilon_{cst}$$

Where $c$ = country, $s$ = NACE sector, $t$ = quarter. Country×sector and sector×time fixed effects absorb level differences and common sector trends.

## Data Source and Fetch Strategy

All data from Eurostat REST API via the `eurostat` R package (no API key needed):

1. **Employment:** `namq_10_a10_e` — Quarterly employment by NACE A*10 sectors, seasonally adjusted, for BE, NL, DE, LU (+ EU peers for SCM)
2. **Labor cost index:** `lc_lci_r2_q` — Quarterly LCI decomposed into wages (D11) and non-wage costs (D12+D4-D5), by NACE B-S
3. **Compensation breakdown:** `namq_10_a10` — National accounts: compensation of employees, wages and salaries, employers' social contributions by sector
4. **Sector labor shares:** `nama_10_a10` — Annual GVA and compensation by sector (for constructing labor intensity measure)

**Fetch order:** All four datasets in parallel. Validate that Belgium shows flat non-wage costs while controls rise (first-stage confirmation). If any dataset is unavailable, check alternative Eurostat table codes.
