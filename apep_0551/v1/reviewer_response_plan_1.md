# Reviewer Response Plan — Round 1

## Summary of Feedback

Three external referees reviewed the paper:
- **GPT-5.4 R1:** REJECT AND RESUBMIT — Pre-trends fatal for causal claims; need reframing
- **GPT-5.4 R2:** REJECT AND RESUBMIT — Same core concerns; need historical treatment data
- **Gemini-3-Flash:** MAJOR REVISION — Pre-trends and OLS/PPML discrepancy must be addressed

## Common Themes

1. **Pre-trend violation is decisive** — cannot claim causal effect of Loi 2003
2. **Treatment measured with current, not historical, Seveso counts** — measurement concern
3. **No first-stage evidence** linking Seveso density to actual inspector expansion
4. **OLS vs PPML discrepancy** — PPML insignificant; count models should be primary
5. **Mechanism claims too strong** — cannot distinguish inspector detection from other channels
6. **Paper should be reframed** as measurement/diagnostic rather than causal evaluation

## Revision Plan

### Must-Fix (Implemented)

1. **Reframe as measurement paper**
   - Rewrite abstract: all causal language removed
   - Rewrite introduction: frame as documenting measurement problem
   - Rewrite conclusion: moderate all policy claims
   - Change title: "Detection or Deterrence? A Measurement Problem in Enforcement-Generated Safety Data"

2. **Add trend-addressing specifications**
   - Department-specific linear trends (eliminates effect: β = -0.36)
   - Region × year fixed effects (effect persists: β = 3.33)
   - Narrow window 1998-2006 (insignificant: β = 1.82)

3. **Strengthen PPML presentation**
   - Full PPML decomposition (total, minor) in robustness table
   - Substantive discussion of OLS/PPML discrepancy

4. **Recalibrate all causal language**
   - Replace "effect" with "association" throughout
   - Replace "precisely estimated null" with power-qualified language
   - Narrow mechanism claims to "reporting/detection expansion"

5. **Expand literature**
   - Add Roth (2022), Rambachan-Roth (2023), Goldsmith-Pinkham et al. (2020), Borusyak et al. (2022), de Chaisemartin-D'Haultfoeuille (2020), Johnson (2020)

### Acknowledged as Limitations (Cannot Fix)

- Historical Seveso counts not available in public registries
- Department-level inspector allocation data not publicly available
- Plant-level linkages require non-public data
