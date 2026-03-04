## Discovery
- **Policy chosen:** Action Cœur de Ville (ACV) — €5B place-based revitalization of 222 medium-sized French cities (2018). Chosen because: no causal evaluation exists (Cour des Comptes gap), 244 treated clusters, DVF universe data, 7yr post-period, speaks to global place-based policy literature.
- **Ideas rejected:** DPE/passoire thermique (more RDD than DiD, DPE data only post-2021); TLV vacancy tax (only 1.5yr post-period); ZRR rural zones (less exciting framing, rural communes have thin DVF data).
- **Data source:** DVF bulk download (518MB, 2014-2025) + ACV city list (data.gouv.fr, verified with INSEE codes) + hybrid API/bulk approach
- **Key risk:** COVID-19 confound (2020-2022 medium-city revaluation)

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex; Gemini FAIL on partial year data)
- **Top criticism:** Control group rural/urban mismatch — all three referees flagged this as the primary identification concern
- **Surprise feedback:** The compositional interpretation (commune-level +7% but transaction-level null) was praised by all reviewers as the most interesting finding
- **What changed:** Added composition figure (apartment share trends), fixed region mapping (Occitanie split bug), added set.seed for reproducibility, fixed \floatfoot and \euro commands, reconciled 222/244/230 treated commune counts, added DVF release timing footnote

## Summary
- **Key lesson:** The most interesting finding emerged from honest reporting — the divergence between commune-level and transaction-level estimates revealed composition effects that are more nuanced and scientifically valuable than a simple "prices went up" result.
- **Technical issues:** ~7 advisor review rounds needed due to cascading issues (placeholder text, undefined LaTeX commands, inconsistent numbers). Front-loading LaTeX quality would save substantial time.
- **Data engineering:** Combining API + bulk DVF requires careful commune code harmonization. The 270→713 control expansion from inconsistent commune codes was a persistent reviewer concern.
