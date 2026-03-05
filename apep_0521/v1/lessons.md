## Discovery
- **Policy chosen:** Constitutional carry (permitless concealed carry) — staggered adoption across 25 states 2010-2023 with clear legislative dates
- **Ideas rejected:** Various gun policy topics already covered; this was novel because it focuses on carry deregulation (vs purchase) and suicide (vs crime)
- **Data source:** CDC Leading Causes (1999-2017), CDC Mapping Violence (2019-2024), FBI NICS — all public APIs
- **Key risk:** Panel A ends 2017 but most adoption is post-2019, limiting treated states to 10 in main panel

## Review
- **Advisor verdict:** 3 of 4 PASS (after 12 iterations fixing consistency errors)
- **Top criticism:** CS-DiD yields opposite sign from TWFE/SA — must diagnose transparently rather than dismiss
- **Surprise feedback:** Reviewers caught many hard-coded values and numerical inconsistencies (88% vs 91% Bacon weight, p=0.002 vs 0.014 SA p-value)
- **What changed:** Added group-specific CS ATTs, softened mechanism language, added welfare sensitivity range, fixed all numerical consistency issues

## Summary
- Paper quality improved substantially through iterative advisor review (12 rounds)
- Key lesson: NEVER hard-code numerical values in tables/figures/text — always derive from model objects
- Multiple panels (A/B/C) create consistency challenges — need systematic verification across all references
- Constitutional carry → suicide finding is robust to TWFE, SA, RI, and LOO but CS-DiD disagrees due to Arizona's outsized weight
