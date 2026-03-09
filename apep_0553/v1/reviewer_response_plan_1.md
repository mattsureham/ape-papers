# Revision Plan — Round 1

## Overview

Three referee reviews received: R1 (REJECT AND RESUBMIT), R2 (MAJOR REVISION), R3 (MINOR REVISION). Plus exhibit review and prose review from Gemini-3-Flash.

## Grouped Concerns and Actions

### Workstream 1: Identification and Causal Language (R1 #1-5, R2 #1-5)
- **Scale back all causal claims** throughout abstract, intro, results, discussion, conclusion
- **Fix β₂ interpretation**: Clarify net 2024 effect = β₁ + β₂ everywhere
- **Reframe tier regressions** as descriptive (not causal)
- **Add stockpiling/mean-reversion** as named threat to validity
- **Add permutation/randomization inference** (1,000 permutations)
- **Attempt wild-cluster bootstrap** (if feasible)

### Workstream 2: Control Group and Product Sample (R1 #1, R2 #2)
- **Add transparency** about how 18 non-CHPL codes were selected
- **Acknowledge limitation** that full within-chapter universe not used
- **Suggest matched controls** as future work

### Workstream 3: PPML and Functional Form (R1 #7, R2)
- **Elevate PPML** from footnote to core discussion
- **Discuss PPML vs OLS discrepancy** as informative about extensive/intensive margins
- **Note insignificant PPML rerouting** as important caveat

### Workstream 4: Methodological References (R1 #12, R2 #11)
- Add Callaway & Sant'Anna (2021), Roth (2022), Goodman-Bacon (2021)
- Add Cameron, Gelbach & Miller (2008), Sun & Abraham (2021)
- Add paragraph on methodological positioning

### Workstream 5: Exhibits (Exhibit Review)
- **Remove Figure 2** (redundant transit CHPL line)
- **Move top products spaghetti** to appendix
- **Change country decomposition** from stacked bar to faceted line
- **Update figure aesthetics** (white background, minimal grids)
- **Add permutation distribution figure** to appendix

### Workstream 6: Prose (Prose Review)
- **Remove "planned research" apologies** from introduction and data sections
- **Remove roadmap paragraph**
- **Clean remaining throat-clearing**
- **Separate descriptive from causal claims** more explicitly

## What We Will NOT Do (and Why)
- Monthly data extension: Not available through current API access
- Additional countries: Would require new data collection
- Full within-chapter product universe: Would require new API calls
- Product-level matching: Deferred to future work (insufficient pre-period covariates for credible matching)

## Execution Order
1. R code changes (permutation inference, wild bootstrap, figure updates)
2. Paper.tex revisions (all workstreams simultaneously)
3. Recompile and verify
4. Write reply_to_reviewers.md
