## Discovery
- **Policy chosen:** Cross-sectoral regulatory ratchet (12 federal agencies, 1994-2020) — confirmed Federal Register API with meaningful variation in significant rules by agency; GDELT GKG themes confirmed for safety incident and burden coverage; Trump EO 13771 provides a unique counterfactual for whether political commitment to deregulation can overcome media-driven salience dynamics.
- **Ideas rejected:**
  - idea_0443 (MSHA only, NEEDS_WORK): Too narrow — single agency limits cross-sectoral inference; GDELT MSHA theme confirmation pending
  - idea_0444 (building codes): Only 13 treated states; single-incident design limits external validity
  - idea_0445 (housing deregulation null): Companion paper — may serve as robustness test within idea_0450 framework
  - idea_0451 (OIRA withdrawals, NEEDS_WORK): Derogatory flag field in OIRA XML schema unconfirmed; feasibility risk
- **Data source:** Federal Register API (api.federalregister.gov) for outcomes; GDELT GKG via BigQuery for news coverage; BLS for severity controls; QuantGov RegData as secondary outcome
- **Key risk:** Small number of agency clusters (N=12) limits statistical inference — mandatory wild cluster bootstrap and Cameron-Miller SEs; first-stage strength of competing-news IV with quarterly aggregation uncertain

## Execution
- **Tables**: modelsummary uses tabularray (not booktabs) by default; need to add \usepackage{tabularray,codehigh} to preamble. Labels must be added to tabularray inner block.
- **Burden collinearity**: Original burden measure was global (identical for all agencies per quarter) → collinear with quarter FEs. Fixed by building agency-specific sector-themed burden using GDELT V2Theme prefix matching.
- **Weak IV**: Cross-sector competing news has F≈1.4 at quarterly level. Monthly/weekly data would recover Eisensee-Strömberg strength. Report OLS as main.
- **Key finding (surprise)**: Burden coverage effect is POSITIVE (β=0.227), not negative as theory predicts. Only under Trump EO 13771 does burden flip negative (β=-0.258). Framing: industry mobilization channel > public deregulation pressure.
- **Page count**: 25 pages main text achieved through literature review + policy implications + extended data section.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-R1, GPT-R2, Codex PASS; Gemini FAIL)
- **External referee verdict:** 2 REJECT AND RESUBMIT (GPT-R1, GPT-R2), 1 MINOR REVISION (Gemini)
- **Top criticism:** Causal language overclaiming + burden coverage construct validity — the "burden coverage" variable is sector-theme × negative tone which doesn't cleanly identify regulatory burden articles; and the paper uses "drive," "produced," "mobilizes" causal language that exceeds the TWFE observational design
- **Surprise feedback:** Both GPT reviewers flagged the EO 13771 heterogeneity as needing a formal pooled interaction test (not split-sample); Gemini gave MINOR REVISION and praised the paper as "Top 5 caliber insight"
- **What changed in revision:** (1) Reframed causal language throughout to association language; (2) Added pooled interaction model for Trump-period heterogeneity with formal Wald test; (3) Clarified "economically significant" outcome definition; (4) Improved burden coverage discussion with explicit acknowledgment that negative-tone sector news ≠ burden, while explaining why the measure still captures the mechanism; (5) Added PPML robustness
