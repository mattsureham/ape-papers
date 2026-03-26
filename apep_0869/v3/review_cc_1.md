# Internal Review — Round 1

**Reviewer:** Claude (Reviewer 2 mode — harsh + constructive)
**Date:** 2026-03-26
**Verdict:** MINOR REVISION — ready for external review pipeline

---

## Summary

This v3 revision of the BIPA/Rosenbach paper makes substantial formatting and content improvements over v2. The paper now uses single spacing (down from double), adds a Related Literature section, a Conceptual Framework with a formal litigation tax model and predictions table, expands the identification and mechanisms discussions, and fixes a pathological robustness row. The title has been downshifted from "Reorganization of Industry" to "Industry Adjustment," which is more proportional to the evidence.

## What Improved (v2 → v3)

1. **Formatting:** Single spacing makes the paper denser and more authoritative. Tables fit properly (adjustbox on the wide ones). No overfull boxes.
2. **Honest framing:** RI is now the primary inference frame. The abstract presents both the baseline and conservative estimate. The limitations section is explicit about what the paper cannot identify.
3. **Conceptual framework:** The litigation tax model (Equation 2) grounds the empirical analysis in predictions, turning the mechanisms section from a list into a test of hypotheses.
4. **Title downshift:** "Industry Adjustment" is more honest than "Reorganization of Industry" given the evidence.
5. **State×Quarter FE fix:** The pathological row is now properly flagged with [a] rather than starred with SE=0.000.

## Remaining Concerns

1. **The pre-trend is still the elephant.** The paper handles it honestly (presents both estimates, discusses anticipation, notes the linear-trend fragility), but a referee will still push hard on this. The paper would benefit from one more sentence explicitly acknowledging that the linear-trend specification rendering the estimate insignificant is "meaningful fragility, not dispositive" — which it does say, but could be even more direct.

2. **The predictions table (Table 1) is useful but potentially sets up falsification.** The paper predicts "mirror image" gains in neighbor states, then shows imprecise positive neighbor-state coefficients. The paper predicts establishment count increases, then shows a null. Two of three predictions are not clearly supported. This is honest, but a referee could frame it as "your own framework is partially falsified."

3. **Related literature section may feel redundant with the intro's contribution paragraph.** There is some overlap between the final paragraph of the introduction (contribution) and the Related Literature section. Consider trimming the intro contribution paragraph to 2-3 sentences and letting the literature section carry the full engagement.

4. **The 2024 amendments paragraph in Robustness is the weakest subsection.** Two quarters of post-amendment data is too short for any conclusion. Consider moving this to a brief mention in the Discussion's limitations, rather than including it in Robustness where it appears to be an empirical test.

## Minor Points

- The Management coefficient (-34.4%) caveat about thin cells is good but could be one more sentence — how many county-quarter observations back it?
- The CONTRIBUTOR_GITHUB placeholder will be replaced by publish — not a real issue.
- The Conceptual Framework's Equation 2 assumes linear scaling; the Discussion mentions super-linear scaling through class-action probability. This slight inconsistency could be tightened.

## Verdict

The paper is ready for the external review pipeline (Stage A: advisor). The remaining concerns are refinements, not structural problems.
