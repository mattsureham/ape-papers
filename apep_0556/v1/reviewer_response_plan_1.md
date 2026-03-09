# Reviewer Response Plan

## Priority 1: Must-Fix

### 1. Retitle paper and reframe estimand
- **Concern (GPT R1, R2):** Title asks "Did India's Health Mission Save Newborns?" but paper doesn't estimate mortality causally. Estimand is differential (early/high-intensity vs later/lower-intensity), not total NRHM effect.
- **Fix:** Retitle to focus on institutional delivery. Reframe throughout as "differential effect of early/intensive NRHM." Remove "resolves" language. Present mortality as descriptive context, not conclusion.

### 2. Soften pre-trend language further
- **Concern (GPT R1, R2):** Even after our edits, "supported by a subset-based pre-trend test" is still too strong for 2 treated states.
- **Fix:** Replace with "suggestive subset-based pre-trend" or "consistent with, but unable to validate." Add power limitation discussion.

### 3. Present all-16-state estimate as primary
- **Concern (GPT R1, R2):** Excluding NE looks ex post and increases estimate from 15.9 to 25.58.
- **Fix:** Present all-states (15.89 pp) as baseline, EAG-only as heterogeneity/sensitivity. Maintain that EAG-only is informative but not "preferred."

### 4. Address NFHS-3 baseline contamination more seriously
- **Concern (all three):** NFHS-3 covers births 2001-2006, straddling NRHM launch. Paper treats this as attenuation, but effect is ambiguous.
- **Fix:** Expand discussion of contamination. Add footnote about direction. Stop saying "makes estimates conservative" without qualification.

### 5. Add modern DiD citations
- **Concern (GPT R1, R2):** Missing Goodman-Bacon (2021), Callaway-Sant'Anna (2021), Sun-Abraham (2021).
- **Fix:** Add citations and brief discussion of why classic staggered-bias concerns are mitigated here (binary treatment timing, not staggered multi-period adoption).

## Priority 2: High-Value Improvements

### 6. Acknowledge population-weighting limitation
- Add paragraph noting equal-weighted state design and that birth-weighted results would differ. Flag as limitation.

### 7. Soften mechanism claims
- Ensure all ASHA/JSY attributions are clearly labeled as suggestive, bundled-package interpretation.

### 8. Soften "facility quality paradox" to hypothesis
- Reframe from demonstrated conclusion to hypothesis consistent with evidence.

## Priority 3: Prose Improvements
- Apply prose review suggestions (already partly done)
- Strengthen transitions

## Not Changing
- Microdata redesign (GPT R2): Would require complete rebuild. Out of scope for this version.
- Population weighting regressions: Cannot be done with state-level STATcompiler data without microdata.
- Wild-cluster bootstrap: Would require re-running R code; RI already provides exact finite-sample inference.
