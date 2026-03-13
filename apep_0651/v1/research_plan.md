# Research Plan: The Spotlight Effect on Enforcement — Media Salience and Mine Safety Regulation

## Research Question

Does media coverage of mine fatalities cause subsequent increases in MSHA enforcement intensity? When a mine fatality is crowded out of the news cycle by competing events, does enforcement weaken — revealing that regulatory intensity responds to media attention rather than (or in addition to) underlying severity?

## Identification Strategy

**Eisensee-Strömberg competing-news IV design.**

- **Endogenous variable:** Media coverage of a specific mine fatality (measured via GDELT article counts mentioning the mine/location within 7 days of the fatality)
- **Instrument:** Total GDELT news volume in the week of the fatality (exogenous news competition). When a major hurricane, political crisis, or mass shooting dominates the news cycle, mine fatalities receive less coverage — regardless of their severity.
- **Exclusion restriction:** National news competition in the week of a specific mine fatality affects MSHA enforcement at that mine only through its effect on media coverage of the fatality. Conditional on mine FEs, year-quarter FEs, incident severity (deaths, injuries), and mine characteristics.

**Reduced form:** Regress enforcement outcomes on the news-competition instrument directly (intent-to-treat effect of competing news on enforcement).

**Two-stage least squares:**
- First stage: news competition → media coverage of the mine fatality
- Second stage: media coverage → enforcement intensity (inspections, violations, penalties)

## Expected Effects and Mechanisms

1. **Spotlight effect:** Fatalities receiving more media coverage trigger stronger enforcement response (more inspections, more violations cited, higher penalties) at the affected mine in the 6-12 months following the event.
2. **Spillover:** Media-salient fatalities also increase enforcement at peer mines in the same state/district.
3. **Asymmetry:** The spotlight effect should be concentrated on discretionary enforcement margins (inspector-initiated inspections, S&S violations) rather than mandatory inspections.
4. **Decay:** The enforcement boost from media coverage should decay over 3-6 months.

## Primary Specification

```
Y_{m,t+k} = α + β·Coverage_{m,t} + γ·X_{m,t} + δ_m + θ_t + ε_{m,t}

where Coverage instrumented by log(TotalGDELT_t)
```

- Y: inspections, violations, penalties at mine m in quarter t+k (k = 1,...,4 quarters post-fatality)
- Coverage: GDELT articles mentioning the mine/location within 7 days
- X: fatality severity (deaths, injuries), mine characteristics (type, size, commodity)
- δ_m: mine fixed effects
- θ_t: year-quarter fixed effects

## Data Sources

1. **MSHA Accidents** (https://arlweb.msha.gov/OpenGovernmentData/): 271,720 records, fatality indicator, mine ID, date
2. **MSHA Inspections** (same): 1,138,759 records, mine ID, inspection date, type
3. **MSHA Violations** (same): 3,057,780 records, mine ID, violation date, proposed penalty, S&S flag
4. **GDELT V2 GKG** (via BigQuery or direct download): Daily news articles with themes and locations, 2015-2025
5. **GDELT V1 Events** (yearly files): Event counts by date, 2000-2025

## Fetch Strategy

1. Download MSHA bulk ZIP files (Accidents, Inspections, Violations) — ~200MB total
2. Query GDELT via BigQuery for weekly article counts + mine-specific coverage
3. Construct mine-level panel: fatality events × post-fatality enforcement

## Key Risks

- **First-stage strength:** Need F-stat > 10 for news competition → mine-specific coverage. If mine fatalities are too small to appear in GDELT at all, the first stage may be weak. Mitigation: focus on fatalities with ≥1 death (most newsworthy); use GDELT GKG themes for mining.
- **Exclusion restriction:** News competition could correlate with economic conditions (recessions → more economic news + less mining activity). Mitigation: control for mine-level and quarter-level economic conditions; check that news competition is uncorrelated with mine characteristics.
- **GDELT temporal coverage:** GDELT V2 starts 2015; V1 events from 2000. May need to restrict sample to 2015-2025 for full coverage measurement. Ensures ~10 years of data.
