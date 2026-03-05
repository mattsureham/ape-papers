## Discovery
- **Policy chosen:** MuKEn 2014 (cantonal building energy codes) — first causal evidence on mandatory building decarbonization, 22 cantons staggered adoption, universe building-level heating data from GWR
- **Ideas rejected:** Municipal mergers (existing causal literature: Zell et al. 2025, Frey et al. 2023); HarmoS education concordat (only 15 treated cantons, limited achievement data); Physician admission restrictions (uncertain data access); HRM2 accounting reform (too niche, few treated cantons)
- **Data source:** GWR (Gebäude- und Wohnungsregister) via opendata.swiss for building-level heating systems; BFS PXWeb for construction/population; ENDK for adoption timing
- **Key risk:** 2016-2020 data gap coincides with treatment rollout; low power with 26 cantons

## Review
- **Advisor verdict:** 3 of 4 PASS (after 7 rounds — GPT failed on minor issues throughout, Grok/Gemini/Codex converged to PASS)
- **Top criticism:** Sun-Abraham SE is ~10x smaller than TWFE SE — all 3 referees flagged this as suspicious. VCOV PSD correction may produce artificially tight inference.
- **Surprise feedback:** Wood placebo failure was expected from the data but all 3 referees treated it as a much bigger threat than anticipated. Need to frame placebos proactively as limitations, not relegate to discussion.
- **What changed:** (1) Expanded SE divergence explanation with three contributing factors, (2) reframed wood placebo as explicit limitation weakening fossil/gas claims, (3) strengthened data gap estimand language, (4) rewrote opening paragraph, (5) added MDE power calculation

## Summary
- Swiss policy papers benefit from clean institutional variation but face small-N power constraints
- When TWFE and robust estimators diverge on significance, frame as "specification-sensitive" rather than promoting the significant result
- 7 advisor rounds is excessive — most failures were minor formatting/framing issues
- A failing placebo on a non-target outcome is a MAJOR red flag for identification, not a footnote
