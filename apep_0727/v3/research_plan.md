# Revision Plan: apep_0727 v3

## Parent: apep_0727 v2 (Rating: initial μ=25.0)
## Referee Verdicts: 2 Major Revision + 1 Minor Revision
## Type: Polish revision — no new data, same design, better execution

## Priority-Ordered Changes

### 1. Annual Bootstrap SEs (Referee #1 priority across all 3 referees)
- 500 bootstrap replications for all 17 annual estimates
- Add SE and 95% CI columns to annual table
- Status: RUNNING

### 2. Monthly Event Study Figure (Referee GPT1+GPT2)
- Monthly bunching ratio 2013-2024 around three policy breaks
- Shows Aug 2014 immediate jump, Jan 2021 gradual decline, Jul 2022 continued decline
- Status: DONE — fig8_monthly_event_study.pdf generated

### 3. Physical Downsizing Verification (Codex #1 concern)
- Capacity-per-module analysis confirms: 310 Wp/module at 9.9 kWp, 265 Wp at 10.1+
- Higher wattage = newer panels used in fewer quantity = real downsizing
- 32 × 310 Wp = 9,920 Wp; 33 × 310 Wp = 10,230 Wp → one panel is the margin
- Status: DONE — results in data/mechanism_kwp_per_module.csv

### 4. Split Post-Reform Period (Gemini referee)
- Main table: separate "2021-2022" from "2023-2024"
- Shows threshold-expansion effect vs surcharge-abolition effect

### 5. Local Counterfactual Robustness (Codex + GPT2)
- Narrower symmetric window (9.5-10.5) with degree-3 polynomial
- Raw histogram at fine bins (0.05 kWp) around threshold
- Addresses the 7 kWp placebo concern about global polynomial reliability

### 6. Claim Register Discipline (Codex + all referees)
- Drop "largest in applied economics" — say "among the largest"
- Replace "on/off like a switch" → "the notch sharply amplified bunching; its removal induced fast but gradual unwinding"
- Demote welfare to illustrative with explicit sensitivity
- Clarify exact 10.0 kWp treatment in registry

### 7. Abstract/Introduction Rewrite
- Fresh rewrite from scratch per Codex
- Lead with the timing evidence, not the magnitude superlative
- Monthly figure as the new flagship

## Not Doing (with explanation)
- Formal structural model → referees didn't request, adds complexity without identification
- Half-year bins replacing annual → monthly figure addresses this better
- Full bibliography expansion → references adequate for polish revision
