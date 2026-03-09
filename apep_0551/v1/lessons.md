## Discovery
- **Policy chosen:** AZF Toulouse explosion (2001) → Loi 2003 industrial safety reform — genuinely unstudied in economics, novel ARIA database, clear enforcement expansion
- **Ideas rejected:** ZFE gentrification (crowded LEZ literature, boundary confounds), Grand Paris Express capitalization (saturated transit literature, anticipation contamination)
- **Data source:** ARIA (data.gouv.fr, 63K records) + ICPE Georisques (Seveso sites) — both confirmed accessible, no API keys needed
- **Key risk:** Reporting bias — more inspectors may generate more detected incidents without improving actual safety. Mitigated by severity stratification.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, Gemini, Codex passed; GPT R2 failed on causal language)
- **Top criticism:** All 3 referees identified pre-trend failure as fatal for causal claims. Dept-specific trends eliminated the main effect (β goes from 2.97 to -0.36).
- **Surprise feedback:** The paper's strength was its honesty about pre-trends — all reviewers praised transparency. But they uniformly insisted on reframing away from causal evaluation.
- **What changed:** (1) Complete reframe as measurement/diagnostic paper, (2) Added dept-specific trends, region×year FE, narrow window, PPML decomposition to robustness, (3) All causal language removed from abstract/intro/conclusion, (4) Title changed to "Detection or Deterrence? A Measurement Problem in Enforcement-Generated Safety Data", (5) Literature expanded with Roth 2022, Rambachan-Roth 2023, Goldsmith-Pinkham et al. 2020, etc.

## Summary
- **Key lesson:** When parallel trends fail decisively, pivot immediately to a measurement/diagnostic contribution rather than defending weak causal claims. The severity decomposition insight survives regardless of identification.
- **Data lesson:** ARIA is genuinely valuable for regulatory economics but requires careful handling of time-varying reporting completeness.
- **Method lesson:** Department-specific linear trends should be a standard robustness check in any continuous DiD — they reveal whether the baseline association is real or reflects pre-existing trajectories.
