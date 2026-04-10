## Discovery
- **Idea selected:** idea_0107 — Poland's 2017 retirement age reversal is a rare symmetric reform-reversal natural experiment. Selected because tournament lessons emphasize policy reversals as "unusually powerful."
- **Data source:** Eurostat LFS (`lfsq_ergan`) — clean quarterly employment rates by sex/age/country via `eurostat` R package. No authentication needed.
- **Key risk:** Single treated country limits SCM power; main identification relies on cross-country DD/DDD with 8 CEE donors.

## Execution
- **What worked:** Cross-country DD produced very clean results (−11.16pp, p < 0.001). The asymmetry comparison (−4.03pp for 2013 raise vs −7.22pp for 2017 reversal) is the paper's distinctive contribution. "Retirement ratchet" framing gives a portable concept.
- **What didn't:** Initial within-Poland DDD event study was over-parameterized (4 cells × 60 quarters can't support 240+ parameters — degenerate SEs). Pivoted to cross-country specifications. SCM failed on unbalanced panel — not debugged for V1.
- **Review feedback adopted:** All three reviewers flagged missing event study and SCM. Added explicit "what this design can and cannot identify" paragraph (Codex-Mini). Added normalized asymmetry comparison per year of age shifted (Gemini, Grok). Added inference limitations paragraph addressing small-cluster concerns (Gemini). Strengthened mechanism discussion re: liquidity vs reference points (Gemini suggestion).
