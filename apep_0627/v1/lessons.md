# Lessons: apep_0627/v1

## Discovery
- The Wales 20mph policy creates a textbook DiD setting: single treatment date, clear treated/control groups, England as counterfactual.
- STATS19 data is freely available and well-structured, but URL patterns for historical years (pre-2020) may differ from recent years. The fetch script successfully downloaded 2020-2024 but the 2018-2019 files appear to use different naming conventions on the DfT portal.

## Execution
- V1 papers cannot include figures — this constraint requires restructuring the paper to rely entirely on tables for empirical evidence. Event study results were tabulated instead of plotted.
- The `factor()` type in R data.table causes errors with `min()`/`max()` — use `as.character()` before comparison operations on factor columns.
- Cairo PDF device is not available on this system — use standard `pdf()` device via `ggsave()` without specifying `device = cairo_pdf`.

## Results
- **Headline finding:** Pedestrian KSI declined 30% (p<0.001), but overall KSI showed no effect. The policy benefit is concentrated among vulnerable road users.
- The null on overall KSI but strong significance on pedestrian KSI is consistent with the physics of speed-injury curves (highly nonlinear for pedestrians).
- High-speed road placebo is clean (null), supporting identification.
- Placebo test at Sep 2022 raises a minor concern for total collisions (p=0.03) but is clean for KSI (p=0.27).
- Border LA subsample shows larger effects, consistent with better geographic comparability.

## Review
- (To be filled after reviews complete)
