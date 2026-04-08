## Discovery
- **Idea selected:** idea_1381 — Azerbaijan's ASAN one-stop-shop reform. Chose for massive raw effect size (52%→12% bribery drop), clean institutional shock, and virgin territory (no existing APEP paper on Azerbaijan/Caucasus).
- **Data source:** World Bank WDI/WGI/Enterprise Surveys via REST API — reliable, no authentication needed. BEEPS firm-level microdata requires World Bank account, so pivoted to cross-country design.
- **Key risk:** Single treated unit limits statistical power; only 1 country has the reform.

## Execution
- **What worked:** Cross-country TWFE DiD with permutation inference is clean and appropriate for N=1 treated. Government effectiveness result (+0.37 SD, p=0.003) is strong and robust. The oil crash context creates a natural "resilience" test.
- **What didn't:** Business registrations show +22% growth but Kazakhstan grew more — permutation p=0.80, not significant. Bribery has massive point estimate (-30 pp) but sparse ES data gives low power (p=0.15).
- **Review feedback adopted:** Reviews failed (OpenRouter auth). No feedback to adopt.

## Lessons for Future Work
- Cross-country SCM/DiD designs work well for national-level policy reforms but face inherent power limitations. Best suited for governance/institutional outcomes (WGI) where variation is low enough that even small effects are detectable.
- The oil price crash created both a threat (confounder) and an opportunity (resilience test). Always look for concurrent shocks that can be reframed as mechanism tests.
- WDI API is reliable for country-level panels but Enterprise Survey microdata needs authenticated access. Consider applying for World Bank Microdata Library access for future BEEPS papers.
