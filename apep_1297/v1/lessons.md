## Discovery
- **Idea selected:** idea_2269 — Ireland HTB bunching at €500K cap. Clean single-threshold design with built-in placebos.
- **Data source:** Property Price Register (propertypriceregister.ie) — per-year CSVs work; combined PPR-ALL.csv is broken (404). 768K transactions across 2010-2025.
- **Key risk:** Whether PPR would still be downloadable (it was, per-year files work fine).

## Execution
- **What worked:** The triple placebo design (second-hand, pre-HTB, non-policy thresholds) is very clean. The data quality is excellent — no missing prices, consistent schema. The bunching ratio (2.33) closely matched the idea manifest's smoke test (2.30).
- **What didn't:** The enhanced HTB period (July 2020-2022) shows lower bunching than expected, likely due to COVID compression. This is a real finding (fewer transactions) but complicates the difference-in-bunching story.
- **Review feedback adopted:** Clarified bootstrap is at transaction level; acknowledged quality vs price margin distinction in incidence discussion; added VAT rate footnote; noted no integration constraint imposed.
