## Discovery
- **Idea selected:** idea_1796 — First Step Act safety valve expansion, chosen for individual-level USSC data, clean DiD design, and racial equity question
- **Data source:** USSC Individual Datafiles (FY2014-2024) — fixed-width format required custom SAS INPUT parser; 220K+ drug trafficking cases
- **Key risk:** Judge-level identification (JUSTFAIR) was infeasible for V1 — pivoted to district-level leniency proxies

## Execution
- **What worked:** SAS INPUT parser to read fixed-width USSC data across 11 years; NODRUG variable for drug offense identification; CH 1-4 restriction for clean DiD
- **What didn't:** Initial specification omitted `newly_eligible` main effect, producing sign errors in safety valve table. Initial sample included CH 5-6 defendants who contaminated the control group. Both caught by reviewers.
- **Review feedback adopted:** Fixed main effect inclusion, restricted sample to CH 1-4, corrected safety valve direction. Did not implement judge-level IV (V2 material).
