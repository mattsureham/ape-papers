# Internal Review — Round 1

**Reviewer:** Claude Code (self-review)
**Paper:** Much Ado About Markets: Null Effects of India's Farm Laws on Retail Commodity Prices

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:** The symmetric on/off design is clever and well-motivated. The continuous treatment (APMC stringency index) avoids the binary treatment trap and exploits meaningful cross-state variation. The identifying assumption—that price trends would have been parallel across states with different APMC stringency absent the farm laws—is clearly stated and testable.

**Concerns:**
- The APMC stringency index is time-invariant and cross-sectional. This means identification relies entirely on the interaction of a fixed state characteristic with policy timing. This is standard for generalized DiD, but the paper could be more explicit about what variation is being exploited — essentially comparing high-APMC vs low-APMC states before/after law changes.
- The ON phase is only 8 months (June 2020–January 2021). This is short for market adjustments to manifest, especially in agricultural commodity markets with seasonal production cycles. The paper acknowledges this but could discuss it more — 8 months may simply be insufficient for structural market reorganization to affect retail prices.
- The COVID-19 confound is discussed but perhaps not fully resolved. The ON phase begins during India's first severe lockdown wave. While commodity-month FE absorb national shocks, state-level COVID responses varied. The paper could run a COVID-severity interaction check.

### 2. Inference and Statistical Validity

**Strengths:** Standard errors clustered at state level (28 clusters) are appropriate. Randomization inference (1,000 permutations) provides a non-parametric alternative. The RI p-value of 0.52 strongly supports the null.

**Concerns:**
- 28 clusters is on the low side for cluster-robust inference. Wild cluster bootstrap would strengthen the inference. The paper does not report this.
- The paper finds precisely estimated nulls — the 95% CI for the ON coefficient is roughly [-0.13, 0.25]. This means the design cannot rule out economically meaningful effects (e.g., a 10% price increase). A power analysis or MDE calculation would help interpret the null.
- The coefficient precision varies considerably across specifications (SE ranges from 0.071 to 0.099), suggesting some sensitivity to controls.

### 3. Robustness and Alternative Explanations

**Strengths:** The paper provides a reasonable battery: event study, leave-one-state-out, randomization inference, two placebo tests, commodity-level heterogeneity, and the symmetric design itself as a built-in falsification.

**Concerns:**
- The pre-period placebo (fake 2019 treatment) shows a coefficient of 0.081 with SE 0.099 — this is not zero and is of similar magnitude to the main ON coefficient (0.058). While statistically insignificant, it weakens the case for parallel pre-trends.
- No discussion of potential spillover effects — if the farm laws affected prices in neighboring states, the APMC stringency-based treatment would be contaminated.
- The commodity heterogeneity analysis shows some variation (onion and tomato appear to have larger, though still insignificant, effects). This could be explored more.

### 4. Contribution and Literature Positioning

**Strengths:** The paper clearly positions itself in the agricultural deregulation literature and the specific India farm laws debate. The citation of Chatterjee (2021), Chand (2020), and historical APMC reforms is appropriate.

**Concerns:**
- The paper cites several works but the bibliography may be thin on international agricultural market deregulation comparisons. Adding references to EU CAP reform effects, US agricultural deregulation episodes, or Chinese hukou-linked agricultural market reforms would strengthen the literature positioning.
- The null result contribution needs sharper framing — what specific prior belief does this update? The paper could engage more with the political economy predictions (MSP displacement, monopsony power) that motivated the protests.

### 5. Results Interpretation and Claim Calibration

**Strengths:** The paper is appropriately cautious about the null. It does not over-claim policy irrelevance — it carefully states "no detectable trace on retail prices."

**Concerns:**
- The conclusion could be sharper about what the null means. Does it mean the laws didn't change market structure? That market structure doesn't affect retail prices? That 8 months was too short? These are different interpretations.
- The standardized effect size (SDE = 0.012) is reported but could be contextualized against effects found in other agricultural deregulation studies.

---

## PART 2: CONSTRUCTIVE SUGGESTIONS

### High-Value Additions
1. **Wild cluster bootstrap:** With only 28 state clusters, adding wild cluster bootstrap p-values (e.g., using `fwildclusterboot` in R) would substantially strengthen inference.
2. **Minimum detectable effect:** Report the MDE at 80% power given the design. This tells readers what effect size the design could have detected and contextualizes the null.
3. **COVID interaction:** Add a specification interacting APMC stringency × phase with state-level COVID severity (cases per capita or lockdown stringency). This directly addresses the most obvious confound.

### Moderate-Value Improvements
4. **Spillover discussion:** Even a brief paragraph on why geographic spillovers are unlikely (or a border-pair analysis if data permits) would preempt a common referee objection.
5. **Back-of-envelope welfare calculation:** Even with null effects, quantifying what the point estimates imply for consumer welfare would add policy relevance.
6. **Seasonal heterogeneity:** Interact treatment with agricultural season (kharif vs rabi) to check if effects differ by harvest cycle.

### Polish
7. **Event study visual:** The event study coefficients could be presented with both pointwise and sup-t uniform confidence bands for stronger pre-trends assessment.
8. **Comparison with wholesale prices:** If wholesale (mandi) price data exists, showing null effects at both wholesale and retail would strengthen the mechanism story.

---

## 6. Actionable Revision Requests

### Must-fix
1. **Add wild cluster bootstrap inference** — 28 clusters is borderline; report WCB p-values alongside RI.
2. **Report MDE/power** — Essential for null result papers. What was the smallest effect detectable?

### High-value
3. **Discuss pre-trend concern** — The pre-period placebo coefficient (0.081) is close to the main estimate (0.058). Explicitly address why this does not undermine identification.
4. **Expand mechanism discussion** — Why might deregulation not affect retail prices? Market structure persistence, MSP as price floor, or retail markup absorption?

### Optional
5. **COVID robustness check** — Interact with state COVID severity.
6. **Broader literature on agricultural deregulation** — One paragraph comparing to non-Indian evidence.

---

## 7. Overall Assessment

**Key strengths:**
- Clever symmetric natural experiment design
- Clean null result with multiple supporting tests
- Well-written with appropriate caution about claims
- Policy-relevant for India's ongoing agricultural reform debate

**Critical weaknesses:**
- Inference with 28 clusters needs reinforcement (WCB)
- No power analysis makes the null hard to interpret
- Short treatment window (8 months) limits the scope of detectable effects
- Pre-period placebo coefficient is uncomfortably close to main estimate

**Publishability:** This paper has a solid design and an important null result. With wild cluster bootstrap, power analysis, and expanded mechanism discussion, it would be a strong submission to AEJ: Economic Policy or Journal of Development Economics.

DECISION: MINOR REVISION
