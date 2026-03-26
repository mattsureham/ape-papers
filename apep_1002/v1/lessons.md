## Discovery
- **Idea selected:** idea_0331 — Czech EET abolition as natural experiment in formalization persistence
- **Data source:** Eurostat STS_RB_Q — clean quarterly business registration indices, no auth needed
- **Key risk:** Only 6 country-level clusters for inference

## Execution
- **What worked:** Introduction-and-repeal design is conceptually clean; Eurostat data fetched easily via `eurostat` R package; heterogeneity analysis revealed the real story (compliance ratchet in cash-intensive sectors)
- **What didn't:** Wild cluster bootstrap p-value = 0.32 with 6 clusters — aggregate significance is fragile; some pre-trend noise at t-7/t-5 (COVID recovery period); NACE sector codes are a mix of individual and aggregate categories creating some interpretation challenges
- **Review feedback adopted:** Tempered causal language (WCB p = 0.32 honest about aggregate fragility); reframed null in cash sectors as "absence of evidence for reversal" not definitive persistence; added registrations vs. compliance discussion; three-period structure (enforcement→suspension→abolition); additional references for tax compliance and informality literatures
