## Discovery
- **Policy chosen:** EU Medical Device Regulation (MDR, 2017/745) — clear treatment date (May 2021), affects all EU member states, understudied in economics despite massive regulatory scope (1.29M registered devices)
- **Ideas rejected:** Runners-up from idea database (GDPR enforcement, ETS carbon pricing) — MDR had strongest data feasibility with Eurostat production index + EUDAMED + FDA comparator
- **Data source:** Eurostat sts_inpr_a (annual industrial production index, 2015-2025) as primary outcome; EUDAMED API for device registrations; FDA openFDA for US comparator. Key surprise: only 6-7 EU countries have C325 (medical instruments) data, limiting cluster count. EUDAMED API doesn't support risk class filtering — required sampling approach.
- **Key risk:** Small number of treated clusters (6-7 countries with C325 data) limits statistical power and makes inference sensitive to individual country influence. Addressed with leave-one-out, wild cluster bootstrap, and randomization inference.

## Execution
- **Pivot:** Original plan was DDD (EU vs US × risk class × time) but EUDAMED only has post-2021 data. Pivoted to within-country industry DiD (C325 vs C21/C265/C26 × post-MDR).
- **Result:** Well-identified null (β = 3.8, SE = 7.7, p = 0.63). Clean pre-trends, placebos pass.
- **Framing:** "The Dog That Didn't Bark" — null is the contribution, explained by staggered MDR deadlines (Class III devices not due until 2027-2028), volume-vs-variety composition, and anticipatory front-loading.

## Review
- **Advisor verdict:** 3 of 4 PASS (Round 7; GPT-R1, Gemini, Codex passed; GPT-R2 failed on minor issues)
- **Referee verdicts:** R&R (GPT-R1), Major Revision (GPT-R2), Minor Revision (Gemini)
- **Top criticism:** "Precisely estimated null" framing overclaims given CI of [-11, +19]. Title claims "innovation decline" but outcome is production volume, not innovation.
- **Surprise feedback:** Both GPT reviewers flagged the 2021 index base year as a serious concern, even though country×year FE absorb it mechanically. Also flagged RI sector exchangeability as non-credible.
- **What changed:** Retitled to "Short-Run Production Effects." Added wild cluster bootstrap (p=0.63). Added 2022-as-post robustness (β=2.6, p=0.74). Softened all "precisely estimated null" language. Demoted 510(k) comparison. Acknowledged RI limitations. Softened mechanism language.
