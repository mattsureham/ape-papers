## Discovery
- **Policy chosen:** Sequential generic drug entry (FDA ANDA approvals) — the idea solves a known selection problem in pharma IO by using within-drug event studies instead of cross-sectional comparisons
- **Ideas rejected:** Forfeiture reform (UCR data quality concerns, heterogeneous treatment), CON repeals (limited treated units for recent wave, quality data only from ~2008)
- **Data source:** CMS NADAC (weekly drug pricing) + FDA Orange Book (approval dates) — both confirmed accessible, high frequency, universe coverage
- **Key risk:** Endogenous entry timing — larger/more profitable markets attract more entrants. Mitigated by within-drug design + GDUFA queue-based timing variation

## Review
- **Advisor verdict:** 3 of 4 PASS (7 rounds to pass — many consistency issues)
- **Top criticism:** NDC count ≠ firm count creates measurement error that could attenuate within-market estimates toward zero (both GPT reviewers flagged this as potentially fatal)
- **Surprise feedback:** The event study was essentially uninformative (SEs ~2000 due to high-dimensional FE), requiring honest reframing as corroborating diagnostic
- **What changed:** Softened causal claims → "within-market associations"; added attenuation bias paragraph; fixed all numerical inconsistencies (cross-section coefficients, robustness table SEs, median price peak N=5 not N=6); removed uninformative placebo test; removed roadmap paragraph; strengthened conclusion

## Summary
- **Paper type:** Selection bias decomposition in generic drug markets — novel framing ("selection gap") of why cross-sectional competition-price gradients are misleading
- **Key lesson:** When the main finding is a precisely estimated zero, reviewers will (rightly) ask whether measurement error explains it. Build the defense into the paper from the start.
- **Advisor loop lesson:** Consistency between tables and text is the #1 source of advisor failures. Always compute numbers from data, never round or paraphrase — use exact values from CSVs.
- **Event study lesson:** High-dimensional FE event studies on short panels can produce massive SEs that render the exercise uninformative. Better to be honest about this than report misleading point estimates.
