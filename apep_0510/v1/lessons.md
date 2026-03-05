## Discovery
- **Policy chosen:** PDMP mandatory consultation laws — staggered adoption across 40+ states (2007-2019) provides strong DiD variation. The opioid crisis is a first-order policy issue, and the substitution hypothesis (prescriptions → fentanyl) creates a belief-changing angle.
- **Ideas rejected:** (1) Cannabis → enrollment (crowded topic, COVID confounds post-2020), (2) Naloxone → college retention (underpowered — overdose deaths too rare among students to move institutional retention rates), (3) ACA dependent coverage → 26th birthday cliff (IPEDS age bins too coarse for age-based RDD), (4) Endowment crash (not a policy shock; hard to separate from concurrent recession)
- **Data source:** IPEDS via Azure DuckDB (1.2 GB, 23 tables, 2000-2024) + CDC overdose data via Socrata API (jx6g-fdh6 for age-specific 1999-2015, VSRR xkb8-kh2a for drug-type-specific 2015-2025). IPEDS DuckDB doesn't support remote ATTACH from Azure — must copy locally.
- **Key risk:** Effect size may be small at the institution level since opioid misuse affects ~6% of 18-25 year olds. Power assessment suggests MDE ~0.3-0.5 pp on retention rate with 50 state clusters.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex pass; Gemini fail — persistent CDC data coverage concern)
- **Top criticism:** The mortality "first stage" was labeled as causal evidence but CDC data ends 2015 while 16 states adopted 2016-2021. Required renaming to "descriptive evidence" and removing all causal language.
- **Surprise feedback:** Table 4 institution counts (4,600 total in IPEDS vs 3,700 in estimation sample) created persistent confusion across 8 advisor rounds. Fix was filtering Table 4 to estimation sample (2,801 treated institutions).
- **What changed:** Abstract completely rewritten to remove mortality claims; all "first-stage" language replaced with "descriptive evidence"; pre-trends section strengthened to explicitly say results "cannot be interpreted as a causal effect."
- **Advisor rounds:** 8 rounds required to achieve 3/4 PASS. Main blockers: table/text consistency (rounds 1-4), institution count discrepancy (rounds 5-7), threeparttable formatting (round 7).

## Summary
- **Key lesson:** Advisor models are extremely sensitive to internal consistency between tables, text, and code output. Any hardcoded table in paper.tex that doesn't match generated outputs will be flagged repeatedly. Use `\input{}` for all tables from the start.
- **Methodology:** CS-DiD with TWFE benchmarks worked well. The enrollment result (p=0.04 CS-DiD, p=0.15 TWFE) illustrates the importance of estimator sensitivity — all three referees flagged this discrepancy.
- **Null result framing:** Reviewers responded positively to honest null framing with MDEs. The welfare calculation added value despite the null.
