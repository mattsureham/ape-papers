## Discovery
- **Idea selected:** idea_1809 — "Treatment Dividend" of hydrocodone rescheduling. Sharp federal supply shock + novel T-MSIS outcome.
- **Data source:** DEA ARCOS (Azure, 178M rows) + CMS T-MSIS (Azure, 227M rows). Both worked well. NPPES API for geocoding (98.6% success on 5,143 NPIs).
- **Key risk:** Time gap between instrument (2006-2012 ARCOS) and outcome (2018-2024 T-MSIS). No overlap for panel DiD.

## Execution
- **What worked:** Azure data pipeline, shift-share instrument construction, NPPES geocoding at scale, placebo test design, honest null reporting
- **What didn't:** Cross-sectional identification too weak — balance test fails (F=6.0), jackknife shows sign instability, CIs too wide to distinguish zero from large effects. FIPS matching required two iterations. Census ZIP crosswalk had parsing issues.
- **Review feedback adopted:** Fixed methadone/buprenorphine inconsistency in results text (buprenorphine shows strongest signal, not methadone as initially claimed). Tempered causal language throughout.
- **Key lesson for future opioid papers:** If ARCOS only goes to 2012 in Azure but the T-MSIS starts in 2018, there is no overlap window for a panel design. Future work should source ARCOS 2013-2019 from Notre Dame API or use SAMHSA TEDS for pre-period treatment outcomes. The cross-sectional design fundamentally cannot distinguish historical prescribing patterns from the causal effect of the rescheduling.
