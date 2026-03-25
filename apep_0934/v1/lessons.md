## Discovery
- **Idea selected:** idea_0630 — Denmark's køberetsordning (wind turbine purchase-right lottery). Chosen for the lottery IV potential and novel policy setting.
- **Data source:** Energidataservice CapacityPerMunicipality + DST StatBank (EJDFOE1, VALGK3, FOLK1A, INDKP106). The ens.dk domain was unreachable; Energidataservice was the fallback.
- **Key risk:** Municipality-level aggregation is too coarse; individual lottery data is inaccessible.

## Execution
- **What worked:** The staggered DiD design with 49 treated vs 48 control municipalities produced clean results. The placebo test (pre-existing wind sites had 10% lower growth) was the most informative diagnostic — it shows why TWFE is contaminated and validates the CS-DiD null.
- **What didn't:** Could not access the Energistyrelsen lottery records or koeberetsordningen.dk project database. The DST API required exact variable code matching and had content-type issues (text/json).
- **Review feedback adopted:** Added clarifying paragraphs about what the treatment identifies (joint turbine + ownership effect, not pure ownership) and the lottery data limitation. Reviewers correctly noted this is the key weakness.
