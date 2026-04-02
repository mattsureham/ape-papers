## Discovery
- **Idea selected:** idea_1986 — California MPA staggered implementation with RCCA monitoring data
- **Data source:** SBC LTER KFCD (knb-lter-sbc.17) — the original RCCA data was only available as baseline snapshots (2011-12, 2014-15), not the full longitudinal panel. The SBC LTER provided 25 years of continuous annual surveys at 11 kelp forest sites.
- **Key risk:** Only 2 sites received MPA treatment in the usable data, creating a severe small-cluster inference problem.

## Execution
- **What worked:** The species-level triple-difference design (targeted vs non-targeted fish within sites) provides clean within-site identification that absorbs all common environmental variation. The DDD coefficient (p=0.012) is the paper's strongest result. The "harvest dividend" framing — that MPAs produce different fish, not more fish — is a memorable conceptual contribution.
- **What didn't:** The site-level DiD fails pre-trends (F=14.07) with only 2 treated sites. The original idea envisioned using the full RCCA dataset with 110+ sites and 3 staggered waves, but this data is not available for bulk public download — only baseline snapshots. The pivot to SBC LTER sacrificed sample size for time depth.
- **Review feedback adopted:** Reframed as case study (not network evaluation), toned down competitive displacement mechanism claims, added explicit limitations about 2-site design and external validity, expressed DDD result as percentages.
