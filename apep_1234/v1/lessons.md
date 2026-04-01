## Discovery
- **Idea selected:** idea_0665 — FATF grey-listing with within-country bank license heterogeneity in Panama. Novel angle: all prior work is cross-country.
- **Data source:** Superintendencia de Bancos de Panamá (SBP) — URLs had migrated from old site structure; needed WebFetch to find new paths. Both key Excel files (Indicadores_Financieros, BANCOS) downloaded successfully.
- **Key risk:** Effective sample size — data at bank-TYPE level (6 types × 122 months) rather than individual banks (~18-20 per type).

## Execution
- **What worked:** Clean null result with multiple robustness checks. The within-country design with pre-determined license types is genuinely novel. Permutation inference (p=0.20) corroborates Driscoll-Kraay results. The "compliance illusion" mechanism framing is memorable and portable.
- **What didn't:** Joint pre-trend test fails (p<0.001) due to anticipatory dip during FATF evaluation window. MDE is large (1.78 SD), limiting power for moderate effects. Two-unit panel structure is inherently fragile — individual bank data would strengthen the paper enormously.
- **Review feedback adopted:** Added permutation inference, joint F-test of pre-trends, MDE calculation, and discussion of prior 2014-16 grey-listing as adaptation. Calibrated null result claims to acknowledge power limitations. All three reviewers (Codex-Mini, GPT-OSS, Kimi) flagged the same core issues.
