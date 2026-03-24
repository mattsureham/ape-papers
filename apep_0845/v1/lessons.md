## Discovery
- **Idea selected:** idea_0533 — EU Professional Qualifications Directive (2013/55/EU) and overqualification
- **Data source:** Eurostat LFS (lfsa_eoqgan) via `eurostat` R package — seamless, no API keys needed
- **Key risk:** Country-level analysis with only 17-24 countries for clustering; pre-trends noisy
- **Pivot:** Initially claimed idea_0761 (India PMFBY crop insurance). Failed after 20 min: ICRISAT data ends 2017, India MOA database down. Pivoted to EU idea with guaranteed data access.

## Execution
- **What worked:** Eurostat data ecosystem is excellent. 105K rows downloaded in seconds. Treatment variable (regulated professions count) from EC database is clean. Non-EU placebo provides compelling evidence the null is real.
- **What didn't:** CELLAR SPARQL for transposition dates returned parsing errors — fell back to manual dates from ECA Report. Initial sample had only 17 countries (EU-foreign breakdown); switching primary outcome to all-foreign gap expanded to 24 countries and passed the ≥20 treated units gate.
- **Review feedback adopted:** (1) Added country-specific linear trends robustness; (2) Toned down causal language about cultural frictions — now explicitly acknowledges implementation failure interpretation; (3) Added Blair & Chung magnitude comparison to discussion; (4) Fixed text-number inconsistencies.
