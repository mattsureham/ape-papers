# Research Plan: The Shutdown Multiplier — Government Payroll Interruptions and Local Private-Sector Employment

## Research Question

Do US government shutdowns reduce private-sector employment in counties with high federal employment shares? What is the local consumption multiplier of government payroll?

## Identification Strategy

**Continuous-treatment DiD** exploiting cross-county variation in pre-shutdown federal employment share.

The identifying assumption: absent the shutdown, private-sector employment trends would have been parallel across counties with different federal employment shares (conditional on county and time fixed effects).

**Two events provide dose-response:**
1. **October 2013 shutdown** — 16-day full shutdown (Oct 1–16), ~800,000 furloughed
2. **December 2018–January 2019 shutdown** — 35-day partial shutdown (Dec 22–Jan 25), ~800,000 furloughed

The stacking of a shorter and longer event tests proportionality: if the multiplier is real, the 35-day shutdown should produce roughly 2× the effect of the 16-day shutdown.

**Key specification:**
```
Y_{c,q} = α_c + γ_q + β × (FedShare_c × Shutdown_q) + X'_{c,q}δ + ε_{c,q}
```
Where:
- Y = private-sector employment, earnings, hiring, separations (QWI)
- FedShare_c = county federal employment share from 2012 QCEW (pre-determined)
- Shutdown_q = indicator for shutdown quarter
- α_c = county FE, γ_q = quarter FE
- Clustering at state level (51 clusters)

## Expected Effects and Mechanisms

**Prior:** Negative multiplier — shutdown reduces federal payroll → less consumer spending in local economy → private sector contracts.

**Mechanism:** Consumption channel (payroll interruption), not production channel (procurement). This distinction matters for fiscal multiplier literature.

**Expected magnitude:** Small but detectable. Chodorow-Reich (2019) estimates state-level multiplier ~1.5–2.0. Our setup is cleaner but effects may be smaller since shutdowns are temporary and workers eventually receive back pay.

**Key heterogeneity:**
- Service sectors (accommodation/food, retail) vs. goods sectors (manufacturing)
- High vs. low federal share counties
- Military base counties (concentrated exposure)

## Primary Specification

1. **Main DiD:** Private-sector employment change regressed on FedShare × Shutdown interaction
2. **Event study:** Dynamic specification with quarterly leads/lags around each shutdown
3. **Stacked events:** Pool both shutdowns with event-time FE for efficiency
4. **Sector decomposition:** Separate regressions for NAICS 72 (accommodation/food), 44-45 (retail), 31-33 (manufacturing placebo), 62 (healthcare placebo)

## Robustness

1. **Pre-trend test:** Event-study coefficients for 8+ pre-shutdown quarters should be zero
2. **Placebo sectors:** Manufacturing and healthcare should show no effect (not consumption-sensitive to local payroll)
3. **Dose-response:** 35-day shutdown effect ≈ 2× the 16-day effect
4. **Alternative exposure:** Using 2010 QCEW instead of 2012 to rule out endogenous sorting
5. **Wild cluster bootstrap:** Supplement clustered SEs given 51 state clusters

## Data Sources

1. **QWI (Azure):** `az://derived/qwi/sa/ns/*.parquet` — county × quarter × NAICS sector, 2001–2025. Variables: Emp, EarnS, HirA, Sep, HirN, FrmJbGn, FrmJbLs
2. **QCEW (BLS):** Bulk download for federal employment by county (own_code = 5 = Federal Government). 2012 baseline for exposure variable.
3. **Census population:** County population for per-capita normalization

## Timeline

- Data fetch: QWI from Azure, QCEW from BLS bulk files
- Analysis: DiD estimation, event studies, sector decomposition
- Paper: AER Insights format, ~12 pages, 5 tables
