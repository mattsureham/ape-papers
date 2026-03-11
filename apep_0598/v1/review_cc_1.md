# Internal Review — Round 1

**Verdict: Minor Revision**

## Strengths
1. **Sharp identification**: The cross-sector DiD exploiting cash-intensity variation is compelling. The perfect monotonic ordering (fuel 14.2% > food 7.0% > non-specialized 3.4%) is striking and immediately convincing.
2. **Novel framing**: "Accidental formalization" is a fresh angle on capital controls — distinct from the macro/crisis management literature.
3. **Multi-method triangulation**: SCM + sector DiD + VAT mechanism test provides multiple lines of evidence.
4. **Persistence result**: The gap *widening* after controls were lifted (-12.3 vs -8.55) is the paper's most interesting finding — consistent with sunk-cost hysteresis through POS investment.

## Issues

### Methodology
1. **SCM pre-treatment fit**: RMSPE ratio of 0.85 (< 1) means pre-treatment deviations are larger than post-treatment. The paper should be more transparent about this limitation and rely more heavily on the sector DiD.
2. **3-cluster inference**: Only 3 NACE sectors — standard errors may be unreliable even with clustering. Wild cluster bootstrap or permutation-based p-values should be reported.
3. **Cash intensity values**: The 55%/75%/90% cash shares are from ECB surveys — these are constructed, not directly measured at the sector level. The paper should acknowledge measurement error in the treatment intensity variable.

### Framing
4. **VAT result sign**: The VAT DiD shows Greece *underperforming* donors (β = -35.75), which contradicts the formalization narrative. The paper needs to address this — likely the Greek recession overwhelmed any formalization gains. A ratio (VAT/GDP or VAT/turnover) would be more appropriate.
5. **Abstract could be punchier**: The opening question is good but the abstract could lead with the natural experiment framing more directly.

### Minor
6. Missing fig5_loo.pdf (leave-one-out) — reference should be removed if figure doesn't exist.
7. Some tables could use `\adjustbox` for width control.

## Recommendation
Address the VAT interpretation issue and cluster inference concern, then proceed to external review.
