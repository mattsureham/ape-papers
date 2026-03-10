# Internal Review — Round 1

**Paper:** Does Voting Reform Change Who Gets Policed? Evidence from Chile's Transition to Voluntary Voting
**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-10

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:**
- The continuous-treatment DiD with Bartik-style turnout decline is well-motivated and avoids the weak-instrument problems of binary treatment designs.
- The detection gap framework (discretionary vs. non-discretionary crime) provides a built-in falsification test: if the effect were driven by actual crime changes, both categories should move together.
- The exclusion of 2013-2017 (no CEAD data) is handled transparently.

**Concerns:**
- The 6-year gap (2012-2018) between treatment and post-treatment observation is the paper's biggest vulnerability. Confounders accumulating during this gap could explain the results. The paper acknowledges this but relies on the detection-gap pattern as the key defense.
- With only one pre-treatment period (2010, base 2011), the parallel trends test has limited power. The paper's Rambachan-Roth sensitivity analysis partially addresses this.
- Treatment is measured at a single cross-section (2008 vs 2012 turnout). No time-varying confounders are controlled beyond comuna and year FEs.

### 2. Inference and Statistical Validity

- Standard errors clustered at the comuna level (343 clusters) — appropriate.
- Randomization inference (1000 permutations) confirms inference is not driven by cluster structure.
- Sample sizes reported consistently (N=3,061).
- R² values (0.865-0.987) are expected with 343 comuna FEs absorbing cross-sectional variation; drug offenses and homicide have lower R² reflecting greater idiosyncratic variation.

### 3. Robustness

- Leave-one-out, COVID-year exclusion, binary treatment, predicted treatment, and heterogeneity by tercile are all reported.
- The placebo (domestic violence) is null as predicted — a strong falsification.
- Missing: no test for spatial spillovers (crime displacement to neighboring comunas).

### 4. Contribution and Literature

- Paper positions itself as the "reverse Fujiwara" — compulsory→voluntary rather than voluntary→compulsory. This is a clear, novel contribution.
- Literature coverage is adequate for the method and domain. Key citations (Fujiwara 2015, Cascio & Washington 2014, Leon 2017, Levitt 1997, DiTella & Schargrodsky 2004) are present.
- The detection-gap mechanism is the paper's strongest theoretical contribution.

### 5. Results Interpretation

- Drug effect (-0.0471) and homicide effect (+0.0132) are plausibly sized.
- The 81% IQR effect for drugs is large but the paper acknowledges this reflects drug crime's near-total dependence on police detection.
- Policy implications are appropriately cautious.

### 6. Actionable Revision Requests

**Must-fix:**
1. Add mean of dependent variable to Table 2 to help readers interpret economic significance.

**High-value improvements:**
2. Add a brief discussion of spatial spillovers — could crime be displaced rather than reduced?
3. Consider adding a balance table showing pre-reform characteristics are uncorrelated with turnout decline.

**Optional:**
4. Consider splitting Figure 3 (event study) into two panels for visual clarity.
5. Number all appendix tables properly.

### 7. Overall Assessment

**Key strengths:** Novel question with clean identification logic; the detection-gap framework is theoretically motivated and empirically testable; strong falsification (DV placebo); transparent about limitations.

**Critical weaknesses:** The 6-year data gap remains the single most vulnerable point; limited pre-treatment periods constrain parallel-trends testing.

**Publishability:** Strong candidate for AEJ: Economic Policy or Journal of Public Economics after minor revision.

DECISION: MINOR REVISION
