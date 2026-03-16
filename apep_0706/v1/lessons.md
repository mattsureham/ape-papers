## Discovery
- **Idea selected:** idea_0261 — Brazil FPM multi-cutoff RDD on homicides. Chosen for combination of well-established identification (17 population thresholds, massive N) with novel outcome (violent crime) and genuinely ambiguous theoretical prediction.
- **Data source:** IPEADATA API (SIM-DATASUS processed) + IBGE SIDRA API — both worked perfectly. SIDRA mortality tables (2681/2682) returned 400 errors, but IPEADATA provided the same municipality-level homicide counts.
- **Key risk:** McCrary bunching at thresholds (known issue documented by Litschig 2012). Addressed with donut-hole specifications.

## Execution
- **What worked:** IPEADATA API is excellent for Brazilian municipality-level health data. Annual panel RDD with year-specific assignment is the right specification for this institutional rule.
- **What didn't:** Initial specification used time-averaged population — a design error caught by GPT-5.4 reviewer. The DATASUS SIDRA mortality tables (2681/2682) return 400 errors despite being documented.
- **Review feedback adopted:** (1) Switched from cross-sectional to annual panel RDD as primary specification; (2) Added youth homicide (15-29) as mechanism test; (3) Fixed abstract/text sample size inconsistency; (4) Improved estimand description to match institutional rule.
