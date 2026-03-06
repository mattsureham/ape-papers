# Revision Plan (Round 1)

## Summary

All three external reviewers identified the pre-trend violation as the central issue. The revision addresses this by:

1. Adding permutation inference (999 permutations) to address small-cluster concerns
2. Adding industry-specific linear trends specification (the most important missing robustness check)
3. Adding joint F-test for pre-period event study coefficients
4. Softening all causal language to be descriptive/associational throughout
5. Adding reconciliation paragraph explaining event study vs DiD coefficient patterns
6. Removing roadmap paragraph and improving prose (active voice in results)

## Workstreams

### W1: New Robustness Checks (Code)
- R8: Permutation inference for all 3 main specifications
- R9: Industry-specific linear trends for entry and senior share
- Joint F-test for pre-period event study coefficients

### W2: Framing/Language (Paper)
- Soften "2.9 million" claim to descriptive arithmetic decomposition
- Soften conclusion language
- Add Cameron et al. (2008) reference for cluster inference

### W3: Structural (Paper)
- Add event study vs DiD reconciliation paragraph
- Remove roadmap paragraph
- Active voice for results section opening
