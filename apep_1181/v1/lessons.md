## Discovery
- **Idea selected:** idea_1975 — Germany's EEG clawback threshold and cross-border electricity flows. Picked for sharp policy lever (two exogenous threshold changes), unusually granular data (15-min bilateral flows), and 11 heterogeneous neighbors.
- **Data source:** Fraunhofer ISE Energy-Charts API — fully open, no API key needed. CBET endpoint returns all 11 neighbors in a single call (not per-neighbor as initially assumed). Values in GW, negative = German export.
- **Key risk:** Whether episode-level DiD has enough power to detect realistic effects.

## Execution
- **What worked:** The Energy-Charts API is excellent for electricity research — 15-min resolution bilateral flows are rare in the literature. The DiD design is clean and intuitive. The neighbor clawback stringency interaction turned out to be the most interesting finding.
- **What didn't:** Initial R code had wrong field names for the CBET API (expected `data`/`values`, got `countries` list structure). Also confused MDE (411 MW at 80% power) with CI bound (232 MW) — caught by consistency checker.
- **Review feedback adopted:** Added joint F-test for pre-trends, neighbor clawback stringency interaction (found significant result for Netherlands), improved precision of numbers throughout. Did not add within-episode RD (infeasible due to all-or-nothing clawback rule) or cross-country placebos (would require additional data fetch).
- **Key insight:** The paper evolved from a pure null to a nuanced finding about regulatory complementarity: clawback works only when both sides of the interconnector have strict rules.
