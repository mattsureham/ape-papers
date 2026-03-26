## Discovery
- **Idea selected:** idea_0913 — EU Landing Obligation's phased species-group implementation as staggered natural experiment; zero causal evaluations exist in the literature
- **Data source:** Eurostat fish_ca_main (catches), fish_ld_main (landings), fish_fleet_gp (fleet) — all open, no API keys
- **Key risk:** Species-group aggregation demands strong parallel trends assumption across biologically distinct fisheries

## Execution
- **What worked:** The staggered species-group DiD produced a stark asymmetry: demersal catches collapsed while pelagic catches were unaffected. DDD (EU × demersal × post) significant at 1%. Norway/Iceland placebo clean. Leave-one-out: all 15 negative.
- **What didn't:** WCB p=0.204 with 17 clusters — few-cluster inference undermines conventional significance. Placebo at 2012 shows marginal pre-trend (-0.237, p=0.08), suggesting confounding from TAC tightening. CS-DiD aggregate ATT near zero while TWFE for demersal is large — inconsistency between estimators that reviewers flagged.
- **Review feedback adopted:** Softened language around causal claims given WCB p-value. Removed €28-41B extrapolation. Added explicit caveats about TAC confounding and aggregation limitations. Acknowledged need for species-level analysis and STECF discard data in future work.
