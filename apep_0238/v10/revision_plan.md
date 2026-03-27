# Revision Plan: apep_0238 v10

## One-Sentence Paper (Codex)
"Episodes that create prolonged nonemployment spells generate persistent labor-market scars; episodes that preserve matches and enable recall do not."

## Three-Question Filter
Every object answers one of: (1) Do GR and COVID differ in long-run scarring? (2) Is the difference clean? (3) Does duration/recall explain it?

## What Dies
- Structural DMP model (equations, calibration, SMM, welfare, counterfactuals)
- Horizon-by-horizon significance narrative
- Reviewer-driven side analyses not serving duration-trap argument
- Python code (rewrite in R)
- All prose (rewrite from scratch)

## What's New
- CPS mechanism evidence: state-level LTU share, temp layoff share, U→E transitions
- Single estimand: average prime-age EPOP months 48-120
- Duration-trap attenuation exercise
- Richer controls + permutation inference primary

## Architecture (~25 pages)
1. Introduction (3pp) — puzzle, guitar string, contribution
2. Duration Traps (2pp) — verbal predictions, no equations
3. Design and Estimand (4pp) — two episodes, two instruments, one outcome
4. Main Result (4pp) — episode-specific + pooled interaction
5. The Duration Trap (6pp) — CPS evidence, attenuation
6. Robustness (3pp) — window, controls, placebos
7. Conclusion (2pp)

5 figures, 6 tables. Title stays: "Demand Recessions Scar, Supply Recessions Don't."

## Co-Author Agreement
- Claude: code, prose, compilation, review pipeline
- Codex: empirical triage, pre-referee sign-off, post-review triage
