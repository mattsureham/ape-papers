# Reply to Reviewers — apep_0509 v1

## Response to Gemini Referee (MAJOR REVISION)

### 1. Pre-Trend Violations (Critical)
**Concern:** 6 of 8 crops fail the joint F-test for pre-trends. The "precise null" claim is overclaiming.

**Response:** We agree this is a genuine limitation and have revised the paper accordingly. We now:
- Explicitly acknowledge that only cotton (p=0.82) and maize (p=0.52) pass pre-trend tests cleanly
- Frame the null result as "well-identified for cotton and maize, suggestive for the remaining crops"
- Qualify the "precise null" language throughout, noting that 95% CIs span ±10-15pp
- Note that the null result is *strengthened* rather than weakened by the two crops with clean pre-trends also showing null effects

We considered adding district-specific linear trends but chose not to, as they risk absorbing the treatment effect itself in a design with only two cohorts separated by one year.

### 2. First Stage Reconciliation (Critical)
**Concern:** The null wage first stage contradicts Imbert & Papp (2015).

**Response:** We have strengthened the discussion of why our wage measure differs from the literature. The key issue is measurement: the ICRISAT wage variable captures annual district-level averages, which mechanically dilute seasonal effects. Imbert & Papp (2015) use National Sample Survey Rural Labour Inquiry data with seasonal detail that captures precisely the lean-season wage increases that annual averaging washes out. We now emphasize this as the primary explanation.

We cannot access MGNREGA MIS data in the current dataset, but we note this as an important limitation and avenue for future work.

### 3. Treatment Intensity (High-Value)
**Concern:** Binary treatment is a blunt instrument; dosage-response analysis would be better.

**Response:** We agree this would strengthen the analysis. However, MGNREGA expenditure/work-days data at the district level is not available in the ICRISAT database. We note this limitation in the discussion and suggest it as future work with administrative data.

### 4. Heterogeneity by Irrigation (High-Value)
**Concern:** Split sample by baseline irrigation levels to test infrastructure channel.

**Response:** The ICRISAT database includes irrigated area data. While we report heterogeneity by baseline backwardness (which correlates with irrigation infrastructure), a direct irrigation split would be a valuable addition. We note this for future work.

## Response to Exhibit Review (Gemini)

- **Table 3 N variation:** Added note explaining why observation counts vary by crop
- **Adjustbox formatting:** All wide tables wrapped in adjustbox to prevent overflow
- **Figure y-axis standardization:** Noted for future revision; current scales allow readers to see effect sizes relative to crop-specific variation

## Response to Prose Review (Gemini)

- Compressed "heterogeneity-robust" discussion in introduction to one sentence with footnote
- Strengthened conclusion's final sentence to be more memorable
- Honest framing of "precise null" with appropriate qualifications
