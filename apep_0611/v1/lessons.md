## Discovery
- **Idea selected:** idea_0469 — CRA lookback cutoff as source of quasi-experimental variation in rule vulnerability
- **Data source:** Federal Register API — excellent, no auth, paginated JSON, 98K+ rules since 1994
- **Key risk:** Running variable measured in calendar days vs legislative days (approximate cutoff dates from CRS reports)

## Execution
- **What worked:** The diff-in-disc design worked cleanly — large, robust page-length effect (-9.6 pages, p<0.001) that survives all robustness checks. Null on volume is a strong complement. FR API data fetch was straightforward.
- **What didn't:** The original idea targeted rule survival/reversal (whether CRA-vulnerable rules get rescinded), but this requires complex cross-rule linking. Pivoted to rule characteristics (page length, significance) — still novel and interesting but reviewers flagged the deviation.
- **Review feedback adopted:** (1) Added page-length bandwidth sensitivity table — crucial, reviewers correctly noted headline result lacked BW robustness. (2) Added exclusion sensitivity dropping 2017/2025 transitions with density manipulation. (3) Improved equation notation. (4) Acknowledged outcome shift from survival to characteristics. (5) Fixed transition count bug in summary table.
- **Lesson for future:** When idea manifest specifies outcome X, either pursue X or explicitly reframe the contribution early. BW sensitivity for ALL main outcomes (not just secondary) is essential from the start.
