# Research Plan: Planning Inspector Leniency and Housing Supply in England

## Research Question

Does winning a planning appeal cause additional housing to be built? England's Planning Inspectorate (PINS) assigns professional inspectors to appeal cases through workload-based allocation, creating quasi-random variation in inspector strictness. Using leave-one-out inspector leniency scores as instruments, this paper estimates the causal effect of appeal outcomes on subsequent housing construction.

## Identification Strategy

**Inspector leniency IV** following Dobbie, Goldin, and Yang (2018).

1. **Leniency construction:** For each case *i* decided by inspector *j*, compute inspector *j*'s leave-one-out allow rate among all other cases in the same (case type × year) cell.
2. **Quasi-randomness:** Conditional on case type × LPA × year fixed effects, inspector assignment is as-good-as-random (workload-based allocation from national pool).
3. **First stage:** Case outcome (allowed=1) regressed on leniency score with case type × LPA × year FEs.
4. **Second stage:** LPA-quarter housing outcomes (completions, prices) on instrumented appeal success rate.

**Exclusion restriction:** Inspector assignment affects housing outcomes only through the appeal decision, not through direct channels.

## Expected Effects

- Marginal approvals (complier cases) should increase housing completions at the LPA level
- Effect may be attenuated if approved developments face subsequent barriers (infrastructure, financing)
- Price effects ambiguous: new supply pushes prices down, but approved sites may be in high-demand areas

## Primary Specification

LPA-quarter panel: housing completions regressed on share of appeals allowed, instrumented by average inspector leniency assigned to that LPA-quarter.

## Data Sources

1. **PINS Appeal Case Portal** (`acp.planninginspectorate.gov.uk`): Case-level data including LPA, case type, dates, outcomes. Inspector names from decision letter PDFs.
2. **MHCLG Housing Statistics** (PS2 tables): LPA-level quarterly housing completions and starts.
3. **MHCLG Planning Application Statistics** (P120/P130): LPA-level appeal volumes and outcomes (aggregate backup).
4. **HM Land Registry Price Paid Data**: Transaction-level house prices by postcode.

## Data Collection Strategy

**Phase 1 — PINS scraping (primary):** Scrape ~3,000-5,000 cases from case IDs 3,240,000-3,340,000 (covering ~2019-2023). Extract HTML fields + download decision PDFs for inspector names. Target: sufficient cases per inspector for stable leniency scores (~300 inspectors × ~10+ cases each).

**Phase 2 — Outcome data:** Download MHCLG PS2 tables (LPA-level completions) and Land Registry PPD bulk file. Merge at LPA-quarter level.

**Fallback:** If PDF scraping is too slow for sufficient inspector coverage, use MHCLG aggregate appeal statistics (Table P120) which report LPA-level appeal allow rates, and construct a reduced-form design using LPA-level variation in appeal generosity.
