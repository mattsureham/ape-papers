## Discovery
- **Idea selected:** idea_1892 — Civil asset forfeiture regulatory leakage via equitable sharing. Chosen for sharp institutional mechanism (jurisdictional arbitrage), massive microdata (7,620 agencies), staggered DiD with 36+ states, and named economic object ("escape valve")
- **Data source:** DOJ ESAC FOIA (justice.gov/afp/dl/ESACfoia.zip) — 29MB zip, pipe-delimited .txt files, 67,424 certifications. Clean and well-structured once format understood.
- **Key risk:** Smoke test suggested positive circumvention effect; DiD revealed opposite (null/negative). Raw trends misleading without proper controls.

## Execution
- **What worked:** ESAC data is rich and well-structured for agency-level panel analysis. Staggered DiD with 36 treated states and 14 never-treated provides clean identification. Reform coding from IJ reports is straightforward.
- **What didn't:** CS-DiD SEs are very wide (0.90 vs TWFE 0.11) due to unbalanced panel (only 8 agencies span all 16 years). NC had to be dropped (reformed in 2000, always-treated in panel). Initial data parsing broke because fread already handles numeric types — gsub("+") turned everything to NA.
- **Review feedback adopted:** Scaled back claims per GPT-5.4 (no more "precisely estimated null" or "illusion"); fixed reform state counts (18 conviction, not 21); gave state-level extensive margin results more prominence; acknowledged ESAC cannot distinguish adoptive from joint seizures in limitations
