# Internal Review — Round 1

**Reviewer:** Claude Code (internal)
**Date:** 2026-03-06
**Verdict:** Minor Revision

## Summary

This paper studies the effect of Grand Paris Express construction on nearby property values using the universe of French property transactions (DVF). The main finding — a 7.4% decline within 1km of active construction — is credible and policy-relevant. The staggered construction timeline across 8 line segments provides plausible identification.

## Strengths

1. **Novel question.** Construction disamenity effects of transit are understudied. Most papers focus on post-opening capitalization.
2. **Comprehensive data.** The universe of 785,000 geolocated transactions eliminates sample selection concerns.
3. **Robust main result.** Leave-one-line-out stability (7.0%–8.8% range) is impressive.
4. **Distance gradient.** The decay from significant at 1km to null at 1.5km is consistent with localized construction externalities.

## Concerns

### Major
1. **Limited pre-period for early lines.** 5 of 8 line segments began construction before 2020. The identifying variation for these comes from cross-sectional comparison (near vs. far within commune), not temporal comparison. This is honestly discussed but weakens the parallel trends argument.

2. **CS-DiD imprecision.** The CS estimate (-16.4%, p=0.15) is not significant. The paper honestly reports this but should be more cautious about claiming "qualitatively similar" results.

### Minor
3. **Compositional sorting.** The finding that transacted properties near construction are smaller/more apartment suggests selection effects. Hedonic controls help but cannot fully address unobserved quality.

4. **Post-opening coefficient.** The negative opening-phase coefficient (-11%) is from a single line (L14S) in a single quarter. This warrants more careful caveating.

## Recommendation

Minor revision. The core finding is solid. The paper should be more transparent about the limitations of the pre-period for early-treated lines and avoid over-interpreting the CS-DiD and post-opening results.
