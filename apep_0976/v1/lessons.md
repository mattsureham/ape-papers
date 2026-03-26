## Discovery
- **Idea selected:** idea_1036 — Japan's Yakuza Exclusion Ordinances across 47 prefectures, chosen for sharp institutional variation and novel real-economy angle on organized crime
- **Data source:** e-Stat System of Social and Demographic Statistics (prefecture-level panel). MLIT transaction-level API was unreachable (DNS failure, likely geo-restricted). Kaggle mirror required credentials not available. The e-Stat pivot gave annual data rather than quarterly transactions — workable but reduced temporal resolution from 8 monthly cohorts to 2-3 annual cohorts.
- **Key risk:** Tohoku earthquake (March 2011) overlaps with modal adoption wave (April 2011)

## Execution
- **What worked:** The e-Stat API is reliable and comprehensive. Prefecture-level data for crime, land prices, building starts, and population all available back to 2003. The Callaway-Sant'Anna estimator handled the 2-cohort structure cleanly. The heterogeneity by baseline crime exposure was the paper's strongest finding.
- **What didn't:** MLIT API completely blocked. The annual data frequency limits the event study to only 2-3 post-treatment points before all units are treated. TWFE estimates were uniformly near zero (classic staggered DiD bias), making the CS vs TWFE comparison itself interesting but reducing the paper's punch for readers less versed in methodology.
- **Review feedback adopted:** Expanded discussion of why benchmark prices were used instead of transaction data, strengthened Tohoku earthquake confound discussion, acknowledged limitations of rough crime as yakuza proxy, noted Economic Census data gap for business formation outcomes.
