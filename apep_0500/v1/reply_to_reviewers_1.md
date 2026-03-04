# Reply to Reviewers — Round 1

## Internal Review (CC-1)

### Issue 1: Pastoral zone classification and regression to mean
> Using pre-treatment violence as part of the classification creates a mechanical concern...

**Response:** Added a paragraph in Section 4.2 (Identifying Assumptions) explicitly discussing this concern. The DDD structure requires mean-reversion to operate differentially across treated and control states. Additionally, half the classification is based on Middle Belt geography, which is orthogonal to violence dynamics. See revised text in Section 4.2.

### Issue 2: Wild cluster bootstrap transparency
> The paper mentions WCB but does not report results.

**Response:** Added a parenthetical note in Section 4.4 explaining that WCB is incompatible with the interacted fixed effects notation in the preferred specification, and that RI serves as the primary non-parametric tool.

### Issue 3: CS ATT sign difference
> The state-level CS ATT is positive while the DDD is negative.

**Response:** Expanded Section 5.6 (Callaway-Sant'Anna Aggregate ATT) with a full paragraph explaining the sign difference: (1) state-level aggregation across heterogeneous LGAs dilutes the pastoral zone effect, (2) implementation-period violence enters the state aggregate but is absorbed by state×year FE in the DDD, and (3) the two estimators answer different questions.

### Issues not addressed
- Table 2 FE labels: adequately documented in notes
- R² discussion: standard for count data with many zeros
