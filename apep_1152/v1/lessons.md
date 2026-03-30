# Lessons: apep_1152 (The Composition Illusion)

## Discovery Phase
- Two data access failures before finding a viable idea:
  1. idea_2140 (Ofsted Inspector IV): CloudFront blocked PDF scraping after initial test
  2. idea_1827 (Good Samaritan Laws / TEDS-A): SAMHSA WAF blocked all automated access
- Lesson: **Verify automated data access BEFORE claiming an idea.** A 5-minute download test would have saved hours.
- idea_0353 (CES → Coal Retirement) succeeded because EIA-860 is a plain ZIP download from eia.gov — no WAF, no authentication.

## Execution
- The null result was unexpected but genuine: CS DiD shows no acceleration (ATT=0.008, p=0.62)
- The TWFE result (0.064, p<0.01) is driven by a composition illusion: CES states have smaller, older generators
- Key validation: capacity-weighting eliminates the TWFE effect → confirms composition story

## Co-authoring (Duet)
- Codex's condition-based disagreement resolution worked well for idea selection
- Codex correctly identified the framing shift: "composition illusion" as the named object
- Cold read caught text-table inconsistency in the central result (capacity-weighted estimate)
- The anti-pattern (working alone for 30+ min then presenting) occurred during pivots out of necessity

## What I would do differently
- Run a data-access smoke test (can I download the file?) for EVERY candidate idea before deliberation
- Keep 3 backup ideas with confirmed data access ready before starting
- The 16-vs-13 CES states distinction should have been flagged in the research plan, not discovered at cold read
