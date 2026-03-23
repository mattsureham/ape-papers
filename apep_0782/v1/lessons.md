# Lessons: apep_0782 — MSHA 2007 Penalty Reform

## Discovery
- MSHA data is a gold mine (pun intended) for policy evaluation: 3M+ violation records with exact penalty amounts, linked to 270K+ injury records, all publicly downloadable with no API keys needed.
- The pipe-delimited format and quoted string fields required careful parsing (gsub quotes on MINE_ID, DEGREE_INJURY_CD, etc.).
- Pre-reform penalty comparison confirmed the idea manifest's claims almost exactly: S&S penalties $571 -> $2,037 (3.6x), total bill from $69M to $307M.

## Identification
- Continuous treatment DiD worked well here: the 4.2x reform created massive variation in treatment intensity across mines based on pre-reform violation profiles.
- The mean pre-reform S&S penalty per mine is a cleaner treatment measure than violation counts because it captures both the intensive margin (penalty severity) and the extensive margin (violation frequency).
- Mine fixed effects are essential: cross-sectional variation in injury rates dwarfs within-mine temporal variation.

## Results
- Main effect: -0.037 per $100 increase in pre-reform penalty (p=0.012). Standardized at -0.010 SD. Small but real.
- Event study is textbook: flat pre-trends (2004: +0.007, 2005: +0.010) and monotonically growing post-reform effects (2007: -0.017, 2008: -0.017, 2009: -0.035, 2010: -0.046).
- Placebo reform in 2004 gives precise null (p=0.773) — strongest identification evidence.
- Winsorized results sharpen dramatically (p<0.001), confirming the raw injury rate's heavy right tail attenuates the main estimate.

## Review Feedback
- All three reviewers flagged (1) mean reversion from sample selection, (2) MINER Act confounding, (3) treatment intensity endogeneity. These are predictable concerns for any continuous-treatment DiD.
- The coal vs M/NM heterogeneity scaling was confusing — treatment intensity distributions differ by mine type, so raw coefficient comparison is misleading. Addressed by explaining the scaling issue.
- Back-of-envelope cost-benefit calculation was straightforward and adds value: ~$94M in averted injury costs vs ~$110M in incremental penalties.

## Process
- Pivoted from UK academies (idea_0960) to MSHA (idea_0686) after the UK data fetch proved unreliable. MSHA's open data infrastructure is vastly superior.
- Total execution time: ~30 minutes from research plan to compiled paper, plus review wait time.
- The V1 format (AER: Insights, 8+ pages) is well-suited to this clean quasi-experiment with a single reform date.

## What I'd Do Differently
- Include zero-violation mines as a control group (treatment intensity = 0) to address external validity concerns.
- Add a Poisson/PPML specification to handle the count data structure and right-skew.
- Include violation rates as a mechanism test (penalties -> fewer violations -> fewer injuries).
- Consider wild cluster bootstrap for state-level clustering (only 52 clusters).
