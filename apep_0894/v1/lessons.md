## Discovery
- **Idea selected:** idea_0476 — CFPB payday lending rule + QWI employment, chosen for Azure QWI availability, built-in reversal test (rescission), and novel supply-side angle
- **Data source:** Azure QWI (NAICS 522, 523) + Census CBP 2017 + Census population estimates. Azure worked smoothly; CBP required zip download (txt URL was 404).
- **Key risk:** COVID contamination of the post-compliance window (compliance Aug 2019, COVID Mar 2020)

## Execution
- **What worked:** Azure QWI data access was fast and reliable. The continuous DiD design is clean with 2,911 counties and good variation in payday density. CBP 2017 pre-announcement baseline is well-timed.
- **What didn't:** The reversal design (rescission test) failed because COVID arrived between compliance and rescission, confounding both. The full-sample result (-0.008, p=0.04) is entirely driven by COVID, not the compliance date. NAICS 5221 (4-digit) isn't available in n3 data — had to use NAICS 523 for placebo instead.
- **Surprising finding:** Precise null in the clean pre-COVID window. A regulation projected to eliminate 60-70% of payday loans produced zero detectable employment effect. Multiple mechanisms plausible: anticipation, expected rescission, industry adaptation, measurement dilution.
- **Review feedback adopted:** Added MDE/power discussion (1.4% at mean density), restricted-sample robustness (payday-only counties, p=0.058), expanded measurement dilution discussion. Dropped: C-S estimator (uniform timing makes TWFE unbiased), NAICS 5221 placebo (4-digit unavailable in n3 data), explicit COVID controls (would require additional data).
