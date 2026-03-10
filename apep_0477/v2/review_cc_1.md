# Internal Review — Claude Code (Round 1)

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths.** The multi-cutoff RDD exploiting five EPC boundaries is a clean and clever design. The institutional setup—where one boundary (E/F) carries regulatory force while others are purely informational—permits a rare decomposition of information vs. regulation effects. The difference-in-discontinuities around MEES enactment adds temporal variation that strengthens the design beyond pure cross-sectional comparisons. The use of pre-linked UPRN-matched data from Chi et al. (2023) is a major advantage over prior work using postcode-level matching.

**Concerns.**
- The E/F boundary **fails the McCrary test** (T = 11.07, p < 0.001), which is a serious threat. While the paper argues manipulation biases estimates toward zero (making the null conservative), this claim deserves more scrutiny. If manipulated properties are systematically *better* (landlords invest to push from 38 to 39), the bias direction is ambiguous. The donut RDD addresses this partially but deserves more emphasis.
- The 500K random subsample is well-motivated for computational reasons, but the paper should report a sensitivity check showing results are stable across different random draws (even just 2-3 draws would suffice).
- Covariate imbalance at E/F (flat p=0.016, new-build p=0.026) is non-trivial. The no-covariate specification addresses this, but a formal joint balance test would strengthen the argument.

### 2. Inference and Statistical Validity

- Standard errors are clustered at the district level—appropriate given spatial correlation in housing markets. Mass-point adjustment for discrete SAP scores is a careful choice.
- P-values are from bias-corrected robust inference throughout—this is correct practice and consistently applied.
- Sample sizes are reported in all main tables. The addition of N (effective) rows is thorough.
- The Holm stepdown approximation to Romano-Wolf is sensible for the five simultaneous tests. After adjustment, only A/B retains any marginal significance (adjusted p = 0.217), confirming the null.

### 3. Robustness and Alternative Explanations

- Bandwidth sensitivity, polynomial order, donut specifications, and address-matched subsample all confirm the null. This is a thorough battery.
- The placebo cutoff analysis at 10 non-boundary scores is useful. Some show significance (c=85, c=88), but these are at score ranges with known density manipulation—the paper should note this.
- The volume RDD showing a significant post-MEES spike (τ=251.7, p=0.003) is an interesting finding that could be developed further. It suggests MEES affected the *composition* of transactions near E/F even if not prices.
- The EPC-to-sale lag result (τ=-119.6 days, p=0.076) is suggestive of strategic behavior and merits discussion.

### 4. Contribution and Literature Positioning

- The paper is well-positioned against the hedonic EPC literature (Fuerst & McAllister, Aydin et al., Brounen et al.) and the energy efficiency gap literature (Allcott & Greenstone, Gerarden et al.).
- The contribution is clear: RDD vs. hedonic produces fundamentally different answers, and the RDD null is informative given adequate power.
- Missing citations: Consider adding Frondel et al. (2020) on German EPCs and Myers (2020) on residential energy efficiency disclosure. The UK-specific literature on MEES compliance (e.g., Ambrose et al. 2021) could strengthen the enforcement discussion.

### 5. Results Interpretation and Claim Calibration

- The paper appropriately distinguishes "no discrete label effect" from "energy efficiency doesn't matter." The continuous score vs. discrete band interpretation is well-articulated.
- The claim that hedonic premia "likely reflect omitted variables" is strong but defensible given the design. The paper correctly notes that the two approaches test different margins.
- The energy crisis non-response is striking and well-presented.

### 6. Actionable Revision Requests

**Must-fix:**
1. Address the E/F McCrary failure more directly—consider adding the donut specification as a co-primary result rather than only a robustness check.
2. Report at least one additional random subsample draw to confirm stability.

**High-value:**
3. Develop the volume RDD finding—it tells an interesting story about strategic behavior under MEES that complements the null price result.
4. Add missing literature citations (Frondel et al. 2020, Myers 2020, Ambrose et al. 2021).
5. Consider a formal power calculation (minimum detectable effect at 80% power) rather than relying only on CI width.

**Optional:**
6. The annual event-study figure could be made more prominent—it's currently in a single paragraph but is one of the most informative exhibits.
7. Consider discussing whether the null implies energy efficiency is priced continuously (through the score) vs. not priced at all.

## PART 2: CONSTRUCTIVE SUGGESTIONS

The paper's main strength is that it delivers a genuinely informative null. The design is well-powered, the robustness is thorough, and the institutional setting is sharp. The contribution is clear and timely.

The paper could be made stronger by:
1. **Elevating the volume result.** The post-MEES volume spike at E/F, combined with the price null, tells a richer story: MEES changed *who* transacts near E/F but not *at what price*. This is a more nuanced finding than a pure null.
2. **Formal power analysis.** An MDE at 80% power would make the "informative null" claim even more precise.
3. **Heterogeneity by property type.** Do flats vs. houses behave differently? The covariate imbalance in flat status suggests differential composition that might mask heterogeneous effects.

## 7. Overall Assessment

**Strengths:** Clean multi-cutoff design, large sample, thorough robustness, informative null, strong institutional setting, pre-linked high-quality data.

**Weaknesses:** E/F density manipulation limits the primary boundary's credibility (mitigated by donut); single random subsample; tenure-specific estimates are noisy; volume result underexplored.

**Publishability:** This paper is close to publication quality. The null is well-powered and robust. With the suggested improvements, it would be a strong contribution to AEJ: Economic Policy.

DECISION: MINOR REVISION
