# Reply to Reviewers — Round 1

## GPT-5.4 (R1): REJECT AND RESUBMIT

### 1A. Limited pre-period for early lines
**Response:** We agree this is the most serious limitation. We have added explicit acknowledgment in Section 4.5 (Threats to Identification) that commune FE do not guarantee within-commune spatial parallel trends, and that our estimates should be interpreted as "suggestive evidence of construction disamenity, conditional on the maintained assumption of within-commune spatial parallel trends." We have tempered causal language throughout (abstract, introduction, conclusion). Sub-commune FE (IRIS or grid-cell) would strengthen the design but are beyond the scope of this version.

### 1B. Parallel trends not established
**Response:** We acknowledge that only later-treated cohorts contribute to pre-treatment event-study coefficients. The event study is informative for Lines 18, 15W, and 15E but not for Lines 14S, 15S, 14N, 16, or 17. We have added discussion of this limitation.

### 1C. Treatment timing coarseness
**Response:** Station-level milestone data would be ideal. We use line-segment-level timing because SmartIDF reports this granularity. We have noted this as a limitation.

### 1D. Control group / within-commune trends
**Response:** We have substantially expanded Section 4.5.1 to discuss within-commune spatial heterogeneity as the most serious potential confound. We explicitly note that station-proximate areas may be redevelopment nodes, existing transit hubs, or targets of concurrent urban renewal.

### 1E. Phase decomposition weakly identified
**Response:** We have sharply tempered the post-opening discussion, noting it is based on a single line with two quarters of data and should be regarded as "exploratory." We removed the detailed mechanistic interpretation.

### 2A-2E. Inference concerns
**Response:** We have added a caveat about CS implementation limitations (within-commune aggregation blurs treatment contrast) and now present CS as "suggestive only" rather than a validation of TWFE.

### 3A-3E. Robustness concerns
**Response:** We acknowledge that LOLO does not address local trend confounders. We have tempered mechanism claims to "hypotheses" and qualified the welfare calculations as "illustrative upper-bound scenarios."

### 5A-5D. Claim calibration
**Response:** Abstract now presents the result as an "association" under a spatial DiD design rather than a settled causal claim. CS is described as "directionally consistent but imprecise" with p-value stated explicitly. Welfare calculations are explicitly labeled as speculative upper bounds.

---

## GPT-5.4 (R2): REJECT AND RESUBMIT

### 1A. Design credibility / pre-period
**Response:** Same as R1-1A. Causal language tempered throughout.

### 1B. Selection into transaction
**Response:** We have reframed the estimand as a "transaction-price effect" in the abstract and conclusion, distinguishing it from stock-value effects. Section 7.1 now more explicitly acknowledges that hedonic controls cannot fully address selection on unobserved quality.

### 2A-2D. TWFE as primary estimator
**Response:** We agree that heterogeneity-robust estimators would strengthen the paper. We have added honest discussion of CS implementation limitations and present TWFE with appropriate caveats about staggered-design concerns.

### 3A-3E. Robustness limitations
**Response:** We have tempered mechanism language, qualified welfare calculations, and added explicit caveats throughout.

---

## Gemini-3-Flash: MINOR REVISION

### 1. 500m vs 1km discrepancy
**Response:** Already discussed in Section 7.2 (Noise and Disruption Channels). We note that the non-monotonicity is within confidence intervals and may reflect sample size, overlapping catchments, or pre-construction demolition removing observations.

### 2. Separate always-treated vs staggered-treated
**Response:** The LOLO analysis provides partial evidence—Lines 14S and 15S are always-treated. Dropping them yields estimates of -7.0% to -7.5%, similar to the full-sample result.

### 3. Interaction with baseline prices
**Response:** This is an interesting extension that we note for future work.

---

## Prose Review (Gemini)

Applied the following suggestions:
1. **Replaced opening sentence** with a hook ("Major transit projects promise to transform cities, but first they must break them.")
2. **Humanized the magnitude** in the introduction (€22,000 loss figure moved to paragraph 3)
3. **De-cluttered results text** by removing column-by-column narration
4. **Strengthened conclusion** with Shleifer-style closing sentence
