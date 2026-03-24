## Discovery
- **Idea selected:** idea_1119 — Taiwan's 2010 R&D tax credit transition (SUI → IIA)
- **Data source:** PatentsView bulk downloads — BigQuery ADC not configured, successful pivot
- **Key risk:** Treatment definition scope (5 vs 22 classes) and pre-trend validation

## Execution
- **What worked:** Expanding treatment from 5 narrow USPC classes to 22 full SUI-scope classes dramatically improved pre-trends (flat) and statistical power. Annual aggregation better matched USPC coverage window (2003-2013).
- **What didn't:** BigQuery access failed (no ADC). PatentsView only has grants, not applications — weaker proxy for innovation effort. Citation truncation limits quality analysis.
- **Review feedback adopted:** (1) Tempered rhetoric throughout — "phantom credit?" not "phantom credit." (2) Added treatment mapping table. (3) Discussed dual treatment (controls also gain credits). (4) Added semiconductor demand confounding caveat. (5) Addressed grants-vs-applications limitation explicitly.
- **Review feedback noted for V2:** Event study figure (V1 zero-figure rule). Wild cluster bootstrap. Firm-level decomposition. Examiner-level analysis from manifest.
