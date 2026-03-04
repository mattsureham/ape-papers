# Reply to Reviewers

## GPT-5.2 (Major Revision)

### 1. Temporal placebo undermines causal claims
**Response:** Agreed. We have downgraded causal language throughout the paper to "association" and "descriptive evidence." The abstract, introduction, and conclusion now explicitly state that the temporal placebo precludes confident causal attribution. We add a formal comparison: the placebo coefficient (-0.0385) is 80% of the main estimate (-0.0478), and the difference is not statistically significant.

### 2. Treatment timing misalignment (Post = Jan 2025 vs election effect)
**Response:** We clarify in the text that the pooled estimate averages over the full post-period, while the announcement decomposition shows the effect concentrates at the election. The abstract now explicitly notes this distinction.

### 3. LA-level treatment intensity too coarse
**Response:** Valid concern. We note this as a limitation and show robustness to continuous treatment (Column 4). Future work with finer-grained data (e.g., MSOA-level) could improve precision.

### 4. "Near good school" ≠ "access to good school"
**Response:** Acknowledged as a limitation. We note that admissions criteria in England are complex and the 3km radius is a proxy. The distance sensitivity analysis (1km to 10km) provides some validation of the spatial pattern.

### 5. GIAS post-treatment extract
**Response:** We add explicit defense that school locations are near-invariant over 14 months, and note this as a limitation. The treatment ranking is based on school counts and locations, not pupil flows.

### 6. Clustering may understate uncertainty
**Response:** Valid concern. We note the 131 LA clusters and acknowledge that spatial correlation across LAs could inflate precision. This is flagged in limitations.

### 7. MDE calculation
**Response:** We acknowledge the MDE should be computed at cluster level, not individual level. This is noted as a caveat.

## Grok-4.1-Fast (Major Revision)

### 1. Pre-trends failure (same as GPT #1)
**Response:** See above. Language downgraded throughout.

### 2. Missing literature (Callaway-Sant'Anna, Roth)
**Response:** We add a citation to Callaway and Sant'Anna (2021) in the HonestDiD section, noting that future work with longer data could apply more sophisticated trend-robust estimators.

### 3. HonestDiD on DDD
**Response:** We note that the Rambachan-Roth framework is not implemented for triple-difference event studies. The DD analysis is presented as suggestive evidence of sensitivity.

## Gemini-3-Flash (Major Revision)

### 1. Placebo/pre-trend test
**Response:** We add a formal comparison showing the placebo and main effect are not statistically distinguishable. Language downgraded accordingly.

### 2. London vs National
**Response:** We expand the heterogeneity discussion to note that the non-London result is insignificant, raising the concern that the result may be driven by London-specific dynamics (post-COVID suburbanization, international buyer withdrawal).

### 3. Boundary discontinuity design
**Response:** Acknowledged as a high-value extension for future work. Current data does not include school catchment boundaries.
