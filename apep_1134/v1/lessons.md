## Discovery
- **Idea selected:** idea_1935 — German EEG clawback thresholds, picked for bunching methodology (highest-rated method in tournament) + 15-minute open-access data
- **Data source:** Fraunhofer ISE Energy-Charts API — open access, CC BY 4.0, no API key. Bidding zone is DE-LU (not DE). 263K price observations, 4.5M generation observations.
- **Key risk:** Small N for bunching (89 episodes in the key 2021-2023 regime)

## Execution
- **What worked:** Data fetching was smooth after fixing the bidding zone code. Cross-country placebos are essentially free from the same API. The within-episode regression design (episode FE + hour-of-day FE) provides clean identification.
- **What didn't:** The bunching estimates are extremely noisy and sensitive to polynomial order/bandwidth, making the bunching test underpowered. The original DiD specification had collinearity issues (episode FE absorb the post indicator) — had to pivot to the within-episode curtailment design.
- **Key insight:** Results flipped the prior — no curtailment cliff. Framing the null as "The Paper Cliff" (collective-action problem) turned a negative result into a contribution.
- **Review feedback adopted:** Added selection bias discussion (conditioning on episodes reaching 3+ hours excludes successfully curtailed episodes), MDE/power quantification, strengthened aggregate data limitations, clarified MW vs MWh, moved collective-action framing to abstract.
