# Reply to Reviewers — Round 1

## Referee 1 (GPT-5.4 R1): Reject and Resubmit

**Main concern:** The paper's causal interpretation (legal indeterminacy → decoupling) is not identified by the cross-offense comparison design.

**Response:** We agree that the design identifies the *pattern* of cross-offense correlations but does not causally isolate the legal-standard mechanism from other offense-specific differences (evidentiary environments, police practices, plea dynamics). We have revised all causal language to "consistent with" framing. The paper's contribution is the empirical pattern itself — documenting that judicial heterogeneity has offense-specific dimensions — and the institutional interpretation as the most parsimonious explanation.

**On shrinkage/hierarchical model:** We have added reliability-corrected correlation estimates to the robustness section. A full Bayesian hierarchical model is a valuable suggestion that we acknowledge as future work.

**On SDE magnitude:** The SDE of 2.20 is mechanical given the LOO construction (regressing conviction on leave-one-out conviction rate). We have added an explanatory note.

## Referee 2 (GPT-5.4 R2): Major Revision

**Main concern:** Same as R1 — the causal claim about legal indeterminacy is overclaimed.

**Response:** Same revision strategy as R1. We have downshifted all causal language.

**On within-offense-type analysis:** R2 suggests the paper would be stronger with richer within-trafficking analysis. We agree but are constrained by available covariates in DataJud (no drug quantities, defendant demographics, or arrest circumstances).

## Referee 3 (Gemini-3-Flash): Minor Revision

**Main concern:** Minor issues including filing-month balance, SDE magnitude, and literature positioning.

**Response:** Filing-month balance is discussed transparently. SDE note added. Literature engagement expanded in Section 2.

## Summary of Changes

1. Revised all causal language to "consistent with" framing throughout abstract, intro, results, and discussion
2. Added reliability-corrected correlation estimates in robustness
3. Added SDE explanatory note
4. Acknowledged hierarchical model as future work
5. Expanded limitations section on alternative mechanisms
