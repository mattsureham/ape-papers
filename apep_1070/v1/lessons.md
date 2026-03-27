## Discovery
- **Idea selected:** idea_1469 — H-2A guestworker expansion DDD using DOL certification data × QWI ethnicity panel
- **Data source:** DOL FLC disclosure files (FY2018-2023) + QWI race/ethnicity from Azure — older DOL files (pre-2018) removed from DOL website, limiting pre-period analysis
- **Key risk:** Selection bias in OLS — counties requesting more H-2A have declining domestic labor supply

## Execution
- **What worked:** The "displacement mirage" narrative — OLS shows substitution, Bartik IV shows null. Clean placebos in non-H-2A industries. Strong institutional detail (H-2A workers excluded from QWI by design).
- **What didn't:** DOL data only available FY2018-2023 (originally planned 2012-2022). This weakened pre-trend analysis substantially. DuckDB Azure connection required manual connection string loading due to semicolon parsing issue.
- **Review feedback adopted:** Strengthened IV caveats (attenuating rather than definitively proving), added QWI suppression caveat, acknowledged pre-trend limitation more explicitly, noted complementarity as alternative interpretation.
