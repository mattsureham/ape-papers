# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1): MAJOR REVISION

### 1. "Design is interrupted time-series, not standard DiD"
**Response:** Accepted. The empirical strategy section now explicitly frames the design as "a comparative interrupted time-series design on national CPI aggregates" (citing Bertrand et al. 2004). The introduction describes it this way as well.

### 2. "HC1 standard errors are not adequate — need Newey-West"
**Response:** Fully addressed. All time-series DD specifications now use Newey-West standard errors (12 lags) as the primary inference method. The full-sample estimate is no longer statistically significant with NW SEs (p=0.31), which we now report honestly. The pre-COVID estimate remains highly significant (p<0.001).

### 3. "Formally test the full-pass-through benchmark"
**Response:** Added. Table 2 now includes a row reporting p-values for H0: β=0.0183 for all specifications. The pre-COVID estimate cannot reject full pass-through (p=0.19).

### 4. "Tone down causal and precision claims"
**Response:** Extensive revisions throughout. Title changed from "Complete Tax Pass-Through" to "Tax Pass-Through." Abstract and conclusion now use "consistent with near-complete pass-through" rather than claiming definitiveness. Limitations section explicitly acknowledges the data are "category-level rather than item-level."

### 5. "Address October 2018 placebo seriously"
**Response:** Added a full placebo-in-time distribution (Section 7.2, Figure 7). The DD is estimated at every candidate month from Jan 2016 through Sep 2019. October 2019 lies at the extreme right of the distribution — the largest estimate among all 46 months.

### 6. "Event study CIs are non-standard"
**Response:** The main text now explicitly states that Figure 1 is descriptive (pre-period residual variance) and directs readers to the panel event study in the Appendix for regression-based inference.

### 7. "DDD with alcohol is weak"
**Response:** The paper now frames the DDD as "a supplementary check rather than a decisive identification layer." We also add a pre-COVID DDD (0.0205, p<0.001) which shows the result holds when alcohol dynamics are less contaminated.

### 8. "Persistence claims too strong"
**Response:** Abstract no longer claims "persistent for 24 months." Results section adds a caveat that "the clean post-treatment window contains only four months."

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

### 1. "Within-product framing doesn't match aggregate CPI data"
**Response:** The paper no longer claims "within-product" identification. Introduction now says "aggregate CPI category data" and "category-level evidence consistent with near-full short-run relative pass-through." The title drops "Complete." Limitations section is substantially expanded.

### 2-5. (Overlap with R1 on inference, DDD, placebo, event study)
**Response:** See R1 responses above. All addressed.

### 6. "Need item-level data or reframe as ITS"
**Response:** The design is now framed as comparative ITS. Item-level data would strengthen the paper but are not available in the public CPI. We acknowledge this as a key limitation.

## Reviewer 3 (Gemini): MINOR REVISION

### 1. "Report pre-COVID DDD"
**Response:** Added. Pre-COVID DDD = 0.0205 (p<0.001), closely matching the pre-COVID DD of 0.0204. Reported in Table 3 Column 2.

### 2. "Figure 1 CIs should use regression-based SEs"
**Response:** Main text now explicitly flags the descriptive nature of Figure 1's confidence bands and directs readers to the panel event study table for formal inference.

## Prose Review Changes
- Killed roadmap paragraph (last paragraph of intro)
- Added "This paper contributes" phrasing for lit audit compliance

## Exhibit Review Changes
- Noted suggestions for future rounds (consolidate tables, benchmark line)
- Added placebo distribution figure (Figure 7)
