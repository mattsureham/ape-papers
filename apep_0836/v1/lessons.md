## Discovery
- **Idea selected:** idea_1032 — Japan Heisei merger fiscal cliff. Chosen for its formulaic shock design (grace period expiration dates mechanically determined by merger date) and large treated sample (~425 merged cities).
- **Data source:** MIC Survey on Local Public Finance (Excel, FY2011-2023) + RIETI Municipality Converter (CSV from GitHub). MIC data only covers cities (shi), not towns/villages — this reduced sample from ~560 to 425 treated municipalities.
- **Key risk:** SFD is formula-based (not actual expenditure), limiting interpretation of "efficiency."

## Execution
- **What worked:** RIETI converter was clean and immediately usable. Municipality code matching required stripping check digits (6→5 digit mapping). The staggered DiD setup was straightforward once merger dates were extracted from Japanese text.
- **What didn't:** MIC Excel files before FY2011 had parsing issues (different format). The direction of results was opposite to what the "fiscal cliff" narrative predicted — SFD increases rather than decreases post-phase-out. Had to reframe from "no fiscal cliff" to "fiscal divergence / dependency trap."
- **Review feedback adopted:** Toned down causal claims about "efficiency not materializing" — SFD is formulaic, not actual spending. Added population control robustness check (reduces TWFE estimate by ~34%). Clarified the distinction between the grace period mechanism (adjusts LAT calculation) and the SFD formula (reflects underlying demographic need). All three reviewers flagged the same core issues: pre-trends, formulaic outcomes, control group comparability.
