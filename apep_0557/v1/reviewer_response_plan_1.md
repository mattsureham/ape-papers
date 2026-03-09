# Reviewer Response Plan

## Summary of Feedback

Three referees reviewed the paper. GPT R1 and R2 recommended Reject and Resubmit; Gemini recommended Minor Revision. The core concerns cluster around:

1. **Identification weakness** (all three, most severe from GPT R1/R2): Single national shock + endogenous cross-sectional aid exposure
2. **Overclaiming from the null** (GPT R1/R2): "Well-powered null" and "the answer is no" too strong
3. **Inference with few clusters** (GPT R1/R2): Need wild cluster bootstrap, RI exchangeability justification
4. **Boko Haram confound** (all three): Need more than leave-one-out
5. **Pre-trend test reporting** (GPT R1/R2): Need formal test statistics
6. **SDE table classifications** (GPT R2): "Large positive" labels misleading for insignificant results

## Revision Plan

### Workstream 1: Strengthen robustness (Code changes)
- Add exclude-northeast robustness (drop 6 Boko Haram states)
- Add geopolitical zone × post FE controls
- Run wild cluster bootstrap-t
- Report pre-trend F-test statistics
- **Status: DONE** — all results computed

### Workstream 2: Soften causal claims (Paper text)
- Replace "the answer is no" with "I find no evidence of buffering"
- Replace "well-powered null" with nuanced language about ruling out large effects
- Acknowledge confidence interval includes small negative effects
- Reframe throughout as "no evidence of buffering in this design"
- **Status: DONE**

### Workstream 3: Report new robustness results (Paper text)
- Add wild bootstrap p=0.111 and CI
- Add exclude-northeast results (β=0.108, p=0.134)
- Add zone×post results (β=0.103, p=0.195)
- Report pre-trend F=0.640, p=0.904
- **Status: DONE**

### Workstream 4: Fix SDE table (Paper text)
- Change "Large positive" to "Positive, n.s." for all insignificant estimates
- **Status: DONE**

### Workstream 5: Prose improvements (from prose review)
- Reduce "column-talk" in results narration
- Improve transitions (intro roadmap, section openings)
- Strengthen conclusion's final sentence
- **Status: DONE**

### What we did NOT change (and why)
- **Triple-diff with FAAC fiscal exposure**: FAAC state-level data is not available in the current dataset. This is acknowledged as a limitation. The zone×post FE specification partially addresses this.
- **Balance table of aid on pre-2008 covariates**: Would require additional data (poverty, urbanization) not currently in the panel. Acknowledged as a limitation.
- **Rambachan-Roth sensitivity analysis**: The HonestDiD R package requires a specific staggered DiD structure; this paper uses a continuous treatment with a single shock. Left for future work.
- **State-specific linear trends**: With 37 states and a continuous treatment, state trends absorb much of the identifying variation and substantially inflate standard errors. The zone×post specification is a reasonable middle ground.
