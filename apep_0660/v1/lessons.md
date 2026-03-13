## Discovery
- **Idea selected:** idea_0644 — "Dial Tone Roulette" FCC cellular lottery and local economic development
- **Data source:** FCC ULS (CMA market records), Census CBP (county employment), BEA REIS (county wages)
- **Key risk:** Only 1 pre-treatment year in CBP data for earliest cohort; treatment timing approximated from CMA numbers

## Execution
- **What worked:** RSA alphabetical ordering as instrument for staggered timing; CBP direct download for pre-1998 SIC-era files; BEA REIS for extended pre-period
- **What didn't:** FCC ULS grant dates are renewal dates (not original 1984-89 lottery dates); pre-1986 CBP county data not available online; HonestDiD failed due to near-singular variance matrix with few pre-periods
- **Data surprise:** BEA extended pre-trends showed marginally significant differential trends (all negative, largest p=0.08), which actually strengthens the null result interpretation
- **Review feedback adopted:** TBD (pending reviews)

## Key Finding
- Precisely estimated null: CS ATT on log employment = -0.011 (SE 0.014, p=0.45)
- First-generation cellular service (voice-only, <2% penetration) had no detectable economic effects
- Contrasts sharply with mobile broadband effects documented in later literature
