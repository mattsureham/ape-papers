## Discovery
- **Idea selected:** idea_1228 — Germany's EEG solar bunching at 10 kWp. Chosen for massive sample (8.5M registry), textbook bunching design, and climate policy puzzle framing.
- **Data source:** OPSD Renewable Power Plants Germany (2020-08-25) — fallback from MaStR bulk download (too slow via open-mastr). Covers 2008-2018 (1.73M solar records).
- **Key risk:** Missing 2019-2024 data prevents the diff-in-discontinuities test (2021 threshold expansion to 30 kWp).

## Execution
- **What worked:** The bunching signal is spectacularly large (ratio 281:1 in single bins, b=113 in Kleven-Waseem). Pre-policy placebo is clean. Every German state shows the effect. The puzzle-first framing ("climate policy shrank the panels") writes itself.
- **What didn't:** MaStR bulk download via open-mastr was impractical (23,000 chunks, hours). OPSD was a clean fallback but lacks post-2018 data and module count / installation type fields. The welfare calculation requires strong counterfactual assumptions.
- **Review feedback adopted:** Added welfare sensitivity bounds (50-200 MW instead of point estimate), strengthened 2012 kink vs 2014 notch discussion in annual estimates, softened claims about 2021 reform.
- **Key lesson:** For bunching papers, the raw bin-level evidence is so compelling that the statistical apparatus (polynomial counterfactual, bootstrap) is almost secondary. The 281:1 ratio in adjacent bins tells the story.
