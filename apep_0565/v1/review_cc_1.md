# Claude Code Internal Review

**Role:** Internal self-review (Reviewer 2 mode)
**Paper:** Education Thresholds and Labour Market Gaps in South Africa
**Round:** 1
**Timestamp:** 2026-03-09T21:30:00

---

## PART 1: CRITICAL REVIEW

### 1. IDENTIFICATION AND EMPIRICAL DESIGN

The paper is transparent that current results are descriptive, not causal (p. 3, Abstract). The multi-cutoff RDD framework (Section 5) is well-specified with binding-constraint running variable and centralized blind marking. The design is a credible blueprint for future causal work with individual-level NSC microdata.

**Strengths:**
- Honest framing as descriptive + RDD blueprint rather than claiming causality from aggregate data
- Mechanical, formula-based thresholds ideal for sharp RDD
- Binding-constraint running variable definition handles multi-cutoff setting

**Concerns:**
- The re-marking discussion (Section 2.3) could further quantify the scale of re-marking applications to assess manipulation risk
- Power calculations for the proposed RDD are absent — given DataFirst sample sizes, what MDE is achievable?

### 2. INFERENCE AND STATISTICAL VALIDITY

- Standard errors are reported for key descriptive differences (20 pp employment gap: SE=0.7; 5.5 pp within-matric: SE=0.9; 17 pp earnings: SE=0.5)
- Oster (2019) bounds are well-documented (δ=3.2, R²max=0.20 vs baseline R²=0.05)
- Provincial trends include SEs (Table 5)
- Large QLFS samples make descriptive differences mechanically significant — paper appropriately notes this

### 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS

- COVID-19 natural experiment (Section 7.2) strengthens descriptive case
- Cross-country comparison effectively rules out universal middle-income phenomenon
- NSFAS funding confounder is discussed (Section 3) but could be more prominent
- Occupational sorting mechanism needs more discussion

### 4. CONTRIBUTION AND LITERATURE POSITIONING

- Good bridge between international RDD literature (Zimmerman 2014, Clark and Martorell 2014) and South African labor economics (Banerjee et al. 2008)
- Contribution paragraph clearly states three literatures the paper contributes to
- Missing: Bhorat and Leibbrandt (2001) on SA returns to education

### 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION

- Effect magnitudes are honestly described as upper bounds
- Policy implications appropriately cautious (capacity constraints noted)
- The five-fold earnings differential is striking but well-contextualized

### 6. ACTIONABLE REVISION REQUESTS

#### Must-Fix
1. Add power calculation for proposed RDD (what MDE given plausible DataFirst sample?)

#### High-Value
1. Quantify re-marking scale (DBE annual reports have these numbers)
2. Add occupational distribution table by credential type

#### Optional
1. More granular COVID analysis (by sector)

### 7. OVERALL ASSESSMENT

**Strengths:** Excellent institutional knowledge, honest framing, promising RDD blueprint, strong cross-country comparison.

**Weaknesses:** Descriptive-only evidence limits contribution; power analysis for proposed RDD missing.

**Publishability:** Suitable for a field journal (Journal of Development Economics, Economics of Education Review) in current form. AER/QJE would require the actual RDD execution.

**DECISION: MINOR REVISION**
