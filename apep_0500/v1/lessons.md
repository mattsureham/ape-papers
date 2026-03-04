## Discovery
- **Policy chosen:** Nigeria's anti-open grazing laws (14+ states, 2016-2021) — first causal evaluation of this life-and-death pastoral policy
- **Ideas rejected:** Petro-Federalism (Gemini flagged fatal exclusion restriction — oil prices affect oil states directly beyond FAAC); Conflict-nightlights (too crowded, weak ID); Naira redesign violence (2023 election confounder); Conflict contagion (identification too uncertain)
- **Data source:** UCDP GED v25.1 (7,418 Nigeria events, geocoded, 1990-2024) — confirmed accessible and rich. NCDC health API unreachable. Open Treasury unreachable.
- **Key risk:** Only 14 treated states (below ≥20 threshold). Mitigated by DDD at LGA level, wild cluster bootstrap, RI. Endogenous adoption is the core ID threat.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 5 rounds — required fixing treatment timing, figure year ranges, inline number consistency, SGF p-value)
- **Top criticism:** Treatment timing alignment — annual panel coding with mid-year adoptions. Required implementing a new convention (Jul-Dec adoptions → treatment begins next year) and re-running entire pipeline.
- **Surprise feedback:** GPT-5.2 referee review was exceptionally detailed (5000+ words), requesting DDD event study and spatial spillover analysis — both implementable and valuable additions.
- **What changed:** Added DDD event study (Figure 7), PPML model, spatial spillover test (76 border LGAs), prose improvements per Gemini review.

## Summary
- **Final DDD coefficient:** -0.480 (SE=0.153, p=0.003) — 79% decline in pastoral zone violence
- **Key robustness:** RI p=0.034, LOO [-0.546, -0.292], SGF -0.546 (p=0.009), PPML IRR=0.14, no spatial spillovers
- **Main limitation:** UCDP Type 2 broader than farmer-herder conflict; WCB infeasible with state×year FE
- **Process insight:** Advisor review caught 5 rounds of subtle consistency errors — the treatment timing fix was the most consequential, requiring full pipeline re-run
