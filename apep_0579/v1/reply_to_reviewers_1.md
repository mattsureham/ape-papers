# Reply to Reviewers — apep_0579/v1

## Response to Referee 1 (GPT-5.4 R1): Reject and Resubmit

**1. Poland identification concerns (contaminated controls, placebo failure, pre-trends)**
We agree that the Poland case has substantial identification problems. In revision, we have significantly strengthened the caveats: the placebo failure (β = 10.18 for women vs men 55-59) is now discussed prominently in the results section as severely undermining the parallel trends assumption. We retain the case as theoretically suggestive but explicitly label the reversal ratio as non-causal.

**2. France: aggregate outcome for targeted treatment, concurrent policies**
We acknowledge this limitation. The supertax targeted only salaries above €1M, yet our outcome is economy-wide labor costs. The concurrent Pacte de responsabilité further confounds identification. We have tempered claims accordingly in the abstract and discussion. A synthetic control redesign would require additional control countries and is beyond the scope of this version.

**3. Over-claiming in abstract and conclusion**
Substantially rewritten. The abstract now leads with "suggestive evidence" rather than definitive claims. The conclusion explicitly states this is a "proof of concept for the reversal ratio framework, not a definitive test of policy irreversibility." All instances of "amplification is the rule" have been removed.

**4. Small-cluster inference**
We acknowledge that cluster-robust SEs with 4-5 clusters are unreliable. For France (5 countries), we use heteroskedasticity-robust SEs rather than clustering in the Germany-only specification. Wild cluster bootstrap is noted as a future improvement. The wide confidence intervals already reflect substantial uncertainty.

**5. RR standard errors (shared pre-period)**
The delta method SE does not account for the covariance between β^ON and β^OFF from shared pre-period data. We acknowledge this limitation. Joint estimation in a stacked framework with Fieller confidence intervals would be ideal and is noted for future work.

## Response to Referee 2 (GPT-5.4 R2): Reject and Resubmit

**1. Denmark outcome variable (HICP vs HICP-CT)**
Critical catch. We have verified and clarified: the dataset is `prc_hicp_midx`, which is the standard HICP monthly index — NOT the constant-tax variant (`prc_hicp_cmon`). The standard HICP includes the mechanical effect of tax changes on consumer prices, which is exactly what we want to measure. This is now explicitly stated in the data description.

**2. France N inconsistency (136/196 vs 140/200)**
Resolved. Austria lacks data for the first four quarters of 2008 (4 NA values in the total-economy aggregate). This is now explicitly documented in the data section, Table 2 notes, and the France appendix entry.

**3. Poland placebo failure**
Now prominently discussed in the results section with specific language about how it "severely undermines the parallel trends assumption."

**4. Reversal ratio inference (Cauchy-like distributions)**
We acknowledge that ratio distributions can be pathological when denominators are imprecisely estimated (as with Italy's near-zero β^ON). We suppress Italy's RR for this reason. For the three reported ratios, the denominators are statistically significant at conventional levels, though we agree that Fieller intervals or bootstrap inference would be preferable.

## Response to Referee 3 (Gemini-3-Flash): Major Revision

**1. Denmark identification strength**
We agree this is our strongest case. Pre-trend p = 0.962, multiple treated categories, monthly frequency.

**2. Concurrent policies confounding France**
Acknowledged and discussed. The Pacte de responsabilité (2014) directly affected employer social contributions during our analysis window. We note this as a limitation and temper claims accordingly.

**3. Abstract over-calibration**
Rewritten to say "suggestive evidence" and note that "wide confidence intervals and heterogeneous design quality caution against strong conclusions."

**4. Poland placebo as "smoking gun"**
We now explicitly acknowledge this in the results section and label the Poland reversal ratio as "suggestive rather than causal."

## Response to Exhibit Review

- Table 3: Czech row removed to eliminate placeholder dashes
- Switch-OFF event studies: Not added in this version; noted as future improvement
- Figure 4 (duration vs RR): Retained for descriptive purposes with clear "N=3, purely suggestive" caveat

## Response to Prose Review

- Roadmap paragraph retained (common in empirical papers)
- Abstract substantially revised for accuracy
- Defensive language in Poland section replaced with direct acknowledgment of design limitations
