## Discovery
- **Idea selected:** idea_0956 — UK plastic bag charges × OSPAR beach litter, chosen for novel data (first causal test with actual pollution measurement) and staggered 4-nation design
- **Initial idea failed:** idea_1927 (SBA procurement) abandoned after USAspending API rate-limited; bulk files too large (400MB/agency)
- **Data source:** OSPAR Beach Litter Database via GitHub mirror (nicrie/seasonality_ospar) — 20 CSV files, 2001-2020
- **Key risk:** Only 4 treatment cohorts (nations), unbalanced panel, NI joined monitoring late

## Execution
- **What worked:** OSPAR data was clean and standardized; beach-to-nation mapping was straightforward; CS-DiD ran without issues once column naming was fixed
- **What didn't:** USAspending API completely blocked after ~345 initial calls; lost ~30 min on first idea
- **Surprising finding:** Null effect on bags despite 95% reduction in sales; bag SHARE of litter increased; the "pollution gap" framing emerged from the data
- **Review feedback adopted:** [pending reviews]
