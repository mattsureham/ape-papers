## Discovery
- **Idea selected:** idea_0651 — ALJ leniency IV for opioid prescribing. Highest-ceiling idea from 30 random draws (5 subagent scouts).
- **Data source:** CDC VSRR (state-level overdose deaths by drug type), Census ACS (disability prevalence). Pivoted from original design (ARCOS county pills + SSA ALJ data) because SSA blocks all programmatic access and WaPo ARCOS API is down.
- **Key risk:** State-level panel (N=261) is coarser than the county/hearing-office design in the manifest.

## Execution
- **What worked:** The "difference-in-drugs" placebo design emerged from the data pivot. It's arguably cleaner than the original ALJ IV for testing the insurance channel — no instrument needed, just compare prescription vs illicit drug responses to disability.
- **What didn't:** Both SSA (hearing office/ALJ data) and WaPo ARCOS (county pills) are completely inaccessible programmatically. The original design was infeasible.
- **Review feedback adopted:** TBD after reviews complete.

## Key finding
- Cross-sectional disability-opioid correlation (+179) reverses to -546 with state+year FE
- Difference-in-drugs placebo uniformly fails — fentanyl and cocaine respond identically to prescription opioids
- Era split reveals the pill pipeline was weakly positive pre-2019 but irrelevant in the fentanyl era
