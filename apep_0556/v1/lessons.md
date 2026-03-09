## Discovery
- **Policy chosen:** India's NRHM (2005) — bundled health worker deployment + JSY cash incentives. Clean Phase 1 vs Phase 2 variation across 28+ states, with 5 DHS/NFHS survey rounds spanning 1993-2020.
- **Ideas rejected:** (1) PM-JAY health insurance — all 3 ranking models flagged insufficient post-treatment data (only NFHS-5 after 2018 launch) and endogenous enrollment. (2) Banking the Unbanked Village (PMJDY + SHRUG) — SHRUG S3 data returns HTTP 403, making it infeasible.
- **Data source:** DHS Program API (subnational indicators, country code IA) + manually compiled SRS state-level IMR panel. DHS API works well but doesn't provide subnational NMR/IMR — had to pivot primary outcome to institutional delivery. World Bank API used for national NMR context.
- **Key risk:** Thin N (30 states × 3-5 surveys ≈ 90-150 obs) and NRHM as bundled treatment (can't isolate ASHA from JSY from facility upgrades). Addressed with continuous JSY intensity variation, RI (p=0.007), and LOO stability.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R2, Gemini, Codex passed; GPT R1 failed on 5-round panel geography)
- **Top criticism:** Both GPT referees flagged that the title/framing overclaimed mortality effects that were not causally identified. The estimand (differential early vs late NRHM, not total vs no NRHM) needed clearer framing throughout.
- **Surprise feedback:** Reviewer suggestion to use individual birth histories from DHS microdata with birth-level timing would fundamentally improve the design — flagged as the clear next step for a revision.
- **What changed:** Retitled paper (from mortality question to delivery focus), presented all-states as primary estimate, softened all pre-trend claims to "suggestive," added modern DiD citations (Goodman-Bacon, CS, SA), reframed facility quality paradox as hypothesis not conclusion, added NFHS-3 contamination and estimand interpretation paragraphs.
