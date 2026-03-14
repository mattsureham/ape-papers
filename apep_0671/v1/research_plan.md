# Research Plan: Closing the Golden Door

## Research Question

Did the 1924 Johnson-Reed Immigration Act — which slashed Southern and Eastern European immigration by 87% — cause native-born American workers to upgrade occupationally? We track 10.7 million individual workers across the 1920 and 1930 censuses using IPUMS Multigenerational Longitudinal Panel (MLP) linked records, exploiting county-level variation in pre-existing immigrant settlement patterns as a continuous treatment intensity.

## Identification Strategy

**Method:** Continuous-treatment Difference-in-Differences (Bartik-style exposure design)

**Treatment intensity:** For each county $c$, we compute the share of the 1920 population born in "restricted-origin" countries (Italy, Russia, Poland, Austria-Hungary, Czechoslovakia, Lithuania, Yugoslavia, Romania, Greece, Albania, Bulgaria). Counties with higher shares experienced larger labor supply contractions after 1924.

**Estimating equation:**
$$\Delta Y_{ic} = \alpha + \beta \cdot \text{RestrictedShare}_c + X_{i,1920}'\gamma + \delta_s + \varepsilon_{ic}$$

where $\Delta Y_{ic}$ is the change in OCCSCORE (or an upgrading indicator) for individual $i$ in county $c$ between 1920 and 1930, and $\delta_s$ are state fixed effects.

**Key assumptions:**
1. Parallel trends: Counties with different pre-existing immigrant shares would have had similar occupational trajectories absent the quota. **Testable** via 1910-1920 placebo panel.
2. Exclusion: The 1924 quota affected native workers only through reduced immigration (no direct effect of county immigrant share on native trajectories, conditional on controls).
3. SUTVA: No spillovers across counties (we address this with state FE and robustness checks excluding border counties).

## Expected Effects and Mechanisms

**Competition hypothesis (Borjas):** Restricted immigration → reduced labor supply in competing occupations → native workers upgrade to fill vacancies or enjoy higher wages in low-skill jobs. Predicts: positive OCCSCORE change, concentrated among low-skilled natives in high-exposure counties.

**Complementarity hypothesis (Peri, Card):** Immigrant and native labor are complements in production. Restricted immigration → reduced productivity and demand for native labor in complementary tasks. Predicts: negative or null OCCSCORE change.

**Internal contrasts:**
- Low-skill vs. high-skill natives (competing vs. complementary)
- Farm vs. non-farm transitions
- Counties with Italian vs. Russian vs. Polish concentrations (different occupational niches)

## Primary Specification

1. **Main outcome:** OCCSCORE change (1920→1930), occupational upgrading indicator (>5 point increase)
2. **Treatment:** County restricted-origin foreign-born share (continuous, 0-25%)
3. **Controls:** 1920 age, race, literacy, initial occupation FE, state FE
4. **Clustering:** County level (3,000+ clusters)
5. **Placebo:** Identical specification on 1910-1920 panel

## Data Sources

All data pre-loaded in Azure:
- `derived/mlp_panel/linked_1920_1930.parquet` — 53.6M linked individuals (main panel)
- `derived/mlp_panel/linked_1910_1920.parquet` — 43.9M linked individuals (placebo)
- `raw/ipums_fullcount/us1920c` — 105M+ (for county-level exposure construction)

**No API calls needed.** All data access via DuckDB + Azure.

## Key Risks

1. **Link quality bias:** MLP links are not random — linked individuals tend to be male, literate, and native-born. We check for differential link rates by county exposure.
2. **Great Migration confound:** Black workers moving North 1920-1930 could confound results. We control for race and test separately by race.
3. **1920s economic boom:** The overall economic expansion may dominate occupation changes. State FE + initial occupation FE absorb much of this.
