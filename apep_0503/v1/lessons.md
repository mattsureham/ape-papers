## Discovery
- **Policy chosen:** France's DPE-based phased rental ban (Loi Climat et Résilience 2021) — uniquely combines energy labels with an actual regulatory prohibition (not just disclosure), creating both information and regulatory discontinuities at the same cutoffs
- **Ideas rejected:** Mayoral salary thresholds (compound treatment problem per Eggers et al. 2018 — every salary threshold coincides with council size change); PPRI flood zones (endogenous boundary placement along rivers/flood plains)
- **Data source:** ADEME DPE (14.17M records, API confirmed) + DVF (property transactions, bulk CSV confirmed) — massive universe-scale data
- **Key risk:** Bunching/manipulation at DPE cutoffs by assessors who help landlords avoid the G classification; double-seuil complicating the running variable dimensionality

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT FAIL, Grok PASS, Gemini PASS, Codex PASS) — required 8 rounds to resolve sign interpretation issues
- **Top criticism:** GPT referee's "ecological RD" critique — commune×year×type cell means are not individual property prices, breaking the standard RD estimand
- **Surprise feedback:** The sign flip at G/F (negative at narrow bandwidth, positive at wide) was consistently flagged by all reviewers. This bandwidth-dependent sign change is a genuine empirical feature.
- **What changed:** (1) Expanded data linkage discussion acknowledging effective sample size vs observation counts; (2) Reframed central claim around existence of discontinuity (not sign/magnitude); (3) Added multiple testing adjustments; (4) Promoted 3 figures + covariate balance table to main text; (5) Softened causal claims

## Summary
- **Key lesson:** When the DV is an aggregate proxy, acknowledge the "ecological" nature of inference prominently. Reviewers catch this instantly.
- **Sign inconsistency handling:** Bandwidth sensitivity analysis was essential for diagnosing the sign flip. The non-monotonicity is real — document it, don't hide it.
- **Multi-cutoff RDD:** The built-in placebo logic is powerful but requires explicit defense of the information-channel-similarity assumption.
- **Advisor review loops:** 8 rounds needed primarily due to sign/language issues. The word "premium" (positive connotation) was incompatible with a negative local estimate — switching to "discontinuity" resolved the tension.
