# Revision Plan: Addressing Referee Feedback

**Paper:** apep_0587 v1
**Date:** 2026-03-10
**Reviews received:** GPT-5.4 R1 (R&R), GPT-5.4 R2 (R&R), Gemini-3-Flash (Minor Revision)

## Overview of Reviewer Concerns

All three reviewers agree the paper asks an interesting and policy-relevant question. The two R&R decisions center on:

1. **Treatment dilution** — HICBC applies only to parents (~13% of taxpayers near £50k), but the SPI covers all taxpayers.
2. **Running variable mismatch** — HICBC applies to ANI, not total income as measured in SPI.
3. **Power concerns** — Whether the coarse percentile data can detect economically meaningful bunching.
4. **Mechanism overclaiming** — Channel decomposition and welfare claims exceed what the evidence supports.
5. **Inference concerns** — Cross-year SEs and residual bootstrap on constructed densities.

The Gemini reviewer (Minor Revision) raises similar but less severe concerns about data granularity and the ANI proxy.

## Revision Strategy

Given that the paper works with published aggregate statistics (not microdata), many "must-fix" requests (obtain ANI data, restrict to treated population) are infeasible. The revision focuses on **comprehensive claim moderation** to align assertions with the evidence base.

### Workstream 1: Claim Moderation (Abstract, Introduction, Discussion)
- Rewrite abstract to lead with caveats on treatment dilution and running variable mismatch
- Replace "precisely estimated null" with "null result" throughout
- Moderate "dominant adjustment margin is administrative" to "appears to be administrative"
- Soften "dramatically understate" to "may understate"
- Add explicit treatment dilution paragraph in introduction with numerical calculation

### Workstream 2: Treatment Dilution Analysis
- Add subsection quantifying the dilution: ~1.1M affected families out of ~8M taxpayers near £50k ≈ 13%
- Show that b=0.2 among treated → b≈0.026 in all-taxpayer distribution, within CIs
- Discuss power implications honestly

### Workstream 3: Running Variable Mismatch Discussion
- Expand Section 5.5 to frame the mismatch as central to interpreting the null
- Explicitly state that the null in total income is consistent with: (a) no response, (b) ANI response invisible in total income, (c) diluted response, (d) low power
- Add discussion of HICBC as quasi-notch/taper rather than sharp notch

### Workstream 4: Channel Decomposition Caveats
- Add stronger caveats to SPI-ASHE residual interpretation
- Acknowledge the many differences between datasets (population, concept, granularity)
- Relabel as "suggestive" rather than identified decomposition

### Workstream 5: Welfare and Mechanism Moderation
- Tone down Section 7.4 welfare claims
- Present pension and opt-out channels as hypotheses consistent with evidence, not demonstrated mechanisms
- Remove or qualify "savvy vs. naive" framing without supporting microdata

### Workstream 6: Literature Additions
- Add Saez, Slemrod, and Giertz (2012, JEL) on taxable-income elasticities
- Add Slemrod (1996) on avoidance vs. real responses
- Add Chetty (2012, AER P&P) on sufficient statistics and optimization frictions
- Strengthen engagement with existing UK-specific work

### Workstream 7: Exhibit Improvements (from Exhibit Review)
- Remove redundant appendix tables (pre-period placebo table, full time series duplicate)
- Add specific period ranges to channel decomposition table panels
- Kill roadmap paragraph per prose review

## Execution Order

1. Workstreams 1-5 (claim moderation — main text edits)
2. Workstream 6 (literature additions)
3. Workstream 7 (exhibit cleanup)
4. Recompile and verify

## Verification

All claims in abstract and introduction must be supportable by the evidence presented. No assertion about mechanisms without "consistent with" or "suggestive" qualifying language.
