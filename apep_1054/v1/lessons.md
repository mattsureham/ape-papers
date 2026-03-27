## Discovery
- **Idea selected:** idea_1072 — Mexico's 2022 DST abolition with border exemptions, a spatial quasi-experiment for darkness and crime
- **Data source:** SESNSP (Secretariado Ejecutivo) municipality-month crime data, downloaded via SharePoint ZIP (133 MB, 2.56M rows)
- **Key risk:** Small control group (27 border municipalities) and whether border vs non-border municipalities have parallel crime trends

## Execution
- **What worked:** The within-state design with state × year-month FEs cleanly absorbs state-level shocks. Triple-difference aligning treatment with DST-active months resolves the attenuation concern. Excluding Sonora (already on permanent standard time like Arizona) eliminated a puzzling white-collar crime placebo failure.
- **What didn't:** Initial 5-state sample included Sonora, which had no treatment variation and introduced spurious effects. SharePoint data download required redirect following. The XLSX files needed manual concatenation after the CSV was accidentally deleted.
- **Review feedback adopted:** (1) Excluded Sonora per institutional analysis, (2) Triple-diff as main specification, (3) Added power discussion comparing to Doleac & Sanders magnitudes, (4) Updated event-study reporting with full coefficients.
