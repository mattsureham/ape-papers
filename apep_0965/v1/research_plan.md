# Research Plan: Tit-for-Tat in the Heartland

## Research Question
Did the EU's June 2018 retaliatory tariffs on politically targeted US products (bourbon, motorcycles, steel, boats) cause measurable local employment losses in exposed US counties? Did the political targeting — choosing products associated with specific congressional districts — translate into concentrated economic pain?

## Identification Strategy
**Continuous difference-in-differences.** County × quarter panel (2015Q1–2022Q4), where treatment intensity = pre-tariff (2017Q4) county employment share in EU-targeted 3-digit NAICS industries (312 Beverage/Tobacco, 331 Primary Metals, 336 Transportation Equipment).

**Why this works:**
- EU selected products for *political* salience (bourbon → Kentucky/McConnell, motorcycles → Wisconsin/Ryan, steel → Rust Belt), not based on US local labor market conditions → quasi-exogenous variation orthogonal to county employment trends
- Sharp timing: EU Regulation 2018/886 effective June 22, 2018 (2018Q3)
- 12 clean pre-treatment quarters for parallel trends validation
- Large sample: 2,492 manufacturing counties, 1,327 with targeted-industry employment

**Primary specification:**
$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot \text{Exposure}_c \times \text{Post}_t + X_{ct}\delta + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: log employment, hires, separations, earnings in county $c$, quarter $t$
- $\text{Exposure}_c$: pre-tariff share of county employment in targeted NAICS (312, 331, 336)
- $\text{Post}_t$: indicator for $t \geq$ 2018Q3
- County FE $\alpha_c$, quarter FE $\gamma_t$
- Clustering: state-level (51 clusters)

**Event study version** to validate parallel trends:
$$Y_{ct} = \alpha_c + \gamma_t + \sum_{k \neq -1} \beta_k \cdot \text{Exposure}_c \times \mathbb{1}(t = k) + \varepsilon_{ct}$$

## Expected Effects and Mechanisms
- **Direct employment channel:** Tariff-exposed counties should see relative employment declines in targeted industries as EU demand falls
- **Spillover channel:** Input-output linkages may amplify effects to non-targeted sectors
- **Magnitude prior:** 25% tariff on ~$2.8B of exports is modest relative to total US manufacturing — expect small-to-moderate effects (SDE 0.005–0.10)
- **Heterogeneity:** Effects should concentrate in counties with concentrated exposure (e.g., bourbon-producing counties in Kentucky)

## Data Source and Fetch Strategy
- **Primary:** Azure QWI parquet files at `derived/qwi/sa/n3/*.parquet` — county × quarter × NAICS 3-digit × sex × age
- **Variables:** Emp (employment), HirA (all hires), Sep (separations), EarnS (avg monthly earnings)
- **Sample:** All US counties, 2015Q1–2022Q4 (32 quarters), collapsed across demographics to county × quarter × industry
- **Treatment construction:** County exposure share from 2017Q4 employment in NAICS 312, 331, 336 relative to total county manufacturing employment

## Robustness
1. Event study for pre-trend validation
2. HonestDiD sensitivity bounds
3. Leave-one-industry-out (drop 336 Transportation, which is very large)
4. Placebo treatment timing (2017Q1)
5. Alternative exposure measures (binary high/low instead of continuous)
6. Wild cluster bootstrap (since state-level clustering with 51 clusters)
