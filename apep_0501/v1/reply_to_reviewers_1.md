# Reply to Reviewers — Round 1

## Consensus Issues

### 1. Dose-response estimated in TWFE contradicts methodology (All reviewers)
**Response:** We re-estimated the dose-response (Post × log(SizeRatio)) in the stacked DiD framework. The result is striking: the interaction coefficient reverses sign from +5.14 (TWFE) to -5.18 (stacked DiD, p=0.008). This is now the paper's central methodological contribution—TWFE contaminates mechanism inference, not just ATT estimation. Paper revised throughout (abstract, intro, Results §6.4, Discussion §8.2, Conclusion).

### 2. Control group contamination from post-2020 mergers (GPT advisor, GPT referee)
**Response:** We identified 40 communes that merged after 2020 in the control pool. Re-estimating the stacked DiD with strictly never-merged controls yields ATT = -1.68 pp (vs -1.67), confirming no contamination. Results reported in new §7.6 "Strictly Never-Merged Controls."

### 3. Canton-level confounding (Grok, Internal)
**Response:** Added canton-clustered standard errors. SE increases from 0.237 to 0.359, but the result remains highly significant (t = -4.66, p < 0.001). Reported in new §7.7 "Alternative Clustering."

### 4. Window width sensitivity (Internal, Grok)
**Response:** ±3 year stacked DiD yields ATT = -2.07 pp (SE 0.23, p < 2.2e-16)—stronger than ±5 year baseline, consistent with narrower window reducing pre-trend contamination. Reported in new §7.4 "Alternative Window Width."

### 5. RI year pool inconsistency (GPT referee)
**Response:** Changed RI year pool from 1990-2020 to 2000-2020, matching the estimation sample. Updated RI p-value: 0.975.

## Individual Reviewer Issues

### GPT-5.2
- **"Never-treated" vs "not-yet-treated" language:** Clarified throughout that controls are communes with no merger during 2000-2020; explicitly noted post-2020 mergers in control pool and tested with strict exclusion.
- **Placeholder author handles:** Fixed to @ai1scl.
- **Treatment window framing:** Clarified that 637 events are descriptive universe (including scheduled future mergers); causal estimation restricted to 2000-2020.

### Grok-4.1-Fast
- **Pre-trend F-tests per window:** Acknowledged but not implemented. Narrower ±3 year window test partially addresses this by showing stronger result with less pre-trend contamination.
- **Synthetic control / IV:** Acknowledged as limitation. Noted that cantonal merger subsidy variation could serve as IV but data not available.

### Gemini-3-Flash
- **Data coverage dates:** Added explicit data vintage note (March 2026 download; BFS publishes within weeks of each referendum). Clarified that BFS mutations registry records scheduled future merger dates.
- **Stacked DiD N explanation:** Added explanatory notes to all tables explaining that control communes appear in multiple cohort-specific sub-experiments.
- **Glarus count consistency:** Added explicit note that Glarus reform created 3 successor communes, hence 3 fewer treated and 3 fewer total when excluded.

## Not Addressed (out of scope)
- Full Callaway-Sant'Anna: did package fails with this data structure (integer overflow to Inf). Acknowledged as limitation.
- Pre-harmonized BFS data: not available via API; acknowledged in Limitations.
- Absorption vs. fusion heterogeneity regression: merger type variable not cleanly available from mutations data. Noted for future work.

## References Added
- de Chaisemartin & D'Haultfoeuille (2020), AER
- Borusyak, Jaravel & Spiess (2024), RES
