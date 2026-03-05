# Revision Plan 1 — APEP-0528

## Changes Addressing Reviewer Feedback

### From all reviewers:
1. **Variance decomposition language** — Changed from "cantonal policy explains 2%" to "charges component accounts for 2% of tariff dispersion" (descriptive, not causal)

### From GPT-5.2 (Reviewer 1):
2. **Design framing** — Reframed as "border-pair DiD with spatial controls" hybrid. Explicitly stated identifying assumption (parallel trends conditional on distance within border pairs)
3. **Placebo claims** — Downgraded from "validates design" to "necessary-condition check"
4. **Inference caveats** — Added note on few-cluster inference limitations; downgraded border-pair heterogeneity significance to descriptive
5. **Sun & Abraham** — Event study now uses staggered-robust estimator (sunab())

### From Grok-4.1-Fast (Reviewer 2):
6. **Sample restriction clarity** — Explained 22 mixed borders vs 10 estimable pairs distinction
7. **Staggered DiD reference** — Added Sun & Abraham (2021) citation

### From Gemini-3-Flash (Reviewer 3):
8. **No major changes required** — Reviewer gave Minor Revision with constructive suggestions for future work

### From exhibit review:
9. **Event study figure** — Split into faceted panels for clarity (eliminated spaghetti plot)
10. **Binscatter** — Residualized against year FE to remove temporal composition effects

### From prose review:
11. **Contribution paragraph** — Reframed from "contributes to three literatures" to "speaks to three debates"
