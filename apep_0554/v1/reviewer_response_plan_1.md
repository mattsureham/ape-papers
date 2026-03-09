# Reviewer Response Plan

## Common Concerns (GPT R1 + R2)

### 1. Causal overclaiming (MUST FIX)
Both GPT reviewers flag that the paper claims causal effects when the design supports only reduced-form associations. The abstract, intro, mechanism section, and conclusion all use causal language.
**Action:** Systematically soften causal language. First stage = "credible evidence"; fertility = "reduced-form association"; mechanism = "plausible interpretation."

### 2. Single-treated-unit inference (MUST FIX)
Country-clustered SEs with one treated unit produce misleadingly small p-values.
**Action:** Add explicit caveat about inference limitations. Note that placebo-in-space permutation test provides the design-appropriate inference for SCM. For DiD, acknowledge that p-values should be interpreted cautiously given N=1 treated unit.

### 3. Treatment timing misalignment (MUST FIX)
July 2018 start → 2018 annual TFR cannot plausibly reflect the reform. Immediate SCM gap in 2018 is suspicious.
**Action:** Add discussion acknowledging the timing mismatch. Note that 2018 gap likely reflects pre-existing trend acceleration rather than immediate reform effect. Emphasize 2019+ evidence.

### 4. Concurrent shocks not adequately ruled out (Address in text)
Min wage hikes, housing, education costs are Korea-specific confounds.
**Action:** Strengthen discussion of confounders. Acknowledge these cannot be separated from the reform in this design.

### 5. Mechanism not directly estimated (Address in text)
Income-time trade-off is asserted, not shown.
**Action:** Soften to "plausible interpretation consistent with external evidence."

## Gemini-Specific Concerns

### 6. Selection into overtime / industry composition (Address)
**Action:** Add brief discussion of limited inter-industry mobility in Korea.

### 7. Lagged fertility effects (Address)
**Action:** Discuss biological lag; note 2018 gap may be spurious.

## Prose Improvements
- Kill roadmap paragraph (DONE)
- Fix mechanism topic sentence (DONE)
- Active voice in data section (DONE)
- Remove "is important" phrasing (DONE)

## Exhibit Improvements
- Rename "treated × post" to "Korea × Post-2018" in DiD table (DONE)
