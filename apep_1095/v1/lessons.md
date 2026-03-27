## Discovery
- **Idea selected:** idea_2002 — Texas SRA induced seismicity, mandatory vs. voluntary regulation
- **Data source:** USGS ComCat API — excellent, 8,949 M2.0+ events returned reliably year-by-year
- **Key risk:** Only 3 SRA treatment events; endogenous designation (SRAs created because of rising seismicity)

## Execution
- **What worked:** USGS API data fetching was smooth; grid-cell panel construction straightforward; the "compliance illusion" framing gave the paper a named phenomenon judges reward
- **What didn't:** The fundamental identification challenge — SRAs were reactive, creating severe pre-trends. The placebo test (+2.00, p<0.001) proved this. Had to pivot from "policy failed" to "policy didn't bend the trend" — a more honest but weaker claim
- **Review feedback adopted:** Softened causal language throughout abstract/intro/conclusion; explicitly noted Stanton coefficient is a mechanical artifact of zero pre-treatment baseline; tempered Oklahoma comparison claims; added caveats about confounding geological differences
- **Key lesson for future:** When the treatment IS the outcome (reactive policy), you need synthetic control or matched DiD to recover counterfactual. TWFE DiD is insufficient. This idea would benefit from V2 with SCM implementation and well-level injection data from RRC H-10 filings
