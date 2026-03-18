## Discovery
- **Idea selected:** idea_0890 — Benefit cap reduction and temporary accommodation; chose for first-order stakes (homelessness), enormous treatment variation (278 LAs), and all-public data
- **Data source:** MHCLG Table 784 (annual TA by LA), DWP benefit cap ODS (LA-level caseloads), NOMIS (population/claimants)
- **Key risk:** Pre-existing housing market trends confounding cap exposure with TA growth

## Execution
- **What worked:** The data pipeline was clean once I found the right sources. Table 784 annual data from Cambridgeshire Insight was the hero — consistent LA-level TA from 2009/10 to 2017/18. DWP ODS Sheet 7 had the LA-level cap data buried under regional aggregates.
- **What didn't:** Quarterly data was the original plan but P1E→H-CLIC transition at April 2018 makes bridging unreliable. Annual data limits power (only 2 post years). The pre-trend failure was the dominant finding.
- **Review feedback adopted:** Added 2012 to event study table (was missing); moderated rhetoric ("no credible design" → "simple cross-area designs"); added paragraph explaining WHY pre-trends exist (housing market dynamics); acknowledged treatment timing limitation (May 2017 is post-reform).
- **Key lesson:** When policy exposure is determined by the same housing market forces that drive the outcome, continuous-treatment DiD will inherit those trends. This is not a data problem — it's structural. Individual-level designs are needed here.
