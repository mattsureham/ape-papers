# Revision Plan 1 — apep_0600/v1

## Reviewer Verdicts
- GPT-5.4 R1: MAJOR REVISION
- GPT-5.4 R2: MAJOR REVISION
- Gemini-3-Flash: MINOR REVISION

## Key Changes (Prioritized)

### 1. Recalibrate "precise null" framing (ALL reviewers)
- Replace "precise null" throughout with "informative null" or "no evidence of economically large effects"
- Acknowledge SA-IW imprecision explicitly; frame TWFE as secondary benchmark
- Soften abstract, results, and conclusion language

### 2. Remove/redo MDE section (GPT R1, R2)
- Remove back-of-envelope MDE calculation (0.05pp claim is not credible given SE=0.115)
- Replace with CI-based discussion: "The TWFE 95% CI of [-0.24, 0.21] rules out effects larger than ~0.2pp"
- Frame detectable range honestly

### 3. Add TWFE on balanced 16-country panel (GPT R1, R2)
- Run TWFE on exact same 768 obs as SA-IW for apples-to-apples comparison
- Add to robustness table
- Explain remaining SE discrepancy (methodology, not sample)

### 4. Add country-specific linear trends (GPT R1, R2)
- Add `country:year` linear trends to TWFE specification
- Report as robustness check
- If null holds, strengthens identification

### 5. De-emphasize house prices (ALL reviewers)
- Move HPI results out of main Table 2
- Create appendix table for HPI
- Frame as "descriptive evidence" with explicit caveat about failed pre-trends
- Keep Figure 3 in appendix as evidence of pre-trend violation

### 6. Soften title (GPT R1, R2)
- Change from "The Regulatory Non-Event" to something more calibrated
- Options: "Harmonization Without Bite?" or "When Harmonization Codifies the Status Quo"

### 7. Rewrite opening (Prose review)
- Start with stakes/puzzle, not bureaucratic history
- More active voice throughout abstract

### 8. Move Figures 5 & 6 to appendix (Exhibit review)
- Figure 5 (consumer placebo) → Appendix
- Figure 6 (RI histogram) → Appendix
- Reduces main text figure clutter

### 9. Improve table notes (Exhibit review)
- Table 1: Add note on N = country-month vs country-quarter
- Table 2: Add FE indicator rows, footnote about HPI pre-trend contamination

### 10. Add missing literature citations (GPT R1, R2)
- Callaway and Sant'Anna (2021)
- Roth et al. (2023) on pre-trends
- Borusyak, Jaravel, Spiess (2024)

## Changes NOT made (with rationale)
- Alternative treatment dates: Data limitation — only notification dates available systematically
- Regulatory gap index: Requires article-by-article legal coding beyond scope
- Expanding outcomes to volumes/approvals: Harmonized micro-data unavailable
- 1000+ RI permutations: 500 is standard for cross-country studies
