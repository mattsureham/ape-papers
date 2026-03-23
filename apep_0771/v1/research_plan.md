# Research Plan: When the Campus Goes Dark

## Research Question

Did mass for-profit college closures (2013–2018), driven by federal regulatory tightening, disrupt local labor markets? This paper estimates the causal effect of closure intensity on county-level employment, hiring, and separations using the staggered nature of chain-wide shutdowns.

## Motivation

Between 2013 and 2018, over 1,261 for-profit colleges closed across 383 US counties following federal enforcement actions (Gainful Employment rule 2014, Cohort Default Rate sanctions, fraud investigations). Corinthian Colleges shuttered 28 campuses in 2015; ITT Tech closed 130+ in 2016; Education Corporation of America dissolved 70+ in 2018. The literature on for-profit closures focuses exclusively on student outcomes (Cellini & Turner 2019, Armona et al. 2022). No study has examined the local labor market consequences—whether these closures, concentrated in specific counties, disrupted employment beyond the education sector.

## Identification Strategy

**Staggered DiD with continuous treatment intensity.**

- **Treatment:** First year a county experiences a for-profit college closure (from IPEDS `deathyr`), with intensity measured as closure count or pre-closure enrollment share.
- **Control group:** 327 counties that had for-profit colleges but experienced zero closures.
- **Estimator:** Callaway & Sant'Anna (2021) for heterogeneity-robust ATT, using not-yet-treated and never-treated counties as controls.
- **Chain IV:** Instrument with (has ITT Tech/Corinthian/ECA campus) × (post-chain-closure year). Chain-wide decisions are plausibly exogenous to county-specific labor market conditions.

## Why Credible

Chain-wide closures (ITT Tech: all 130+ campuses simultaneously; Corinthian: all 28) are driven by federal-level regulatory actions, not county economic conditions. The same chain closed in growing and declining local economies. Cross-county variation in exposure is determined by pre-existing campus locations—a function of historical market decisions made years or decades earlier.

## Expected Effects

- **Education sector (NAICS 61):** Negative employment effect (direct job losses from closures).
- **Healthcare/Social Services (NAICS 62):** Potentially negative (many for-profits trained healthcare workers; pipeline disruption).
- **Accommodation/Food (NAICS 72):** Potentially negative (student and employee spending multiplier).
- **Overall:** Direction genuinely uncertain—could be offset by reallocation to community colleges and public institutions.

## Primary Specification

$$Y_{ct} = \alpha_c + \alpha_t + \beta \cdot \text{Closures}_{ct} + X'_{ct}\gamma + \epsilon_{ct}$$

Where $Y_{ct}$ is employment/hires/separations in county $c$, quarter $t$; $\text{Closures}_{ct}$ is closure intensity; $\alpha_c, \alpha_t$ are county and quarter FEs. CS-DiD for event study. Clustered at county level.

## Data Sources

1. **IPEDS** (Azure: `raw/ipeds/ipeds.duckdb`): Institution-level data with `deathyr` (closure year), `sector` (for-profit indicator), county FIPS, enrollment counts.
2. **QWI** (Azure: `derived/qwi/sa/ns/*.parquet`): County × quarter × NAICS sector employment flows (Emp, HirA, Sep, EarnS), 2001–present.

## Outcome Variables

| Variable | Source | Measure |
|----------|--------|---------|
| Employment (Emp) | QWI | Beginning-of-quarter employment count |
| All Hires (HirA) | QWI | All hires in quarter |
| Separations (Sep) | QWI | All separations in quarter |
| Average Earnings (EarnS) | QWI | Average monthly earnings |

Sectors: Education (61), Health Care (62), Accommodation/Food (72), Total Private.

## Robustness

1. Event study with CS-DiD (dynamic ATT)
2. Chain IV (ITT/Corinthian/ECA campus presence × post)
3. Placebo sector: Government (excluded from private QWI) or Mining (NAICS 21)
4. Intensity variants: closure count, enrollment-weighted closures
5. Donut hole: exclude counties with very small for-profits
6. HonestDiD sensitivity analysis for parallel trends violations

## Design Parameters

- Treated counties: 383 (83 high-intensity with ≥3 closures)
- Control counties: 327
- Pre-periods: 12+ quarters (2010Q1–2012Q4)
- Treatment timing: 2013–2018 (staggered)
- Observation-level: county × quarter × NAICS sector
