# Revision Plan

## Priority 1: Address Key Reviewer Concerns

### 1. CS-DiD Discrepancy (all 3 reviewers)
- Add explicit discussion that CS-DiD uses never-treated only controls
- Add footnote on CS group-specific ATTs showing Arizona drives the negative result
- Note that restricting CS to cohorts with post-treatment data yields positive estimates
- Position TWFE + SA as preferred given Bacon clean weight (91%)

### 2. Prose Improvements (prose review)
- Sharpen opening sentence with paradox framing
- Tighten introduction: lead with result magnitude, minimize CS-DiD apologetics
- Active voice in data section

### 3. Exhibit Improvements (exhibit review)
- Define "FA" and "NF" in Table 3 notes
- Minor: improve figure axis labels where feasible

### 4. Temper Claims (GPT reviewer)
- Soften "mechanism confirmed" to "consistent with mechanism"
- Add uncertainty range to welfare calculation
- Note multiple testing informally

## Not Addressing (out of scope for v1)
- Wild cluster bootstrap (would require code changes)
- Borusyak et al. imputation estimator (new package)
- State-specific linear trends (methodologically controversial)
- Synthetic control (entire new analysis)
- Policy bundling controls (data not available)

These are appropriate suggestions for a v2 revision if the paper enters that stage.
