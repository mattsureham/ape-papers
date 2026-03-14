## Discovery
- **Idea selected:** idea_0958 — Nutrient neutrality as a housing supply constraint. Strong staggered DiD with 69 treated LPAs and exogenous assignment via hydrology. No existing academic causal evaluation.
- **Data source:** MHCLG PS1 (12MB CSV, quarterly planning decisions) + Live Table 122 (annual net dwellings). Both downloaded without issues.
- **Key risk:** PS1 data covers total planning decisions, not residential-only. This makes estimates conservative but reduces the specificity of the mechanism test.

## Execution
- **What worked:** Clean staggered DiD with CS-DiD ATT = -11.9 (p < 0.05), log TWFE = -4.7% (p = 0.001). Pre-trends flat. HonestDiD robust at M-bar = 0.5. Wave-specific estimates consistent. Not-yet-treated controls yield identical results.
- **What didn't:** LT122 net dwellings result imprecise (p = 0.20) due to short annual post-treatment window and decision-to-completion lag. LPA name matching required manual fixes for 4 authorities.
- **Review feedback adopted:** Strengthened the "moratorium" framing (changed from "near-complete halt" to "partial moratorium on major housing schemes"). Added explicit note that PS1 covers all application types, making estimates conservative for residential. Expanded discussion of displacement and suggested future postcode-level analysis.
