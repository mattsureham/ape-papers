# Revision Plan 1 — apep_0582/v1

## Summary of External Reviews

| Reviewer | Decision | Key Concern |
|----------|----------|-------------|
| GPT-5.4 (R1) | REJECT AND RESUBMIT | Inference not strong enough; claims exceed evidence |
| GPT-5.4 (R2) | MAJOR REVISION | Same inference concerns; GDP comparison not apples-to-apples |
| Gemini-3-Flash | MINOR REVISION | Share endogeneity; gross production vs value added |

## Prioritized Changes

### Workstream 1: Strengthen Inference (R1 #1, R2 #1)
- **Two-way clustering** (country AND sector) as robustness check
- **Increase RI permutations** from 500 → 2000
- **Add AKM (2019) citation** and shift-share inference discussion
- **Report formal joint pre-trend F-test** (already computed)

### Workstream 2: Recalibrate Claims (R1 #2, R2 #2)
- Remove "credible interval excludes zero" language (Section 7.6)
- Change "established" → "suggestive"; "rules out" → "consistent with"
- Reframe as differential manufacturing effects, not total GDP effects
- Explicitly state the design identifies relative amplification, not the full level effect
- Tone down abstract to match evidence strength

### Workstream 3: Unified Phase Model (R1 #5, R2 #5)
- Replace separate escalation regressions with single model: `exposure × phase_indicator`
- Phases: Pre, Mar-May 2022, Jun-Aug 2022, Sep-Dec 2022, 2023, 2024
- Test monotonicity across phases within one model

### Workstream 4: Downgrade Mechanism Claims (R1 #9, R2 #8)
- Reframe fiscal shield as "exploratory heterogeneity"
- Remove "offset roughly one-third" quantitative claim from abstract/intro
- Soften tercile heterogeneity interpretation

### Workstream 5: Production-Weighted Specification (R1 #7, R2 #7)
- Add baseline (2017-2019) production-weighted regression

### Workstream 6: Prose & Exhibit Improvements
- Kill roadmap paragraph (Prose review)
- Move Figures 4-5 to appendix (Exhibit review)
- Sharpen defensive writing about R² and p-values
- Better conclusion (Prose review suggestion)

### Workstream 7: 2021 Placebo Treatment
- Reframe January 2021 placebo as a precursor stress test, not a design threat
- Acknowledge the broader 2021-2022 energy crisis timeline explicitly

## NOT Addressed (Infeasible Within Revision)
- Alternative exposure measures (2019 gas shares) — would need new data fetch
- Country-sector-specific linear trends — computationally heavy with triple FE
- Controls for non-gas war exposure — requires trade data
- Value added data — not available at required frequency
- Map of Europe — lower priority than statistical improvements
