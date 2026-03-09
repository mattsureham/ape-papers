# Revision Plan — Stage C

## Summary of Reviewer Feedback

All 3 reviewers recommend REJECT AND RESUBMIT. Key themes:

### Consensus Points (addressed below)
1. **Monotonicity claim too strong** — "satisfied" should be "consistent with"
2. **Upper-bound claim unjustified** — sign of bias unknown; remove or qualify
3. **"Built-in placebo" overstated** — general equilibrium could affect all sectors; use "informative diagnostic"
4. **44 courts is the effective sample** — panel of 720 overstates identifying variation
5. **Same-sample confound** — controls specification changes both controls AND N (720→500)
6. **Literature gaps** — need Frandsen et al., Bhuller et al., Borusyak-Hull-Jaravel, GPSS
7. **Case-mix contamination underdiscussed** — nationality, detained/non-detained confound
8. **Prose improvements** — kill passive reporting, distill result narrative

### Infeasible Requests (noted in reply)
- Obtain case-level EOIR data (fundamental redesign, out of scope)
- Wild bootstrap / permutation inference (requires new R analysis)
- Cross-sectional court-level regressions as primary spec (requires new analysis)
- Alternative geographic units (CBSA, commuting zones)
- Pre-determined outcome falsifications (requires new data)

## Planned Changes

1. **Section 6.7 (Monotonicity):** Change "satisfied" → "consistent with"; tone down claims
2. **Section 7.3 (What We Learn):** Remove "upper bound" language; qualify controlled specification
3. **Throughout:** "built-in placebo" → "sector-heterogeneity diagnostic" or "informative placebo"
4. **Section 5.2 + Results caveat:** Explicitly state 44 courts as effective identifying variation
5. **Section 6.2:** Add note that controls change both specification AND sample; acknowledge limitation
6. **references.bib + text:** Add Frandsen/Lefgren/Leslie (2019), Bhuller et al. (2020), Borusyak/Hull/Jaravel (2022), Goldsmith-Pinkham/Sorkin/Swift (2020)
7. **Section 7.1:** Add case-mix as a third fundamental reason for design failure
8. **Prose:** Remove roadmap paragraph; improve results narrative; active voice fixes
