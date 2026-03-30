## Discovery
- **Idea selected:** idea_2007 — China's centralized land auction reform, a clean DiD with 22 treated cities
- **Data source:** NBS 70-city housing price indices via AKShare — API returned 2 cities at a time, required looping through 35 pairs
- **Key risk:** COVID contamination of pre-period (March 2020 placebo significant)

## Execution
- **What worked:** AKShare data fetch was reliable once I understood the 2-city-at-a-time API. 12,740 city-month observations, strong panel. The used-housing placebo (coefficient = 0.004, p = 0.92) was the paper's strongest identification argument — a near-perfect zero on an outcome that shouldn't respond to land auction reform.
- **What didn't:** AKShare doesn't provide size-category breakdowns (under 90m², 90-144m², above 144m²), forcing a pivot from within-city price dispersion (the manifest's primary outcome) to aggregate month-to-month volatility. All three reviewers flagged this deviation.
- **Key pivot:** Reframed the paper around "lumpy information arrival → volatility" rather than "lumpy information → dispersion." This is a weaker but still valid test of the theoretical mechanism.
- **Review feedback adopted:** (1) Expanded limitations section to be transparent about missing size-category data and COVID identification concern. (2) Added event study coefficient description to appendix. (3) Softened abstract language about "concentrated" effects since Tier-2 is also significant at 10%.
- **Lesson for future:** When the manifest promises outcomes requiring specific data granularity, verify data availability in the smoke test before claiming the idea. AKShare's 70-city data is aggregate only — direct NBS access or CEIC would be needed for size-category breakdowns.
