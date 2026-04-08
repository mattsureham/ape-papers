# Lessons: apep_1423/v1 — The Ridgeline Discontinuity

## Discovery
- Watershed boundary designs are conceptually compelling (geologically determined treatment assignment) but the gap between the RDD/DiD ideal and what a cross-sectional snapshot can deliver is large. Reviewers uniformly flagged this.
- EPA data ecosystem is fragmented: ECHO API has a two-step QID system that's poorly documented; ATTAINS endpoints vary between REST and ArcGIS; FRS Wastewater GIS layer turned out to be the best single source.

## Review
- All three reviewers (Codex-mini, Qwen 3.5, DeepSeek V3.2) converged on the same three concerns: (1) cross-sectional design vs proposed panel DiD, (2) no spatial RD with distance-to-boundary, (3) reverse causality. This convergence suggests these are genuine weaknesses, not idiosyncratic preferences.
- Honest framing of limitations (MDE calculation, explicit acknowledgment of cross-sectional constraints) is better than defensive dismissal.

## Summary
- A precise null (β=0.003, SE=0.016) on 303(d) listing → facility compliance. The finding is informative: CWA listing adds a label but not a lever for major NPDES dischargers already under monitoring.
- HUC-12 assignment via USGS WBD point-in-polygon API is reliable but slow (~25 min for 4,589 facilities). Cache aggressively.
- The boundary sample construction (within-HUC-8 variation in listing status) yielded 2,276 facilities across 375 HUC-8s — adequate for inference but smaller than the manifest's 100K+ ambition.
