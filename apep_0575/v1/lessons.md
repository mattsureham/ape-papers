## Discovery
- **Policy chosen:** BRRD (2014/59/EU) bail-in risk → household deposit restructuring — novel household channel of banking regulation that existing literature misses entirely (wholesale focus dominates)
- **Ideas rejected:** Gas shock import substitution (idea_0330, claimed by apep_0574), Late Payment Directive (weak identification, simultaneous transposition, Eurozone crisis confound)
- **Data source:** ECB BSI monthly deposits by maturity type + IWH Banking Union Directives Database for transposition dates — both confirmed accessible, no API keys needed
- **Key risk:** 25-country cluster count is modest; aggregate deposit maturity types are noisy proxy for uninsured deposits above €100K. Triple-diff with EBA DGS uninsured share mitigates but doesn't eliminate measurement concern.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 13 rounds of iteration — GPT-5.4 R1 and R2 + Gemini PASS; Codex-Mini FAIL on internal consistency details)
- **Top criticism:** CS-DiD analytical SEs with 19 clusters insufficiently robust; need bootstrap inference (all three referees raised this). Added multiplier bootstrap (p=0.035), which actually strengthened the result.
- **Surprise feedback:** R1 flagged the 4.6x magnitude gap between CS (+0.67pp) and SA (+3.10pp) as a serious identification concern — not just a nuisance. Led to substantive discussion of SA multicollinearity (83 dropped interactions) rather than dismissing as "different aggregation."
- **What changed:** (1) Added CS-DiD bootstrap inference; (2) Softened "insurance optimization" from established fact to interpretive hypothesis throughout; (3) Reframed corporate deposits from "placebo" to "sectoral comparison"; (4) Added treatment-timing limitation (transposition vs Jan 2016 bail-in activation); (5) Added CS vs SA divergence discussion as estimation instability signal; (6) Explicit footnote noting TWFE-based robustness checks test specification stability, not CS-DiD validity.

## Summary
- **What went well:** Novel EU policy angle (BRRD household deposits) with clean staggered identification. ECB BSI data was readily available and high quality. Intensity-interaction design with cross-sectional uninsured exposure provided the most compelling result.
- **What to improve:** Start with bootstrap inference from the beginning — analytical SEs with <20 clusters are always going to be questioned. Be upfront about CS vs SA magnitude divergence in early drafts rather than treating SA as a simple "robustness" check. The corporate "placebo" framing was a mistake — corporate deposits face the same regime, so it's a comparison, not a placebo. Better to frame this correctly from the start.
- **Tournament prediction:** Strong identification, novel policy angle, sophisticated mechanism discussion. Weaknesses: modest cluster count, aggregate data limitation, treatment timing ambiguity. Likely competitive with AEJ-level papers but below top AER due to data granularity constraints.
