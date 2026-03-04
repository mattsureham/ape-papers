## Discovery
- **Policy chosen:** MGNREGA three-phase rollout (2006-2008) — cleanest quasi-experiment in Indian development economics with 313+ districts, well-studied but crop-specific productivity angle is genuinely novel
- **Ideas rejected:** Forest Rights Act (endogenous implementation), APMC reforms (too few treated states), Demonetization agricultural channel (1-season post-window), Jan Dhan → agricultural credit (weak identification)
- **Data source:** ICRISAT District Level Database (DLD) via REST API — no auth needed, 29 crops, 313 apportioned districts, 1966-2017. Also has wages (to 2013), fertilizer, irrigation, rainfall, Census population
- **Key risk:** MGNREGA saturation in APEP (5 existing papers) — must frame as agricultural productivity/input substitution paper, not "another MGNREGA paper." Pre-trend validation essential given backwardness-index selection into treatment.

## Review
- **Advisor verdict:** 2 of 4 PASS (Grok PASS, Codex PASS on clustering concern, Gemini FAIL on false positives, GPT-5.2 unavailable due to API credits)
- **Top criticism:** Pre-trend failures for 6 of 8 crops undermine "precise null" framing
- **Surprise feedback:** Gemini consistently found new issues each round (7 attempts), many false positives about fixest's Within R² computation and Sun & Abraham estimator mechanics
- **What changed:** Rewrote pre-trend discussion honestly; qualified "precise null" to "well-identified for cotton and maize, suggestive for others"; strengthened first-stage reconciliation; improved conclusion prose

## Summary
- **Result:** Well-identified null — MGNREGA had no detectable effect on crop-specific yields across 8 crops, 311 districts, 18 years
- **API lesson:** ICRISAT DLD API returns data.frame headers (not list-of-lists); need `raw$headers$header` not `sapply(raw$headers, function(h) h$header)`
- **Pipeline lesson:** OpenRouter daily credit limits can exhaust mid-session; plan for this in long review cycles
- **Two-cohort design:** With only 2 cohorts separated by 1 year, pre-trend tests become crucial but also fragile; recommend designs with more cohort variation
