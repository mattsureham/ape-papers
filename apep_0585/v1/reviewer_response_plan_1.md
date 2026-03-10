# Reviewer Response Plan

## Summary of Reviews
- **GPT-5.4 (R1):** Reject and Resubmit
- **GPT-5.4 (R2):** Major Revision
- **Gemini-3-Flash:** Minor Revision

## Grouped Concerns and Planned Responses

### 1. TITLE/FRAMING: "Innovation" vs "Production" [ALL 3 REVIEWERS]
- All reviewers note production ≠ innovation. Title claims too strong.
- **Fix:** Retitle to focus on "production." Rewrite abstract and key passages to say "aggregate production volume" not "innovation decline."

### 2. "PRECISELY ESTIMATED NULL" OVERCLAIM [R1, R2]
- 95% CI [-11, +19] is not precise. Can't rule out moderate declines.
- **Fix:** Replace "precisely estimated null" with "no statistically detectable effect" throughout. Keep "rules out COVID-magnitude decline" as the properly calibrated claim.

### 3. INFERENCE WITH FEW CLUSTERS [R1, R2]
- 6 treated countries → cluster-robust SEs unreliable. Need wild bootstrap.
- **Fix:** Add wild cluster bootstrap via `fwildclusterboot` R package. Report bootstrap p-values alongside standard cluster-robust.

### 4. 2021 AS TREATMENT YEAR AND INDEX BASE [R1, R2]
- 2021 = 100 by construction + partial treatment creates mechanical issues.
- **Fix:** Add robustness specification treating 2022+ as post-period (2021 = transition year). Note that Eurostat index base year doesn't affect within-country DiD because country×year FE absorb level differences.

### 5. CONTROL SECTOR INSTABILITY [R1, R2]
- Pairwise estimates: +14.6 (C21), +4.7 (C265), -7.8 (C26). Sign reversal.
- **Fix:** Add explicit pre-trend correlation table. Acknowledge the variation more honestly. Argue C265 (measuring instruments) is closest comparator.

### 6. RI DESIGN QUESTIONABLE [R1, R2]
- Permuting sector labels not credible — sectors not exchangeable.
- **Fix:** Acknowledge this limitation explicitly. Present RI as supplementary, not primary. Note that wild bootstrap is the primary small-sample correction.

### 7. DDD WEAKNESS [R1, R2]
- Effectively EU vs Turkey for treated sector. Add sector×year FE concern.
- **Fix:** Demote DDD interpretation. Present as "suggestive" not "corroborating."

### 8. 510(k) COMPARISON [R1, R2]
- Not valid comparator for EU production.
- **Fix:** Demote to appendix context. Remove from main results discussion.

### 9. MECHANISMS SPECULATIVE [R1, R2]
- Label as hypotheses, not established explanations.
- **Fix:** Add "We hypothesize..." framing. Clarify these are consistent interpretations.

### 10. PROSE [Prose Review]
- Opening paragraph too bureaucratic. Data section reads as inventory.
- **Fix:** Already rewrote opening. Clean up data section prose.

### 11. EXHIBITS [Exhibit Review]
- Figure 1 cluttered. EUDAMED fig could go to appendix.
- **Fix:** Already cleaned Figure 1. Keep EUDAMED in main text (supports mechanism discussion).

## Execution Order
1. Add wild cluster bootstrap to 04_robustness.R
2. Add 2022-as-post robustness to 04_robustness.R
3. Update 06_tables.R with new robustness results
4. Retitle paper, soften framing throughout paper.tex
5. Demote 510(k) to appendix
6. Strengthen control-sector justification
7. Soften mechanism language
8. Recompile and verify
