# Internal Review — Round 1

**Verdict: Minor Revision**

## Strengths
1. **Compelling framing:** The resilience puzzle is far more interesting than "did gas hurt manufacturing." Opening with the 342 EUR/MWh price spike is vivid and effective.
2. **Escalation design:** The monotonically increasing effects from Feb → Oct 2022 is the paper's strongest causal signature, as it rules out confounders that don't intensify with the gas cutoff.
3. **Clean March 2019 placebo:** Addresses the fatal flaw of apep_0544 (whose March 2019 placebo was larger than the main estimate).
4. **Triple FE structure:** Absorbs the major confounders (country-level macro, global sector trends). The identification is credible.
5. **Subsidy mechanism:** Directionally correct (positive interaction, attenuating), even if imprecise. Framing subsidies as the explanation for resilience is the right move.

## Weaknesses
1. **Statistical precision:** RI p=0.138 is honest but weak. The paper needs to lean on the escalation pattern and placebo integrity rather than the point estimate alone.
2. **Missing PPI data:** Without producer price pass-through, one mechanism channel is purely descriptive. This limits the "complete causal narrative" judges reward.
3. **Jan 2021 placebo:** Shows -0.015, same magnitude as the main effect. The paper should address this directly — it likely reflects the European gas price increases that began in late 2020, before Russia's invasion.
4. **Heterogeneity is directional but imprecise:** High-intensity sectors show smaller (closer to zero) coefficients, which is the WRONG direction for the "gas hurts gas-intensive sectors" story. Need to reconsider the framing.
5. **Subsidy data is cross-sectional and from a secondary source:** Bruegel tracker values are not from the primary Eurostat API. This is a data limitation to acknowledge.

## Recommendations
1. Add a paragraph explicitly addressing the Jan 2021 placebo (pre-invasion energy price rally).
2. Reframe heterogeneity: the with-time-FE specification absorbs country-level subsidies, so the within-sector heterogeneity result measures something different.
3. Add sentence about PPI data unavailability as a limitation.
4. Strengthen the escalation results presentation — make this the centerpiece of the causal argument.
