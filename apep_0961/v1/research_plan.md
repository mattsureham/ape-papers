# Research Plan: The Fiscal Dividend of Tobacco Advertising Bans

## Research Question

Do tobacco billboard advertising bans reduce per-capita healthcare expenditure? Using the staggered adoption of billboard bans across Swiss cantons (1997–2017), I estimate the causal fiscal effect of advertising regulation on healthcare costs, exploiting non-smoking-related cost categories as built-in placebos.

## Identification Strategy

**Design:** Staggered difference-in-differences using Callaway & Sant'Anna (2021).

**Treatment:** Cantonal adoption of tobacco billboard advertising bans (16 cantons treated, 10 never-treated controls). Treatment dates from Stoller (2026, arXiv:2601.08352) and cantonal legislation records.

**Unit of observation:** Canton × year (26 cantons × 28 years = 728 canton-years). Disaggregated analysis at canton × cost-category × year level (~7,280 observations).

**Control group:** 10 cantons that never adopted billboard bans serve as the never-treated group in the CS-DiD framework.

**Key identifying assumption:** Parallel trends in healthcare expenditure between adopting and non-adopting cantons, conditional on canton and year fixed effects. Tested via event-study plots over 10-year pre/post windows.

**Built-in placebo:** Non-smoking-related cost categories (physiotherapy, SPITEX home care, laboratory services) should show null effects if identification is valid. Smoking-related categories (hospital inpatient, pharmacy, physician visits) are the treatment-affected channels.

## Expected Effects and Mechanisms

**Primary channel:** Billboard bans reduce smoking initiation and prevalence → lower incidence of smoking-related diseases (lung cancer, COPD, cardiovascular disease) → reduced healthcare utilization and costs.

**Expected direction:** Negative effect on total per-capita costs, concentrated in smoking-related categories. Effect likely grows over time as health stock improvements accumulate.

**Magnitude prior:** If bans reduce smoking prevalence by 2-5 percentage points (Stoller 2026), and smoking-attributable healthcare costs are ~6-8% of total Swiss healthcare expenditure (BAG estimates), the expected SDE is in the small-to-moderate negative range.

## Primary Specification

```
Y_ct = α_c + γ_t + β × BillboardBan_ct + ε_ct
```

Where Y_ct is per-capita healthcare expenditure in canton c, year t. Estimated via Callaway & Sant'Anna with never-treated as comparison group.

**Robustness:**
1. Wild cluster bootstrap (26 clusters)
2. Randomization inference (permute treatment across cantons)
3. Placebo cost categories (non-smoking-related should show null)
4. Leave-one-out (drop each treated canton)
5. Continuous treatment intensity (years since ban)

## Exposure Alignment

**Who is treated?** All residents of cantons that adopt tobacco billboard advertising bans. The treatment operates through reduced exposure to outdoor tobacco advertising, which affects smoking initiation and cessation decisions at the population level. The treatment intensity is uniform within canton (binary: ban or no ban) and does not vary by individual characteristics.

**Outcome alignment:** Per-capita healthcare costs are measured at the canton level for all insured persons (universal coverage under OKP). The treatment and outcome are aligned at the canton-year level — the same population exposed to reduced advertising is the population whose healthcare costs are measured.

**Temporal alignment:** Billboard bans take effect on a specific date within each canton. Healthcare costs are measured annually. Effects are expected to emerge gradually (health-stock mechanism: reduced smoking takes years to lower disease incidence), so the relevant exposure window extends from the ban year forward, with growing effects over 5-15 years.

## Data Sources

1. **FOPH OKP Dashboard** — Per-capita gross healthcare expenditure by canton, sex, and 10 cost categories (1997–2024). Administrative insurance data with universal coverage. ~26,649 rows.

2. **Treatment dates** — Cantonal billboard ban adoption years from Stoller (2026) Table 3 and cantonal legislation. 16 treated cantons with dates ranging 1997–2017.

3. **BFS population data** — Cantonal population for weighting (from BFS PXWeb API).

## Fetch Strategy

1. Download FOPH OKP healthcare cost data (ZIP file from BAG/FOPH website or opendata.swiss)
2. Code treatment dates from Stoller (2026) reference and verify against cantonal laws
3. Fetch BFS cantonal population data via PXWeb API
