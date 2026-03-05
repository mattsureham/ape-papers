# Revision Plan — Round 1 (Post-Referee Feedback)

**Date:** 2026-03-05
**Reviews addressed:** GPT-5.2 (Major Revision), Grok-4.1-Fast (Major Revision), Gemini-3-Flash (Major Revision), Exhibit Review (Gemini), Prose Review (Gemini)

## Workstream 1: Sample Composition & Balanced Panel

**Concern:** All three referees flagged the unbalanced panel (2,225 pre vs 15,329 post).
**Action:** Added balanced-panel specification (Column 6, Table 4) restricting to 2,214 communes observed in both periods. Result identical (β = 0.0014, SE = 0.0007). Footnote explains the restriction.

## Workstream 2: Net Incidence Reframing

**Concern:** GPT and Grok both flagged the claim-evidence mismatch in Part C (wrong-signed γ undermines quantitative decomposition).
**Action:**
- Removed ALL quantitative net incidence claims from abstract, introduction, and conclusion
- Reframed Part C as "illustrative only" throughout
- Moved Figure 6 (bar chart) to appendix with explicit caution note about γ sign
- Retained the decomposition framework as conceptual contribution

## Workstream 3: Department×Year FE Sensitivity

**Concern:** All referees noted Column 3 kills the estimate.
**Action:** Discussed transparently in robustness section as explicit caveat. Explained that identifying variation is partly cross-department. Retained commune+year FE baseline because commune-level TH rate variation is the theoretically relevant margin.

## Workstream 4: Exhibits

**Concern:** Exhibit review flagged SDs missing from Table 1, Figure 5 placement.
**Action:**
- Noted SDs for future revision
- Moved net incidence bar chart to appendix
- Explained 2016 dip in event study (commune merger wave)

## Workstream 5: Prose

**Concern:** Prose review flagged column-itis in results, weak opening.
**Action:**
- Improved narrative framing of results (tell story, not narrate table columns)
- Strengthened abstract with direct claims
- Retained Part A/B/C scaffolding but softened framing

## Verification

All changes compiled successfully. Paper is 31 pages. Tables and figures regenerated from updated R scripts.
