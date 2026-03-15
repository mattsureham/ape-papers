## Discovery
- **Idea selected:** idea_0847 — PPP nonprofit employment at the 25% revenue decline threshold
- **Data source:** IRS SOI 990 extracts + SBA PPP FOIA data, linked via IRS BMF
- **Key risk:** Annual revenue is a noisy proxy for the quarterly eligibility threshold

## Execution
- **What worked:** The data linkage pipeline (990 → BMF → PPP) was clean and efficient. 158K organizations matched, with clear summary statistics showing selection patterns. The pre-treatment placebo (2018 employment) was a powerful diagnostic that changed the paper's story.
- **What didn't:** The RDD first stage was flat — the 25% threshold doesn't bind when measured in annual data. This required a major reframing from "PPP effects" to "program design failure."
- **Pivot:** Reframed the null RDD as the main contribution rather than a failed identification. The paper became about administrative data mismatches in program design.
- **Review feedback adopted:** Added discussion distinguishing attenuation bias from genuinely non-binding threshold (three pieces of evidence). Expanded limitations section on external validity of 45% match rate. Clarified paper's identity as diagnostic rather than evaluative.

## Key Takeaway
When designing an RDD around a policy threshold, verify that the threshold is observable in the available data at the same frequency the policy operates. The PPP's quarterly threshold was invisible in annual 990 data — a fundamental design-data mismatch that may generalize to other emergency programs targeting nonprofits.
