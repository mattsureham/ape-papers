## Discovery
- **Idea selected:** idea_0902 — UK S60 stop-and-search relaxation; two-cohort staggered DiD with spatial displacement test
- **Data source:** police.uk bulk archives (monthly ZIP files ~1.6GB each) — the REST API was unusable due to severe rate limiting
- **Key risk:** Weak first stage if the policy relaxation didn't actually change policing behavior

## Execution
- **What worked:** The bulk download approach (download ZIP, extract CSV, delete ZIP, repeat) was reliable. Callaway-Sant'Anna estimator ran cleanly. The force-month panel (42 × 26 = 1,092 obs) was well-balanced.
- **What didn't:** (1) police.uk API rate limits killed the sequential/parallel fetch approaches — 502/429 errors after ~100 calls. (2) Bulk archives contained ~35 duplicate batch files per force — had to deduplicate by keeping only the latest batch, which caused a 27× inflation bug in the first analysis run. (3) Pre-trends for weapons crime failed (p=0.000), compromising the main causal claim.
- **Review feedback adopted:** Fixed unit inconsistencies (per 1,000 → per 100,000), clarified searches vs. authorizations distinction, strengthened pre-trends acknowledgment, added confidence interval interpretation in policy terms, acknowledged GDELT IV omission.

## Key Insight
The most interesting finding was a surprise: the policy failed at the FIRST STAGE. The S60 relaxation changed authorization rules but didn't change policing behavior. This is a stronger finding than the original displacement hypothesis — it identifies the specific failure mechanism (institutional inertia, street-level bureaucracy) rather than just the downstream outcome. Future UK policing papers should check whether legal threshold changes actually translate into operational changes before assuming they do.
