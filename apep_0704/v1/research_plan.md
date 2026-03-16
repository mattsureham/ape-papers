# Research Plan: apep_0704

## Do Workers Vote with Their Feet? Labor Market Responses to Random OSHA Safety Inspections

**Idea:** idea_0610

## Research Question

Do OSHA safety inspections cause workers to reallocate away from inspected industries? All existing OSHA literature studies firm-side outcomes (fatalities, wages, survival). Nobody has tested the supply side: whether revealed violations cause workers to exit or demand higher compensation — the fundamental prediction of compensating differentials theory.

## Identification Strategy

**Design:** Stacked event study exploiting quasi-random timing of OSHA programmed inspections.

OSHA's Site-Specific Targeting (SST) program randomly selects establishments for inspection from those with above-median injury rates. Construction programmed inspections use computer-generated random numbers. Within the eligible pool, **timing is as-good-as-random**.

**Unit:** State × 2-digit NAICS × quarter panel (2005–2023).

**Treatment event:** A state-industry-quarter with a sharp increase in programmed inspection count (above the 90th percentile of that state-industry's historical distribution). This captures "inspection waves" that reveal safety information to workers.

**Control:** Not-yet-treated and never-treated state-industry-quarters (Callaway-Sant'Anna estimator).

**Key outcomes (QWI):**
- Separations (Sep) — workers leaving
- New hires (HirN) — firms attracting replacement workers
- New-hire earnings (EarnHirAS) — wage premium required to attract workers to revealed-unsafe industries
- Firm job creation/destruction (FrmJbGn/FrmJbLs) — firm-side response

## Expected Effects and Mechanisms

**Primary hypothesis:** After inspection waves revealing violations, separations increase and new-hire earnings rise (compensating differential adjustment).

**Mechanism 1 — Information channel:** Workers learn about hazards from public inspection records → exit. Predicts: effect larger for SERIOUS violations (directly health-threatening) than OTHER-THAN-SERIOUS.

**Mechanism 2 — Enforcement channel (placebo):** Complaint-driven inspections (type B/C) are endogenous — they respond to existing worker awareness. If the information channel matters, programmed inspections (random) should produce LARGER worker reallocation than complaint inspections (workers already knew).

## Primary Specification

```
Y_{sit} = α_i + γ_t + Σ_k β_k × D_{sit}^k + X'_{sit}δ + ε_{sit}
```

Where:
- i = state × industry
- t = year-quarter
- D^k = event-time indicators (k = -8 to +8 quarters)
- X = state-level controls (unemployment rate, GDP)

CS-DiD with never-treated comparisons. Cluster SEs at state level (~50 clusters).

## Data Sources

1. **OSHA Enforcement Data** (DOL bulk download)
   - Inspection records: establishment, NAICS, state, date, type (H=programmed, B=complaint)
   - Violation records: type (serious/willful/repeat/other), penalty
   - ~170,000+ inspections over 2005–2023

2. **QWI** (Azure: `derived/qwi/sa/ns/*.parquet`)
   - State × 2-digit NAICS × quarter
   - Variables: Emp, HirA, HirN, Sep, EarnS, EarnHirAS, FrmJbGn, FrmJbLs, TurnOvrS

3. **BLS QCEW** (supplementary validation)
   - Establishment counts and wages for consistency checks

## Robustness

- Leave-one-state-out (sensitivity to large states like TX, CA)
- Alternative event thresholds (75th, 95th percentile)
- Pre-trend event study coefficients (β_{-8} through β_{-1} ≈ 0)
- Wild cluster bootstrap for p-values (50 state clusters)
- Dose-response: serious violations vs. other-than-serious
