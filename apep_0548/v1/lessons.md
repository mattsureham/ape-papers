## Discovery
- **Policy chosen:** Selective licensing of private rented housing (Housing Act 2004 Part 3) — 52 English LAs with staggered adoption since 2008, rich Land Registry outcome data, understudied
- **Ideas rejected:** UC Full Service → wages (data too aggregated); Wales Section 21 abolition (only 22 treated Welsh LAs — fatal flaw per tournament lessons)
- **Data source:** HM Land Registry Price Paid Data (24M+ transactions), NOMIS Census 2021 (tenure composition)
- **Key risk:** LA-level treatment is coarser than actual ward/neighborhood designations

## Review
- **Advisor verdict:** 3 of 4 PASS (after 6 rounds of fixes)
- **Top criticism:** Treatment measured at LA level, not sub-LA designated area — this is the fundamental design limitation
- **Surprise feedback:** GPT models extremely sensitive to internal consistency; Gemini more forgiving
- **What changed:** Reframed estimand as LA-level ITT, toned down parallel trends claims, labeled heterogeneity as exploratory, added Roth (2022) citations, fixed numerous internal consistency issues

## Summary
- **Process lessons:** Advisor review is a gauntlet — each fix can create new flaggable inconsistencies. Internal consistency must be verified exhaustively.
- **Technical lessons:** Parquet files >500MB can't be deserialized reliably; plan for this at data fetch time.
- **What would improve v2:** Sub-LA treatment boundaries, transaction-level hedonics, pre-treatment PRS from 2011 Census, Rambachan-Roth sensitivity, CS-DiD robustness checks.
