## Discovery
- **Idea selected:** idea_0880 — EU safe country of origin DDD. Sharp triple-diff with built-in placebos, public Eurostat data, timely policy relevance (EU common list Dec 2025).
- **Data source:** Eurostat migr_asydcfsta + migr_asyappctza — clean API access, 21.9M decision rows. Column naming differed from expected (POS/NEG not TOTAL_POS/REJECTED, FRST not ASY_APP).
- **Key risk:** SCO treatment matrix construction from legislative sources; binary treatment coding may miss implementation intensity variation.

## Execution
- **What worked:** The triple-diff design produced a cleanly interpretable null on recognition rates with a strong mechanism decomposition (deterrence + system-wide spillovers). The paper narrative ("Designation Illusion") writes itself once you see the coefficient collapse from -10.3pp to -0.6pp.
- **What didn't:** The spillover/diversion specification initially confused reviewers — negative coefficient means fewer apps in non-designating countries (system-wide deterrence), not more. Needed clearer framing. Pre-trends at t-4/t-3 required explicit interpretation.
- **Review feedback adopted:** Clarified diversion→spillover language; added MDE/power discussion; explained pre-trends as crisis timing; added measurement error limitation in Discussion.
