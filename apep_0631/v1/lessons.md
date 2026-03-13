## Discovery
- **Idea selected:** idea_0063 — SALT cap reversal creates rare symmetric tax experiment for housing capitalization
- **Data source:** Zillow ZHVI (zip monthly) + IRS SOI 2017 (zip SALT deductions). Both downloaded instantly.
- **Key risk:** Short post-OBBB window (7 months) limits reversal inference

## Execution
- **What worked:** Continuous-treatment DiD with metro×month FE gives clean identification. 25K zip codes, massive power. Event study shows textbook pattern.
- **What didn't:** FHFA HPI server was down (503). IRS SOI data has no AGI_STUB=0 total rows — needed to aggregate across income classes.
- **Review feedback adopted:** Toned down reversal claims from "conclusive asymmetry" to "early evidence, no immediate rebound." Confronted k=-3 pre-trend coefficient directly. Added TCJA confounds discussion (standard deduction doubling, MID cap). Added OBBB sunset and AGI phaseout as limitations.
- **Key finding:** 3.2% price decline per $10K SALT bite. No detectable recovery after 2025 reversal.
