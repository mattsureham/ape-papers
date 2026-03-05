## Discovery
- **Policy chosen:** State Right-to-Try laws (2014-2018) — first rigorous causal study; 38+ treated states with staggered adoption, novel ClinicalTrials.gov data
- **Ideas rejected:** Indoor tanning bans (NAICS measurement error), conversion therapy bans (YRBSS data gaps), NP full practice authority (saturated literature)
- **Data source:** ClinicalTrials.gov API v2 — universe of registered US clinical trials; tested and confirmed rich state-level facility data
- **Key risk:** Near-zero actual Right-to-Try usage may produce null effects across all margins; paper viability depends on well-powered null framing with clear MDE bounds

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT failed on CONTRIBUTOR_GITHUB placeholder — known false positive)
- **Top criticism:** Enrollment outcome construction (full planned enrollment assigned to every state) is mechanically duplicative and not interpretable as state-level enrollment. All 3 referees flagged this.
- **Surprise feedback:** GPT reviewer demanded spillover/interference analysis for multi-state trials — valid concern for null-result papers where attenuation bias matters.
- **What changed:** (1) Added enrollment caveat footnote + downgraded to secondary outcome; (2) Added SUTVA paragraph in identification section; (3) Holm-Bonferroni correction for terminal-condition p=0.09 → adjusted p=0.27; (4) Fixed Table 1 stale values (N=1,280/760 → 1,520/520); (5) Added N column to robustness table; (6) Explained CS vs TWFE sign flip for enrollment; (7) Fixed donut N (1,989 → 2,004)

## Summary
- **FIPS zero-padding bug:** Single-digit FIPS codes (01-09) failed merge with panel, misclassifying 6 treated states including CA and CO. Fixed with sprintf("%02d"). Always zero-pad FIPS codes.
- **Table hardcoding trap:** Never hardcode summary statistics in LaTeX — always read from regenerated CSV after any data pipeline change.
- **Advisor persistence:** Required 6 rounds to pass advisor review. Key blockers: stale Table 1 values, NE/WI "not-yet-treated" language, p-value rounding mismatches, sign flip explanation.
