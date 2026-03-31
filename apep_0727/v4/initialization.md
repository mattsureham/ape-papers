# Human Initialization
Timestamp: 2026-03-31T02:05:00Z

## Launch Prompt
> revise-paper-duet apep_0727 v3, i'm sure you guys can figure out how to make it even better, more polished, more compelling.

## Contributor (Immutable)
**GitHub User:** @SocialCatalystLab

## System Information
- **Claude Model:** claude-opus-4-6
- **Co-Author:** Codex (via Duet daemon)

## Revision Information
**Parent Paper:** apep_0727
**Parent Title:** Too Small by Design: How Threshold-Based Climate Policy Shrank the Panels It Subsidized
**Parent Version:** v3 (published, rating μ=37.1, conservative 27.0, 9W-1L)
**Parent Decision:** MAJOR REVISION (2 of 3 referees)
**Revision Rationale:** Address unresolved technical gaps (inference, missing mass, monthly formalization, mechanism evidence) and reframe from bunching application to general policy design paper

## Key Changes Planned
1. Pipeline audit: unify estimator stack across all code files
2. Formal monthly event study with bootstrap CIs as core evidence
3. Missing-mass notch analysis to earn or honestly decline the "shrank capacity" claim
4. Decide intermediary mechanism status (result vs interpretation)
5. Honest uncertainty via pre-specified estimator family
6. Reframe introduction around the world question
7. Subtract: 30 kWp → appendix, ground-mount demoted, annual table → appendix

## Original Reviewer Concerns Being Addressed
1. **GPT1+GPT2:** Inference is misleading (bootstrap SEs from near-census) → specification family + bounded range
2. **GPT1+GPT2:** Monthly evidence is only visual → formal tabulated event study with CIs
3. **GPT1+GPT2:** Notch analysis incomplete (no missing mass) → full mass balance exercise
4. **GPT1+GPT2:** Welfare claims exceed evidence → data-driven welfare from missing mass
5. **GPT1+GPT2:** Mechanism claims overstated → explicit claim register (result vs interpretation)
6. **All strategic reviewers:** Reframe from bunching app to policy design paper → new intro/abstract

## Inherited from Parent
- Research question: same (threshold-based climate policy distortions)
- Identification strategy: same (four-break design at 10 kWp) + strengthened (formal timing, missing mass)
- Primary data source: same (Marktstammdatenregister, 3M+ installations)
