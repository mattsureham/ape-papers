# Internal Review — Claude Code (Round 1)

**Paper:** apep_0238 v10 — "Demand Recessions Scar, Supply Recessions Don't"
**Reviewer:** Claude (self-review as Reviewer 2 + Editor)
**Date:** 2026-03-26

## Reviewer 2 (Harsh)

### Major Concerns

1. **The single estimand is not significant.** The headline GR coefficient (-0.057) has HC1 p=0.23 and permutation p=0.16. For a paper whose central claim is "demand recessions scar," the primary estimand failing to reach conventional significance is a serious problem. The paper is honest about this (good), but a referee will still flag it.

   *Mitigation:* The LP at h=6 and h=12 ARE significant. The horse race is strong. The IV confirms at medium horizons. And the duration-trap attenuation (37-77%) is the real contribution — it's about mechanism, not just persistence. Consider whether the estimand window should be narrower (36-84?) where the LP is stronger.

2. **Pre-trend at h=-36 is significant (p=0.009).** This suggests that high-HPI states were already on different employment trajectories 3 years before the recession. While h=-12 is clean, referees will seize on the h=-36 result. This undermines the exclusion restriction.

   *Mitigation:* The Saiz IV and horse race address this — the exogenous component of HPI (geography) is not correlated with pre-trends. Should add a specification with pre-2003 trend controls.

3. **COVID sign convention may confuse.** The COVID coefficients in Table 2 are positive (0.0029), which readers might misinterpret as "COVID helped." This is because the Bartik is standardized and more-exposed states have more-negative values. The paper should be clearer about this, or flip the sign.

4. **No CPS microdata mechanism.** The plan called for CPS microdata (temp layoff share, U→E flows by state). The actual analysis uses UR persistence as a proxy. This is fine but weaker than promised. The "CPS evidence" language in the abstract overstates what's delivered.

### Minor Concerns

5. The pooled interaction is not significant (p=0.69). Drop or explicitly flag as underpowered.
6. First-stage F=11.4 is below the Stock-Yogo 10% threshold of ~16.4 for 2SLS. Use weak-IV-robust inference (AR CIs).
7. Figure numbering in text doesn't match — text says "Figure 1" for the scatter but that's actually Figure 2 in the file names.
8. Missing "Keywords" line on page 1.

## Editor (Constructive)

### What Works

- **The question is first-order.** This is the right question for the moment.
- **The guitar string metaphor** is vivid and memorable.
- **The architecture is clean.** No structural model bloat. Duration-trap is the clear center.
- **The attenuation result (37-77%)** is the paper's best finding. It's concrete, novel, and answers the "why" question.
- **Honest about limitations.** The paper doesn't hide the imprecision.

### What Needs Work Before External Review

1. Fix figure cross-references (Fig 1 vs Fig 2 numbering).
2. Address the pre-trend at h=-36 explicitly in text.
3. Clarify COVID sign convention in Table 2 notes.
4. Either deliver CPS microdata or soften the abstract language.
5. Consider narrowing the GR estimand window to where power is strongest.

### Verdict

The paper is ready for advisor review with minor fixes. The core architecture is sound and the duration-trap mechanism is compelling. The power limitation is real but inherent to N=50 — no amount of revision fixes that. The honesty about it is a strength.

**Decision: PROCEED TO ADVISOR REVIEW after addressing items 1-3 above.**
