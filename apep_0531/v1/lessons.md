## Discovery
- **Policy chosen:** PCSO (Police Community Support Officer) austerity cuts in England — 56% decline 2010-2025 with enormous cross-force variation. Novel: only one causal study exists (Ariel et al. 2016 RCT in one city).
- **Ideas rejected:** UC→crime (d'Este & Harvey 2024 JLEO preempted core finding); VRUs (simultaneous treatment, Home Office already ran gsynth); Late Night Levy (<10 adopters); Police precepts (endogenous); Rainfall→crime (not DiD); PSPOs (no central adoption register).
- **Data source:** Home Office workforce ODS (2007-2025, force×year×worker type) + ONS PFA crime tables. Both freely downloadable, confirmed working.
- **Key risk:** Exogeneity of PCSO cuts — forces that cut PCSOs most may differ systematically. Mitigated via Bartik IV (pre-2010 grant dependence × national cut), pre-trends, jackknife sensitivity.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex passed; Gemini failed). Took 13 rounds to reach 3/4 PASS.
- **Top criticism:** GPT-5.2 (R&R) argued identification needs an IV or shift-share design beyond TWFE + FE. Also flagged population denominator constructed from 2010 officer shares as potentially distorting per-capita measures.
- **Surprise feedback:** Table overflow was invisible in LaTeX source — columns 4 of Tables 2 and 3 were cut off at the right margin. Required `scale_down` in kable_styling. Also, fraud data availability was opposite to initial claim (available 2008-2013, not post-2013).
- **What changed:** Added Bell et al. (2016) citation, fixed table overflow with scale_down, corrected fraud data description, standardized coefficient precision across tables, fixed population denominator description consistency, added set.seed before boottest, replaced placeholder tokens with actual contributor handle.
