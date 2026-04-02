## Discovery
- **Idea selected:** idea_2040 — EPA PFAS MCL + housing capitalization; first-ever national PFAS drinking water standard creates a natural experiment with built-in placebo (7 prior-MCL states)
- **Data source:** EPA UCMR 5 (1.93M rows, free bulk download) + FHFA ZIP5 HPI (690K rows, free) — both downloaded successfully on first attempt after correcting URLs
- **Key risk:** Single post-treatment year (2024) limits causal claims; pre-trends not perfectly clean

## Execution
- **What worked:** The DDD with prior-MCL states is the paper's strongest contribution — it isolates the informational channel cleanly. UCMR 5 data is remarkably well-structured and the ZIP crosswalk made linkage straightforward. The "forever chemical discount" framing gives the null result a compelling narrative.
- **What didn't:** Pre-trends are consistently negative (treated ZIPs on weaker growth path), which weakens the simple DiD. State × year FE shrinks the effect to near zero, confirming the simple specification partly captures state-level trends. The CEM matching didn't improve on the baseline because quartile-based matching was too coarse to bite.
- **Review feedback adopted:** Added joint F-test of pre-trends (p=0.56), explicit power calculation (MDE ~0.15 log points), and dollar-value translations of coefficients. Reviewers also suggested exploiting rolling UCMR 5 release timing and adding spatial controls — good ideas for V2.
