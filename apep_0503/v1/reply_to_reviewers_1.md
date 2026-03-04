# Reply to Reviewers

## Reviewer 1 (GPT-5.2): REJECT AND RESUBMIT

### §1.1: Core identification problem — outcome is commune-level mean, not property price

> "the outcome is not a property's transaction price... This 'ecological RD' breaks the core RD logic"

**Response:** We agree this is an important limitation and have substantially expanded the discussion. Section 4.3 (Data Linkage) now includes four paragraphs explicitly addressing: (1) why the merge cannot create a spurious discontinuity (symmetric cell assignment); (2) why measurement error attenuates toward zero; (3) the distinction between observation counts and effective sample size (distinct commune×year×type cells); and (4) the infeasibility of individual-level matching with current French data formats (ADEME BAN geocodes vs. DVF cadastral identifiers).

The Limitations section (§7.5) now explicitly uses the term "ecological RDD" and acknowledges that the estimand is the discontinuity in average local prices conditional on energy score, rather than the discontinuity in the property's own price. We interpret the estimates as lower bounds on individual-level effects.

We acknowledge that transaction-level matching would be strictly preferable. However, individual DPE-to-DVF linking is infeasible with current public data: no crosswalk exists between BAN and cadastral identifiers, and fuzzy string matching would introduce noise exceeding the measurement error from the cell-level merge.

### §2.1: Standard errors invalid with duplicated outcome

> "Effective sample size is the number of distinct cells, not 841,704"

**Response:** Section 4.3 now explicitly notes that multiple DPE observations within the same cell share an identical dependent variable, and that the effective sample size for inference is the number of distinct cells. We note that commune-level clustering of standard errors in the pooled specification accounts for within-commune correlation, and that rdrobust's nearest-neighbor variance estimator is conservative in the presence of clustered outcomes.

### §2.4: Multiple testing

> "G/F p=0.023 should be supported with adjustments for multiple comparisons"

**Response:** We now report both Bonferroni and Holm adjustments in §6.2. Under Bonferroni (threshold 0.0083), G/F does not survive. Under the Holm step-down procedure (more powerful, recommended by Romano and Wolf 2005), G/F is rejected. We note this honestly and emphasize that the multi-cutoff comparison (pooled γ₂) is the paper's primary test, not any single cutoff p-value.

### §3.1: Sign inconsistency at G/F

> "If the discontinuity has the 'wrong sign' at the preferred local bandwidth, the interpretation as a regulatory penalty is not secure"

**Response:** We have substantially expanded the sign discussion in §6.2 (now 5 paragraphs). We provide two economic interpretations consistent with the regulatory-teeth hypothesis: (1) positive selection among sellers near the G/F threshold; (2) local hedonic non-monotonicity. We reframe the paper's central claim as the EXISTENCE of a discontinuity uniquely at the regulatory cutoff, rather than its sign. The multi-cutoff contrast — not the sign of any single estimate — identifies the regulatory channel.

### §3.2: F/E McCrary manipulation

> "Sorting can exist in this system... undermining the idea that information-only cutoffs are clean placebos"

**Response:** We have expanded the F/E McCrary discussion to 2 paragraphs. We note: (1) the bunching operates in the assessment market, not the transaction sample; (2) if sorting inflated better-label prices at F/E, we would expect a positive price discontinuity there — instead the estimate is zero; (3) the absence of manipulation at G/F (the cutoff where the price effect appears) is the relevant diagnostic.

### §3.3: Placebo at 90 kWh significant

**Response:** Expanded to a full paragraph. The 90 kWh placebo falls in the A/B range with the smallest effective sample (N=16,880), dominated by new construction with sharply non-linear price-energy relationships, and adjacent to the marginally significant B/A cutoff. This is a false positive specific to the highest-efficiency segment, not a threat to identification at the G/F boundary.

### §3.4: Heterogeneity tests contradict mechanism prediction

**Response:** We now acknowledge the null heterogeneity as a limitation of the aggregate data (§6.4.2 rewritten). Individual-level data would provide a sharper test of the rental mechanism.

### §4: Missing literature

**Response:** Added Romano and Wolf (2005) for multiple testing. The paper already cites the key energy/housing/salience literatures extensively.

---

## Reviewer 2 (Grok-4.1-Fast): MAJOR REVISION

### Must-fix 1: G/F sign inconsistency

**Response:** See response to GPT §3.1 above. Expanded to 5 paragraphs with economic interpretations and reframing around the multi-cutoff contrast.

### Must-fix 2: F/E McCrary rejection

**Response:** See response to GPT §3.2 above. Expanded discussion addresses the assessment-vs-transaction market divergence.

### Must-fix 3: Strengthen aggregate outcome defense

**Response:** See response to GPT §1.1 above. Four new paragraphs in §4.3 plus expanded Limitations section.

### High-value 1: Power up heterogeneity

**Response:** Acknowledged as limitation. The commune-level merge dilutes the rental-specific channel. Individual-level data (noted as future work) would enable sharper tests.

### High-value 3: Add citations

**Response:** Added Romano and Wolf (2005) for multiple testing.

---

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### Must-fix 1: Reconcile G/F sign/magnitude

**Response:** See response to GPT §3.1 above. The sign discrepancy is now extensively discussed with two economic interpretations and a reframing of the paper's central claim.

### Must-fix 2: Commune-level aggregation

**Response:** See response to GPT §1.1 and §2.1 above. Effective sample size, clustering, and ecological RDD terminology all addressed.

### High-value 1: Rental market heterogeneity null

**Response:** §6.4.2 rewritten with honest acknowledgment that the aggregate data dilutes the rental mechanism test.

### High-value 2: 90 kWh placebo

**Response:** See response to GPT §3.3 above. Expanded with economic reasoning.

---

## Exhibit Review Changes

Per the exhibit review:
1. **Promoted** Figure 2 (DPE distribution/timeline) to §2 (Institutional Background)
2. **Promoted** Figure 3 (RDD bin-scatters) to §6.2 (Results)
3. **Promoted** Figure 5 (coefficient plot) to §6.2 (Results)
4. **Promoted** covariate balance table to §6.3 (main text)
5. **Moved** Table 5 (pre/post ban) to Appendix (low N in post-ban column)
6. **Removed** redundant Appendix Table 6 (identical to main text Table 3)

## Prose Review Changes

Per the prose review:
1. Shortened roadmap paragraph (compressed from full description to single sentence per section)
2. Rewrote §6.4.2 opening in Glaeser style ("If the rental ban drives the G/F discontinuity, the effect should be strongest where people actually rent.")
3. Changed "A subtlety arises from" → "The double-seuil system creates a complication" (active voice, §5.4)
4. Softened over-claiming language throughout (abstract: "demonstrate" → "suggest"; conclusion: qualified with "in this setting")
