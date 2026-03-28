# Internal Review — Claude Code (Reviewer 2 + Editor)
## apep_0749 v2: Beyond Game Day

### Harsh Reviewer (Reviewer 2)

**Overall Assessment:** The paper makes a genuine contribution: it corrects a false positive and documents a real but diffuse alcohol-crash externality from sports betting legalization. The baseline result is robust and the game-day null is convincing. However, several issues need attention.

**Concerns:**

1. **The game-day null could be a power issue.** With only 18 treated states and a noisy within-quarter game-day/non-game-day decomposition, the DDD may simply lack power to detect a real but smaller game-day concentration. The paper should report power calculations or at minimum discuss what effect size the DDD could have detected.

2. **The late-night concentration.** The late-night ATT (0.225) is significant, but the hour-bin decomposition doesn't sum exactly to the overall ATT (0.045 + 0.036 + 0.057 + 0.225 = 0.363 vs 0.380). This discrepancy should be explained — likely driven by crashes with unknown hours (HOUR=99). Report this.

3. **The non-alcohol placebo for the DDD.** The paper reports a non-alcohol game-day DDD of 0.462 (insig), which is actually LARGER than the alcohol game-day DDD. This should be discussed — it suggests the DDD specification may have power/noise issues.

4. **Concurrent policy confounders.** The paper acknowledges this limitation but doesn't attempt any controls. Even a simple check — listing which treated states also legalized recreational cannabis during the same period — would help.

5. **The citation \citep[APEP-0749,][]{} produces a malformed reference.** Fix this — it should reference the V1 paper properly.

6. **The welfare section is better than V1 but still rough.** The fatality-rate estimate (0.49) is used for welfare, but the paper should note the wide confidence interval and acknowledge that the welfare calculation is illustrative.

### Constructive Editor

**Strengths:**
- The "negative mechanism evidence as a result" framing is exactly right
- The design-waterfall narrative (V1 positive → three corrections → null mechanism) is compelling
- Figures are well-chosen: event study, hour decomposition, game-day null, LOO
- Robustness is thorough (LOO range [0.34, 0.43] is impressively tight)

**Suggestions:**
- Add a sentence about power for the DDD in the mechanism section
- Explain the hour-bin sum discrepancy
- Fix the APEP-0749 citation
- Consider adding a "design waterfall" figure showing how the coefficient changes as each correction is applied

### Priority Fixes Before Advisor Review
1. Fix the \citep citation for APEP-0749
2. Add note about hour-bin sum vs total (unknown-hour crashes)
3. Add DDD power discussion (1-2 sentences)
4. Verify all text numbers match table values
