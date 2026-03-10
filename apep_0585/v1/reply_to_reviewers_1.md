# Reply to Reviewers

## Response to GPT-5.4 (R1): Reject and Resubmit

### 1A. Treatment misclassification (NACE C325 vs MDR scope)
**Concern:** MDR applies to products by intended medical use, not by NACE code. C325 may miss some treated products; controls (C26, C265) may contain MDR-regulated devices.

**Response:** We acknowledge this limitation. NACE C325 is the best available sectoral proxy for medical device production in Eurostat data. While some medical devices may appear in C26 (e.g., electromedical equipment), the bulk of the sector—surgical instruments, implants, dental devices—maps to C325. Any treatment misclassification would bias our estimates toward zero, making our null result conservative. We have added explicit discussion of this in the Threats to Validity section and now frame our contribution as evidence on "aggregate NACE C325 production" rather than "innovation" broadly.

### 1B. Treatment timing (2021 as both treatment year and index base)
**Concern:** Using 2021=100 indexed data where 2021 is also the treatment year creates mechanical normalization issues.

**Response:** The index base year does not affect the DiD estimator in our specification: country-by-year fixed effects absorb any level normalization common to all sectors within a country-year. Nevertheless, we now report a robustness specification coding 2022+ as post-treatment (treating 2021 as a transition year). The estimate is β=2.569 (p=0.74)—qualitatively identical and, if anything, closer to zero. This is now reported in both the Threats to Validity section and the Robustness section.

### 1C. Thin identifying variation
**Concern:** Only six EU countries report C325; the broader sample overstates effective power.

**Response:** We agree that the treatment coefficient is identified by within-country C325-vs-controls variation in the six reporting countries. We have revised the text to be more transparent about this.

### 1D. Parallel trends weakly assessed
**Concern:** Few pre-periods, annual data, low power for pre-trend tests.

**Response:** Acknowledged. We now describe the pre-trend evidence more carefully, noting that failure to reject is necessary but not sufficient for identification.

### 1E. DDD not credible
**Concern:** Effectively EU vs Turkey only.

**Response:** We have softened the DDD interpretation substantially, now presenting it as "suggestive" and noting it "lacks the statistical power to distinguish between a wide range of effect sizes."

### 2A. "Precisely estimated null" overclaim
**Concern:** 95% CI [-11, +19] is not precise.

**Response:** We have replaced "precisely estimated null" with "no statistically detectable effect" throughout the abstract, introduction, results, and conclusion. We now explicitly note what sizes we can and cannot rule out.

### 2B. Standard error strategy
**Concern:** Need wild cluster bootstrap with few clusters.

**Response:** Added wild cluster bootstrap with Rademacher weights (999 iterations). Bootstrap p-value = 0.63, confirming the cluster-robust inference.

### 2C/2D. RI and sample size
**Concern:** RI not credible; sample sizes misleading.

**Response:** We now explicitly acknowledge that sector exchangeability is not fully credible and present RI as supplementary, with wild cluster bootstrap as the primary small-sample correction.

### 3. Robustness gaps
**Response:** Added wild bootstrap and 2022-as-post specifications. Acknowledged control-sector instability more honestly.

### 4. Contribution framing
**Response:** Retitled to "Short-Run Production Effects." Reframed throughout as evidence on aggregate production volume, not innovation.

### 5. Claim calibration
**Response:** Softened all overclaiming language. Policy implications now explicitly note that we cannot address variety, SME burden, certification delays, or post-2027 effects.

---

## Response to GPT-5.4 (R2): Major Revision

R2's concerns substantially overlap with R1's. Key additional points:

### 1.3. Index normalization
**Response:** See R1 §1B above. Added 2022-as-post robustness and explained why country-by-year FE absorb the normalization.

### 2.4. Sharp SE reduction in trend specification
**Concern:** Column 3's SE drops from 7.7 to 2.3 with sector trends.

**Response:** This is a valid concern. The sector-specific linear trends absorb much of the low-frequency variation in each sector, mechanically reducing standard errors. We now present this specification as supplementary rather than giving it equal billing. The preferred specification remains Column 2 (country-by-year FE without trends).

### 4.3. Literature coverage
**Response:** Added citation of Cameron, Gelbach, and Miller (2008) for wild bootstrap inference in the methodology section.

---

## Response to Gemini-3-Flash: Minor Revision

### 1. Re-titling
**Done.** Changed to "Short-Run Production Effects."

### 2. EUDAMED time series
**Response:** The EUDAMED snapshot is cross-sectional (March 2026). We cannot construct a time series of new vs legacy registrations from this data. Noted as a limitation and opportunity for future research.

### 3. DDD power statement
**Done.** Added explicit language about the wide CI and limited power.

---

## Prose and Exhibit Improvements

### Prose (from prose review)
- Rewrote opening paragraph: now leads with the "catastrophe" prediction and the non-result, not with a bureaucratic date
- Softened mechanism language to "hypotheses consistent with" rather than established explanations
- Improved control-sector variation discussion with explicit justification of C265 as closest comparator

### Exhibits (from exhibit review)
- Cleaned Figure 1: confidence intervals shown only for treatment group (C325), reducing visual clutter. Treatment line made thicker for visual prominence.
- Kept EUDAMED figure in main text (supports mechanism discussion about risk-class heterogeneity)
