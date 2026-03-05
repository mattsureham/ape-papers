# Reviewer Response Plan — Round 1

## Summary of Reviews
- GPT-5.4: Substantive concerns (DDD spec, CS-DiD, power)
- Grok-4.1-Fast: MINOR REVISION (CS SE, lit gaps, polish)
- Gemini-3-Flash: MINOR REVISION (stable hire selection, software note)

## Priority Fixes

### 1. DDD Specification — Add state × worker-type FE (GPT concern)
- Add `state:new_hire` interaction to the DDD regression
- This allows each state its own permanent new-hire vs continuing-worker gap
- Re-estimate and update Table 2, Column 4

### 2. Soften CS-DiD claims (GPT, Grok)
- Acknowledge the manual aggregation is a workaround, not standard inference
- Frame CS-DiD as "directional check" rather than formal test
- Note the package version issue transparently

### 3. Soften DDD placebo claims (GPT)
- Add caveat that continuing workers become contaminated over time
- Note this makes the DDD a short-run placebo

### 4. Power section (GPT)
- Rely on confidence intervals rather than back-of-envelope MDE
- Soften MDE claims

### 5. Prose improvements (Prose review)
- Remove roadmap paragraph at end of introduction

### 6. Exhibit improvements (Exhibit review)
- Clean variable names in etable output (already done)

## What Won't Change
- Core null result and narrative
- Basic identification strategy
- Figures
