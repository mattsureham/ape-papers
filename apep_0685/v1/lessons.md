## Discovery
- **Idea selected:** idea_0031 — Canada's federal carbon backstop. First facility-level causal evidence on backstop effectiveness using ECCC GHGRP data.
- **Data source:** ECCC GHGRP (direct CSV via Azure API endpoint) + FRED WTI. The main data URL required URL-encoded path; R's download.file failed on the redirect, fixed with curl.
- **Key risk:** Few province clusters (N=6) for inference. Wild cluster bootstrap confirmed analytical p-values.

## Execution
- **What worked:** Clean facility-level panel (11,038 obs), 15 pre-periods. Gas decomposition as mechanism test was compelling — CO2 drives the effect, methane unchanged. Event study flat pre-trends. Multiple robustness checks all confirm.
- **What didn't:** TWFE and CS estimates differ substantially (14.6% vs 8.4%). The control group (BC/QC) already had carbon pricing, so the estimand is relative to existing provincial pricing, not vs. no pricing. This needed careful framing.
- **Review feedback adopted:** Reframed estimand throughout (relative to existing provincial pricing, not absolute); added OBPS discussion as limitation; softened "fuel switching" to "combustion-related adjustment" (no fuel use data to confirm); made welfare calculation more cautious; reported both TWFE and CS as co-primary (8-15% range); added wild bootstrap p-values to main text.
