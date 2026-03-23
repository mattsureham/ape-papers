## Discovery
- **Idea selected:** idea_0779 — HMDA reporting exemption (EGRRCPA Section 104) creates a natural experiment in disclosure and discrimination
- **Data source:** CFPB HMDA Data Browser API, state-by-state downloads for 2018-2022
- **Key risk:** No pre-2018 data available via the API, limiting causal identification

## Execution
- **What worked:** Within-county comparison of exempt vs non-exempt lenders is clean and intuitive. The mechanism decomposition (both denial rates lower, White dropping more) told a more interesting story than expected. The Asian-White placebo provided specificity. 2.67M aggregated loan records across 5 years, 51 states.
- **What didn't:** Pre-treatment trend test impossible without legacy HMDA files (2014-2017). The 500-origination threshold RDD from the idea manifest was not pursued due to data aggregation level. The result attenuates to borderline significance with controls.
- **Review feedback adopted:** Fixed abstract to honestly report both specifications. Added extensive discussion of pre-treatment limitation. Added economic magnitude calculation. Strengthened threats section.
- **Surprise finding:** The detection gap is not about active discrimination increasing — it's about relationship lending benefits (lower denial rates) flowing more to White borrowers at community banks freed from scrutiny. This is a subtler and more interesting story than the original hypothesis.
