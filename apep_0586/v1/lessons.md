## Discovery
- **Policy chosen:** WWII military mobilization + GI Bill — high-salience question about occupational upgrading with clear first-order stakes (wages, education, occupation for 9M men)
- **Ideas rejected:** Pinned idea (idea_0377), no alternatives evaluated
- **Data source:** MLP 3-decade panel (Azure) — 41.5M records confirmed accessible; state mobilization instrument constructed from 1940 census agricultural share
- **Key risk:** Collins & Zimran (2025 EEH) already study WWII veterans with linked 1940-1950 census. Our delta: 1930 pre-baseline for pre-trends, IV strategy (not selection-on-observables), full-count universe (not sample). Must position clearly against them.
- **Additional risk:** No individual veteran status in the census extract — using reduced-form ITT design instead of 2SLS. This is actually cleaner (avoids weak-instrument issues) but limits the structural interpretation.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-5.4 R1, GPT-5.4 R2, Codex-Mini PASS; Gemini FAIL)
- **Top criticism:** Text-table inconsistencies were pervasive — pre-trend coefficient sign, sample size references, heterogeneity column labels, and trend-adjusted coefficient non-additivity all flagged
- **Surprise feedback:** GPT-5.4 caught the mathematical non-additivity of trend-adjusted coefficient (different control sets across specifications)
- **What changed:** Fixed 15+ text-table inconsistencies, deleted fabricated data file (05b_figures_lite.R), added 30% sample explanation, restructured robustness table, rewrote pre-trend section to correctly distinguish controlled/uncontrolled estimates, added footnote explaining trend-adjusted coefficient non-additivity

## Referee Review & Revision (Stage C)
- **Referee verdict:** GPT-5.4 R2 = MAJOR REVISION, Gemini = MINOR REVISION, GPT-5.4 R1 = substantive concerns
- **Consensus criticism:** All three reviewers agreed the paper overclaimed causal "returns to military service" when the design only identifies a reduced-form state×cohort exposure effect. The diagnostic/methodological contribution is strong but the causal paper is not yet established.
- **Key lesson:** When your paper's main finding is a rejection of its own identifying assumption, lean INTO that diagnostic contribution rather than trying to also be a causal paper. The reframing made the paper stronger, not weaker.
- **What changed in revision:** (1) Title reframed to emphasize identification failure, (2) Abstract leads with falsification test, (3) Trend-adjusted specification demoted to "exploratory," (4) Added estimand discussion, (5) Reframed pre-trend as "falsification test" rather than parallel-trends test, (6) Softened all mechanism language, (7) Expanded linkage/survivorship selection discussion, (8) Added "What Would Strengthen Identification?" section, (9) Conclusion reframed as diagnostic contribution

## Summary
- **Biggest lesson:** A paper that honestly demonstrates an identification failure is more publishable than one that overclaims causal estimates from a compromised design. Embrace diagnostic contributions.
- **Process lesson:** Text-table consistency checking should happen BEFORE advisor review, not during it. The 4-cycle advisor loop was caused by accumulated small inconsistencies.
- **Data lesson:** The MLP 3-decade panel is an extraordinary resource. The pre-trend test it enables is simple (same specification on pre-treatment outcomes) but devastatingly informative.
