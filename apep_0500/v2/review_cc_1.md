# Internal Review: apep_0500 v2

## Summary
This revision implements six identification fixes to paper apep_0500:

1. **RI Redesign**: Cohort-preserving randomization inference that maintains exact staggered adoption structure
2. **Within-State Displacement Test**: DD for non-pastoral LGAs in treated states (null, supporting deterrence)
3. **Geography-Only Classification**: Attempted but collinear with state×year FE due to Middle Belt geography
4. **WCB Fix**: Reported on simpler specification; preferred spec singular under WCB
5. **Effective Sample Table**: 12 of 37 states contribute to DDD identification
6. **Mechanism Section Promotion**: New Section 6 with systematic deterrence vs displacement analysis

## Key Results
- Main DDD: -0.480 (p=0.003), unchanged from v1
- Within-state displacement: 0.036 (p=0.24) — null, supports deterrence
- Cross-state spillover: 0.037 (p=0.75) — null
- RI (cohort-preserving): p=0.183 (conservative due to structural centering)
- Leave-one-out: [-0.546, -0.292]
- SGF sub-sample: -0.546 (p=0.009)
- Effective sample: 12 contributing states (6 treated, 6 control)

## Limitations Noted
- RI permutation distribution not centered at zero due to Middle Belt pastoral structure
- Geography-only classification collinear with state×year FE
- WCB only feasible on simpler specification
- Conflict-only classification produces insignificant coefficient of opposite sign
