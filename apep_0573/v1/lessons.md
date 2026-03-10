## Discovery
- **Policy chosen:** EU 2014 Public Procurement Directives (2014/24/EU) — staggered transposition across 28 member states provides clean DiD variation
- **Ideas rejected:** Idea came from pinned idea database (idea_0514), no alternatives considered
- **Data source:** TED (Tenders Electronic Daily) contract award notices — required stream-processing architecture (download → aggregate → delete per year) to avoid disk exhaustion (~700MB per year uncompressed)
- **Key risk:** Only 28 clusters (member states) with compressed treatment timing (most transpose within 2015-2018); pre-trends marginal (F-test p=0.031)

## Execution
- **Stream processing essential:** TED CSVs are 200MB+ each. Original design tried to hold all 15 years in memory/disk simultaneously → disk full. Rewrote to process one year at a time.
- **SPARQL and API failures:** EUR-Lex CELLAR SPARQL for transposition dates failed; World Bank API for governance scores failed. Both required hand-coding from authoritative sources.
- **Variable quality issues:** open_proc_share was constant (all zeros) — TOP_TYPE field doesn't map cleanly to open procedure. processing_days was mostly zero — award date parsing unreliable. Both mechanism models failed to estimate.
- **Null result is the story:** TWFE = -0.005 (SE 0.015), C-S ATT = +0.014 (SE 0.052). The reform had no effect on competition. One positive: award ratio improved (-0.044, p=0.047). Framed as "procedural simplification doesn't overcome structural entry barriers."
- **Bacon decomposition clean:** 90.4% weight on treated-vs-untreated comparisons, minimizing TWFE bias concerns.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 5 rounds — GPT R2 remained skeptical throughout)
- **Top criticism:** Treatment timing misalignment — legal transposition date is a noisy proxy for actual implementation; award dates include contracts initiated pre-reform. This fundamentally limits causal interpretation.
- **Surprise feedback:** C-S SME result (-0.202) contradicted TWFE (+0.006); cohort decomposition revealed it's driven by a single 5-country cohort (CY, FI, HR, LV, SE). Advisors repeatedly flagged @CONTRIBUTOR_GITHUB placeholder (by design, publish script replaces it) — resolved by inserting actual names.
- **What changed:** Reframed all claims as "reduced-form association with transposition timing"; added extensive treatment timing limitation; softened RI language; added cohort decomposition of C-S SME; fixed figure legend (7→8 on-time states); clarified pairs bootstrap (was mislabeled as WCB); added processing_days variable definition.

## Summary
- **Key lesson:** For EU directive transposition designs, the gap between legal adoption and actual implementation is the Achilles heel. Future papers should either document first-stage implementation evidence or explicitly frame as ITT/reduced-form.
- **Pre-trends are more dangerous than expected:** A p<0.001 F-test cannot be argued away even with a null result. Rambachan-Roth is essential but doesn't make the problem disappear — it shows what the bounds look like under violations.
- **Advisor review is stochastic:** Same paper can fail one round and pass the next. Persistent issues: rounding consistency, internal cross-references, placeholder text. Systematic fixes (not cosmetic patches) are needed to get consistent PASS results.
