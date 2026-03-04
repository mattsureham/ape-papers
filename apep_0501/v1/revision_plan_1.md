# Revision Plan 1 — Stage C Response to Reviews

## Consensus Issues Addressed

### 1. Dose-response re-estimated in stacked DiD framework
- All reviewers flagged that using TWFE for dose-response contradicts the paper's own argument against TWFE
- **Fix:** Re-estimate Post × log(SizeRatio) interaction within the stacked design

### 2. Exclude post-2020 mergers from stacked controls
- GPT advisor and referee flagged that controls include communes merging after 2020, contaminating late cohort windows
- **Fix:** Load full merger timeline and exclude any commune with merger year ≤ 2025 from stacked control pool

### 3. Canton-by-year fixed effects robustness
- Grok and internal review flagged cantonal merger incentive programs as confounders
- **Fix:** Add canton × year FE specification as robustness check

### 4. Alternative window widths (±3 years)
- Multiple reviewers requested narrower window to test sensitivity
- **Fix:** Re-estimate stacked DiD with ±3 year windows

### 5. Two-way clustering (commune × canton)
- Multiple reviewers flagged that commune clustering may understate uncertainty with cantonal merger programs
- **Fix:** Report canton-clustered SEs alongside commune-clustered

### 6. Within-window pre-trend diagnostic
- All reviewers noted pre-trends remain significant within ±5 window
- **Fix:** Add trend-adjusted specification with commune-specific linear trends within stacked windows

### 7. Paper text revisions
- Tighten abstract/conclusion language about conditional nature of estimates
- Add acknowledgment of HonestDiD fragility in abstract
- Add missing methodological references (Sun & Abraham 2021, de Chaisemartin & D'Haultfoeuille 2020)
- Clarify contribution paragraph

## Not Addressed (out of scope for this revision)
- Pre-harmonized BFS data reconstruction (data not available via API)
- Full Callaway-Sant'Anna (did package fails with this data structure)
- Synthetic control per-cohort (scope too large)
