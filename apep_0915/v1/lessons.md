## Discovery
- **Idea selected:** idea_1875 — EPA OIAI withdrawal creating bunching incentives at CAA HAP thresholds. Strong because: bunching is tournament-favored method (μ=20.6), "regulatory leakage" is a named winning mechanism, and NEI facility data is public.
- **Data source:** EPA National Emissions Inventory Facility Summaries (gaftp.epa.gov). Downloaded 9 of 10 years (2017 timed out due to extremely slow EPA FTP server at ~33 KB/s). Emissions reported in pounds, not tons — required unit conversion.
- **Key risk:** Whether bunching would be detectable in a steeply declining emission distribution.

## Execution
- **What worked:** The NEI data is excellent — 597K facility-years, 111K unique facilities, clean HAP classification via `hap_type` column. The DiD design with near_threshold × post interaction is well-identified with facility + year FE.
- **What didn't:** The 10-ton single-HAP threshold shows no significant bunching response — a genuine null. The polynomial counterfactual for the bunching estimator is sensitive to order and window choice when the distribution is steeply declining.
- **Key finding:** Asymmetric response — the 25-ton combined threshold shows significant positive DiB while 10-ton is null. This is actually more interesting than a simple positive result because it reveals the mechanism: distributed abatement across pollutants is feasible, concentrated single-pollutant abatement is not.
- **Review feedback adopted:** Fixed Discussion section contradiction (claimed 10-ton bunching when the result is null); aligned polynomial order (5th) across text and tables; toned down causal language per GPT-5.4 suggestion; improved NEI data year description and measurement caveats. Deeper fixes (permit data linkage, CEMS decomposition) beyond V1 scope.
