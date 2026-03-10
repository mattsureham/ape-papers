# Reviewer Response Plan

## Review Summary
- **Gemini:** MINOR REVISION — very positive, wants pre-COVID DDD and regression-based event study CIs
- **GPT R1:** MAJOR REVISION — reframe as ITS, Newey-West primary, formal full-pass-through test, full placebo distribution, tone down claims
- **GPT R2:** REJECT AND RESUBMIT — similar to R1 but stronger; aggregate CPI framing, HC1 inadequate, DDD weak

## Workstream 1: Inference (Must-Fix)
- Switch to Newey-West SEs as primary in all time-series regressions
- Report HC1 alongside for comparison
- Update 03_main_analysis.R and 06_tables.R

## Workstream 2: Formal Full-Pass-Through Test (Must-Fix)
- Test H0: β = 0.0183 (not just H0: β = 0)
- Report p-values for both nulls
- Add to Table 2

## Workstream 3: Full Placebo Distribution (Must-Fix)
- Run DD at every possible month in pre-period
- Show where October 2019 ranks in distribution
- Add figure and discussion to robustness section
- Update 04_robustness.R and 05_figures.R

## Workstream 4: Framing/Claims (Must-Fix)
- Remove "same product, same store" language from intro
- Change "complete pass-through" to "near-complete" or "consistent with full"
- Acknowledge ITS character of design
- Add Bertrand et al. (2004) citation
- Soften persistence claims
- Strengthen limitations paragraph

## Workstream 5: Pre-COVID DDD (High-Value)
- Restrict DDD to pre-COVID sample
- Report in Table 3

## Workstream 6: Prose (from prose review)
- Already addressed: killed roadmap paragraph
- Tighten lit review transitions

## Workstream 7: Exhibits (from exhibit review)
- Consider consolidating Table 2 and 3 (skip — they serve different identification layers)
- Note: benchmark line suggestion is good but minor
