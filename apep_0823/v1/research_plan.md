# Research Plan: The Alice Dividend — How Weakening Software Patent Protection Affected Industry Labor Markets

## Research Question

Did the Supreme Court's June 2014 Alice Corp v. CLS Bank decision — which tripled Section 101 patent rejection rates for software but left pharmaceutical patents untouched — affect employment in software-intensive industries relative to unaffected industries?

## Identification Strategy

**Difference-in-differences at the county × industry × quarter level.**

- **Treatment group:** NAICS codes intensive in Alice-affected patents: 334 (Computer & Electronic Product Manufacturing), 518 (Data Processing/Internet), 511 (Publishing incl. software)
- **Control group:** NAICS codes unaffected by Alice: 325 (Pharmaceuticals/Chemicals), 336 (Transportation Equipment), 339 (Misc. Manufacturing)
- **Pre-period:** 2012Q1–2014Q2 (10 quarters)
- **Post-period:** 2014Q3–2017Q4 (14 quarters)
- **Fixed effects:** County × quarter (absorbs all local shocks); Industry (absorbs permanent level differences)

**First stage (USPTO BigQuery):** Show that Section 101 rejection rates in software tech centers (TC 36xx) spiked after June 2014 while pharmaceutical tech centers (TC 17xx) were unaffected. This validates that Alice operated on the intended margin.

**Reduced form (QWI Azure):** Estimate employment, hiring, and earnings effects in treated vs control industries.

## Primary Specification

$$Y_{c,j,t} = \alpha + \beta \cdot \text{Software}_j \times \text{Post}_t + \gamma_{c,t} + \delta_j + \varepsilon_{c,j,t}$$

Where $Y$ is log employment (or hires, separations), $c$ = county, $j$ = NAICS 3-digit, $t$ = quarter. $\gamma_{c,t}$ = county × quarter FE. SEs clustered at state level.

## Expected Effects

Two competing hypotheses:
1. **Patent thicket view:** Alice cleared patent thickets, reducing litigation risk and entry barriers → positive employment effects in software ("Alice Dividend")
2. **Appropriability view:** Alice weakened IP protection, reducing incentives to invest → negative employment effects

## Data Sources

1. **USPTO BigQuery** (`patents-public-data.uspto_oce_office_actions.office_actions`): Office action data with rejection codes by technology center, 2013-2017. Validates first stage.
2. **QWI Azure** (`az://derived/qwi/sa/n3/*.parquet`): County × quarter × NAICS-3 employment, hires, earnings, separations. 2012-2017.
3. **Census Business Formation Statistics** (via FRED/Census API): New business applications by state, 2004-2020. Secondary outcome for entry effects.

## Robustness Checks

1. Event study with leads/lags (pre-trends test)
2. Placebo industries (match treated to similar-trend industries pre-Alice)
3. Intensity variation: counties with higher pre-Alice software patent shares should show larger effects
4. Exclude major metro areas (to check it's not driven by San Francisco/Seattle trends)

## Fetch Strategy

1. BigQuery: Query USPTO office action data for Section 101 rejection rates by tech center and quarter
2. Azure: Read QWI parquet files for selected NAICS codes
3. FRED: Supplementary state-level data if needed
