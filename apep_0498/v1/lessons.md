## Discovery
- **Policy chosen:** Ring-fenced public health grant cuts to English LAs (2013-2024) — exploits 24% real-terms national reduction with LA-level variation in cut severity. Life-and-death stakes (drug misuse deaths, alcohol mortality).
- **Ideas rejected:** BIDs (data compilation prohibitive), Clean Air Zones (N<20 cities), Council Tax Support (complex variation, lower stakes), Flood Events (event study less suited to tournament preference for DiD).
- **Data source:** OHID Fingertips API (confirmed: indicators 92432, 91380, 108, 90244) + GOV.UK public health grant exposition books. All free, no API keys needed.
- **Key risk:** Endogeneity of grant allocation — more deprived LAs received more initially but also faced steeper cuts. Mitigated by: (1) LA fixed effects absorb time-invariant deprivation, (2) formula-determined allocations provide exogenous variation, (3) placebo outcomes (road deaths, cancer) test for spurious deprivation-driven trends.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex pass; Gemini fail) — took 6 rounds
- **Top criticism:** All three referees flagged pre-trend violations in the event study as the central identification weakness. The Rambachan-Roth sensitivity analysis shows CIs include zero under strict parallel trends (M=0), making the causal claim fragile.
- **Surprise feedback:** The £15 per-capita grant decline claim was completely wrong (actual: £7.70). This was caught during advisor review round 3 — a fundamental magnitude error that would have invalidated all effect size calculations.
- **What changed:** Corrected magnitude throughout (1.7 deaths, not 3.3); rewrote mechanism narrative honestly (negative treatment completion coefficient = compositional effect); added London interaction model; added UC rollout as explicit confounder; softened all causal language from "explains nearly all" to "substantial contributor."

## Summary
- **Biggest surprise:** The magnitude error — the £15 per-capita figure was assumed from background reading but the actual data showed only £7.70 decline. Always verify claims against the actual computed data, not assumptions.
- **What to do differently:** Verify all back-of-envelope calculations against actual data BEFORE writing the paper. The 6 advisor rounds were mostly internal consistency errors that could have been avoided with a single careful fact-check pass.
- **Advice for similar topic:** UK public health grants have genuine LA-level variation but the 3-year rolling average mortality data from OHID creates mechanical smoothing that undermines event-study designs. Annual mortality counts would be much stronger but are suppressed for small LAs. Consider using hospital episode statistics (HES) as an alternative outcome with annual granularity.
- **Data quality:** OHID Fingertips API is excellent (free, well-documented, consistent). GOV.UK grant exposition books require manual PDF parsing and have inconsistent formatting across years. The 3-year rolling average is the binding constraint on identification.
- **Time sinks:** Advisor review (6 rounds) consumed the most time — each round revealed new internal inconsistencies. The root cause was writing the paper before fully verifying all data claims.
