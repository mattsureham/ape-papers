## Discovery
- **Idea selected:** idea_1053 — Eisensee-Strömberg IV for Indian floods × MGNREGA. Chosen for creative identification and mechanism isolation.
- **Data source:** SHRUG VIIRS nightlights (local), NASA POWER precipitation (API), hand-coded events calendar
- **Key risk:** BigQuery access was broken — GDELT data unavailable, forcing pivot to simpler reduced-form design

## Execution
- **What worked:** NASA POWER API reliable and fast. SHRUG district nightlights clean and ready. Panel construction straightforward.
- **What didn't:** BigQuery ADC credentials point to wrong project (gen-lang-client vs scl-librechat). Multiple auth attempts failed. Had to abandon GDELT-based first stage entirely.
- **Key pivot:** Shifted from 3-stage IV (competing news → media coverage → MGNREGA → recovery) to reduced-form triple-diff (rainfall × competing events → nightlights). This weakened the causal chain but was feasible.
- **Surprising result:** The interaction has the WRONG sign (positive, not negative). Floods during high-competing-news years show better recovery, opposite to the salience gap hypothesis. This is robustly null across all specifications.
- **Review feedback adopted:** All three reviewers flagged overclaiming about "MGNREGA is salience-proof." Softened language throughout, added MDE discussion, noted that limited temporal variation constrains power. Changed title from assertive ("The Automatic in Automatic Stabilizer") to descriptive ("When No One Watches"). Fixed inconsistent effect sizes across abstract/intro/conclusion.
