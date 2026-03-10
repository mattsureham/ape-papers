# Internal Review - Round 1

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design
The sharp RDD at the 75% GDP/capita threshold is well-motivated and follows the established Becker-Egger-von Ehrlich tradition. The running variable (2008-2010 average GDP/cap as % of EU27) matches the institutional rule exactly. Key strengths:
- McCrary density test (p=0.97) shows no manipulation
- Covariate balance tests pass on all three pre-determined variables
- The clarification that the RDD estimates above-vs-below (not restricted to graduates) is important and well-articulated

Concerns:
- The sample includes candidate countries not subject to ERDF. While the LOCO analysis shows robustness, a restricted sample would be cleaner.
- The donut specifications show sign instability — this is acknowledged but remains a concern for the identification near the cutoff.

### 2. Inference and Statistical Validity
- Standard errors are robust bias-corrected (CCT procedure) — appropriate for RDD
- The main estimate is imprecise (p=0.17), which the paper is honest about
- The event study provides complementary evidence with better precision at longer horizons
- Sample sizes are properly reported (N=140 estimation sample, ~36 effective within bandwidth)

### 3. Robustness
- Bandwidth sensitivity shows consistent negative sign across 5-25pp range
- Polynomial sensitivity shows larger effects at higher orders
- Placebo cutoffs show no significant effects
- LOCO analysis is thorough
- Donut sign flip at ±2-3pp is the main weakness — adequately explained but still concerning

### 4. Contribution and Literature
- Clear differentiation from Becker et al. (2010, 2013, 2018, 2023) — they study receipt, this studies withdrawal
- Good positioning relative to Garcia-Mila & Ponce (2023) on persistence
- Manufacturing channel ties to Rodriguez-Pose & Fratesi (2004)

### 5. Results Interpretation
- Claims appropriately calibrated given imprecision
- "Economically large but statistically imprecise" framing is honest
- Policy implications are proportional to evidence

## PART 2: CONSTRUCTIVE SUGGESTIONS
1. Consider restricting sample to EU member states only for main specification
2. Heterogeneity by institutional quality (per Rodriguez-Pose & Garcilazo 2015)
3. First-stage regression showing ERDF payment discontinuity formally

## 6. ACTIONABLE REVISION REQUESTS
1. Must-fix: None identified
2. High-value: Formal first-stage table; EU-only sample as robustness
3. Polish: Minor exhibit improvements per exhibit review

## 7. OVERALL ASSESSMENT
- **Strengths:** Novel withdrawal angle, clean RDD design, compelling event study, honest about limitations
- **Weaknesses:** Statistical imprecision of main RDD, donut fragility, candidate countries in sample
- **Publishability:** Suitable for AEJ: Economic Policy after minor revision

DECISION: MINOR REVISION
