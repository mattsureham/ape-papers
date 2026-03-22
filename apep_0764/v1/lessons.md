## Discovery
- **Idea selected:** idea_1061 — Brazil's 2017 labor reform and intermittent contracts
- **Data source:** RAIS via BigQuery — 1.3M municipality-CNAE2-year rows, no issues
- **Key risk:** Bartik exposure using post-treatment (2019) sector rates

## Execution
- **What worked:** BigQuery access to RAIS is excellent — aggregation on server avoids downloading 2B rows. Municipality-specific linear trends cleanly resolve pre-trend violations for wages.
- **What didn't:** Naive Bartik DiD had severe pre-trend failures. SIDRA API returned 400 for PNAD data. Using 2018 (first reform year) adoption rates kills the result — too little variation with only 8K intermittent contracts nationally.
- **Key insight:** The pre-trend correction (municipality trends) is essential and itself constitutes a methodological contribution for Bartik designs in developing countries.
- **Review feedback adopted:** Tempered welfare claims to acknowledge composition channel; added leave-one-sector-out robustness; discussed 2018 vs 2019 exposure rates openly as limitation; reframed from "worker welfare harm" to "formal wage composition change."
