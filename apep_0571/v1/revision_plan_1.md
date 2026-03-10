# Revision Plan — Round 1

## Summary of Reviewer Concerns

All three reviewers agree on the core strengths (novel question, detection-gap framework, clear predictions). The two R&R reviews (GPT R1, GPT R2) share overlapping concerns about identification. Gemini gives Minor Revision.

## Changes to Make

### Must-Fix (Code + Paper)

1. **Add region×year FE** as robustness specification in 04_robustness.R
2. **Add covariate×post interactions** (baseline poverty, rurality, age × post) as additional specification
3. **Add population-scaled outcomes** (crime rates per 100K) as robustness check
4. **IHS transformation** for homicide (and other outcomes) as alternative to log(count+1)
5. **Reframe predicted treatment** as descriptive check, remove IV/Bartik language

### Must-Fix (Paper Only)

6. **Soften causal language** throughout — "consistent with" rather than definitive
7. **Acknowledge treatment conflation** — automatic registration + voluntary voting, discuss decomposition
8. **Expand data comparability discussion** — add explicit category mapping paragraph
9. **Reframe pre-trend test honestly** — acknowledge 1 pre-period is limited
10. **Temper policy conclusions** — match evidence strength

### Won't Change (with explanation in reply)

- 2012-2017 data gap: no data exists; already acknowledged as limitation
- Direct policing data: not available at comuna-year level; noted as limitation
- PPML: already documented as non-convergent
- Denuncias vs detenciones decomposition: not available in aggregate data

## Execution Order

1. Modify R code (03, 04) to add new specifications
2. Re-run analysis pipeline
3. Revise paper.tex extensively
4. Recompile and verify
5. Write reply_to_reviewers_1.md
