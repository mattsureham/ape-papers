# Research Plan: The CROWN Act and Black Worker Outcomes

## Research Question

Does banning hair discrimination under state CROWN Act laws reduce racial employment and earnings gaps for Black workers, and through which channels—hiring, occupational upgrading, or earnings growth?

## Policy Background

The CROWN Act (Creating a Respectful and Open World for Natural Hair) prohibits employment discrimination based on hair texture and protective hairstyles (e.g., locs, braids, twists, Bantu knots) associated with race. California enacted the first CROWN Act in July 2019 (effective January 2020), and by 2024, 25 states have adopted similar laws with staggered effective dates spanning 2019–2024.

Prior sociological evidence documents pervasive hair-based discrimination: Black women are 1.5× more likely to be sent home from work because of their hair, 2.5× more likely to have their hair perceived as "unprofessional," and 80% report changing their natural hairstyle to conform to workplace expectations (Dove CROWN Study, 2019). Despite this, no economics paper has estimated the causal labor market effects of anti-hair-discrimination legislation.

## Identification Strategy

**Design:** Staggered difference-in-differences with triple-differencing.

**Primary specification (Triple-Diff):**

Y_{ist} = α + β₁(Black_i × CROWN_st × Post_st) + γ(Black_i × CROWN_st) + δ(Black_i × Post_st) + θ(CROWN_st × Post_st) + State_s + Year_t + Race_i + State×Year_{st} + Race×Year_{it} + State×Race_{si} + ε_{ist}

Where:
- Y_{ist}: outcome for individual i in state s at time t
- Black_i: indicator for Black/African American race
- CROWN_st: indicator that state s has an active CROWN Act at time t
- Post_st: indicator for post-enactment period in state s

**Triple-diff logic:** β₁ captures the differential change in outcomes for Black workers (vs White workers) in CROWN-adopting states (vs non-adopting states) after enactment. This nets out: (a) common time trends, (b) state-specific shocks like COVID that affect both races, (c) race-specific national trends.

**Estimator:** Callaway and Sant'Anna (2021) for heterogeneous treatment timing, with group-time ATTs aggregated by event time.

## Pre-Registered Primary Outcomes (4)

1. **Black-White employment rate gap** (extensive margin)
2. **Black-White log weekly earnings gap** (intensive margin, conditional on employment)
3. **Black share in customer-facing occupations** (SOC 35xxxx food prep/serving, 39xxxx personal care, 41xxxx sales, 43xxxx office/admin support, 53xxxx transportation)
4. **Black share in professional/managerial occupations** (SOC 11xxxx management, 13xxxx business/financial, 15-29xxxx computer/science/education/healthcare)

## Expected Effects and Mechanisms

**Hypothesis:** CROWN Acts reduce appearance-based discrimination, primarily benefiting Black workers (especially women) in customer-facing and professional roles where hairstyle norms are most binding.

**Expected signs:**
- Employment gap: narrowing (positive β₁ if coded as Black employment advantage)
- Earnings gap: narrowing
- Customer-facing occupation share: increasing for Black workers
- Professional occupation share: increasing for Black workers

**Mechanism decomposition:**
1. **Hiring channel:** New employment for previously excluded Black workers
2. **Occupational upgrading:** Movement from non-customer-facing to customer-facing/professional roles
3. **Retention/productivity:** Reduced need to alter natural hair → lower psychic cost → better performance
4. **Heterogeneity by sex:** Effects concentrated among Black women (stronger hairstyle norms)
5. **Heterogeneity by occupation type:** Effects larger in customer-facing vs back-office roles

## Exposure Alignment (DiD)

- **Who is treated?** Black workers in states that adopt CROWN Act laws
- **Primary estimand population:** Working-age (16-64) Black adults in treated states
- **Placebo/control population:** (1) White workers in treated states, (2) Black workers in never-treated states, (3) Workers in non-customer-facing occupations
- **Design:** Triple-diff (Black × State × Post)

## Power Assessment

- **Pre-treatment periods:** 2015–2018 (4 years for early adopters), extending to 2019 for later adopters
- **Treated clusters:** 25 states, staggered over 5 adoption years
- **Post-treatment periods per cohort:** 1–5 years depending on adoption date
- **Sample size:** ACS 1-year has ~3.5M respondents/year; ~12% Black → ~420K Black respondents/year; state-year cells for Black workers average ~8,400 observations
- **MDE:** With 50 states × 10 years = 500 state-year cells, ~25 treated, standard errors clustered at state level → well-powered to detect 1-2pp changes in employment rates or 2-3% changes in earnings

## Data Sources

1. **American Community Survey 1-year PUMS** (2015–2024): Primary dataset via Census API/FTP. Variables: employment, earnings, occupation (SOC), industry (NAICS), state, race, sex, age, education.
2. **Current Population Survey Basic Monthly** (2015–2024): Secondary for monthly dynamics, via Census Bureau FTP or IPUMS.
3. **Google Trends:** "CROWN Act" search interest by state for awareness/salience.

## Planned Robustness Checks

1. Exclude 2020 entirely (COVID shock)
2. Exclude 2020 + early 2021
3. Use only post-2020 adopters (clean pre-periods)
4. Bacon decomposition for weighting diagnosis
5. Randomization inference (permute treatment assignment)
6. Rambachan-Roth HonestDiD sensitivity
7. Border PUMA analysis (adjacent PUMAs across state lines)
8. Placebo test: Asian/Hispanic workers (less affected by hair texture norms)
9. Placebo test: Effects in states with existing broad anti-discrimination protections
10. Event study with pre-treatment leads (parallel trends test)
11. Stacked DiD (clean comparison groups per cohort)
12. Sun and Abraham (2021) interaction-weighted estimator as alternative

## Welfare Calculation

Total welfare gain = ΔEmployment × E[earnings] + ΔEarnings × N_employed

Will compute per-worker and aggregate gains for Black workers in treated states, separately by sex.
