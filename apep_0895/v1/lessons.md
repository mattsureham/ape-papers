## Discovery
- **Idea selected:** idea_0522 — EU 5AMLD transposition provides staggered adoption across 23 treated + 4 never-treated countries; novel question (no causal AML evaluation exists)
- **Data source:** Eurostat crim_off_cat (crime stats) + CELLAR SPARQL (transposition dates) — SPARQL was intermittently unavailable, but data was confirmed and hardcoded from a successful earlier fetch
- **Key risk:** Country-level annual data limits power; only 2 pre-periods for earliest (2018) cohort

## Execution
- **What worked:** Clean identification — pre-trends test p=0.85, placebo on property crime null, leave-one-out stable. The "compliance trap" framing resonates.
- **What didn't:** Assault data (ICCS0201) was empty in Eurostat NR unit. Eurostat column names changed across datasets (TIME_PERIOD vs time). CELLAR SPARQL returned old NIM dates from prior directives that needed filtering.
- **Review feedback adopted:** Added MDE language (can rule out >39% but not modest effects); strengthened caveats on never-treated group (may have transposed via omnibus law); nuanced measurement discussion (detection vs. deterrence, classical attenuation)
