## Discovery
- **Idea selected:** idea_0484 — French carbon tax (TICPE) and RN populist vote shift, commune-level dose-response
- **Data source:** data.gouv.fr (elections), INSEE (census transport mode, Filosofi income) — all public, no API keys needed
- **Key risk:** Pre-existing correlation between car-dependency and RN voting confounding the carbon-tax effect

## Execution
- **What worked:** Massive sample (33,390 communes) with clean dose-response design. The 2011 census transport data contains multi-year snapshots (2011, 2016, 2022) in a single file, providing pre-treatment exposure.
- **What didn't:** data.gouv.fr resource URLs are unstable — all initial URLs returned 404. Had to use the API to discover correct dataset IDs. INSEE MobPro URLs also dead (500 errors). The election file formats differ across years (2022 XLSX with proper headers, 2017 XLS with skip rows, 2012/2007 multi-sheet XLS with different column layouts).
- **Surprise result:** Expected positive β (car dependency → more RN growth). Found NEGATIVE β for 2012-2017 and POSITIVE β for 2012-2022 — the gilets jaunes period flipped the sign. The pre-trend test (2007-2012) revealed car-dependent communes were already trending RN before any carbon tax, undermining the causal narrative.
- **Review feedback adopted:** Fixed incorrect claim about 2022 coefficient sign (was negative in text, actually positive). Toned down causal language to acknowledge pre-trend violation more honestly. Reframed conclusion around gilets jaunes timing distinction.
