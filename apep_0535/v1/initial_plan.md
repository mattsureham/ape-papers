# Initial Research Plan: apep_0535

## Research Question

Do permanent state gasoline tax increases — the most visible consumer price signal — cause disproportionate shifts in broader macroeconomic beliefs? Specifically, when a state raises its gas tax and pump prices rise, do residents become more pessimistic about the national economy, beyond what local economic conditions would justify?

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway-Sant'Anna (2021) estimators.

- **Treatment:** Discrete legislative state gasoline tax increases (effective date and magnitude from Tax Foundation/NCSL/FHWA). Approximately 25-30 clean treatment events across 2013-2023. Automatic variable-rate indexation adjustments excluded from primary specification.
- **Treatment cohorts:** Groups of states by year of first discrete gas tax increase in the sample period.
- **Control group:** Never-treated states and not-yet-treated states.
- **Unit of analysis (CES):** Individual respondents nested within state-year cells. ~700K respondents, 2006-2024 waves.
- **Unit of analysis (Google Trends):** State-month search intensity index, 2010-2024.
- **Key assumption:** Parallel trends in macroeconomic perceptions between treated and control states absent the gas tax change. Validated via event-study pre-trend coefficients.

### Exposure Alignment

- **Who is actually treated?** Residents of states that enacted a discrete gasoline tax increase. All residents are exposed to higher pump prices (even non-drivers see gas station signs), but drivers/commuters are more directly affected.
- **Primary estimand population:** CES respondents in treated states (post-treatment waves).
- **Placebo/control population:** (1) CES respondents in never-treated states; (2) Urban non-driving populations within treated states (density-based proxy); (3) Google Trends for non-economic search terms.
- **Design:** Staggered DiD (primary), with heterogeneity by exposure intensity.

### Power Assessment

- **Pre-treatment periods:** CES 2006-2012 provides 7 annual pre-periods before the earliest treatments (2013). Google Trends provides monthly data from 2010.
- **Treated clusters:** ~25-30 states with discrete gas tax increases.
- **Post-treatment periods per cohort:** Varies by adoption year; earliest cohorts (2013) have up to 11 post-periods.
- **MDE given sample size:** With ~700K CES respondents across ~50 states and ~19 years, state-year cells average ~700 respondents. Standard errors clustered at the state level (~50 clusters). Given the 5-point outcome scale (mean ~3.0, SD ~1.2), the minimum detectable effect at 80% power is approximately 0.05-0.10 scale points (3-7% of a standard deviation), which is plausible for a salient price signal.

## Expected Effects and Mechanisms

**Primary hypothesis:** Gas tax increases make residents more pessimistic about the national economy, measured by CES `economy_retro` shifting toward "gotten worse."

**Mechanism:** Salience bias in information processing. Gasoline is the most frequently observed price signal (posted on large signs at every street corner, encountered 1-2 times per week by drivers). Following D'Acunto et al. (2021), the frequency of price exposure — not the expenditure share — determines its weight in belief formation. A gas tax increase raises a highly salient price, which consumers may overgeneralize to broader economic conditions.

**Expected magnitudes:** Based on Binder & Makridis (REStat 2022) finding that a 1 SD gas price increase reduces consumer sentiment by ~2% of a SD, and Jo & Klopack (JME 2025) finding that a gas tax reduction lowered inflation expectations by 1.35 pp, we expect gas tax increases of $0.10-$0.25/gallon to shift economic retrospection by 0.05-0.15 points on the 5-point CES scale.

**Heterogeneity predictions:**
1. Larger effects for rural/suburban residents (more car-dependent, more gas station exposure)
2. Larger effects for lower-income respondents (gas is larger budget share)
3. Larger effects for older cohorts (Malmendier-Nagel experience effects from 1970s oil crises)
4. Potentially asymmetric: positive gas tax changes (hikes) may have larger effects than negative (per D'Acunto et al. loss aversion in price signals)

## Primary Specification

**CES Individual-Level (Main):**
```
economy_retro_{ist} = α + β · PostGasTax_{st} + X_{ist}γ + δ_s + θ_t + ε_{ist}
```

Where:
- `economy_retro_{ist}`: 1-5 scale economic retrospection for individual i in state s, year t
- `PostGasTax_{st}`: indicator = 1 if state s has enacted a discrete gas tax increase by year t
- `X_{ist}`: individual controls (age, gender, race, education, income, party ID)
- `δ_s`: state fixed effects
- `θ_t`: year fixed effects
- Standard errors clustered at the state level

Estimated via Callaway-Sant'Anna `did` package with not-yet-treated as comparison group and inverse probability weighting.

**Google Trends (Secondary, High-Frequency):**
```
SearchIndex_{sm} = α + β · PostGasTax_{sm} + δ_s + θ_m + ε_{sm}
```

State-month panel of Google Trends search intensity for "inflation" and "recession" keywords.

## Planned Robustness Checks

1. **Pre-trends:** Event-study coefficients for 5+ years before treatment (CES) and 24+ months before (Google Trends)
2. **Placebo search terms:** Google Trends for "weather," "sports," "recipes" should show null effects
3. **Temporal placebo:** Assign fake treatment dates 2 years before actual changes
4. **Dose-response:** Interact treatment with gas tax increase magnitude (cents/gallon)
5. **First-stage validation:** EIA SEDS annual state gas prices showing pass-through
6. **Bundled legislation control:** Control for concurrent state tax changes (income, sales, property)
7. **TWFE comparison:** Run standard TWFE and compare with CS-DiD to show sensitivity
8. **Bacon decomposition:** Decompose TWFE into clean vs. potentially biased 2x2 comparisons
9. **Alternative control groups:** Never-treated only vs. not-yet-treated
10. **Urban/rural heterogeneity:** Test exposure channel (rural residents more affected)
11. **Partisan heterogeneity:** Test whether Republican vs. Democrat respondents respond differently
12. **Income heterogeneity:** Test whether low-income (higher gas budget share) respond more
