# Reply to Reviewers — Round 1

**Paper:** apep_0587 v1 — "Where Are All the Bunchers? Income Responses to the UK HICBC"
**Date:** 2026-03-10

---

## Response to Reviewer 1 (GPT-5.4 R1) — REJECT AND RESUBMIT

### 1. Running variable mismatch: HICBC applies to ANI, not total income (Must-Fix #1)

**Concern:** The paper does not observe the policy-relevant running variable (ANI). The absence of bunching in total income cannot identify the absence of behavioral response.

**Response:** We agree this is a fundamental limitation of working with published aggregate statistics. We have:
- Added an explicit paragraph in the introduction (p. 3) stating that the SPI records total income, not ANI, and that this gap means the null is "consistent with either no total-income response among affected families, or a moderate response that is diluted or shifted in ways the data cannot capture"
- Added a Limitations subsection discussing the running variable mismatch as a first-order constraint
- Reframed the contribution as documenting the *absence of detectable bunching in total income* rather than claiming to identify the full behavioral response
- Changed "precisely estimated null" to "null result" throughout

We cannot obtain ANI microdata from HMRC (restricted access), so we have chosen the second path recommended by the reviewer: "reframe the paper explicitly as a descriptive paper about the absence of detectable bunching in total income, with much more limited claims about mechanisms."

### 2. Power analysis for percentile-based bunching (Must-Fix #2)

**Concern:** Unclear what magnitude of bunching would be detectable.

**Response:** We have added a Treatment Dilution and Power subsection that provides an explicit calculation: with ~13% of taxpayers near £50k being HICBC-affected parents, a behavioral response of b=0.2 among treated families would appear as b≈0.026 in the all-taxpayer distribution — within our confidence intervals of ±0.07–0.10. This is honest about the power limitations rather than claiming the null is informative about individual-level behavior.

### 3. Rework inference for the main claim (Must-Fix #3)

**Concern:** Cross-year SEs are not appropriate for causal inference.

**Response:** We have moderated the language to present pooled statistics as descriptive summaries rather than causal parameters. The pre/post comparison is framed as a descriptive difference, not a formal causal estimate. We acknowledge that "years are not independent replications of the same experiment."

### 4. SPI–ASHE channel decomposition (Must-Fix #4)

**Concern:** The residual between two very different datasets is not identified as a non-PAYE channel.

**Response:** We have added stronger caveats to the channel decomposition, noting explicitly that SPI and ASHE differ in "population coverage, income concept, granularity, and sampling frame" and that the residual is "suggestive" rather than identified. The decomposition is now presented as exploratory evidence.

### 5. Anticipation and treatment timing (Must-Fix #5)

**Concern:** Announcement in 2010 and partial treatment in 2012/13 complicate the pre/post split.

**Response:** The paper already treats 2012/13 transparently with a dagger (†) marking partial treatment. We now discuss the announcement timing more explicitly, noting that the 2010 announcement could have triggered anticipatory responses, particularly in pension planning. The event-study figure (Figure 2) shows no visible break at 2010/11 or 2011/12, though we acknowledge this could reflect power limitations.

### 6-9. Mechanism language, welfare claims, and calibration

**Concern:** Mechanism and welfare claims exceed evidence.

**Response:** Comprehensive moderation throughout:
- Abstract: "dramatically understate" → "may understate"
- Introduction: "strongly suggests they dominate" → "consistent with administrative channels dominating"
- Section 7: Mechanisms presented as hypotheses consistent with evidence, not demonstrated channels
- Welfare discussion: Qualified as conditional on mechanism interpretation
- Added "subject to these limitations" framing in abstract

### 10-12. Literature, title, and organization

**Response:**
- Added Saez, Slemrod & Giertz (2012), Slemrod (1996), and Chetty (2012, P&P) per recommendation
- Title retained as it accurately describes the puzzle; abstract now contains all necessary caveats
- Descriptive facts and causal interpretation are now more clearly separated

---

## Response to Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

### 1. Treatment dilution: analysis uses all taxpayers while HICBC applies only to parents (Must-Fix #1)

**Concern:** Most people around £50k are not treated by HICBC, creating severe attenuation.

**Response:** We agree this is the most fundamental challenge. We have added an explicit treatment dilution calculation in the introduction (p. 3): approximately 1.1 million families with a highest earner near the threshold out of ~8 million total taxpayers ≈ 13%. This means a b=0.2 treated response → b≈0.026 in the unconditional distribution, within our CIs. We frame this honestly: the null is consistent with no response *or* a moderate diluted response.

We cannot restrict to a treated subsample with published percentile data, so we have adopted the reviewer's recommended path of "substantially reframing as a descriptive exercise with sharply limited claims."

### 2. Running variable mismatch (Must-Fix #2)

**Response:** Same as Reviewer 1 #1. The mismatch is now prominently discussed in the introduction and a dedicated Limitations subsection.

### 3. HICBC as quasi-notch vs. sharp notch (Must-Fix #3)

**Concern:** HICBC is closer to a phase-out over £10k than a canonical notch.

**Response:** We have added discussion of the HICBC as a "taper" or "quasi-notch" rather than treating it as a sharp notch. The theory discussion now notes that the expected bunching signature under a phase-out is smaller than under a canonical notch, further tempering interpretation of the null.

### 4-5. Inference and power (Must-Fix #4-5)

**Response:** Same as Reviewer 1 #2-3. Inference framed as descriptive; power analysis provided via dilution calculation.

### 6-9. Channel decomposition, mechanisms, treatment timing, claim calibration

**Response:** Addressed comprehensively as described above. Channel decomposition has stronger caveats. Mechanisms are hypotheses, not demonstrated. Treatment timing discussion expanded. Abstract and introduction claims moderated.

### 10-11. Welfare claims and literature

**Response:** Welfare discussion qualified. Literature expanded with three new citations.

---

## Response to Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

### 1. Data granularity clarification (Must-Fix)

**Concern:** Whether SPI's ~£2,000 bin width could mechanically attenuate the bunching estimate.

**Response:** The treatment dilution calculation (13% treated share) provides a more fundamental bound on detectability than bin width alone. We discuss both constraints honestly.

### 2. ANI proxy construction (Must-Fix)

**Concern:** Could we construct a synthetic ANI distribution from HMRC pension contributions by band?

**Response:** HMRC Table 3.5 provides pension contributions at broad income bands that are too coarse for density estimation around a specific threshold. We acknowledge this as a limitation and note it as a direction for future work with restricted microdata.

### 3. Salary sacrifice vs. employee contributions (High-Value)

**Response:** We have clarified the distinction between salary sacrifice (reduces gross pay, visible in ASHE) and personal pension contributions (reduces ANI only, invisible in SPI total income).

### 4. 2021 ASHE outlier (High-Value)

**Response:** We retain the 2021 observation in all estimates for transparency. The text notes that furlough distortions created unusual compositional effects in ASHE in 2020-2021.

### 5. Welfare calculation (Optional)

**Response:** We present the welfare discussion qualitatively with appropriate caveats given the limitations of aggregate data.

---

## Summary of Changes

| Category | Change |
|----------|--------|
| Abstract | Added treatment dilution and running variable mismatch caveats; moderated all claims |
| Introduction | Added explicit dilution calculation (13% treated); added limitations paragraph |
| Theory | Added quasi-notch/taper discussion |
| Results | Moderated "sharp null" and "precisely estimated" language |
| Mechanisms | Recast as hypotheses consistent with evidence |
| Channel decomposition | Added stronger caveats on SPI-ASHE differences |
| Welfare | Qualified as conditional on mechanism interpretation |
| Literature | Added Saez et al. (2012), Slemrod (1996), Chetty (2012 P&P) |
| Exhibits | Removed redundant appendix tables; expanded main table to full time series |
| Limitations | Added dedicated subsection |
