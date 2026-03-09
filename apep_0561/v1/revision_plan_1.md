# Revision Plan — apep_0561 v1 (Round 1)

## Review Summary

Three external reviewers (GPT-5.4 R1: R&R, GPT-5.4 R2: R&R, Gemini: Major Revision) identified five convergent concerns:

1. **Clustering level**: Commune-level clustering is inappropriate when treatment is assigned at EPCI level
2. **Pre-trends failure**: Significant 2002 event-study coefficient and significant placebo test
3. **Only one post-treatment election**: Limits ability to distinguish treatment from idiosyncratic 2022 shock
4. **Denominator/composition effects**: Vote-share decline may be mechanical via electorate growth
5. **No first-stage economic evidence**: Missing evidence that ZRR loss affected local economy

## Revision Decisions

### Addressed (incorporated into paper)

1. **Department-level clustering**: Added Table 6 showing commune vs department clustering comparison. Result is insignificant under department clustering (p=0.396). Prominently reported.

2. **Pre-trends reported honestly**: Placebo test significance (p=0.013) reported prominently. 2002 coefficient discussed. New "Dropping the 2002 Election" subsection shows result weakens further (p=0.065) without 2002.

3. **One post-treatment election**: Acknowledged throughout as fundamental limitation. Claims softened from "causal" to "suggestive." Abstract rewritten to lead with "no robust evidence."

4. **Denominator analysis added**: Table 3 shows differential electorate growth (+15 registered voters, +12 valid votes). Event studies for inscrits/exprimes computed. Result interpreted as potentially compositional.

5. **Claim calibration**: Abstract, introduction, and conclusion all rewritten to use "suggestive" language. HonestDiD including zero reported prominently. Department clustering insignificance is central, not peripheral.

### Not addressed (with justification)

1. **EPCI-level clustering**: Commune-to-EPCI crosswalk for 2017 period unavailable. Department clustering (84 clusters) is more conservative than EPCI would be. This is a genuine data limitation.

2. **Threshold-based RD design**: Would require fundamentally different paper and EPCI-level running variable data. Noted as direction for future work.

3. **First-stage economic evidence**: Would require SIRENE/DADS data acquisition and analysis. Beyond scope of current data infrastructure. Noted as limitation.

4. **Wild cluster bootstrap**: 84 departments is adequate for asymptotic cluster-robust inference. Adding WCB would not change the conclusion (result is already insignificant).
