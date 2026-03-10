## Discovery
- **Policy chosen:** Egypt's November 2016 EGP devaluation (48% overnight float) — clean single-event shock with massive magnitude, well-documented IMF conditionality
- **Ideas rejected:** idea_0349 (sanctions rerouting — already published as apep_0553), idea_0229 (Uzbekistan exchange rate — N=1 SCM weakness), idea_0499 (STRI transport barriers — cross-country regulatory indices less clean)
- **Data source:** UN Comtrade HS6 bilateral trade data — API confirmed working with subscription key, returned 4,500+ products per year; BEC classification constructed at HS2/HS4 level manually
- **Key risk:** Pre-trends during 2011-2013 Arab Spring period create divergence between BEC categories before the devaluation; must be addressed honestly

## Review
- **Advisor verdict:** 3 of 4 PASS (first round: 1/4 — sample count inconsistencies; second round: 3/4 after fixes)
- **Top criticism:** Internal consistency in sample counts — fixest removes 192 singleton products (5,534→5,342), but original text used different numbers in abstract, data section, and tables without explaining the discrepancy
- **Surprise feedback:** Col(2) product count was 4,814 not 5,234 as originally reported; Col(2) had a missing significant coefficient (Post×Capital×Pre-Import = -0.092***) that was not shown in the table
- **What changed:** Reconciled all sample counts with explicit singleton explanation; added missing coefficient; added capital goods RI p-value (0.265); fixed summary table to fit on page; clarified decomposition table sample differences
