## Discovery
- **Policy chosen:** State salary history ban laws (20 jurisdictions, 2017-2024) — clean staggered adoption, first-order gender wage gap stakes, QWI provides unique new-hire vs continuing-worker mechanism test
- **Ideas rejected:** Fentanyl test strips (existing paper + treatment bunching), insulin copay caps (crowded + data mismatch), AVR (biennial data too sparse), RPS (saturated topic)
- **Data source:** Census QWI via API — universe employer-employee data with separate new hire earnings. Confirmed working via API tests.
- **Key risk:** Compositional changes in who gets hired post-ban could confound the wage-setting interpretation. Addressed with female hire share test.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT failed on internal consistency, Grok/Gemini/Codex passed)
- **Top criticism:** DDD needed state × worker-type FE; CS-DiD SEs were too small due to manual aggregation dividing by sqrt(N_cells)
- **Surprise feedback:** The `did` package v2.3.0 aggte() bug required manual aggregation, and naive SE computation treated group-time cells as independent — dramatically understating uncertainty
- **What changed:** Added state × worker-type FE to DDD, fixed CS-DiD SEs, added N to all tables, softened CS-DiD to "directional check"

## Summary
- **Result:** Precisely estimated null — salary history bans had no detectable aggregate effect
- **Key lesson:** Manual aggregation of group-time ATTs requires extreme care with SE computation. Do NOT divide by sqrt(N) when cells share common units.
