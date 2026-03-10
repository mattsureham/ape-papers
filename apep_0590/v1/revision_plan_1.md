# Revision Plan — apep_0590 v1

## Reviews Summary
- GPT-5.4 R1: REJECT AND RESUBMIT
- GPT-5.4 R2: REJECT AND RESUBMIT
- Gemini-3-Flash: MAJOR REVISION

## Key Issues (All Three Reviewers)

### 1. Inference Level Mismatch (CRITICAL — all 3 reviewers)
Treatment varies at state level but CS-DiD bootstrap resamples at municipality level.
**Fix:** Add acknowledgment in empirical strategy; note this strengthens the paper's conclusion since even with possibly understated SEs, the pre-trend violation is the binding constraint on causal interpretation.

### 2. Section 5.1 Argues for ID Then Revokes (R1, R2)
**Fix:** Remove claims that rollout supports parallel trends. Present design as exploratory from outset.

### 3. Treatment Too Coarse (R1, R2)
State-level treatment when actual eligibility is municipality-level.
**Fix:** Add explicit discussion of ITT interpretation and limitations.

### 4. Additional Estimators (R1, R2)
Sun-Abraham, Borusyak-Jaravel-Spiess would strengthen methods contribution.
**Fix:** Add references and note as future work (v2 revision candidate).

### 5. Common Support Diagnostics (R2)
**Fix:** Strengthen existing overlap discussion; the paper already documents this well.

### 6. Move Figures to Main Text (Exhibit Review)
**Fix:** Move treatment map and event study to main text.

### 7. Prose Tightening (Prose Review)
**Fix:** Apply top 3 suggestions.

## Implementation Plan
1. Rewrite Section 5.1 — remove pro-identification arguments
2. Add inference discussion (clustering concern)
3. Add ITT/treatment-coarseness discussion
4. Move Figures 1, 3 to main text
5. Add missing references
6. Tighten framing in abstract, intro, conclusion
7. Recompile and publish
