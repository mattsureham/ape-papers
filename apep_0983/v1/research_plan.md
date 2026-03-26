# Research Plan: Tax Wedges and Factor Sorting

## Research Question

Do differential corporate vs. personal municipal tax rates (Steuerfuss) in Swiss municipalities cause factor-specific sorting — firms moving toward lower corporate rates and residents toward lower personal rates?

## Identification Strategy

**Triple-Difference (DDD):** Within-municipality, within-year, across-factor-type variation.

Treatment variable: Corporate-personal Steuerfuss wedge change (ΔWedge_{mt}).

- **First difference:** Before vs. after wedge change
- **Second difference:** Treated vs. control municipalities (no wedge change)
- **Third difference:** Firms (respond to corporate rate) vs. residents (respond to personal rate)

When a municipality cuts its corporate rate relative to its personal rate, firms should enter while residents may leave (or vice versa). Municipality and year FEs absorb level confounders. The DDD isolates the wedge effect from common municipal shocks.

**Built-in placebo:** If the wedge matters, *cutting both rates equally* should attract both firms and residents, but should NOT cause differential sorting.

## Expected Effects and Mechanisms

1. **Direct effect:** A wider corporate-personal wedge (lower relative corporate rate) increases firm count/employment and decreases population
2. **Mechanism:** Tax-base competition — municipalities use targeted rates to attract mobile factors
3. **Heterogeneity:** Effects should be stronger for (a) small/mobile firms, (b) border municipalities, (c) municipalities competing with low-tax neighbors

## Primary Specification

```
Y_{mt} = α + β₁ΔWedge_{mt} + β₂ΔWedge_{mt} × Factor_type + μ_m + τ_t + ε_{mt}
```

Where:
- Y_{mt}: firm count (STATENT) or population (BFS) in municipality m, year t
- ΔWedge_{mt}: corporate minus personal Steuerfuss change
- Factor_type: indicator for firms (=1) vs. residents (=0)
- μ_m: municipality FE
- τ_t: year FE
- Clustering: municipality level

## Data Sources

1. **Steuerfuss rates:** Canton of Zurich open data (natural persons + legal persons, 1990-present) + Canton of Basel-Landschaft (similar structure)
2. **Firm data:** BFS STATENT via PXWeb API (establishment counts by municipality, 2011-2023)
3. **Population:** BFS Bevölkerungsstatistik via PXWeb API (municipality-year population, 2010-2023)
4. **Tax revenue:** Zurich Steuerkraft per capita (1990-present) for mechanism tests

## Design Parameters

- ~246 municipalities (Zurich + BL) with wedge variation
- ~3,200 municipality-year observations
- ~5-10 pre-periods depending on canton
- Continuous treatment (wedge magnitude) with staggered timing
