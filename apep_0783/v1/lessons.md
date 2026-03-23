## Discovery
- **Idea selected:** idea_1675 — USPS POStPlan dose-response DiD on rural business formation. Chosen for massive sample (2,740 treated counties), clean dose structure (2/4/6 hour reductions), and vivid mechanism.
- **Data source:** POStPlan office list from Save the Post Office Google Sheets (FOIA-sourced); Census BFS county-level annual Excel download. Both free, well-documented.
- **Key risk:** AWEL workload scores correlate with community size/economic health, so dose assignment may proxy for decline.

## Execution
- **What worked:** Pre-trends are clean (F=0.90, p=0.49). Dose-response is monotonic and scales as expected. The Level 18 placebo group provides a useful within-POStPlan comparison. BFS Excel bulk download was reliable after the API failed.
- **What didn't:** The original USPS PDF URL from the idea manifest was fabricated (404). The Census BFS API returned 400 errors for county-level queries — had to pivot to bulk Excel. The Level 18 placebo is marginally significant (p=0.03), suggesting some selection into POStPlan broadly.
- **Review feedback adopted:** Expanded threats-to-validity section with spatial spillover discussion and measurement error acknowledgment. Added Level 18 placebo interpretation. Clarified state-by-year FE attenuation logic (between vs. within-state variation). Noted future mechanism tests (money orders, bank branches, broadband). Clarified abstract language ("relative to unaffected counties").
