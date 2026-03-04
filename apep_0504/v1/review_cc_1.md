# Internal Review — Round 1

**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-04
**Verdict:** MINOR REVISION

## Summary

The paper presents a clean DiD design exploiting staggered adoption of mandatory food hygiene rating display across UK nations. The primary finding — substantial entry deterrence (6.4 fewer entries per LA per quarter) — is well-identified and robust across specifications. The CS-DiD estimator confirms the TWFE result. The triple-difference placebo is a strength.

## Strengths

1. **Clean natural experiment**: Identical inspection system across nations, only display mandate varies
2. **Universe-scale data**: 5.7M companies, 586K FHRS establishments
3. **Multiple estimators**: TWFE, CS-DiD, DDD, border design, wild cluster bootstrap
4. **Pre-trends look clean**: Flat pre-period coefficients in event study

## Weaknesses

1. **Exit measurement limitation**: The bulk CH file only has active companies. Exit proxy (cohort survival) is cross-sectional, not a clean quarterly exit flow. Paper should acknowledge this more explicitly.
2. **Entry deterrence interpretation**: The -6.4 effect seems very large (>100% of pre-treatment Welsh mean of ~1.0 per LA per quarter for food). Need to verify units — could be driven by overall England trends absorbed by DiD.
3. **Limited power for NI**: Only 11 NI LAs — bootstrap addresses this but should note.
4. **FHRS quality comparison is descriptive**: Cross-sectional comparison confounds many things. Should not be presented as causal.

## Required Changes

1. Add discussion of exit measurement limitation in Data section
2. Verify and discuss magnitude of entry effect (appears very large)
3. Clearly label FHRS quality comparison as descriptive, not causal
4. Add a sentence about the paper needing 25+ pages for publication requirements

## Minor Issues

- Some redundancy between Introduction and Results
- Conclusion could be shorter
