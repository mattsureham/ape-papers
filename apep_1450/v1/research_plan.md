# Research Plan: The 75th Percentile Penalty

## Research Question
Is the HACRP 1% Medicare payment penalty — imposed on hospitals scoring above the 75th percentile of the Total HAC Score — informative about underlying hospital quality at the margin? Or does the penalty threshold amount to a lottery among statistically indistinguishable hospitals?

## Identification Strategy
**Sharp RDD** at the 75th percentile of the Total HAC Score distribution. The running variable is a z-score composite of 7 HAC measures (CLABSI, CAUTI, SSI colon, SSI hysterectomy, MRSA bacteremia, C. diff, patient safety composite). Hospitals above the cutoff lose 1% of all Medicare DRG payments.

Key validity arguments:
1. **Peer-referenced z-score**: A hospital's score depends on the entire distribution, making precise manipulation extremely difficult
2. **Composite of 7 measures**: Gaming one component doesn't guarantee crossing the threshold
3. **Confirmed sharp**: FY2026 gap between last non-penalized and first penalized is 0.0007

**Specification**: For each fiscal year t, estimate:
Y_{i,t+1} = α + τ·1(Score_{it} > p75_t) + f(Score_{it} - p75_t) + X_i + ε_{it}

where Y is next-year HAC performance, τ is the causal penalty effect, f(·) is a local polynomial, and X_i are hospital characteristics.

**Cross-sectional design**: FY2026 HACRP data only (historical archived data unavailable from CMS). Test informativeness of penalty at the margin using contemporaneous quality outcomes. The affected population (treatment-eligible) is the worst-performing 25% of hospitals by Total HAC Score; exposure is the 1% Medicare payment reduction.

## Expected Effects and Mechanisms
- **Direct quality improvement**: Penalized hospitals invest in infection prevention → lower HAC rates (τ < 0)
- **Reporting response**: Hospitals near the cutoff may improve coding/reporting without real quality gains
- **Reversion to mean**: Mechanical concern — hospitals at the margin may naturally regress. Address with donut-hole RDD and lagged outcomes
- **Spillover**: Penalty revenues fund Medicare trust fund, not competing hospitals — no strategic interaction

## Primary Specification
Local linear RDD with MSE-optimal bandwidth (Calonico-Cattaneo-Titiunik 2014). Triangular kernel. Bias-corrected robust confidence intervals.

## Data Sources
1. **CMS HACRP Hospital Results** (FY2026): Total HAC Score, domain scores, penalty indicator. CMS Provider Data API.
2. **CMS Hospital General Information**: Ownership, emergency services, star ratings. CMS Provider Data API.
3. **CMS HAI Hospital Data**: Individual SIRs (CLABSI, CAUTI, SSI, MRSA, C.diff). CMS Provider Data API.

## Fetch Strategy
1. Fetch FY2026 HACRP results via CMS Provider Data API (POST, paginated at 1500/page)
2. Fetch hospital info and HAI measures via same API
3. Merge on CCN (as character)
4. Cross-sectional RDD: penalty assignment → contemporaneous quality outcomes
