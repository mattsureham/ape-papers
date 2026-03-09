## Discovery
- **Policy chosen:** France's Schema National d'Accueil 2021-2023 asylum dispersal — centralized policy with clear timing (Dec 2020 decree), geographic variation across ~96 departments, and direct mirror to apep_0464's carbon tax design
- **Ideas rejected:** N/A (pinned idea from database, idea_0492)
- **Data source:** SCI NUTS3 from Humanitarian Data Exchange (public), election Parquet from data.gouv.fr, asylum capacity data from Ministry of Interior/OFII
- **Key risk:** Small N (96 depts × 4 elections = 384 obs), need AKM standard errors for shift-share, asylum capacity data may need manual construction from government reports

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1 PASS, GPT R2 PASS, Gemini FAIL, Codex PASS)
- **Referee decisions:** GPT R1 REJECT AND RESUBMIT, GPT R2 REJECT AND RESUBMIT, Gemini MAJOR REVISION
- **Top criticism:** Treatment is imputed from regional aggregates — department-level shifts are not observed, making the contact vs network decomposition unidentified. AKM inference missing.
- **Surprise feedback:** All three reviewers independently identified the geography confound (SCI ≈ proximity) as a first-order threat, despite the paper already discussing it. The severity was understated in the original.
- **What changed:** Comprehensive claim recalibration throughout — abstract, intro, results, conclusion all rewritten to present findings as "suggestive evidence" with prominent caveats about treatment imputation, inference limitations (~13 regional shocks), and geography-SCI confound. Triple-difference reframed as "exploratory." Added new geographic spillover subsection to Alternative Explanations. Killed roadmap paragraph. Improved active transitions.

## Summary
- **Key lesson:** When treatment variables are constructed from coarse aggregates (NUTS-2 → NUTS-3 imputation), be upfront about it from the start. The paper would have been stronger if the Introduction had immediately framed the analysis as "studying regional asylum capacity transmitted through social connectivity" rather than claiming department-level treatment observation.
- **What worked:** The shift-share framework with SCI is genuinely novel and interesting — all three reviewers acknowledged the contribution. The event study, RI, and LOO checks were valued.
- **What didn't work:** Overclaiming the contact hypothesis distinction when hosting is imputed. Presenting department-clustered SEs as sufficient for shift-share inference. Not implementing AKM.
- **For future papers:** Always implement shock-level inference for shift-share designs. Add geographic distance controls when using SCI. Frame imputed treatment variables with full transparency from the abstract onward.
