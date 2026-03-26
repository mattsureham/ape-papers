## Discovery
- **Idea selected:** idea_0545 — European Investigation Order and crime deterrence. Zero empirical papers exist on this EU instrument, making novelty guaranteed. The staggered transposition across 25 member states provides clean DiD variation.
- **Data source:** Eurostat crim_off_cat + CELLAR SPARQL for transposition dates. Both free, no API keys. CELLAR SPARQL returned predecessor instrument measures (pre-2016) that needed filtering — future EU papers should date-filter NIMs.
- **Key risk:** Few never-treated controls (only DK, IE opted out). Addressed with not-yet-treated C-S specification.

## Execution
- **What worked:** EUR-Lex CELLAR SPARQL is excellent for building transposition panels programmatically. The `eurlex` R package template was unnecessary — direct SPARQL via httr2 was cleaner. The triple-difference design (cross-border vs domestic crimes) provided the paper's most interesting result.
- **What didn't:** fwildclusterboot package not available for R 4.3 — skipped WCB. The never-treated group (2 countries) was too small for standard C-S with nevertreated control; switching to notyettreated solved it.
- **Review feedback adopted:** Tempered detection-channel language from assertive to suggestive; added power/precision paragraph; addressed assault placebo anomaly; fixed Table 2 status labels; added SDE cross-reference in main text.
