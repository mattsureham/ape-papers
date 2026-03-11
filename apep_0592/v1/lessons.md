## Discovery
- **Policy chosen:** State prohibition (1907-1919) — understudied GE labor market effects on non-alcohol workers; rich staggered timing + continuous intensity variation
- **Ideas rejected:** None (pinned idea from idea_0122)
- **Data source:** IPUMS full-count census + MLP linked panels via Azure — worked well, 8.7M+ linked workers per decade
- **Key risk:** Pre-trend in 1900-1910 panel is positive and significant (β=5.34 vs main β=0.80), complicating causal interpretation

## Execution
- **Memory management critical:** 16GB RAM limit required splitting 03_main_analysis.R from 03b_mechanisms.R, selective column reads, and aggressive gc() after each regression
- **IND1950 codes surprise:** Initial alcohol industry codes (268, 269, 278) don't exist in data — had to discover correct codes (869=eating/drinking places, 730=bartenders)
- **Sign flip with controls:** Treatment coefficient is negative without OCCSCORE control (-0.44) but positive with it (+0.80) — reflects composition differences between treated/control states
- **Long-run reversal:** Most novel finding — positive short-run association reverses to -1.03 in 1920-1930

## Review
- **Advisor verdict:** 3 of 4 PASS (after 6 attempts; issues: Column 4 interpretation, pre-trend labeling, coefficient scaling, binary outcome interpretation)
- **Top criticism:** Pre-trend coefficient (5.34) is 6.7x the main effect (0.80), undermining parallel trends assumption
- **Surprise feedback:** All 3 referees flagged treatment timing heterogeneity as fundamental design flaw
- **What changed:** Comprehensive softening of causal language; reframed as descriptive evidence; added modern DiD citations; renamed "Mechanism Tests" to "Heterogeneity"; promoted figures to main text

## Summary
- **Biggest lesson:** When a pre-trend fails badly, frame as descriptive from the outset. Trying to present as causal with caveats satisfies nobody.
- **Design lesson:** Decadal census panels severely limit identification strategies. Event-study designs require annual data.
- **Process lesson:** Advisor review iterations consumed most review time — coefficient scaling, pre-trend labeling, Column 4 interpretation required 6 attempts. Many could have been caught earlier.
