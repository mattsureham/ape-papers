# Research Plan: Newsroom Cliff — Press Subsidies and Local Democracy in Norway

## Research Question

Does government subsidy of local newspapers causally increase voter turnout? Norway's produksjonstilskudd (production subsidy) awards substantial funding exclusively to newspapers that are *not* the market leader in their municipality. This sharp eligibility rule creates a regression discontinuity that identifies whether subsidized newspaper survival translates into democratic participation.

## Institutional Setting

Norway's press production subsidy has operated since 1969, growing to 313 million NOK (~€35M) by 2017. Eligibility requires:
1. The newspaper must **not** be the largest in its local market (must be a "number 2" paper)
2. At least 50% of circulation must be subscribed
3. Subsidy capped at 40% of operating costs

The subsidy is substantial — tens of millions of NOK annually for qualifying papers — and explicitly aims to preserve media pluralism. The Norwegian Media Authority (Medietilsynet) administers the program; circulation is measured by an independent auditor (Mediebedriftenes Landsforening), not self-reported.

## Identification Strategy

**Primary: Fuzzy RDD at the market-rank threshold.**
- Running variable: Market share gap = (largest paper's circulation − own circulation) / largest paper's circulation
- Newspapers with positive gap (below market leader) are subsidy-eligible
- Newspapers at or above market leader position are ineligible
- First stage: Crossing the threshold predicts subsidy receipt and amount
- Bandwidth: MSE-optimal CCT (Calonico, Cattaneo, Titiunik 2014)

**Key assumptions:**
1. No precise manipulation: circulation measured by independent audit, not self-reported
2. No other policy discontinuity at the market-rank threshold
3. McCrary density test for bunching at the cutoff

**Secondary: Municipality-level DiD.**
- Cross-municipality variation in subsidized newspaper presence over time
- Municipalities that gained/lost a subsidized "number 2" paper vs. always-monopoly markets
- Callaway-Sant'Anna for staggered treatment timing

## Expected Effects and Mechanisms

Two competing hypotheses:
- **H1 (Democracy dividend):** Subsidized papers increase local political information, enabling voters to monitor local politicians, increasing turnout. Mechanism: information → accountability → participation.
- **H2 (Null — captured press):** Subsidies keep papers alive but don't change voter behavior — either because readers substitute to online sources, or because subsidized papers produce low-quality journalism. Mechanism: subsidy → survival but no informational gain.

Expected magnitude: MDE ~1.5-2 pp turnout with ~400 RD observations (baseline turnout 65-85%, within-municipality SD ~2-3 pp).

## Primary Specification

Fuzzy RD: Y_i = α + τ · D_i + f(X_i) + ε_i

Where:
- Y_i = municipality-level voter turnout (%)
- D_i = subsidy receipt (instrumented by eligibility)
- X_i = market share gap (running variable)
- f(·) = local polynomial (linear, MSE-optimal bandwidth)

## Data Sources

1. **SSB table 08243**: Municipality-level Storting election turnout (%), 1945-2021 — confirmed live API
2. **SSB local election tables**: Municipal council election turnout — need to identify exact table
3. **Medianorway (medienorge.uib.no)**: Per-newspaper annual circulation data (query ID 193)
4. **Medietilsynet annual reports**: Subsidy recipient lists with amounts (public PDFs, 1993-2023)

## Data Fetch Strategy

1. SSB turnout: Direct API call (JSON-stat2 format) — confirmed working
2. Medianorway circulation: Web scrape or direct download from medienorge.uib.no
3. If newspaper-level circulation data not programmatically accessible: construct municipality-level treatment from Medietilsynet subsidy lists and pivot to DiD
4. SSB also publishes media statistics — check for supplementary data

## Risks and Mitigation

| Risk | Mitigation |
|------|-----------|
| Medianorway data not machine-readable | Pivot to DiD using subsidy lists |
| Small RD sample (200-400 obs) | Supplement with pooled local + national elections |
| Norwegian municipality mergers | Use SSB concordance tables for consistent units |
| Subsidy endogenous to newspaper quality | McCrary + covariate balance at threshold |
