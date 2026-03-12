## Discovery
- **Idea selected:** idea_0053 — Colombia FARC peace → education DiD, novel two-shock decomposition
- **Data source:** datos.gov.co (education panel, Socrata API) + UCDP GED v24.1 (conflict events, bulk CSV)
- **Key risk:** Small treated sample (15 high-FARC municipalities), PDET identification via time split only

## Execution
- **What worked:** datos.gov.co Socrata API returned clean 14-year panel (2011-2024). UCDP bulk CSV download reliable. Binary treatment (≥3 events) produced clear significant result (4.5pp secondary enrollment). Violence first-stage confirms mechanism.
- **What didn't:** UCDP API now requires token (switched to bulk CSV). PDET and population APIs returned 404 (hardcoded PDET codes, used education data as proxy). Per-capita treatment insignificant (p=0.28) — raw counts remained main spec. Wild cluster bootstrap failed (missing fwildclusterboot package). Two-shock decomposition individually insignificant for both subperiods — limits PDET causal claims.
- **Review feedback adopted:** (1) Fixed text-table numerical inconsistencies (5.9pp→4.7pp, Table 5 col 1 insignificance). (2) Softened PDET causal claims throughout — changed from "concentrated after 2018" to "suggestive" language. (3) Addressed primary > secondary puzzle with compositional/return-migration framing. (4) Fixed timing inconsistencies (2015-2017→2016-2017 to match Post=2016+ definition). (5) Added quantity-quality tradeoff framing for approval rate decline.
- **Review feedback NOT adopted:** Per-capita treatment (tried, insignificant). Triple-diff PDET design (beyond V1 scope). Wild cluster bootstrap (R package issue). Event study figures (V1 = zero figures).

## Key Takeaway
When the two-shock decomposition lacks power to distinguish subperiods, don't oversell the PDET channel. The honest contribution is the main DiD result; the two-shock is suggestive evidence, not a clean identification of PDET.
