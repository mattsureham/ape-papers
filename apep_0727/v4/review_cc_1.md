# Internal Review (Claude+Codex) — V4

## Changes from V3

### Empirical (Phases 1-5)
1. **Unified estimator stack** — all scripts use `00_bunching_estimator.R` (integer bins, degree 7, 500 bootstrap)
2. **Missing-mass analysis** — excess 134,524 below, missing 4,788 in [10,11); mass balance 28:1; distribution comparison shows [10,13) share collapsed from 18% to 2.3% to 25%
3. **Data-driven welfare** — distribution-based bounds (100-135 MW) replace scenario arithmetic; polynomial lower bound (97 MW) as cross-check
4. **Formal monthly event study with bootstrap CIs** — 144 months, 500 bootstrap reps each; three transition tables with pre-trend tests
5. **Pre-specified estimator family** — 9 specifications (3 degrees × 3 windows) giving range [52, 98]; full grid of 30 specs in appendix [47, 144]
6. **Temporal difference-in-bunching at placebos** — only 10 kWp shows policy-timed break (DiB = +74.8); all others ≤|-15|
7. **Installer-proxy heterogeneity** — municipality-level concentration shows no difference (b=86.9 vs 82.7) → Path B (interpretation)
8. **Fine-grid distribution** — 0.01 kWp bins confirm 9.90 kWp as modal bin (31,611 systems), consistent with specific module configurations

### Framing (Phase 6)
9. **Abstract rewritten** — leads with threshold trap concept, reports spec family range, names the missing middle
10. **Introduction rewritten from scratch** — world question first (when do thresholds become catastrophic?), Germany as demonstration
11. **Welfare section rebuilt** — distribution-based revealed counterfactuals as headline, polynomial as conservative floor
12. **Conclusion rewritten** — teaches "the threshold trap" principle; three diagnostic questions for policymakers
13. **Claim register calibrated** — intermediation = interpretation (Path B), spec sensitivity acknowledged honestly, welfare = bounded range
14. **30 kWp → appendix**, ground-mount demoted, annual table reference preserved in main text

### Structural
15. **Spacing** — `\onehalfspacing` (V2+ requirement)
16. **Appendix expanded** — specification curve figure, 30 kWp, ground-mount placebo

## Text-Table Consistency
- Period bunching ratios match `bunching_10_by_period.csv`
- Annual estimates match `bunching_10_annual_with_se.csv`
- Welfare bounds (100-135 MW) derive from distribution shares (18% pre, 2.3% surcharge, 24.9% post)
- Spec family range [52, 98] from `spec_family.csv`
- Monthly CIs from `bunching_10_monthly.csv` (144 months × 500 bootstrap)

## Open Items for Codex Pre-Referee Sign-Off
1. Tables need regeneration from v4 code outputs (currently using v3 tables)
2. Monthly event study figure needs updating with CI bands
3. Literature deepening not yet done (10-15 new citations needed)
4. Numbers in v3 tables may not match v4 text (stale tables)
