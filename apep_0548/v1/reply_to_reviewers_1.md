# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

### §1A: Treatment measured at wrong geographic level
**Response:** We agree this is the paper's most important limitation. We have:
- Reframed the estimand explicitly as an "LA-level intention-to-treat effect of first adoption"
- Added a new subsection (5.3) discussing treatment coarseness and its implications
- Acknowledged that LA-level estimates are likely attenuated relative to neighborhood-level effects
- Identified sub-LA treatment geography as the key avenue for future work

We note that many influential staggered DiD papers use similarly aggregated treatment definitions (e.g., state-level policy evaluations), and that the methodological contribution (TWFE bias demonstration) is valid regardless of treatment granularity.

### §1B: Parallel trends not established
**Response:** We have:
- Replaced all "strong support" language with "consistent with—though does not prove"
- Added citations to Roth (2022) on pretest limitations
- Acknowledged limited power with 52 treated units
- Cited Rambachan and Roth (2023) as priority for future sensitivity analysis

### §1D: Treatment timing coarse
**Response:** We now transparently describe the annual treatment coding for both panels. The quarterly panel uses the same annual coding, which we acknowledge introduces misclassification of pre-treatment quarters in the adoption year.

### §2B: Too much reliance on TWFE robustness
**Response:** We added an explicit caveat at the start of the Robustness section noting that these TWFE-based exercises describe properties of the TWFE estimator rather than providing causal validation. CS-DiD robustness is noted as a priority for future work.

### §3B: Mechanism claims over-interpreted
**Response:** We relabeled all heterogeneity analysis as "exploratory," flagged the post-treatment PRS measure, and changed "consistent with capitalization mechanism" to "suggestive cross-sectional pattern."

### §5: Claims too strong
**Response:** We recalibrated the abstract, conclusion, and policy implications to reflect the LA-level ITT design and wide confidence intervals.

---

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

### §1A: Treatment definition too coarse
**Response:** See response to R1 §1A. We have reframed the estimand and added treatment coarseness discussion.

### §1B: Selection into treatment endogenous
**Response:** See response to R1 §1B. We acknowledge that pre-trend insignificance does not validate parallel trends, especially with targeted adoption.

### §1C: Timing measured imprecisely
**Response:** We now transparently describe the annual coding and acknowledge it as a limitation.

### §2B: TWFE robustness after arguing TWFE is biased
**Response:** Added explicit caveat. See response to R1 §2B.

### §3C: Mechanism claims too strong
**Response:** All heterogeneity relabeled as exploratory with post-treatment moderator caveat.

### §4C: Literature positioning
**Response:** Added Roth (2022) and Rambachan-Roth (2023) references.

---

## Reviewer 3 (Gemini): MINOR REVISION

### §6.1: Treatment intensity
**Response:** We added treatment coarseness discussion and acknowledged borough-wide vs partial scheme heterogeneity as important future work.

### §6.2: Hedonic characteristics
**Response:** Noted as limitation. The 766MB parquet file exceeds memory limits for transaction-level analysis.

### §6.3: Anticipation effects
**Response:** Noted as future extension. The CS-DiD currently assumes zero anticipation.
