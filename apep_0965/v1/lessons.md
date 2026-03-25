## Discovery
- **Idea selected:** idea_0917 — EU retaliatory tariffs on politically targeted US products. Compelling political economy puzzle with sharp institutional variation.
- **Data source:** Census QWI via public API — Azure DuckDB connection failed due to unquoted semicolons in connection string; bulk API calls (one per state×industry) completed in ~3 minutes.
- **Key risk:** Section 232 confounding for steel (NAICS 331) — US tariffs on imported steel simultaneously protected domestic steel producers.

## Execution
- **What worked:** The continuous DiD design with county×quarter panel (89,600 obs) gave clean identification. The asymmetry between targeted-industry employment (sharp decline) and total manufacturing (null) tells a compelling reallocation story. QWI's quarterly frequency reveals dynamics invisible in annual data.
- **What didn't:** Azure Blob access from R failed consistently. The SDE table and summary statistics table both had LaTeX formatting bugs (unescaped `%` characters, margin overflow) caught during visual QA.
- **Review feedback adopted:** Added targeted-industry event study discussion, decomposed leave-one-out results to explain Section 232 confounding, strengthened threats-to-validity section. All three reviewers flagged the same issues — good convergence.
