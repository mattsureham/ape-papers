## Discovery
- **Policy chosen:** France's 2018 PTZ/Pinel geographic withdrawal from zones B2/C — clear, discrete policy shock with multi-stage treatment intensity and universe outcome data (DVF)
- **Ideas rejected:** DPE rental ban (too similar to UK EPC paper apep_0477), SRU quotas (DVF pre-period too short for 2013 reform), flood risk PPRi (GIS complexity + most adoptions pre-DVF), rent control (too few treated cities for inference)
- **Data source:** DVF (data.gouv.fr, ~3.5M transactions/year), Sitadel construction permits, ABC zone classification — all open data, no authentication required for core analysis
- **Key risk:** COVID confound for 2020 full elimination overlaps with pandemic; mitigated by commercial property placebo and pre-COVID 2018-2019 sub-period analysis

## Review
- **Advisor verdict:** 4 of 4 PASS (after 8 iterations fixing subtle consistency issues)
- **Top criticism:** GPT-5.2 raised fundamental concern about B1 as credible counterfactual for B2/C—differential exposure to macro/urbanization shocks not addressed by département clustering alone. Region×year FE would be the proper fix.
- **Surprise feedback:** GPT pointed out that PTZ subsidy value should be measured as PV of interest savings (~€5-15K), not loan principal (~€30-50K). This substantially changes the capitalization rate interpretation (from 4-6% to 12-35%).
- **What changed:** (1) Softened mechanism claims from definitive to "suggestive"; (2) Rewrote welfare section with PV-of-subsidy benchmark; (3) Added explicit estimand definition; (4) Added selection-into-sample discussion; (5) Moved 2 figures to appendix; (6) Sharpened prose (opening hook, removed roadmap, lead-with-facts); (7) Added Conley/Roth/Mense citations; (8) Fixed \euro undefined control sequence.

## Summary
- **Biggest lesson:** The difference between "loan principal" and "PV of interest savings" fundamentally changes subsidy incidence calculations. Always think about what the economic value of a policy instrument is to the marginal agent, not its face value.
- **Process:** Advisor review loop (8 rounds) was the bottleneck—each round surfaced new text-consistency issues. The fix was systematic: read every data claim against the source tables and figures.
- **For next France paper:** DVF is excellent but commune-year medians create a severe selection issue (8K of 168K commune-years). Consider EPCI-level aggregation or transaction-level hedonics.
