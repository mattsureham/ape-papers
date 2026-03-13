# Research Plan: Breaking Job Lock — Medicaid Expansion and Worker Mobility

## Research Question
Does Medicaid expansion unlock job mobility? We test whether delinking health insurance from employment—via ACA Medicaid expansion—increased job-to-job transitions, separations, and new hiring, particularly among low-education workers in industries with high employer-sponsored insurance (ESI) rates.

## Identification Strategy
**Triple-difference (DDD):**
1. Pre/post Medicaid expansion
2. Expansion vs. non-expansion states
3. High-ESI industries (Manufacturing, Finance, Information) vs. low-ESI industries (Accommodation/Food, Retail, Agriculture)

The identifying assumption: Medicaid expansion does not differentially affect high- vs. low-ESI industries through channels other than health insurance access.

**Quadruple-difference:** Low-education (no bachelor's) vs. high-education workers. Expansion primarily affected workers without degrees—they serve as the treated subgroup; degree-holders provide a within-industry-state placebo.

**CS-DiD:** Callaway-Sant'Anna (2021) with staggered treatment timing across 7 treatment cohorts (2014, 2015, 2016, 2019, 2020, 2021, 2022-23). 10 never-treated states as controls.

## Expected Effects and Mechanisms
- **Primary:** Increased job-to-job transitions (HirN) and separations (Sep) in high-ESI industries in expansion states, concentrated among low-education workers.
- **Mechanism:** Workers no longer tethered to employers for insurance → higher voluntary turnover.
- **Firm dynamics:** If mobility increases, firms may respond with higher wages (EarnS) or job creation (FrmJbGn) to retain workers.
- **Heterogeneity:** Stronger effects in states with thinner pre-expansion Medicaid (larger coverage gain).

## Primary Specification
Y_{s,i,t} = α + β₁(Expand_s × Post_t × HighESI_i) + γ(Expand_s × Post_t) + δ(HighESI_i × Post_t) + state×industry FE + industry×time FE + state×time FE + ε_{s,i,t}

Where Y is turnover rate (TurnOvrS), new hires from other employers (HirN/Emp), or separation rate (Sep/Emp).

## Data Source and Fetch Strategy
**QWI on Azure Blob Storage** (Parquet files):
- `derived/qwi/se/ns/*.parquet` — sex × education × NAICS sector (~123M rows)
- `derived/qwi/sa/ns/*.parquet` — sex × age × NAICS sector (~185M rows)

Query via DuckDB using `scripts/lib/azure_data.R`.

**Treatment timing:** KFF/MACPAC Medicaid expansion dates.

**Sample:** State × quarter × NAICS sector × education level, 2010Q1–2019Q4 (pre-COVID). 50 states + DC, 20 NAICS sectors, 4 education levels.
