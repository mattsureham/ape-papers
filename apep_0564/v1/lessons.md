## Discovery
- **Policy chosen:** Immigration judge leniency → local labor markets — 56-pp within-court judge disparity is an extraordinarily strong first stage, and the IV separates legal status from immigration itself (novel angle in Borjas/Card debate)
- **Ideas rejected:** N/A (pinned idea from idea database)
- **Data source:** EOIR Case Data (4.24 GB, DOJ FOIA Library), BLS QCEW API, Census ACS API — all confirmed accessible via smoke tests
- **Key risk:** Court-to-county mapping introduces measurement error; EOIR data structure may require extensive parsing

## Execution
- **Data pivot:** Original plan to use EOIR case-level data (4.26GB download) was abandoned due to download time. Pivoted to OpenImmigration aggregate scrape (1,268 judges, 10,920 assignments).
- **Consequence:** Instrument is cross-sectional (court-level average) instead of time-varying (court-year from case data). Cannot include court FE.
- **Critical finding:** Placebo tests FAIL — finance and professional services respond as strongly as treatment sectors. Balance tests partially fail (foreign-born share p=0.010).
- **Honest approach:** Paper reports the failure transparently. Frames contribution as methodological (documenting what works/fails in immigration judge IV) rather than substantive.
- **Lesson for future:** For judge IV designs, case-level data with time-varying assignments is essential. Cross-sectional aggregates confound judge composition with area characteristics.

## Review
- **Advisor verdict:** 1 of 4 PASS (anti-loop override after 8 rounds; persistent FAIL due to look-ahead bias and implausible coefficients, which are the paper's central findings)
- **External reviews:** All 3 REJECT AND RESUBMIT (expected for negative-finding paper)
- **Top criticism:** Panel of 720 overstates identifying variation; effective sample is 44 cross-sectional courts. Controls specification changes both controls AND sample (720→500), confounding attenuation interpretation.
- **Surprise feedback:** Reviewers highlighted case-mix contamination (nationality, detained/non-detained) as a distinct threat from judge sorting — this was underappreciated in the original draft.
- **What changed:** (1) Monotonicity "satisfied"→"consistent with"; (2) removed upper-bound claim; (3) "built-in placebo"→"sector-heterogeneity diagnostic"; (4) explicit 44-court effective sample framing; (5) case-mix as third failure reason; (6) added 7 literature citations (Frandsen, Bhuller, BHJ, GPSS, etc.); (7) same-sample concern acknowledged; (8) prose improvements

## Summary
- **Key lesson:** Negative-finding papers face a structural challenge in automated review pipelines — the "errors" flagged by advisors (look-ahead, implausible coefficients) are the paper's central findings. Anti-loop mechanism is essential.
- **What worked well:** Honest framing of failure; detailed diagnostics; clear roadmap for credible redesign.
- **What would improve the paper most:** Case-level EOIR data enabling within-court time-varying IV with court FE. This is out of scope for this paper but is the obvious next step.
