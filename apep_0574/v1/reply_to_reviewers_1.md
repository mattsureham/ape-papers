# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

### 1A. Trade data too coarse (5 SITC groups)
**Response:** We acknowledge this limitation but note that finer SITC or HS-level Eurostat data for the 2023-2024 period face significant availability and coverage constraints. We add explicit discussion of this limitation and note that the broad-category results provide a necessary first-pass test that finer analysis could refine.

### 1B. Annual treatment timing too blunt
**Response:** Agreed. We now emphasize the persistence decomposition (Shock 2022 vs. Post-normalization 2023-24) as the primary specification rather than the pooled post coefficient. The pooled estimate is presented as a summary.

### 1C. Production event study missing country×month FE
**Response:** Valid concern. We re-estimate the production event study with the full saturated structure (country×month + sector×month + country×sector FE). Results are qualitatively similar — the collapse timing and magnitude are preserved. Added as a robustness check.

### 1D. Pre-trends evidence not strong enough
**Response:** We revise language to be more cautious about parallel trends validation, consistent with the borderline F-test (p=0.089). We clarify that the Rambachan-Roth bounds are analytical approximations, not the formal HonestDiD implementation.

### 1E. Extra-EU imports insufficient for broad trade claim
**Response:** This is the most important criticism. We substantially narrow all claims throughout the paper to refer specifically to "extra-EU imports" rather than "trade adjustment" broadly. We add explicit discussion of intra-EU substitution as a first-order alternative channel that our data cannot address.

### 2A. Null treated as proof of no effect
**Response:** We add minimum detectable effect (MDE) calculations and explicitly state what magnitudes the design can rule out.

### 2B. Value vs. quantity confounding
**Response:** Acknowledged as a key limitation. We add discussion noting that quantity/volume data would be needed to distinguish price from quantity effects, and we reframe claims as being about import expenditure rather than physical substitution.

### 3A. Placebo tests weaken interpretation
**Response:** Agreed. We rewrite the placebo section to acknowledge that significant placebo effects indicate broader import weakness in gas-dependent countries, which reduces confidence in the energy-intensity-specific channel. This is now framed as a diagnostic warning, not supportive evidence.

### 3B. Mechanism overclaiming
**Response:** We reframe the demand-destruction interpretation as a hypothesis consistent with the evidence, not a demonstrated mechanism. The language throughout is softened from "we show" to "the evidence is consistent with."

---

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

Reviewer 2's concerns largely overlap with Reviewer 1. Key additional points:

### Intra-EU trade
**Response:** Same as 1E above. Claims narrowed throughout.

### Country×month FE
**Response:** Same as 1C above. Re-estimated with saturated FE.

### Wild cluster bootstrap
**Response:** Already reported in appendix; we add a note in the main text pointing readers to the bootstrap results.

### Treatment timing
**Response:** Same as 1B above. Persistence decomposition emphasized.

---

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### Intra-EU trade
**Response:** Same as above. Claims narrowed.

### Price vs. quantity
**Response:** Same as 2B above. Limitation acknowledged.

### Downstream exposure measure
**Response:** This would require input-output tables matched to trade data at the country-sector level. Beyond the scope of current revision but noted as a direction for future work.

---

## Summary of Changes Made

1. **Narrowed all claims** from "trade adjustment" to "extra-EU import substitution" (abstract, intro, conclusion)
2. **Re-estimated production event study** with country×month FE (robustness check)
3. **Rewrote placebo section** to acknowledge placebos as diagnostics that weaken energy-specific identification
4. **Softened mechanism language** from demonstrated to hypothesized
5. **Added MDE discussion** for the null result
6. **Fixed identical F-test issue** — verified both tests and clarified they are from different specifications
7. **Relabeled Rambachan-Roth section** as analytical sensitivity bounds
8. **Added intra-EU trade limitation** as prominent discussion point
9. **Added value vs. quantity limitation** with explicit framing
