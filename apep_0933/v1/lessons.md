## Discovery
- **Idea selected:** idea_0981 — Mandatory BNG and housing development in England. Picked after two failed claims (Norway caseworker IV needed individual microdata; Swiss MuKEn had 92% overlap with existing paper).
- **Data source:** DLUHC PS1/PS2 planning statistics + Brownfield Land Register — all public CSVs, no API keys needed.
- **Key risk:** Post-treatment window (7 quarters) might be too short for planning pipeline effects.

## Execution
- **What worked:** The heterogeneous-intensity DiD design with brownfield availability as treatment intensity was clean and intuitive. The event study showed flat pre-trends, lending strong support to the identifying assumption.
- **What didn't:** Initial data fetching used stale URLs (404s). The brownfield entity-to-GSS mapping required debugging — `statistical-geography` was the correct column, not `reference`. The etable output from fixest initially produced duplicate FE indicator rows.
- **Review feedback adopted:** Added triple-DiD paragraph (staggered rollout), noted early adopter exclusion doesn't affect results, acknowledged Land Registry data as future work.
