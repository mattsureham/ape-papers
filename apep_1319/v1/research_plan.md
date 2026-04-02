# Research Plan: The Toolkit Trap

## Research Question
Does consolidating fragmented enforcement regimes improve or undermine enforcement effectiveness? Specifically, did the Anti-Social Behaviour, Crime and Policing Act 2014 — which replaced 19 enforcement tools with 6 streamlined powers — reduce anti-social behaviour, and did areas most reliant on the old toolkit experience the largest disruption?

## Policy Background
The Anti-Social Behaviour, Crime and Policing Act 2014 (Royal Assent 13 March 2014, main provisions commenced 20 October 2014) replaced the entire enforcement toolkit:
- ASBOs, drinking banning orders, dispersal orders, crack house closure orders, and 15 other tools → 6 new powers (Civil Injunction, Criminal Behaviour Order, Community Protection Notice, Public Spaces Protection Order, Closure Power, Dispersal Power)
- All police force areas treated simultaneously
- But pre-reform reliance on the old tools varied enormously: Greater Manchester issued 2,197 ASBOs (1999-2013) vs Wiltshire's 113

## Identification Strategy
**Continuous-treatment DiD** with predetermined treatment intensity.

Treatment intensity = pre-reform cumulative ASBO issuance rate per 100,000 population (from Home Office ASBO Statistics, 2000-2013, by Criminal Justice System area). This is predetermined — ASBOs issued years before the reform was announced cannot be affected by anticipation of the 2014 Act.

**Primary specification:**
ASB_{ft} = alpha_f + gamma_t + beta * (Post_t x ASBORate_f) + X_{ft} delta + epsilon_{ft}

Where f indexes force areas, t indexes months, Post_t = 1 after October 2014, and ASBORate_f is the pre-reform ASBO issuance rate per capita.

**Inference:** Cluster at force-area level (N~42). Given few clusters, supplement with wild cluster bootstrap (Webb weights, 6-point distribution).

## Expected Effects and Mechanisms
Two competing hypotheses:
1. **Simplification dividend:** Streamlined tools lower barriers to enforcement → high-ASBO areas benefit most (beta < 0)
2. **Toolkit trap:** Areas that built enforcement capacity around ASBOs face transition costs, institutional inertia, retraining needs → high-ASBO areas see relative increase in ASB (beta > 0)

Mechanism tests:
- Decompose by crime type (ASB-specific vs. other crime categories)
- Test for adaptation dynamics (does the effect attenuate over time?)
- Heterogeneity by force area characteristics (urban vs. rural, deprivation)

## Data Sources
1. **Anti-social behaviour incidents:** data.police.uk bulk CSV downloads (May 2013-present), monthly by police force area. ~42 forces × ~150 months.
2. **ASBO issuance statistics:** Home Office ASBO Statistics (data.gov.uk), 2000-2013 by CJS area. Provides the treatment intensity measure.
3. **Police force area population:** ONS mid-year population estimates for rate construction.

## Primary Specification
- Unit: Police force area × month
- Outcome: ASB incidents per 100,000 population
- Treatment: Post × ASBO rate per capita
- Fixed effects: Force area + year-month
- Clustering: Force area (wild cluster bootstrap)
- Pre-period: May 2013 - September 2014 (18 months)
- Post-period: November 2014 onwards

## Exposure Alignment
The treatment variable (pre-reform ASBO issuance rate) measures institutional investment at the police force area level. The outcome (ASB incidents) is also measured at the police force area level, ensuring that the treatment and outcome are aligned at the same geographic unit. All residents of a force area are exposed to the same enforcement regime — there is no individual-level variation in exposure conditional on location. The reform affected enforcement tools available to all forces equally; variation comes from how much each force relied on the old tools.

## Robustness
1. Event study (monthly leads and lags)
2. Placebo outcome: non-ASB crime categories (burglary, vehicle crime)
3. Alternative treatment measures (ASBO rate using different base years)
4. Leave-one-out: drop Greater Manchester/London (high-leverage)
5. Permutation inference (Fisher exact test)
