# Internal Review — Round 1 (Claude)

## Summary
V2 revision of "Closing the Golden Door" reframes the paper from a precise null on occupational mobility to a three-part story: (1) restriction failed to deliver occupational gains, (2) restriction reduced homeownership transitions in exposed counties, and (3) the pre-restriction period shows complementarity, suggesting restriction destroyed a beneficial dynamic.

## What Works
- **Homeownership as co-primary outcome** transforms the paper. The V1 buried this as a secondary finding; V2 makes it central. The mechanism decomposition (Table 8) shows effects concentrated in young workers (β=-0.271***) and urban areas (β=-0.270***), with a precise null in rural areas. This geographic pattern is exactly what you'd expect if the channel is local demand destruction.
- **Categorical ladder climbing** (β=-0.095**, Table not yet named) is a new finding that resolves the tension between "null OCCSCORE" and "restriction hurt." OCCSCORE is a continuous index that averages across occupational ranks; the binary ladder variable captures actual category transitions. Restriction reduced upward mobility even though average scores didn't move.
- **First-stage evidence** (Table 6) quantifies what was qualitative in V1. High-exposure counties experienced measurably larger declines in restricted-origin foreign-born population.
- **The multi-wave contrast** is visually striking: β=+17.9*** in 1910-1920 vs β=-1.35 in 1920-1930.
- **All 8 figures** are new (V1 had zero). The event study, first-stage binscatter, and complementarity figure are the most effective.

## Issues to Address

### Must Fix
1. **Table numbering**: the paper references Table 6 (first stage) but need to verify the \input paths and labels all match.
2. **Abstract word count**: verify ≤150 words.
3. **OCCSCORE vs ladder discrepancy**: the paper needs to explicitly address why OCCSCORE shows null but the ladder variable is significant. Without this, referees will see it as cherry-picking.
4. **Placebo coefficient magnitude**: β=+17.9 in the full specification seems very large. Need to verify this is the correct spec (with state + occupation FE) and not the raw bivariate. The V1 had a raw placebo of 10.41 without FE.

### Should Fix
5. **Transition matrix figure** (Fig 6): verify the difference probabilities sum correctly and the color scale is interpretable.
6. **Self-employment null**: β=-0.011 is mentioned but not discussed. Either discuss briefly or drop.
7. **Brain drain finding**: the high-skill × exposure mobility interaction (β=0.131***) is important but may need more discussion. Selective out-migration of skilled workers from exposed counties is a mechanism for why homeownership declined.

### Optional
8. **State-clustered SEs**: currently shown as robustness. Could be primary given state-level policy.
9. **Conley spatial SEs**: not implemented but would strengthen.

## Verdict
Paper is ready for external review pipeline. The issues above are manageable. The key concern is #4 (placebo coefficient magnitude) — if the full-spec placebo is really +17.9 with occupation FE, that needs explicit interpretation.
