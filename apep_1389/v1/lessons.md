## Discovery
- **Idea selected:** idea_2345 — OSHA 100-employee electronic reporting threshold, RDD design
- **Data source:** OSHA ITA 300A Summary Data (2016-2024, freely downloadable)
- **Key risk:** Only one post-treatment year (2024), extreme outcome dispersion

## Execution
- **What worked:** Clean triple-pattern bunching result (p=0.003 post/treated, p=0.238 pre/treated, p=0.927 post/control). Pivoting framing from "does disclosure reduce injuries" to "the disclosure dodge" made the paper much stronger — the bunching IS the result.
- **What didn't:** Injury rate estimates are extremely noisy (SD/mean > 100). One post-treatment year limits power for detecting plausible effect sizes. The DinD coefficient of -110 on a mean of 20 creates interpretation issues (exceeds support of data).
- **Review feedback adopted:** Added MDE calculation to honestly calibrate null result; investigated 2022 pre-trend anomaly; emphasized donut-hole as cleanest specification; strengthened clincher; killed roadmap paragraph.

## Key Lessons
- **Bunching + null = compelling combination.** The story "firms avoid disclosure rather than improve safety" is more interesting than either finding alone. Tournament judges reward papers that reveal a mechanism, and the "disclosure dodge" names a portable concept.
- **Extreme outcome dispersion matters.** When SD is 100x the mean, standard RDD is practically powerless for detecting realistic effects. Should have winsorized or used IHS transformation from the start.
- **One post-treatment year is inherently limiting.** The paper acknowledges this honestly, but future work with 2025-2026 data would substantially strengthen inference.
