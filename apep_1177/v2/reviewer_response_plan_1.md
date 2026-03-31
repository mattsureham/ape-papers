# Reviewer Response Plan — Round 1

## Consensus Across Reviewers

All three reviewers agree:
1. The empirical pattern (trafficking-theft r=0.10 vs robbery-theft r=0.67) is descriptively interesting
2. The cross-offense comparison within the same courthouse is a design strength
3. The causal claim about legal indeterminacy is overclaimed — the design doesn't isolate legal precision from other offense-specific differences

## Response Strategy

### Accept: Downshift causal claims
Both GPT reviewers and our co-author (Codex) flagged this. The honest claim is: "the cross-offense pattern is *consistent with* offense-specific discretion under a vague standard" — not "we identify the causal effect of legal indeterminacy." We will revise all causal language in abstract, introduction, and conclusions.

### Accept: More careful statistical treatment
GPT-R1 wants shrinkage-corrected correlations and formal hierarchical model. This is a valid request we partially addressed. We will add reliability-corrected correlation estimates in robustness.

### Accept: Address SDE magnitude issue
Gemini flagged the SDE=2.20 as implausibly large. This is mechanical given the LOO construction. We will add a note explaining this and downweight the SDE significance.

### Defer: Full hierarchical model
GPT-R1 wants a formal Bayesian hierarchical model. This is a valid suggestion but out of scope for this revision cycle. We acknowledge it as future work.

### Reject: Comparison to other drug offenses
GPT-R1 suggests comparing to a drug offense with clearer criteria. No such offense exists in Brazilian law — that IS the policy problem.

## Actions for This Revision Cycle

Given the verdict distribution (1 Minor, 1 Major, 1 R&R), the priority is to downshift rhetoric and add statistical robustness. We will NOT attempt a full redesign.

1. Revise all causal language to "consistent with" framing
2. Add reliability-corrected correlations
3. Fix SDE table note
4. Write reply_to_reviewers_1.md
