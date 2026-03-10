## Discovery
- **Policy chosen:** Oregon Measure 110 + HB 4002 — rare symmetric natural experiment with both decriminalization and recriminalization
- **Ideas rejected:** Used pinned idea (idea_0127) from idea database; no alternatives considered
- **Data source:** CDC VSRR Socrata API (xkb8-kh2a) — worked smoothly; Census ACS API for population
- **Key risk:** Fentanyl supply shock confounds the decriminalization estimate; symmetric test addresses this partially

## Execution
- **augsynth crashed:** osqp QP solver segfaulted on the 51×116 panel; pivoted to tidysynth (Abadie solver) which worked perfectly
- **Time index bug:** difftime/30 approach created duplicate time indices; fixed with (year-2015)*12+month_num
- **LOO failures:** 13 of 50 leave-one-out specifications failed due to computational singularity in Synth's solver; remaining 37 were stable (ATT range 10.2–13.6)
- **2020 population gap:** ACS disrupted by COVID; required linear interpolation from 2019/2021 to fix summary table consistency

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, GPT R2, Codex; Gemini FAIL on recurring 12-month-window concern)
- **Top criticism:** Symmetric sum inference invalid without joint permutation test (both GPT reviewers)
- **Surprise feedback:** Gemini referee gave MINOR REVISION — noted the paper's "epistemic humility" as a strength
- **What changed:** Implemented joint permutation test (p=0.549), added placebo-in-time test, toned down causal language, added SE methodology transparency, removed redundant Figure 6

## Summary
- **Key pattern:** Cascading numerical updates — fixing one data issue (2020 population interpolation) required updating dozens of hardcoded values throughout paper.tex
- **What worked:** Transparent treatment of fentanyl confound praised by all reviewers; symmetric design concept well-received
- **What to avoid:** Hardcoding rounded values in text that diverge from exact table values (e.g., SE: 3.8 vs exact 3.727)
