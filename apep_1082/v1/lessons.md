## Discovery
- **Idea selected:** idea_0642 — DV lottery eligibility loss and immigrant selection
- **Data source:** ACS PUMS (Census API) — 240K records, 2005-2023, 11 countries
- **Key risk:** Few treated units (4 countries) limits statistical power; mitigated by randomization inference and Callaway-Sant'Anna decomposition

## Execution
- **What worked:** ACS PUMS API reliable for all 18 years; country-year cell sizes adequate for most countries (>100/year for major origins); Callaway-Sant'Anna decomposition revealed meaningful heterogeneity hidden by pooled TWFE
- **What didn't:** Several planned control countries (Kenya, Ethiopia, Nepal, Tanzania) had too few ACS observations; Peru also dropped; DHS Yearbook Excel URLs all returned 404 (endpoint format has changed)
- **Review feedback adopted:** Reframed null as heterogeneity story; added power discussion; explained Bangladesh puzzle; added back-of-envelope policy calculation; acknowledged missing labor market second stage as limitation

## Key Findings
- Overall effect is a well-powered null (CS ATT = -0.65 pp, p = 0.69)
- Nigeria: 6-8 pp decline in college share after 2015 (significant)
- Bangladesh: opposite direction (confounding secular trends)
- The lottery channel matters only where it's a large share of total immigration
