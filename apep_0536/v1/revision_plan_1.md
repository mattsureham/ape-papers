# Revision Plan 1 — apep_0536/v1

## Context

After advisor review (3 of 4 PASS) and three external referee reviews, the following revision plan addresses the key concerns raised.

## Workstreams

### 1. Causal Language (All Reviewers)
- Soften all causal claims to "associated with" throughout abstract, introduction, results, conclusion
- Add Roth (2022) citation on pre-test conditioning
- Frame TWFE result as conditional on identifying assumptions the paper's own diagnostics question

### 2. Election-Type Mixing (All Reviewers)
- Present by-election-type split (Section 6.1) as the most informative specification
- Remove spurious election-type × year FE robustness check (mechanically identical to baseline)
- Honestly present the sign reversal across election types as the key puzzle

### 3. Data Bug Fix (Internal)
- Fix European election anti-system vote classification (nuance code aggregation)
- Update all downstream statistics: summary stats, balance tests, robustness results
- Verify every number in paper.tex matches code output

### 4. Literature Additions (Reviewers)
- Add de Chaisemartin & D'Haultfœuille (2020), Borusyak et al. (2024), Roth (2022), Boxell et al. (2017), Guriev et al. (2021)

### 5. Sun-Abraham Results (Reviewer)
- Add numerical ATT estimate (-0.009, SE = 0.004, p = 0.03) with event-study description

### 6. Text-Table Consistency (Advisor)
- Fix summary statistics (22.2% → 16.5%)
- Fix turnout interpretation (coefficient is negative)
- Fix jackknife range, quarter count, balance test sign
- Harmonize anti-system coding list across Section 3.2 and Appendix

## Items Deferred to Future Revision
- Commune-level analysis
- Rambachan-Roth sensitivity bounds
- GDELT mechanism data

## Verification
All changes verified against data CSVs and R output before final compilation.
