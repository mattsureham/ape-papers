## Discovery
- **Idea selected:** idea_0974 — Swiss cantonal tobacco billboard bans and healthcare costs. Chose this for the clean staggered DiD design with 16/10 treated/never-treated cantons and built-in placebo (cost categories).
- **Data source:** FOPH OKP Dashboard — downloaded seamlessly as ZIP from opendata.swiss. Clean, comprehensive, 1997-2024.
- **Key risk:** Small N (26 cantons) for clustering. Wild bootstrap p=0.16 confirms this is a real limitation.

## Execution
- **What worked:** The category decomposition (smoking vs placebo) is the strongest feature — hospital costs fall 13%, placebo categories near-zero in levels. Event-study dynamics show exactly the health-stock pattern (growing effects over 10+ years). Leave-one-out rock solid.
- **What didn't:** The log-based placebo test is noisy (physiotherapy -5%, p=0.07). The levels-based placebo is much cleaner but gets less attention. Should lead with levels-based placebo in future. Also, Geneva dropped from CS-DiD due to no pre-treatment data — small sample problem compounding.
- **Review feedback adopted:** Expanded limitations section to address policy bundling, missing mechanism data, and inference fragility. Added explicit discussion of physiotherapy placebo result. All three reviewers converged on the same three issues — honest acknowledgment is better than defensive hand-waving.
