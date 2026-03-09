# Initial Research Plan — APEP-0546

## Research Question

Do Extreme Risk Protection Order (ERPO) laws reduce total suicide mortality, or do they merely shift deaths from firearms to other methods? This paper tests the means substitution hypothesis — the possibility that individuals denied access to firearms substitute to other lethal means, undermining the policy's life-saving potential.

## Identification Strategy

**Callaway and Sant'Anna (2021) staggered DiD** exploiting the staggered adoption of ERPO laws across 22 US states between 1999 and 2024.

- **Treatment:** Binary indicator equal to 1 in the year a state's ERPO law takes effect and all subsequent years.
- **Control group:** Never-treated states (28 states with no ERPO law) as the primary comparison group. Not-yet-treated states as a robustness check.
- **Estimand:** Group-time average treatment effects on the treated (ATT), aggregated into an overall ATT and dynamic event-study coefficients.

### Exposure Alignment

- **Who is treated:** State populations in states that adopt ERPO laws
- **Primary estimand:** Effect on age-adjusted suicide rate per 100,000
- **Placebo population:** Drug overdose deaths (should not respond to firearm removal)
- **Design:** Standard staggered DiD with 22 treated states

### Key Assumptions

1. **Parallel trends:** Absent ERPO adoption, treated and control states would have followed the same suicide rate trajectory
2. **No anticipation:** States do not change suicide behavior before ERPO laws take effect
3. **SUTVA:** One state's ERPO law does not affect another state's suicide rate (testable via border-state analysis)

## Expected Effects and Mechanisms

**Firearm suicide:** Negative effect expected. ERPOs temporarily remove firearms from high-risk individuals, reducing access to the most lethal suicide method (85% case fatality rate).

**Non-firearm suicide:** Ambiguous. If means substitution is complete, non-firearm suicide should increase by a comparable magnitude. If substitution is partial or absent, the coefficient should be near zero.

**Total suicide:** The key estimand. If ERPOs save lives net of substitution, total suicide should decline. If substitution is complete, total suicide shows no change despite firearm suicide declining.

**Drug overdose (placebo):** No effect expected. Firearm removal should not affect drug-related deaths.

## Primary Specification

```r
# Callaway-Sant'Anna with never-treated controls
cs_result <- att_gt(
  yname = "rate_All_Suicide",  # Total suicide rate
  tname = "year",
  idname = "state_id",
  gname = "G",  # First treatment year; 0 for never-treated
  data = panel,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)
```

## Planned Robustness Checks

1. **Alternative estimator:** Sun & Abraham (2021) interaction-weighted estimator
2. **Alternative control group:** Not-yet-treated states
3. **TWFE diagnostic:** Standard two-way fixed effects (known biased — for comparison only)
4. **Goodman-Bacon decomposition:** Diagnose TWFE bias sources
5. **Leave-one-out:** Drop each treated state to check influence
6. **Wild cluster bootstrap:** Few-cluster inference (51 clusters)
7. **HonestDiD:** Rambachan-Roth sensitivity bounds for parallel trend violations
8. **Heterogeneity by gun ownership:** Interaction with pre-treatment firearm suicide share

## Power Assessment

- **Pre-treatment periods:** 6-25 years depending on cohort (1999-2017 for late adopters)
- **Treated clusters:** 21 states (excluding CT with no pre-periods in the panel)
- **Post-treatment periods per cohort:** 2-20 years
- **MDE given sample size:** With 51 states × 25 years ≈ 1,275 state-years and SD of suicide rate ≈ 5.5 per 100K, the design can detect effects of approximately 0.8-1.5 per 100K with 80% power.

## Data Sources

1. **CDC Mapping Injury** (2019-2024): Firearm suicide, all suicide, drug overdose, homicide — state × year via Socrata API
2. **NCHS Leading Causes of Death** (1999-2017): Total suicide deaths and AADR — state × year via Socrata API
3. **ERPO adoption dates:** Hand-coded from Everytown, RAND, Giffords Law Center
4. **Gun ownership proxy:** Firearm suicide share (2019 CDC data)
