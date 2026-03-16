## Discovery
- **Idea selected:** idea_0894 — UK MEES bunching at EPC threshold. Chosen for massive data (28.9M EPCs), sharp regulatory threshold, built-in rental/sale placebo.
- **Data source:** GOV.UK EPC Live Tables D1 (band counts) and D4B (transaction types). Individual-level EPC Register API requires authenticated access — had to pivot from score-level bunching to aggregate band-level analysis.
- **Key risk:** Without individual scores, we can't do true bunching estimation.

## Execution
- **What worked:** The cross-LA DiD using rental intensity as treatment produced a clean, surprising result: high-rental LAs saw attenuated F+G declines, not accelerated declines. The "measurement effect" framing emerged naturally from the data.
- **What didn't:** The original bunching idea was infeasible without EPC API credentials. The event study pre-trends are noisy, which weakens identification.
- **Review feedback adopted:** Clarified that positive coefficient represents attenuated decline (not absolute increase); added back-of-envelope calculation of measurement effect magnitude; acknowledged data limitation and deviation from bunching design explicitly.
