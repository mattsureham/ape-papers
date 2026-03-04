## Discovery
- **Policy chosen:** Mandatory Food Hygiene Rating Display (Wales 2013, NI 2016) — cross-national information disclosure experiment with clean staggered variation across 33 treated + 300 control LAs
- **Ideas rejected:** Business Rates Revaluation (mixed rankings, VOA data complex), Council Tax Support (crime data limited to 36 months via API), Permitted Development Rights (Article 4 selection problem)
- **Data source:** FSA FHRS API (586K establishments, no key), Companies House (5M firms, bulk CSV), Land Registry PPD, NOMIS — all confirmed working
- **Key risk:** Wales vs. England systematic differences; mitigated by border design, triple-diff with non-food placebo, and pre-trend tests
- **CRITICAL DATA BUG:** FSA API countryId mapping: 1=England, 2=NI, 3=Scotland(FHIS), 4=Wales. Original code used c(1,3,4) which downloaded Scotland instead of NI. Fixed to c(1,2,4).

## Review
- **Advisor verdict:** 3 of 4 PASS after 8 rounds (Grok, Gemini, Codex PASS; GPT FAIL)
- **Top criticism:** DDD coefficient is POSITIVE (+1.4), contradicting initial "entry deterrence" narrative. Required complete rewrite.
- **Surprise feedback:** Companies House bulk data only has currently registered firms — survivorship bias affects entry counts, especially for older cohorts.
- **What changed:** Complete narrative pivot from "deterrence" to "food sector resilience"; fixed FHRS data mislabeling; DDD equation aligned with code; expanded limitations; toned down mechanisms.

## Summary
- **Key lesson:** Always verify API data mapping (FSA countryId values are non-obvious)
- **Key lesson:** Let the data tell the story — when DDD contradicts simple DiD, the DDD is the honest answer
- **Advisor loop insight:** GPT-5.2 checks every number in text against tables; even small rounding differences trigger FAIL
- **DDD equation must match code:** Claiming sector-interacted FEs in the equation while using plain FEs in code is fatal
