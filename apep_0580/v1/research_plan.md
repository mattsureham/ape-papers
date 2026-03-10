# Initial Research Plan: Follow the Money or Follow the Crime?

## Research Question

When US states reform civil asset forfeiture laws — removing or restricting law enforcement's ability to profit from seized property — do police departments reallocate enforcement effort away from drug crimes (which generate seizures) toward other crime types? This tests whether police respond to financial incentives in their enforcement priorities, as predicted by economic models of bureaucratic incentives.

## Identification Strategy

**Callaway & Sant'Anna (2021) staggered DiD** exploiting the staggered adoption of civil asset forfeiture reform across 37 US states (2014-2020), using 13 never-reformed states as controls.

**Treatment definition:** Multi-dimensional:
- **Binary:** Any reform vs. no reform (primary)
- **Ordinal intensity:** 0 = no reform, 1 = reporting requirements only, 2 = conviction requirement, 3 = full abolition. This creates a dose-response test.
- **Timing groups:** States grouped by reform year for CS-DiD

**Key identification assumptions:**
1. Parallel trends in arrest composition absent reform (testable with 10+ pre-treatment years)
2. No anticipation — reforms are legislative, with known effective dates
3. SUTVA — no cross-state spillovers in policing (testable: border counties)

## Expected Effects and Mechanisms

**Primary hypothesis (reallocation):** Removing forfeiture revenue incentive reduces drug enforcement effort, freeing resources for other crime types.

- Drug arrest share of total arrests: **negative** (main effect)
- Violent crime arrest share: **positive** (reallocation channel)
- Property crime clearance rates: **positive** (welfare-relevant)
- Total crime rates: **ambiguous** (substitution vs. level effects)

**Mechanism:** Forfeiture creates a direct revenue stream from drug enforcement (seized cash, vehicles, property). Removing this incentive changes the relative return to drug enforcement vs. other enforcement. Police are budget-maximizing bureaucracies (Niskanen 1971; Finan, Olken, Pande 2017).

**Heterogeneity predictions:**
- Larger reallocation in states with higher pre-reform forfeiture dependence
- Larger effects in agencies with tighter budgets (smaller fiscal slack)
- Stronger for abolition than conviction requirement (dose-response)

## Primary Specification

$$Y_{st} = \sum_{g} \sum_{t} ATT(g,t) \cdot \mathbf{1}[G_s = g] + \alpha_s + \gamma_t + \varepsilon_{st}$$

where $Y_{st}$ is the drug arrest share (or violent arrest share, clearance rate) in state $s$ at time $t$, $G_s$ is the reform year for state $s$, and $ATT(g,t)$ is the group-time average treatment effect estimated via Callaway & Sant'Anna (2021).

**Unit of observation:** State × year (primary) and agency × year (robustness)
**Sample period:** 2004-2020 (pre-NIBRS)
**Clustering:** State level (primary), wild bootstrap with 37+ clusters

## Planned Robustness Checks

1. **Event-study plots** with 5+ pre-treatment leads for visual parallel trends
2. **Rambachan & Roth (2023)** sensitivity analysis for pre-trend violations
3. **Sun & Abraham (2021)** interaction-weighted estimator as alternative
4. **Randomization inference** — permute reform timing across states
5. **Dose-response** — abolition vs. conviction requirement vs. reporting only
6. **Heterogeneity by pre-reform forfeiture reliance** (IJ revenue data)
7. **Border-county analysis** — neighboring counties across state lines
8. **Leave-one-state-out** jackknife for influential observations
9. **Balanced panel** — restrict to agencies reporting all 17 years
10. **Placebo outcomes** — non-crime administrative metrics (traffic stops, DUI arrests) that should not respond to forfeiture incentives

## Exposure Alignment (DiD Required Section)

**Who is actually treated?** Police departments in states that pass forfeiture reform legislation. Treatment removes or restricts the financial incentive to pursue asset-generating enforcement (primarily drug crimes).

**Primary estimand population:** All law enforcement agencies in reformed states, weighted by population served.

**Placebo/control population:**
1. Never-reformed states (13 states, primary control)
2. Not-yet-treated states (CS-DiD handles this automatically)
3. Within-state placebo: non-drug, non-property enforcement (e.g., DUI, traffic) that should not respond to forfeiture incentive changes

**Design:** Staggered DiD with CS-DiD estimator. Single treatment dimension (reform year) with ordinal intensity (reform type).

## Power Assessment

- **Pre-treatment periods:** 10+ years (2004-2014 for early reformers)
- **Treated clusters:** 37 states (well above 20-state threshold)
- **Post-treatment periods:** 1-6 years depending on cohort (2015-2020)
- **Within-state variation:** ~18,000 agencies provide micro-level variation
- **MDE assessment:** With 50 state-years and drug arrest shares ~25% of total, standard DiD power calculations suggest MDE of ~2-3 percentage points (8-12% of mean), which is well below the ~37% effect found by Kantor et al. (2021) for the 1984 expansion.

## Data Sources

1. **Arrests:** Jacob Kaplan's UCR ASR concatenated files (ICPSR 102263), 2004-2020, agency-level
2. **Offenses/Clearances:** Kaplan's UCR Return A files (ICPSR 100707), 2004-2020, agency-level
3. **Treatment coding:** Institute for Justice reform database + legislative research
4. **Mechanism/intensity:** IJ Policing for Profit forfeiture revenue data (National_Revenue.csv)
5. **Agency characteristics:** LEMAS (Law Enforcement Management and Administrative Statistics) for agency size, budget
