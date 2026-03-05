# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1. Interpretation inconsistency: Black overrepresentation + positive effect = widening gap
**Response:** This was the most important criticism. The paper erroneously described the +1.28pp effect as a "14% reduction" in the gap when Blacks are already overrepresented (47% vs 38%). We have:
- Removed all "reduction in the gap" language
- Reframed the abstract, introduction, Section 6.2, Discussion, and Conclusion to honestly state that the effect *widens* Black overrepresentation
- Added discussion of two interpretations: (a) grooming barriers excluded from *higher-status* customer-facing jobs, so the effect reflects expansion within the category; (b) the shift from professional to customer-facing could represent downgrading
- Noted this cannot be resolved without finer occupational data

### 2. TWFE triple-diff in staggered setting
**Response:** We acknowledge this as a limitation (new 5th limitation paragraph). We note that the Bacon decomposition shows 82% clean weight, but heterogeneity-robust DDD estimators are methodologically nascent. The CS-DiD vs triple-diff discrepancy (0.5pp vs 1.28pp) is now discussed more honestly as possibly reflecting different estimands, not just power differences. We suggest stacked DDD as future work.

### 3. Treatment timing: calendar-year coding
**Response:** Already discussed in Section 4.2 as conservative attenuation. Adding exposure-weighted coding would require re-running all analysis, which we note as future work.

### 4. Puerto Rico
**Response:** Added a paragraph in Threats to Validity explaining PR's inclusion and noting results are qualitatively unchanged when excluded.

### 5. Missing occupation cells / Census suppression
**Response:** Added paragraph in Threats to Validity discussing that suppression is driven by small Black populations in never-treated states (Wyoming, Vermont, Montana), suggesting minimal bias risk. Recommend PUMS microdata as the definitive solution.

### 6. Multiple testing
**Response:** Added paragraph in Robustness section noting the customer-facing result survives Bonferroni correction (p < 0.0125) while the professional share result does not and should be treated as suggestive.

### 7. Move to ACS microdata
**Response:** Acknowledged throughout as the most important extension for future work. This is beyond the scope of this version but noted in limitations and conclusion.

### Not addressed (deferred to future revision):
- Wild cluster bootstrap (requires re-running R code)
- Stacked DDD / heterogeneity-robust DDD estimator
- Industry composition × year controls
- HonestDiD pre-trend sensitivity analysis
- O*NET customer-contact intensity measures

---

## Reviewer 2 (Grok-4.1-Fast): MAJOR REVISION

### 1. Sign/interpretation mismatch (same as GPT #1)
**Response:** Fully addressed. See response to GPT #1 above.

### 2. Triple-diff event study needed
**Response:** Acknowledged as a limitation. Implementing dynamic DDD requires code modifications beyond the current revision scope. Noted in limitations.

### 3. Refine mechanism evidence (PUMS, finer SOC)
**Response:** Acknowledged as the most important extension. Cannot be done with Summary Tables.

### 4. RI/Bacon for occupation outcomes
**Response:** Noted as a high-value improvement for future work.

### 5. PR/DC clarification
**Response:** Added to Threats to Validity.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### 1. Address CS-DiD vs triple-diff estimate discrepancy
**Response:** Substantially expanded discussion in Section 6.2, noting the point estimate difference (not just SE) suggests different estimands, not just power. Added discussion of what race-by-year FEs absorb and why this matters during COVID recovery.

### 2. Professional share decrease
**Response:** Now discussed as part of the interpretation concern throughout the paper. Noted that the welfare interpretation depends on whether this is downgrading or reallocation.

### 3. Enforcement heterogeneity
**Response:** Already discussed in limitations (now 6th limitation). A formal private-right-of-action split would require additional data collection.

### 4. Earnings by occupation
**Response:** Noted as future work. Table B24011 could provide this but was not included in the original data pull.
