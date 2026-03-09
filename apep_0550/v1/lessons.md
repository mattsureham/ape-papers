## Discovery
- **Policy chosen:** India's 2020 farm laws pass-and-repeal — the symmetric ON-OFF structure is rare and provides built-in reversal test
- **Ideas rejected:** Export bans (overlaps apep_0220), bank branches (needs SHRUG download), farm loan waivers (needs CMIE subscription), NEET RDD (requires PDF scraping)
- **Data source:** Pivoted from AGMARKNET/data.gov.in API (unreliable: 10 records/page, rate limiting) to WFP/VAM via HDX (instant download, 139K records, 169 markets, 28 states)
- **Key risk:** WFP captures retail prices, not wholesale mandi prices. The farm laws targeted wholesale regulation — realized as null result on retail prices.

## Execution
- **Data challenge:** data.gov.in API fundamentally broken for bulk access. Six different download scripts all failed. HDX/WFP was the solution.
- **Result:** Null — farm laws had zero effect on retail commodity prices (RI p=0.52)
- **Honest null:** Reframed paper around the null as a contribution. Three mechanisms discussed: brief implementation, wholesale-retail disconnect, mandis as genuine infrastructure.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-5.4 R1 PASS, GPT-5.4 R2 PASS, Gemini PASS, Codex FAIL)
- **Top criticism:** "Precisely estimated null" overclaimed — reviewers wanted explicit CI bounds and narrower scope claims (retail prices only, not farm laws broadly)
- **Surprise feedback:** Wild cluster bootstrap incompatible with feols + high-dimensional FE (fwildclusterboot package limitation); reverse-treatment placebo acknowledged as mechanically uninformative in a linear model
- **What changed:** (1) Replaced "precisely estimated null" throughout with "no evidence of large retail price effects" + CI bounds; (2) Added 5 new robustness checks: balanced sample (122/139 cells), state-specific trends, split OFF period, formal pre-trend test (p=0.43), 7 placebo onset dates; (3) Toned down symmetric design rhetoric, added β1=β2 equality test (p=0.34); (4) Expanded Limitations from 5 brief items to 6 substantive paragraphs; (5) Political economy section rewritten to acknowledge protests were about MSP/bargaining power, not retail prices
