## Discovery
- **Idea selected:** idea_0992 — Swiss cantonal EV tax exemptions. Chose for clean institutional variation (26 cantons, 0-100% exemption rates), large municipality-level dataset, and novel channel (recurring annual taxes vs one-time purchase subsidies).
- **Data source:** BFS PXWeb API — API required careful batching (year × fuel type) to stay under 5,000 cell limit. Custom headers caused 403 errors; worked without them.
- **Key risk:** Only 26 canton-level clusters for inference, and treatment varies at canton level.

## Execution
- **What worked:** Triple-diff design (EV vs ICE within municipality) provided clean built-in placebo. The dose-response decomposition (full vs partial exemptions) transformed a null average effect into a sharp, publishable finding.
- **What didn't:** Border municipality test from the idea manifest was not implemented — would require geocoded municipality data. Worth adding in V2.
- **Review feedback adopted:** Added wild cluster bootstrap caveat (Cameron et al. 2008), formal Wald test for threshold, registration gaming discussion, expanded limitations on correlated cantonal policies.
