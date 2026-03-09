## Discovery
- **Policy chosen:** Wales Renting Homes Act 2016 (implemented Dec 2022) — first UK jurisdiction to abolish Section 21 no-fault evictions, creating a clean Wales-England natural experiment with exact statutory date
- **Ideas rejected:** Child Benefit Notch (bunching design, potentially narrow); Universal Credit wages (annual ASHE data limits pre-periods; UC employment already covered by apep_0473)
- **Data source:** HM Land Registry PPD (bulk CSV, no auth, 24M+ transactions) — universe-scale admin data with postcode-level precision
- **Key risk:** Only 22 treated clusters (Welsh LAs) — requires permutation inference, wild bootstrap, and leave-one-out to establish robustness

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, Gemini, Codex pass; GPT R2 fail on minor issues)
- **Top criticism:** Baseline DiD fails identification — the paper's own diagnostics (permutation p=0.299, border counties null, placebo outcomes decline more) show the causal claim is not credible. All three referees noted this is the paper's thesis, not a flaw.
- **Surprise feedback:** Two reviewers flagged that permutation test's exchangeability assumption is debatable — Wales is structurally different from random English LA subsets. The paper overstated permutation as "gold standard."
- **What changed:** Removed "gold standard" and "unusually clean" language; added extended explanation of bootstrap vs permutation divergence; downgraded price claims to note compositional selection; fixed log-point vs percentage conflation; corrected second-home LA count (3→5); strengthened Category A/B proxy caveats

## Summary
- **Paper type:** Null-result/cautionary paper with honest identification failure
- **Key lesson:** A paper that honestly debunks its own finding can be a strong contribution — but requires careful calibration of language (avoid overclaiming in either direction)
- **Technical lesson:** With 22 treated clusters, permutation inference and wild bootstrap can sharply disagree — explain why, don't just report both p-values
- **Data lesson:** Land Registry PPD Category A/B ≠ owner-occupied/buy-to-let; mean transaction prices ≠ hedonic prices
