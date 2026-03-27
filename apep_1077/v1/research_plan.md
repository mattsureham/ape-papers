# Research Plan: apep_1077

## The Protection Illusion: Child Labor Law Rollbacks and Teen Employment

### Research Question

Do state-level rollbacks of child labor protections (2022--2024) increase teenage employment in food services and retail? Twelve U.S. states weakened child labor laws by extending permissible hours, eliminating work permits, or lowering minimum ages. If these century-old protections were binding constraints on teen labor supply, rollbacks should increase teen employment in affected industries. A null implies the protections were already non-binding --- states dismantled regulations for no marginal labor-market effect.

### Identification Strategy

**Triple-difference (DDD):**
- **D1 (State):** 12 rollback states vs. ~38 non-rollback states
- **D2 (Industry):** Teen-intensive industries (NAICS 72 food services, NAICS 44-45 retail) vs. adult-dominated placebo (NAICS 54 professional services)
- **D3 (Age):** Teens (age 14--18, QWI group A01) vs. young adults (19--21, A02)

This absorbs: (1) state-level shocks (via state x quarter FE), (2) national teen employment trends (via age x quarter FE), (3) industry macro cycles (via industry x quarter FE).

**Estimator:** Callaway-Sant'Anna (2021) with staggered treatment cohorts. Treatment cohorts: NH/NJ (2022), IA/AR/TN (2023), AL/FL/IN/KY/WV (2024). Never-treated states as comparison group.

**Inference:** Cluster at state level (~50 clusters). Wild cluster bootstrap as robustness.

### Expected Effects and Mechanisms

**Prediction 1 (Binding constraint):** If protections were binding, expect positive DDD on teen employment in food services/retail post-rollback.

**Prediction 2 (Non-binding / Protection Illusion):** If other factors (school requirements, family norms, employer preferences, federal FLSA) substitute for state restrictions, expect null DDD. This is the "protection illusion" --- states removed rules that were already non-binding.

**Prediction 3 (Stigma/sorting):** If rollbacks signal permissive attitudes, adult workers may sort away from teen-heavy industries, yielding composition effects without net employment gain.

### Primary Specification

$$Y_{csaqt} = \alpha + \beta \cdot \text{Rollback}_{st} \times \text{Teen}_{a} \times \text{FoodRetail}_{q} + \gamma_{sq} + \delta_{aq} + \eta_{iq} + \epsilon_{csaqt}$$

where $c$ = county, $s$ = state, $a$ = age group, $i$ = industry, $q$ = quarter. $Y$ is log employment. DDD coefficient $\beta$ = marginal effect of rollback on teen employment in affected industries relative to adults in unaffected industries.

### Data Sources

1. **QWI (Quarterly Workforce Indicators)** on Azure: `derived/qwi/sa/ns/*.parquet`
   - County x quarter x NAICS sector x sex x age group
   - Variables: Emp (employment), HirA (hires), Sep (separations), EarnS (earnings)
   - Coverage: 2018Q1--2025Q1 (pre/post rollbacks)
2. **Treatment coding:** Law effective dates from National Conference of State Legislatures (NCSL) and Economic Policy Institute (EPI) compilations
3. **Controls:** State quarterly unemployment rate (BLS LAUS), state GDP (BEA)

### Key Risks

1. **Short post-treatment window:** Most rollbacks 2022--2024, so only 1--3 years of post data. Mitigated: labor market responses to deregulation should be rapid if binding.
2. **Heterogeneous law content:** States weakened protections in different ways (hours vs. permits vs. age). Mitigated: all weaken the same margin (teen labor supply constraint).
3. **COVID recovery confound (2022 states):** NH/NJ passed laws during COVID recovery. Mitigated: DDD washes out state-level recovery (via state x quarter FE) and national teen trends (via age x quarter FE).
