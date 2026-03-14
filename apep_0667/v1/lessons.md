## Discovery
- **Idea selected:** idea_0160 — EBT rollout and drug-market disruption via the SNAP trafficking channel
- **Data source:** CDC drug poisoning mortality (Socrata API, no auth) + FRED population + hand-coded EBT dates from literature
- **Key risk:** Outcome pivot — manifest proposed FBI SHR drug homicides but SHR/UCR data were inaccessible (FBI API 403, FRED crime series nonexistent). Pivoted to CDC drug poisoning mortality, which tests the health/consumption channel rather than the violence channel.

## Execution
- **What worked:** CDC Socrata API was reliable and required no authentication. EBT dates from published literature were straightforward to compile. CS-DiD + TWFE comparison with HonestDiD sensitivity provided thorough identification. Null result was genuine and well-powered.
- **What didn't:** FBI Crime Data Explorer API rejected DEMO_KEY with 403. FRED state-level crime series (ALPRPCRT etc.) don't exist. BJS API returned 404. Multiple data pivots consumed ~30% of execution time.
- **Review feedback adopted:** Added MDE power calculation (1.04 per 100k, ~10% of mean), acknowledged outcome channel limitation (health vs. violence), tempered policy conclusions to distinguish anti-fraud success from drug-market claims, added note about future violence-channel research.
- **Key lesson:** When an idea manifest specifies a particular data source (FBI SHR), verify API access before claiming the idea. The data pivot from homicides to drug poisoning changed the contribution — still valuable but tests a different mechanism.
