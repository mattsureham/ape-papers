# Internal Review — Round 1

**Reviewer:** Claude (Reviewer 2 mode — harsh + constructive)
**Date:** 2026-03-26
**Verdict:** MINOR REVISION — ready for external review with small fixes

---

## Summary

This paper studies the employment effects of a judicial ruling that activated private enforcement of biometric privacy law in Illinois. Using a continuous-exposure triple-difference design with border counties, it finds that a one-unit increase in biometric litigation exposure reduced employment by 9-12% in Illinois relative to neighboring states, with the range depending on how a localized 2018 pre-trend is handled. The paper is honest about its limitations and makes claims proportional to its evidence.

## Essential Points

1. **The abstract is now too conservative.** It leads with "9.4% after excluding a localized pre-trend" — but the baseline is -11.7% (p<0.001). The trimmed window is one robustness check, not THE result. The abstract should present the baseline and note the range, not lead with the most conservative specification. A reader seeing "9.4%" in the abstract won't understand this is already the strongest paper on the leaderboard. Suggestion: "I find that a one-unit increase in biometric litigation exposure reduced employment by 11.7% in Illinois border counties (9.4% in a conservative specification excluding a localized 2018 pre-trend)."

2. **The L11 JEL code (Production, Pricing, Market Structure) is debatable.** The paper no longer makes IO/firm-structure claims. Consider replacing L11 with L50 (Regulation and Industrial Policy: General) or K31 (Labor Law).

3. **Management sector coefficient (-34.4%) is huge and imprecise.** The paper reports it alongside Information (-13.7%) and Professional (-7.1%) as evidence for the gradient, but -34.4% in Management with p=0.046 should get more scrutiny. Is this driven by a small cell? How many county-quarter observations back it? If the cell is thin, consider noting this.

## Suggestions

- The introduction's second paragraph is doing a lot of conceptual work. It might benefit from breaking the "litigation tax" definition into its own sentence rather than embedding it in a long parenthetical.
- The "border concentration" subsection in mechanisms is now somewhat disconnected — the neighbor coefficient being negative (-8.2%) is interesting but doesn't clearly support any of the three channels listed in the section opener. Consider restructuring: either make border concentration its own finding (the effect concentrates where regulatory competition matters) or merge it with the limitations.
- The 2024 amendments paragraph says "too early to draw conclusions" — consider cutting it entirely if it adds no information. One sentence in limitations suffices.
