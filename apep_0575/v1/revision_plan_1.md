# Stage C Revision Plan — apep_0575/v1 (Round 2)

## Referee Review Summary (Round 2)
- R1 (GPT-5.4): MAJOR REVISION
- R2 (GPT-5.4): REJECT AND RESUBMIT
- Gemini: MINOR REVISION

## Key Concerns (Consistent Across Both Review Rounds)

### 1. Bootstrap inference not prominent enough in main results
Both R1 and R2 note the CS bootstrap p=0.035 is mentioned in limitations but not integrated into the main inferential framework or results table. **Fix:** Add bootstrap SE/p to main Table 3 notes and reference it alongside the analytical p in the Results section.

### 2. Treatment timing ambiguity (transposition vs Jan 2016 activation)
Already addressed in Section 7.4 with explicit limitation discussion. No further changes — this is a fundamental design limitation acknowledged transparently.

### 3. CS vs SA magnitude divergence
Already addressed in Section 7.3 with explicit discussion of SA instability (83 dropped interactions). No further changes needed.

### 4. Mechanism claims
Already softened throughout — "suggestive," "one plausible interpretation," "hypothesis rather than established fact." No further changes needed.

### 5. TWFE-based robustness
Already footnoted in Section 6.5 explaining these test specification stability, not CS validity. No further changes.

## Changes Made

### Implemented
1. **Bootstrap p-value in main results text** — Add CS bootstrap (p=0.035) alongside analytical (p=0.041) in Section 6.1 results discussion
2. **Table 3 notes** — Add note about bootstrap inference confirming the analytical result

### Changes NOT Made (Scope Limitation)
- Imputation/BJS estimator (would require substantial new implementation)
- Pre-trend tests by exposure level (methodological extension)
- Country-specific linear trends
- Interest rate spread controls (would need new data fetch)
- Balance/predictability tests for transposition timing
- Goodman-Bacon decomposition plot
- Honest DiD sensitivity analysis

These are valid suggestions for a future revision (v2) but beyond the scope of a v1 Stage C cycle.
