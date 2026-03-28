# Revision Plan: apep_0749 v2

## Joint Diagnosis (Claude + Codex, independent then converged)

### Critical Problems
1. Game-day DDD broken: state-quarter + coarse calendar proxy + wrong rate normalization
2. Treatment sample mismatch: 18 in-sample adopters, not 24 (6 launch post-FARS)
3. No event-study figure
4. Overclaiming: welfare, enforcement, text-table inconsistency
5. No intermediate mechanism evidence

### Kill-Shot Risk
Corrected high-frequency design may kill the game-day result.

## Execution Plan (Priority Order)

### Phase 1: Rebuild Core Design
- State-week panel (state-day may be too sparse for rare events)
- Actual NFL game schedules from Pro Football Reference
- Fix treatment: exact launch dates, 6 future-treated → never-treated in sample
- Proper exposure: crash counts with log(population × days) offset, or per-day rates
- FE: state + year-week, or state + year-month + DOW

### Phase 2: FARS Mechanism Validation (Free)
- Night (8pm-4am) vs day crash-hour decomposition using FARS HOUR
- Fatalities as outcome (not just fatal crashes)
- Non-alcohol placebo at state-week
- Off-season/non-game-day placebo windows

### Phase 3: Clean Baseline
- Treatment appendix (all 51 units)
- Event-study figure with CI bands
- Leave-one-out, weighted/unweighted
- Pre-trend joint test

### Phase 4: Reframe
- Cut enforcement language
- Mute welfare unless fatality result is solid
- Reframe as cross-market digital vice externality
- Fix all text-table consistency

### Phase 5: Heterogeneity (if core survives)
- Betting handle, playoffs, local NFL team

### Phase 6: External Mechanism (if needed)
- Alcohol sales, bar traffic

### Phase 7: Inference + Polish
- Wild cluster bootstrap / RI
- Full V2 paper (25+ pages)
