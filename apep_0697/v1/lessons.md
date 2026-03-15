## Discovery
- **Idea selected:** idea_0019 — NZ's 2018 foreign buyer ban (world's first prohibition vs tax), exploiting cross-regional variation in foreign buyer intensity
- **Data source:** Stats NZ Property Transfer Statistics (historical quarterly releases) + BIS house prices via FRED
- **Key risk:** SCM with single treated country; pivoted to regional DiD as main design

## Execution
- **What worked:** The regional DiD with 37 areas cleanly identifies the ban's compliance effect. The event study shows a sharp break at exactly the right quarter (2019Q1). Annual panel (2016-2024) confirms long-run persistence. The pre-ban intensity variation is large (0.6% to 15%).
- **What didn't:** No regional price data available from Stats NZ's public releases. RBNZ data returned 403 errors. The SCM collapsed to Australia (0.999 weight) — useless as standalone evidence but OK as supplementary. The data required downloading 23 historical Excel releases and parsing messy government spreadsheets.
- **Review feedback adopted:** Toned down price-effect claims substantially. Reframed contribution from "ban had no price effect" to "ban achieved compliance but price channel is an open question." Acknowledged 37-cluster inference limitations. Moved SCM to supplementary role.
- **Lesson for future:** When the idea manifest promises multiple identification strategies, check data availability for each BEFORE claiming. The idea had SCM + regional DiD + 2025 reversal; only the regional DiD was feasible. Also: government data portals change formats over time — earlier releases had quarterly TA data, later ones switched to annual only.
