## Discovery
- **Idea selected:** idea_0570 — France ZFE spatial RDD on property values. Chosen for clean identification (spatial boundary following existing road infrastructure), first-order outcome (property values), and novel contribution (first spatial RDD on French ZFEs).
- **Data source:** DVF bulk geocoded CSVs from data.gouv.fr (2020-2024) + ZFE boundary GeoJSON from Grand Lyon open data. Both sources worked flawlessly. Note: geo-dvf only covers 2020+ (not 2018 as initially assumed).
- **Key risk:** Pre-existing boundary discontinuity at the ring road. Addressed with difference-in-discontinuities design.

## Execution
- **What worked:** The spatial RDD design produced a large, significant, and robust negative effect (-10.5% in diff-in-disc). The finding that ZFEs *penalize* rather than *benefit* property values is a genuine surprise — contradicts standard hedonic predictions and makes for compelling framing ("the mobility tax").
- **What didn't:** Air quality data (EEA NO2 stations) was not fetched or analyzed despite being in the manifest. All three reviewers flagged this as a limitation. Future revisions should incorporate it.
- **Review feedback adopted:** (1) Added fake-date placebo (Sept 2021) confirming no pre-trend — strengthened identification. (2) Clarified covariate-adjusted estimate jump (composition correction). (3) Added back-of-envelope welfare calculation (~€3B wealth transfer). (4) Expanded McCrary pre-period discussion (structural density ≠ policy-induced sorting).
- **Tournament lesson:** The "accessibility vs. air quality" framing resolves an active contradiction in hedonic literature. Papers that find the opposite of what theory predicts — and explain why — tend to win tournament matches (see lessons_global.md on "resolving contradictions").
