## Discovery
- **Policy chosen:** State income tax differentials at US borders + TCJA SALT cap — sharp geographic variation, clean temporal shock, high policy relevance
- **Ideas rejected:** Estate tax thresholds (no individual wealth × migration data), ACS border RDD (PUMA too coarse, $75K+ too low), state-level IRS migration (no geographic precision for RDD), remote work alone (COVID confounds everything)
- **Data source:** IRS SOI ZIP-code income data (2012-2021) — confirmed available, has $200K+ AGI bracket, ~42K ZIPs, free download
- **Key risk:** Pre-existing sorting at borders may dominate the SALT cap event study effect. McCrary density test and pre-trend analysis are critical diagnostics.

## Review
- **Advisor verdict:** 3 of 4 PASS (Gemini failed on numerical precision; fixed in revision rounds)
- **Top criticism:** DDD needs parallel pre-trends event study and is not significant with border-pair clustering (GPT/Grok). All reviewers wanted pooled estimate excluding NJ-PA.
- **Surprise feedback:** DDD event study showed pre-trends test rejects (p=0.005, driven by 2016 outlier), and post-effects emerge in COVID years (2020-21) not immediately after 2018 SALT cap. Border-pair clustering makes DDD insignificant (p=0.27). Honest science requires reporting this.
- **What changed:** (1) Reframed cross-sectional RDD as descriptive geography, not causal. (2) Added DDD event study with formal pre-trends test. (3) Added pooled-excluding-NJ-PA showing sign reversal. (4) Added border-pair clustering comparison. (5) Softened all causal claims around DDD.

## Summary
- **Best feature:** Transparency and honest engagement with design limitations. Multiple reviewers praised the diagnostic failures as a strength.
- **Biggest weakness:** Only 8 border pairs limits inference. DDD event study timing overlaps COVID, preventing clean SALT attribution.
- **Lesson for future papers:** Always run few-cluster inference before claiming significance. Pre-specify which cluster level matters for the identifying variation. DDD event studies with proper income-group × year controls are essential — without them, national trends in income composition create spurious pre-trends.
