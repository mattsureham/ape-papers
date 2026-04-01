## Discovery
- **Idea selected:** idea_1719 — CMS hospice PPEO as a natural experiment for entry regulation effects on healthcare market structure
- **Data source:** CMS PECOS (enrollments, ownership) + CMS Hospice Quality Reporting — all public, no API keys
- **Key risk:** Only 4 treated states → standard cluster SEs unreliable; mitigated with RI and WCB

## Execution
- **What worked:** Clean data pipeline (PECOS enrollment dates parsed from IDs, 100% success). RI gave p < 0.001 despite 4 clusters — the effect is so large no random draw of 4 states comes close. For-profit/nonprofit decomposition is the central finding.
- **What didn't:** Per-beneficiary spending was NaN in quality data (formatting issue). CMS API has 500-row limit requiring CSV download instead. Quality data is cross-sectional only, limiting causal quality analysis.
- **Review feedback adopted:** (1) Added alternative mechanism discussion (capital constraint vs fraud screening), (2) Clarified sample construction for re-enrollments, (3) Fixed abstract to avoid implying causal quality effect, (4) Acknowledged TX LOO insignificance.
