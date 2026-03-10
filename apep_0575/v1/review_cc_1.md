# Internal Review - Round 1

## PART 1: CRITICAL REVIEW

### Identification and Empirical Design
The staggered DiD design exploiting BRRD transposition timing across 19 EU countries is well-motivated. The Callaway-Sant'Anna estimator appropriately addresses TWFE bias under heterogeneous treatment effects. Key concern: the not-yet-treated comparison pool is exhausted by December 2015, limiting post-treatment horizons for later cohorts. This is now acknowledged in the text (footnote to Section 6.2).

### Inference and Statistical Validity
Standard errors are properly clustered at the country level for TWFE and SA specifications. The CS-DiD uses analytical (pointwise) SEs from the `did` package, which is clearly stated. The p-values are now internally consistent (p=0.041 for CS ATT throughout). Wild cluster bootstrap is included as additional inference check. With only 19 clusters, inference should be interpreted cautiously.

### Robustness
Leave-one-out, randomization inference, placebo timing, GIIPS exclusion, and bail-in tool activation all provide meaningful checks. The robustness section now clearly states these are TWFE-based checks that test specification stability rather than directly validating the CS-DiD headline. The intensity-interaction results provide the strongest robustness evidence.

### Corporate Placebo
The sector DDD interaction (Post × Household = -0.020, p=0.41) is correctly described as underpowered. The paper appropriately notes this lacks power to formally reject equal effects.

## PART 2: CONSTRUCTIVE SUGGESTIONS
1. Consider adding a "never-treated" comparison if any EU countries did not transpose the BRRD, to extend the CS event study horizon.
2. The SA estimate (3.1 pp vs CS 0.67 pp) gap deserves more discussion — what drives the 4.6x difference?
3. Could strengthen the insurance optimization mechanism with micro-data on deposit splitting.

## DECISION
DECISION: MINOR REVISION
