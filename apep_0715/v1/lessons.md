## Discovery
- **Idea selected:** idea_0963 — FOBT stake reduction, zero NBER papers, dramatic 98% stake cut
- **Data source:** UK Gambling Commission Industry Statistics — clean, comprehensive, publicly downloadable
- **Key risk:** Sector-level design with only 4 units limits causal inference power

## Execution
- **What worked:** The within-betting decomposition (OTC vs machine GGY) provided the strongest evidence. When OTC barely changes but machine GGY collapses, the mechanism is clearly the targeted regulation, not a broader demand shock. This internal falsification is more persuasive than the formal DiD.
- **What didn't:** LA-level data wasn't accessible through the Gambling Commission's public datasets or NOMIS API, forcing a pivot from the manifest's continuous-treatment design to a sector-level comparison. Future work should pursue the LA-level panel.
- **Key discovery:** The trend-adjusted substitution rate (6%) vs naïve rate (38%) completely reframes the policy conclusion. Remote betting was already growing at £113M/year; most "substitution" was actually pre-existing digitization.
- **Review feedback adopted:** Added limitations section on sector-level inference, permutation inference bounds, trend adjustment to substitution analysis, and explicit path forward for LA-level extension.
