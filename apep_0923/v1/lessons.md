## Discovery
- **Idea selected:** idea_0971 — Switzerland AEOI and bilateral deposits. Chosen for sharp bilateral staggered design, massive data (200+ countries, BIS), and first-order policy question about financial transparency.
- **Data source:** BIS Locational Banking Statistics (bulk CSV, 511MB) — quarterly bilateral positions since 1977. Also SNB bank statistics and BFS employment data.
- **Key risk:** Endogeneity of AEOI timing to bilateral economic conditions. Mitigated by political determination of activation dates and four-wave staggered structure.

## Execution
- **What worked:** The BIS bulk download approach (after API endpoints returned 404). The staggered DiD with 209 countries × 56 quarters gave massive statistical power. The CS-DiD confirmed TWFE results.
- **What didn't:** Initial BIS API queries failed — the BIS SDMX API moved from `data.bis.org/api/v2` to `stats.bis.org/api/v2` (XML only) and `data.bis.org/static/bulk/` for CSVs. R's `download.file` timed out on the 120MB file; curl with 10-minute timeout succeeded.
- **Surprise finding:** AEOI activation *increased* bilateral deposits (+0.30 log points), reversing the expected sign. The "transparency dividend" is the named economic object — transparency formalized rather than destroyed Swiss banking.
- **Review feedback adopted:** All three reviewers (Codex-Mini, GPT-5.4, Qwen-3.5) flagged control group validity — never-treated developing nations are poor controls for EU/OECD countries. Ran eventually-treated-only robustness, which collapsed the coefficient to zero. Rewrote paper to present this as the credible finding (a well-powered null). Also tightened "deposits" → "liabilities" terminology per reviewer feedback. Did not add downstream employment analysis (reviewer suggestion) — deferred to V2.
