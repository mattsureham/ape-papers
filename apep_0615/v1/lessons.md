## Discovery
- **Idea selected:** idea_0144 — Drug price transparency laws and strategic threshold avoidance (bunching design)
- **Data source:** CMS NADAC via data.medicaid.gov datastore API — API had changed since manifest was written; required significant debugging (SODA API deprecated, POST-based JSON query API now required)
- **Key risk:** National pre/post design lacks cross-product variation; all NDCs face same national binding threshold

## Execution
- **What worked:** Semi-annual data construction solved the pre-period validation gate (8 pre-periods vs 4 with annual). NADAC API has excellent coverage (1.5M+ brand drug records). Bunching estimation implemented cleanly.
- **What didn't:** Original hypothesis of strategic threshold bunching was not supported — instead found entire distribution compression. Pivoted paper framing from bunching to "spotlight/deterrence" theory. The dose-response regression with n_laws is collinear with time, limiting causal identification.
- **Review feedback adopted:** Toned down causal language throughout (all 3 reviewers). Added NADAC-WAC mismatch discussion (Codex and GPT-5.4). Acknowledged semi-annual threshold frequency mismatch (Grok). Strengthened limitations section significantly. Not adopted: full CS-DiD redesign (too large for V1 single pass), WAC data acquisition (not publicly available at NDC level).
- **API lesson:** data.medicaid.gov now uses POST to `/api/1/datastore/query/{dataset_id}/0` with JSON conditions body. Max batch size is 5000. The old SODA API endpoints return HTML now.
