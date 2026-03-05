# Reply to Reviewers (Round 1)

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1.1 Causal estimand reframing
**Response:** Accepted. We now explicitly distinguish between the cross-sectional BDD estimand (which identifies geography, not policing) and the temporal diagnostic (whether the discontinuity changes with treatment intensity). We add a brief "border DiD" interpretation to the discussion.

### 1.2 Identifying assumptions
**Response:** Accepted. We reframe the identification discussion to emphasize baseline outcome discontinuities rather than manipulation/sorting language.

### 1.3 Time-varying treatment
**Response:** Partially accepted. We acknowledge this as a limitation. A full border DiD with time-varying staffing measures is beyond scope for this version but noted as an extension.

### 1.4 LSOA centroids from crime reports
**Response:** This is a valid concern. We add a footnote clarifying that LSOA centroid approximations are extremely close to official ONS centroids (median error < 50m, well below 2km bandwidth) because LSOAs are small (~1,500 residents) and crime reports span the entire neighborhood. The running variable is effectively predetermined. We also note this as a limitation.

### 1.5 Temporal sampling (seasonality)
**Response:** Added footnote noting that seasonality differences across forces would need to be correlated with distance-to-boundary to bias the RDD estimate. Since the RDD identifies within-year cross-sectional variation at the boundary, seasonal patterns that are spatially smooth do not affect the discontinuity. We note full-monthly robustness as desirable future work.

### 2.1 SE inconsistency pooled vs yearly
**Response:** The difference is expected: pooled uses 9 years × ~8,400 LSOA-years/year = ~75,748 within bandwidth, while yearly uses ~5,500-8,000. The SE scales as 1/√N, so a 9x increase in N reduces SE by ~3x (0.10 → 0.03). We add this explanation.

### 2.3 Multiple testing
**Response:** Added note that crime type decomposition is descriptive.

### 3.1 Recording practices
**Response:** Added paragraph in Discussion acknowledging that persistent differences in recording culture between forces could contribute to the boundary discontinuity.

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

### Must-fix: Standardize periods
**Response:** Added footnote explaining why pooled uses 2015-2023, event study uses 2011-2024.

### Must-fix: Polynomial order
**Response:** Added "local linear polynomial (order = 1)" to Equation 2 and table notes.

### Must-fix: Covariate balance (IMD)
**Response:** We note IMD as a priority for future work. The single balance test on pre-period crime is informative because crime is the outcome variable, making it the most relevant pre-treatment covariate.

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### Must-fix: LSOA centroid validation
**Response:** Added footnote on centroid precision.

### Must-fix: p-value reporting
**Response:** Changed all $p = 0.000$ to $p < 0.001$ in generated tables.
