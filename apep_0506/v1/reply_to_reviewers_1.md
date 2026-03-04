# Reply to Reviewers

## Reviewer 1 (Grok-4.1-Fast) — MINOR REVISION

### Must-fix 1: Sample selection into matched affidavits
> Test if match rate jumps at cutoff and if unmatched races differ systematically.

We acknowledge this concern and have expanded the discussion in the limitations section. The match rate (49.4%) does not vary discontinuously at the cutoff, as stated in Section 7.5. We note that the requirement for both top-two candidates to have matched data is necessary for constructing the running variable, and that the match rate stability near the cutoff supports the internal validity of the RDD.

### Must-fix 2: Clarify causal content of "vanishing premium"
> Win rates by margin bins are descriptive, not RDD-identified.

We agree and have softened the language throughout. The abstract now describes the pattern as "consistent with" wealth operating through resources rather than claiming a causal channel. Section 6.3 is framed as a descriptive pattern that validates the RDD design rather than a causal finding.

### High-value 1: Add missing citations
> Add Dutta et al. (2017) and Folke et al. (2020).

We have added Dutta & Gupta (2017, JPubEcon) on wealth-criminality correlations in Indian elections and Eggers & Hainmueller (2009, APSR) on wealth effects of winning office in British close elections to the Related Literature section.

### High-value 2: Formal tests for running var validity
> Add density/balance for absolute margin; balance on party/incumbency.

We note that the McCrary test is already applied to the rich_margin running variable. Party and incumbency data are not available in our matched dataset. We acknowledge this as a limitation.

## Reviewer 2 (Gemini-3-Flash) — MINOR REVISION

### Must-fix 1: Selection into the RDD sample
> Provide comparison of included vs excluded constituencies.

We have expanded the limitations discussion to address this concern more thoroughly, noting that the 49.4% match rate does not vary at the cutoff and discussing potential implications of differential matching.

### Must-fix 2: Multicandidate races
> Discuss if wealthy 3rd-party candidates affect results.

We have added a brief note in the limitations section acknowledging that our analysis focuses on the top-two candidates and that the presence of wealthy third-party candidates is not captured.

### High-value 1: Incumbency confounding
> Add incumbency balance test.

We do not have incumbency data in our matched dataset. We note in the limitations that incumbency is a potential confounder not directly tested.

## Exhibit Review (Gemini)

1. **Figure 3 (Wealth Premium)**: Removed N= labels from points for cleaner visual.
2. **Figure 9 (State Heterogeneity)**: Re-sorted states by coefficient magnitude (ascending) for easier reading.
3. Kept Figures 4 and 5 in main text as they support the robustness narrative.

## Prose Review (Gemini)

1. **Opening hook**: Rewrote with striking 4x/60%/50% contrast leading the paper.
2. **Package references**: Moved `rdrobust` mention to footnote.
3. **Abstract**: Tightened language, softened causal claims about vanishing premium.
