## Discovery
- **Idea selected:** idea_2013 — COVID-era anti-Asian sentiment and sectoral reallocation of Asian American workers. Chosen after 6 overlap-blocked claims. Zero overlap with existing APEP papers.
- **Data source:** Census QWI (Azure Parquet) + Census ACS (API). GDELT BigQuery was planned but unavailable (no gcloud ADC).
- **Key risk:** Binary post-COVID treatment instead of continuous GDELT media intensity weakens the discrimination-specific causal claim.

## Execution
- **What worked:** QWI race × industry data from Azure provides rich state-quarter panels. The DDD design (Asian × customer-facing × post-COVID) yields very strong, robust results (-11.3%). Event study shows clean immediate pre-trends and sharp onset.
- **What didn't:** Azure connection string handling in bash (semicolons truncated). BigQuery credentials missing. Had to pivot from continuous GDELT treatment to binary indicator + cross-sectional ACS population shares.
- **Review feedback adopted:** Softened "permanent" to "persistent" language. Acknowledged GDELT absence explicitly. Clarified that reallocation symmetry is partly mechanical. Noted pre-trend concerns at longer horizons.

## Key finding
Asian employment in customer-facing sectors fell 11.3% relative to the triple-difference counterfactual after COVID onset. The displacement was symmetric — knowledge sectors gained equally. States with larger Asian populations experienced less displacement ("safety in numbers"), suggesting co-ethnic networks buffer discrimination shocks. The effect persists through 2024 but is gradually attenuating.
