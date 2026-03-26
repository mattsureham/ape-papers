## Discovery
- **Idea selected:** idea_1723 — Right-to-Counsel and community-level homelessness. First-order welfare question, sharp institutional variation, accessible data.
- **Data source:** HUD PIT counts (2007-2024, xlsb format) + manual RTC coding from NCCRC and legislation
- **Key risk:** Endogenous adoption timing (cities/states adopt RTC in response to rising homelessness)

## Execution
- **What worked:** HUD PIT data is remarkably clean and complete. 18 years of panel data with ~385 CoCs/year. The Callaway-Sant'Anna estimator handled the staggered design well.
- **What didn't:** Initial 14 city-level treated CoCs failed the ≥20 threshold. Expanding to include state-level programs (CT, WA, MD, MN) introduced pre-trend contamination. The state-level adoption in 2021-2023 was clearly endogenous.
- **Key pivot:** The paper evolved from "RTC doesn't reduce homelessness (null)" to "the apparent reduction is driven by selection, not causation." The contrast between clean city-level null and contaminated full-sample "effect" became the contribution.
- **Review feedback adopted:** Added power calculation for pre-COVID subsample (80% power for ±8% effects). Added pipeline calibration (20% eviction reduction × 5% conversion = 1% expected effect). Both reviewers emphasized these quantitative benchmarks.
