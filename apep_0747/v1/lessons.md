## Discovery
- **Idea selected:** idea_1674 — First causal test of "Coming to the Nuisance" hypothesis from Banzhaf-Ma-Timmins (2019 JEP)
- **Data source:** Census ACS API + USDA NASS QuickStats — both worked flawlessly
- **Key risk:** Only 7 treated states; state-level clustering with few clusters

## Execution
- **What worked:** Triple-difference design (state RTF × county CAFO density × time) cleanly separates nuisance-specific effects from state-level confounders. Continuous intensity model with state×year FE is the strongest result (p=0.005). Placebo test (low-CAFO counties) delivers precise null.
- **What didn't:** FHFA HPI not available at county level for property value channel test. ACS 5-year overlapping estimates create mechanical serial correlation. CS-DiD shows some pre-trend concerns at longer horizons.
- **Review feedback adopted:** Added explicit discussion of ACS overlap limitation, property value channel gap, and inference concerns with 7 clusters. Emphasized continuous intensity specification as main result since it uses state×year FE and is less affected by clustering.
- **Key insight:** The continuous intensity specification (exploiting within-state variation with state×year FE) is a more credible design than the binary DDD when treated clusters are few. Future CAFO/environmental justice papers should pursue parcel-level transaction data for property value channel.
