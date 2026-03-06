## Discovery
- **Policy chosen:** USPTO green patent (Y02) IP regime — chosen because examiner IV is "gold-standard" per tournament judges, climate is first-order stakes, and Sampat & Williams (2019 AER) provides an exact template in a different domain.
- **Ideas rejected:** Immigration judge IV (ecological mismatch between individual treatment and county outcomes — all 3 models flagged this as fatal). ERPO suicide substitution (crowded literature, short post-periods for most adopters, policy bundling concerns).
- **Data source:** PatentsView bulk TSVs (confirmed accessible, well-documented) + USPTO PatEx for application-level outcomes (13M+ applications incl. denials).
- **Key risk:** Whether PatEx data is practically downloadable (JavaScript-rendered page). Fallback: construct instrument from PatentsView grants only using art-unit normalization.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 11 rounds — GPT R1, Gemini, Codex consistently passed; GPT R2 oscillated)
- **Top criticism:** Grants-only data limitation. The instrument is a grant share not a grant rate. All three referee reviews identified this as the central weakness. The paper cannot distinguish examiner permissiveness from workload/processing speed without application-level data (PatEx).
- **Surprise feedback:** GPT R1's R&R was extremely harsh — treated the paper as fundamentally unidentified, not just limited. The experienced-examiner subsample (-0.004, p=0.09) was flagged as potentially more informative than the full sample due to less measurement error, which is a good point we hadn't emphasized.
- **What changed:** (1) Rewrote Limitations section with explicit selection, aggregation, and local estimand subsections; (2) Added balance test caveat about grants-only balance; (3) Tempered all policy claims — removed "sideshow" conclusion, narrowed WTO claims; (4) Expanded experienced-examiner discussion; (5) Added workload confound to Threats to Validity; (6) Added Frakes & Wasserman (2017) citation.

## Summary
- **What worked:** Large-N precisely-estimated null is a genuine contribution. The citation-vs-patenting divergence is the paper's most interesting finding. Comprehensive robustness checks (Poisson, clustering, winsorization, experienced examiners, domain heterogeneity) strengthen the null.
- **What didn't:** PatEx data proved inaccessible (JavaScript-rendered bulk download page), forcing the grants-only approach. This is the paper's Achilles heel and was flagged by every reviewer. In hindsight, should have confirmed PatEx access before claiming the idea.
- **For future revisions:** If this paper is revised, the #1 priority is obtaining PatEx application-level data to construct a proper examiner grant rate and address sample selection. Everything else (cross-subclass outcomes, placebo tests, binscatter figures) is secondary.
