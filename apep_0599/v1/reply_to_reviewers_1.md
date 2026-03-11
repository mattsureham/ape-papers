# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): MAJOR REVISION

### 1. DP stock outcome has failed pre-trends
**Response:** Agreed. We now flag this explicitly in the main text and shift emphasis to the DDD as the preferred specification. The new DDD event study (Figures 10, 10b) shows 0/19 pre-period coefficients significant at 5% for both DP and resource scheme outcomes, validating the DDD design. The simple DiD is retained as descriptive context but no longer carries causal weight for DP stocks.

### 2. Employment result under-validated
**Response:** Agreed. We added an employment event study (Figure 11) revealing 4/4 significant pre-period coefficients, and an employment DDD yielding a much smaller coefficient (-0.586 pp, p=0.066 vs. DiD of -3.52 pp). The text now acknowledges the simple DiD employment claim is contaminated by age-specific secular trends and interprets employment evidence cautiously.

### 3. DDD design needs pre-trend evidence
**Response:** Addressed with new DDD event study (Section 6.4, Figures 10–10b). Pre-period DDD coefficients are jointly insignificant for all main outcomes.

### 4. Control group (50-59) is also treated
**Response:** Added explicit discussion in the limitations section framing the design as relative treatment intensity, not a pure control comparison.

### 5. Resource scheme result is aggregate
**Response:** Added stock-vs-flow discussion in limitations. Changed language from "where blocked applicants went" to "which program stocks rose disproportionately."

### 6. Abstract/conclusion overclaim
**Response:** Rewrote both. Abstract now frames results as "patterns consistent with" rather than definitive. Conclusion adds two-paragraph limitations discussion and explicitly acknowledges aggregate data cannot trace individual transitions.

---

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

### 1. Main DiD inference invalid (Moulton problem)
**Response:** Agreed this is a serious concern. Added explicit discussion of the Moulton problem in Section 5.5 (Threats to Validity), citing Bertrand, Duflo, and Mullainathan (2004). The simple DiD is now clearly subordinate to the DDD, where treatment varies within municipalities. The RI p-value of 0.094 is now interpreted as corroborating the inference concern rather than providing reassurance.

### 2. DDD event study needed
**Response:** Implemented. See new Section 6.4 and Figures 10–10b. Clean pre-trends (0/19 significant for DP and resource scheme).

### 3. Employment not credibly identified
**Response:** Addressed comprehensively. Employment event study shows pre-trends, employment DDD is much smaller (-0.59 vs -3.52). Text now explicitly states the employment evidence is not credibly causal from the simple DiD.

### 4. Recalibrate claims to stock data
**Response:** Throughout the paper, replaced "where blocked applicants went" with language about relative shifts in program stocks. Added explicit stock-vs-flow discussion.

### 5. HighBase median split ad hoc
**Response:** Acknowledged in DDD section. The median split is retained as the main specification for interpretability, but we note this is a design choice that trades information for transparency.

### 6. Missing methodology citations
**Response:** Added Bertrand, Duflo, and Mullainathan (2004) and Roth (2022).

---

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### 1. Employment measure clarification
**Response:** Added explicit description: RAS200 defines employment as holding a job in November; resource scheme participants are classified outside employment.

### 2. Functional form for stock variables
**Response:** Addressed by promoting the DDD (which handles baseline differences through municipal FE interactions) and noting the log specification in robustness. The text now explicitly acknowledges that levels-based DiD on stocks with different baselines mechanically creates issues.

### 3. Transition accounting
**Response:** The substitution accounting figure is retained with clearer framing: it shows DiD coefficients capturing relative program stock changes, not literal flows.
