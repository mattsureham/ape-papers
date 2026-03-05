## Discovery
- **Policy chosen:** France's 2014 QPV redesignation (ZUS→QPV transition) — rare large-scale experiment in REMOVING place-based status, directly tests displacement hypothesis from Mayer et al. 2017
- **Ideas rejected:** SRU social housing quotas (3 existing papers, DVF only starts 2014), Loi Macron Sunday trading (only 18 ZTI, fails DiD gate), ZRR 2024 reform (politically reversed within months), CVAE abolition (only 2 years post-treatment)
- **Data source:** SIRENE bulk establishments (parquet, creation dates since 1973) + QPV/ZUS shapefiles (data.gouv.fr) + DVF geocoded (2020-2025)
- **Key risk:** DVF only geocoded from 2020, limiting property price pre-trends to SIRENE firm outcomes. QPV designation methodology change (composite → grid income) may correlate with differential trends.

## Execution
- **ZUS shapefile unavailable:** sig.ville.gouv.fr download links all 404. Pivoted to commune-level approach using ZUS XLS list + QPV shapefile commune matching.
- **SIRENE download:** 2.2GB parquet needed curl with extended timeout (R default 60s too short)
- **Treatment assignment:** 75 lost, 646 kept, 1 ambiguous. 183 ZFU-overlapping excluded from main sample → 75 lost, 463 kept in main sample.
- **Pre-trends issue:** Event study shows POSITIVE significant pre-treatment coefficients. Lost-status neighborhoods were growing faster pre-2015. Likely selection: improving neighborhoods less likely to meet QPV income criterion. Honest about this in paper — Rambachan-Roth sensitivity computed.
- **Main result:** Static DiD = -272 firms/year (p<0.001). Dynamic: -116 (short), -306 (medium), -364 (long-run). Effect grows over time.
- **IPW eliminates effect:** Coefficient attenuates to 3.7 (p=0.90) after IPW reweighting, confirming selection drives the raw estimate.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 4 rounds fixing inconsistencies)
- **Top criticism:** Pre-trends violate parallel trends assumption; IPW and Rambachan-Roth both show effect is not robust to selection correction. Paper is descriptive, not causal.
- **Surprise feedback:** None — the pre-trends issue was identified during execution and all reviewers flagged it.
- **What changed:** Reframed entire paper as descriptive association; removed "quasi-random" and causal language; updated abstract, intro, identification, conclusion; fixed 5+ internal inconsistencies (nine/ten years, placebo text, Pseudo R², entropy balance text, contributor placeholders).

## Summary
- **Key lesson:** When pre-trends reject parallel trends AND robustness checks (IPW, Rambachan-Roth) eliminate the effect, the honest response is to reframe as descriptive. This is still a contribution — documenting the correlation between status loss and economic dynamics is policy-relevant — but overstating causality will be caught.
- **Data lesson:** French ZUS polygon shapefiles are completely unavailable online. Commune-level matching via XLS list is a workable but coarse substitute.
- **Technical lesson:** fixest Pseudo R² can exceed 1 for OLS models with fixed effects — suppress with `fitstat = ~ n + sq.cor`.
