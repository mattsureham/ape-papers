# Revision Plan 1

## Stage C Revision Plan (Post-Referee Reviews)

### Reviews Received
- **GPT-5.4 (R1):** REJECT AND RESUBMIT — broad control group, WCB p=0.107, RI not design-consistent, need formal pre-trends
- **GPT-5.4 (R2):** REJECT AND RESUBMIT — overlapping concerns with R1, plus population magnitude, outcome definition
- **Gemini-3-Flash:** MINOR REVISION — reconcile population vs vacancy magnitudes, RDD power

### Priority Revisions

1. **Canton-by-year FEs** (addresses differential Alpine shocks): Run TWFE with canton×year interactions. Result: -0.49 pp (p=0.012), stronger than baseline.

2. **Near-threshold local DiD** (addresses control group breadth): Restrict to 10-30% second-home share. Result: null (-0.02, p=0.83), consistent with dose-response mechanism.

3. **Formal pre-trends test** (addresses parallel trends concern): Joint Wald test F=112.4, p<0.001 — statistically significant but driven by power over 15+ coefficients with N>37K. Reported honestly.

4. **Soften claims throughout**: Abstract now includes WCB p-value, welfare section rewritten to remove speculative rent-increase calculation, policy extrapolation narrowed.

5. **Sample selection transparency**: Added explanation for 2100→1301 reduction.

6. **Vacancy definition clarification**: Added note that vacancy includes for-sale units.

7. **RI caveat**: Added note that unrestricted permutation may overstate significance.

### What We Did NOT Change
- Did not fundamentally redesign the DiD (matched controls, border comparisons) — these would require a revision cycle
- Did not obtain rental-specific data — not available at municipality level in Switzerland
- Did not compute within-canton RI — computationally intensive and would require new code infrastructure
