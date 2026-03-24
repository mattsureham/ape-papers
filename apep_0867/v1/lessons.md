## Discovery
- **Idea selected:** idea_0708 — EU Copyright Directive Article 17 upload filters. Chosen for 27-country staggered transposition, zero causal papers, and active policy debate.
- **Data source:** Eurostat LFS (lfsa_egan2) — clean API, perfectly balanced panel. EUR-Lex NIM for transposition dates (legal facts).
- **Key risk:** NACE J too broad for platform-specific effects; pre-trends in late transposers.

## Execution
- **What worked:** The DDD (NACE J vs K) is a strong built-in placebo. Randomization inference is elegant with 30 countries. The "upload filter illusion" framing gives the null a vivid economic object.
- **What didn't:** Pre-trends in the 2023 cohort were significant and hard to dismiss. Country-level data limits power relative to NUTS2. The `did` package rejected the never-treated group (only 4 countries) — had to use not-yet-treated.
- **Review feedback adopted:** Added cohort-specific CS-DiD excluding 2023 cohort (shows ATT is larger positive without them). Added Poland exclusion sensitivity. Added limitation paragraphs on NACE J breadth and country-level aggregation.
