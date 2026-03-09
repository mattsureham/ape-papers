## Discovery
- **Policy chosen:** Kenya's 2016 interest rate cap + 2019 repeal — symmetric on/off natural experiment in credit market regulation, rare globally (one of very few countries to both impose and repeal a rate cap)
- **Ideas rejected:** Constitutional marginalization fund (47 counties, 2 periods, too thin); free maternity/devolution (diffuse treatment, capacity endogenous); Inua Jamii pension RDD (survey-based RDD too thin); SGR railway (NEEDS_WORK)
- **Data source:** CBK supervisory data (bank-level annual balance sheets + monthly aggregates) — PDFs need parsing but universe coverage of all 42 banks. World Bank WDI for cross-country context.
- **Key risk:** CBK Annual Report PDFs may require manual table extraction; COVID contaminates repeal window (4-month clean window available)

## Review
- **Advisor verdict:** 4 of 4 PASS (round 8; earlier rounds failed on incomplete RI coverage and figure issues)
- **Top criticism:** Only 3 cross-sectional units (tier-year aggregates) — both GPT referees flagged this as the fundamental design limitation that prevents clean causal claims. RI exchangeability questioned since tier labels are structural, not randomly assigned.
- **Surprise feedback:** Gemini gave Minor Revision (nearly accepted), praising the design — sharp contrast with both GPT referees who gave R&R. This split highlights that the paper's strength is the natural experiment framing and the weakness is the small-N inference.
- **What changed:** (1) Systematic language calibration — softened all causal claims to "suggestive evidence of persistent effects"; (2) Added RI validity caveat section; (3) Computed RI for all 4 outcomes (not just loan/asset); (4) Consolidated figures into multi-panel; (5) Expanded limitations to 5 items; (6) Renamed mechanisms section with evidence hierarchy; (7) Distinguished stock vs flow in post-repeal interpretation.

## Summary
- **Key lesson:** With only 3 cross-sectional units, the ceiling for causal claims is low regardless of how clever the identification seems. Language calibration is essential — present findings as suggestive evidence from a rare natural experiment, not definitive causal proof.
- **What worked well:** The symmetric on/off policy experiment is genuinely compelling as a case study. Cross-country context adds value. RI permutation test provides some inferential discipline despite small N.
- **What to improve:** Future Kenya banking papers should seek bank-level microdata (not just tier aggregates) to support stronger causal claims. The Tier 3 compositional change (22→16 banks) is a real threat that cannot be resolved without unit-level data.
