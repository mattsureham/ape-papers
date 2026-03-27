## Discovery
- **Idea selected:** idea_1987 — Coal-tar sealant bans + WQP data. Chosen after 5 overlap rejections on other ideas.
- **Data source:** USGS Water Data API (new endpoint; old WQP API was returning 400 errors). 13,161 fluoranthene records across 35 states.
- **Key risk:** Monitoring network too sparse for causal inference. This turned out to be the paper's central finding.

## Execution
- **What worked:** The `read_USGS_samples()` function from `dataRetrieval` v2.7.18 accessed USGS data reliably. The staggered DiD framework (Callaway-Sant'Anna + TWFE) ran cleanly. All tables generated from code. The "cautionary finding" framing turned a potential failure into a contribution.
- **What didn't:** WQP's legacy API was completely broken (HTTP 400 on all states). Panel sparsity (most stations: 3-5 obs over 26 years) crippled the CS estimator. State-level treatment assignment was too coarse. 63.7% non-detect rate introduced measurement artifacts. The lead placebo test was the most damaging result — it showed confounding that can't be addressed with this design.
- **Review feedback adopted:** Tempered the "monitoring data can't work" conclusion to "state-level DiD on existing data can't, but purpose-built monitoring could." Added explicit limitations section noting Austin omission, spatial dilution, non-detect bias, and water vs sediment choice. Added power calculation to make the monitoring critique constructive. Three reviewers all flagged the same issues — high agreement on the core limitations.

## Key Insight
Environmental chemistry data is abundant but was designed for compliance monitoring, not policy evaluation. The spatial density, temporal regularity, and site-selection logic needed for causal inference are fundamentally different from those needed to flag regulatory exceedances. This is a structural gap in environmental governance that affects not just sealant bans but any product-specific environmental regulation.
