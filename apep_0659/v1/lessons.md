## Discovery
- **Idea selected:** idea_0223 — Ethnic enclaves as insurance during Great Depression using IPUMS MLP linked census panel
- **Data source:** Azure Blob Storage (IPUMS MLP pre-loaded) — 3-decade panel (1920-1930-1940), full-count census co-ethnic shares
- **Key risk:** Endogenous sorting (immigrants choose counties; county characteristics drive both enclave density and outcomes)

## Execution
- **What worked:** Azure data access via DuckDB; cross-sectional OLS with nationality and state FE; boom-vs-bust comparison as validation device
- **What didn't:** Initial self-employment rates were wrong (SQL CLASSWKR IN (1,2) counted wage workers); MLP panel lacks `lit_1920` variable (used `school_1920` instead); Azure connection string truncated by shell `source .env` (semicolons in connection string)
- **Key pivot:** Boom-period "placebo" showed significant negative effect (β = -0.272***), transforming the paper from "enclaves help during crises" to "enclave paradox — same institution traps during booms, insures during busts"
- **Review feedback adopted:** Strengthened identification section with explicit endogeneity discussion, acknowledged industry-confound concern, clarified "insurance" as relative stabilization not absolute protection, contextualized effect magnitude in SD terms, expanded limitations section
