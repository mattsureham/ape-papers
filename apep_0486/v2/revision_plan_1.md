# Revision Plan — Round 1

## Review Summary
- **Gemini-3-Flash:** MINOR REVISION (highly positive; needs RI expansion, homicide caveat)
- **GPT-5.4 (R2):** MAJOR REVISION (wants CS-DiD centered, stronger inference, DDD validation)
- **GPT-5.4 (R1):** REJECT AND RESUBMIT (wants full re-centering around heterogeneity-robust estimators)

## Consensus Issues (All 3 Reviewers)
1. **RI p=0.113 vs clustered p<0.01** — paper overclaims significance
2. **Homicide analysis too weak** — should be demoted further
3. **Metro CS-DiD (-21) vs metro TWFE (-76)** — divergence undermines "credible range"

## Feasible Changes (This Round)
1. Soften "credible range" language — present TWFE as descriptive, CS-DiD as primary
2. Add explicit hierarchy: CS-DiD is primary, matched TWFE is supporting
3. Demote homicide from abstract/intro claims
4. Soften mechanism assertions to "consistent with" language
5. Add "to my knowledge" to novelty claims
6. Acknowledge metro CS-DiD divergence directly in results

## Deferred to v3
- Implementing Sun-Abraham, Borusyak-Jaravel-Spiess estimators
- Wild cluster bootstrap (broken with current fixest version)
- RI for metro and DDD specifications
- Treatment coding validation appendix
- CDC WONDER annual homicide data
- Dynamic DDD event study
- Stacked DiD
