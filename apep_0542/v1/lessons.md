## Discovery
- **Policy chosen:** HS2 Phase 2 cancellation (October 4, 2023) — surprise announcement shock with within-project control group and universe-scale Land Registry data
- **Ideas rejected:** Selective licensing (angle overlap with apep_0472), Wales 20mph (short post-period, predictable direction of effect)
- **Data source:** HM Land Registry Price Paid Data (24M+ transactions, bulk CSV, freely accessible) — confirmed working via smoke test
- **Key risk:** Post-period is only 5 quarters (Q4 2023 - Q4 2024); need to verify sufficient transactions near cancelled stations and clean pre-trends

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-5.4 R1 FAIL, GPT-5.4 R2 PASS, Gemini PASS, Codex PASS)
- **External reviews:** GPT-5.4 R1 R&R, GPT-5.4 R2 R&R, Gemini Minor Revision
- **Top criticism:** Pre-trends decisively violated — the DiD design cannot support causal claims. Control groups (London Phase 1 vs Northern Phase 2) are economically incomparable.
- **Surprise feedback:** All reviewers praised the transparency about design failure. Gemini said "top-journal ready" prose. GPT reviewers suggested corridor GIS data and monthly event timing as improvements.
- **What changed:** Softened "well-powered null" to "no detectable break"; added transaction timing lag discussion; cited Roth (2022); moderated Phase 1 placebo interpretation; added design limitation acknowledgments; recalibrated policy claims.

## Summary
- Paper honestly reports a null result with violated pre-trends — descriptive rather than causal
- The honest framing was praised but the design weakness limits journal placement
- Key lesson: for UK infrastructure studies, North-South housing divergence is the dominant confounder; future work needs more local geographic controls
- Transaction timing (completion vs exchange dates) is a first-order issue for UK housing event studies
