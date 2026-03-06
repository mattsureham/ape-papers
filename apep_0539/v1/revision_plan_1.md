# Revision Plan — Round 1

## Key Changes Based on Referee Feedback

### From All Three Reviewers:
1. **Moderate claims throughout** — narrow estimand language from "no effect of EBT on crime" to "no detectable effect of statewide EBT completion on aggregate state-level crime rates"
2. **Treatment mismeasurement** — elevate within-state county-by-county rollout from limitation to central interpretive caveat in abstract, intro, and conclusion
3. **Remove "Missouri outlier" language** — replace with acknowledging different estimands and geographic resolution

### From GPT-5.4 (R1):
4. **Explain CS vs Sun-Abraham divergence** — attribute to different aggregation weighting schemes
5. **Clarify identified post-treatment window** — note that 2005 cohort contributes no post-treatment estimates

### From GPT-5.4 (R2):
6. **Strengthen treatment definition clarity** — make explicit that `ebtissuance` records statewide status, consistent throughout

### From Gemini:
7. **MDE/burglary framing** — ensure abstract and conclusion explicitly note burglary MDE cannot exclude Wright et al. estimate

## Changes NOT Made (with rationale):
- **County-level analysis** — infeasible without county rollout data not available in SNAP Policy Database
- **Wild cluster bootstrap** — valid suggestion but standard analytical SEs with 41 clusters are adequate; flagged as future improvement
- **SNAP participation heterogeneity** — state-year participation data would require additional data acquisition; noted as important limitation
- **Official UCR data rebuild** — Disaster Center compilation is a standard secondary source; flagged as limitation
