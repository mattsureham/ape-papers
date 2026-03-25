## Discovery
- **Idea selected:** idea_1737 — Anchor store exit cascades via Bartik shift-share IV using chain bankruptcies
- **Data source:** Census CBP via API — worked perfectly, 269K rows, all 18 years (2005-2022). BDS download failed (404 on direct URL).
- **Key risk:** County-level aggregation dilutes tract-level effects; state-based exposure is too coarse vs. actual chain presence

## Execution
- **What worked:** Bartik shift-share with 9 chain bankruptcy events provided strong first stage (F=76). Leave-one-chain-out extremely stable (0.84-1.00). State×year FE specification absorbed state-level trends well.
- **What didn't:** (1) Initial treatment definition too liberal — had to restrict to 2010+ bankruptcy events only. (2) The "cascade" hypothesis was falsified — chain bankruptcies led to NET positive grocery entry, not exits. (3) Manufacturing placebo was significant, raising exclusion restriction concerns. (4) CS-DiD had pre-trend issues.
- **Review feedback adopted:** Softened title and claims from "no cascade" to "county-level evidence of replacement"; acknowledged symmetry assumption; reported manufacturing placebo honestly; restructured discussion to separate three claims of decreasing strength; elevated state×year FE to preferred specification.
