# Research Plan: The Racial Anatomy of the Trade War

## Research Question

Did the 2018–2019 Section 301 tariffs on Chinese imports produce racially heterogeneous employment effects in U.S. manufacturing? Specifically, did Asian workers — who are 4:1 overrepresented in tariff-targeted electronics manufacturing — experience disproportionately larger employment losses relative to white and Black workers in the same industries and counties?

## Identification Strategy

**Primary design: Shift-share difference-in-differences with racial decomposition.**

County-level tariff exposure is constructed as:
  Exposure_c = Σ_s (L_{cs,2017} / L_{c,2017}) × Tariff_s

where L_{cs,2017} is county c employment in 3-digit NAICS s in 2017Q2 (pre-treatment), and Tariff_s is the trade-weighted average Section 301 tariff rate for industry s based on HS-NAICS concordance.

The key innovation is estimating separate effects by race (White, Black, Asian, Hispanic) using the QWI race × industry × county × quarter panel. The hypothesis is that Asian workers face disproportionate losses in tariff-exposed industries, beyond what industry composition alone would predict.

**Identifying assumptions:**
1. Parallel trends in employment across race groups within tariff-exposed vs unexposed counties
2. Pre-treatment industry composition is exogenous to tariff assignment
3. No race-specific shocks coinciding with tariff timing

**Key threats:**
- COVID contamination (restrict sample to 2015Q1–2019Q4 to avoid)
- Thin cells in QWI (suppress cells with < 5 workers)
- Correlation between tariff exposure and pre-existing manufacturing decline

## Expected Effects and Mechanisms

1. **Industry concentration channel:** Asian workers are concentrated in NAICS 334 (electronics, 20.2% Asian) which faces heavy Section 301 tariffs. Mechanical exposure is higher.
2. **Beyond-industry channel:** Conditional on industry, Asian workers may face additional frictions if employers reduce hiring from a group perceived as connected to the tariff target country (statistical or taste-based discrimination).
3. **Decomposition:** Total racial gap = within-industry composition effect + conditional-on-industry differential treatment effect.

Expected: moderate negative effects on manufacturing employment in exposed counties, with larger effects for Asian workers. The decomposition tests whether the gap is fully explained by industry sorting or reflects an additional identity-salience margin.

## Primary Specification

$$\ln(Emp_{csrt}) = \alpha + \beta_r \cdot Exposure_c \times Post_t + \gamma_{cr} + \delta_{st} + \lambda_{rt} + \varepsilon_{csrt}$$

Where:
- c = county, s = 3-digit NAICS, r = race, t = quarter
- β_r = race-specific treatment effect (the key parameter)
- γ_{cr} = county × race FE
- δ_{st} = industry × quarter FE (absorbs national industry trends)
- λ_{rt} = race × quarter FE (absorbs national race trends)

Cluster SEs at the commuting zone level (following Autor, Dorn, Hanson).

## Data Sources

1. **QWI (Azure):** `az://derived/qwi/rh/n3/*.parquet` — 460M rows, county × 3-digit NAICS × race × quarter. Variables: Emp (beginning-of-quarter employment), EmpS (stable employment), EarnS (average monthly earnings), HirA (all hires), Sep (separations).

2. **Tariff rates:** UN Comtrade HS6 trade values (2017) for weighting + Section 301 list-to-HS mapping from USTR Federal Register notices. Construct industry-level tariff rates via HS-NAICS concordance.

3. **Census population:** County-level controls (population, education, demographics) from ACS 5-year 2017.

## Fetch Strategy

1. Read QWI Parquet files from Azure via Arrow (no download needed)
2. Construct tariff exposure measure from Comtrade + USTR tariff lists
3. Merge county controls from Census API
4. Pre-treatment sample: 2015Q1–2017Q4; Post: 2018Q3–2019Q4

## Key Robustness

1. Event study (quarterly leads/lags) to verify pre-trends
2. Leave-one-industry-out to check no single industry drives results
3. Placebo: non-manufacturing industries (services)
4. Alternative exposure: binary (above/below median)
5. Bartik-style rotational share instrument (Borusyak et al. 2022)
