# Reviewer Response Plan - Round 1

## Summary of Feedback Sources

1. **GPT-5.2 Referee** (review_gpt_1.md): MAJOR REVISION
2. **Grok-4.1-Fast Referee** (review_grok_1.md): MAJOR REVISION
3. **Gemini-3-Flash Referee** (review_gemini_1.md): MINOR REVISION
4. **GPT-5.2 Advisor** (advisor_gpt_1.md): FAIL (3 fatal errors)
5. **Internal Review** (review_cc_1.md): MINOR REVISION
6. **Exhibit Review** (exhibit_review_gemini_1.md): Constructive suggestions
7. **Prose Review** (prose_review_gemini_1.md): Constructive suggestions

## Workstream 1: Fix Fatal Errors from GPT Advisor (Highest Priority)

**Source:** GPT advisor fatal errors 1-3

**Actions taken:**
- Fixed appendix alternative treatment description to match main text (β=-0.018, p=0.01)
- Fixed JSA denominator description: "working-age population" → "total population" in main text
- Clarified Table 4 note: column 4 "replaces year FE with LA-specific linear time trends"

## Workstream 2: Treatment Endogeneity (Highest Priority)

**Source:** All 3 referees' must-fix #1

**Issue:** 2017/18 CTS expenditure is post-treatment; local shocks could drive both outcomes and spending.

**Actions taken:**
- Rewrote first limitation paragraph to lead with this as most important concern
- Added explicit discussion of expenditure conflating generosity with caseload/take-up
- Elevated alternative treatment (pre-reform JSA exposure, β=-0.018, p=0.01) throughout: abstract, intro, discussion, conclusion, appendix
- Noted scheme-parameter data as highest priority for future work

## Workstream 3: Soften Causal Claims (High Priority)

**Source:** All 3 referees (especially GPT)

**Actions taken:**
- Abstract: "isolates" → "is consistent with isolating"; added treatment measure caveat
- Discussion: "reveals" → "separates"; "powerful strategy" → "useful diagnostic strategy"
- Conclusion: "operates through reduced demand" → "consistent with reduced demand"; added explicit caveat about causal interpretation
- £4,200: clarified as "cumulative foregone appreciation over 2013-2019, not annual"
- Throughout: hedged mechanism claims, added "conditional on causal interpretation" qualifiers

## Workstream 4: Horse-Race Multicollinearity (Medium Priority)

**Source:** GPT referee high-value #5, Grok referee must-fix #2

**Actions taken:**
- Added new limitation paragraph (seventh) on r=0.70 correlation and sign-flip fragility
- Noted alternative treatment as independent corroboration
- Acknowledged VIF analysis and alternative normalizations as future extensions

## Workstream 5: Compositional Bias (Medium Priority)

**Source:** Gemini referee must-fix #2

**Actions taken:**
- Added evidence in limitations: median price tracks mean (0.021 vs 0.020), transactions unaffected (<0.001, p=0.98)
- Acknowledged micro-level analysis needed for full decomposition

## Workstream 6: Geographic Spillovers (Medium Priority)

**Source:** All 3 referees

**Actions taken:**
- Added spatial spillover limitation paragraph discussing SUTVA concerns
- Noted property markets have natural geographic boundaries
- Acknowledged spatial lag model would be ideal but is beyond scope

## Workstream 7: Prose and Presentation (from earlier rounds)

**Actions taken:**
- Opening hook with concrete policy impact
- Condensed literature review
- Findings-first prose throughout
- Table notes for clarity
