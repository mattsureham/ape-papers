# Research Plan: The Measurement Artifact of Crime

## Research Question

Does the transition from the FBI's Summary Reporting System (SRS) to the National Incident-Based Reporting System (NIBRS) mechanically inflate measured crime rates through the elimination of the hierarchy rule? If so, by how much — and what does this mean for the empirical crime literature?

## Background

Since 1930, U.S. law enforcement agencies reported crime through the UCR Summary Reporting System (SRS), which counted only the **most serious offense** per incident (the "hierarchy rule") across 8 Part I categories. Beginning in 1991, the FBI began transitioning agencies to NIBRS, which records **all offenses** per incident across 52 categories with no hierarchy rule. The transition was staggered across 18,000+ agencies over three decades. By 2024, ~76% of agencies report NIBRS.

The hierarchy rule means SRS systematically undercounts crimes: if a robbery and an assault occur in the same incident, SRS counts only the robbery. NIBRS counts both. This creates a mechanical upward shift in measured crime rates at adoption — a pure measurement artifact, not a change in actual criminal behavior.

## Identification Strategy

**Callaway–Sant'Anna (2021) staggered DiD** with heterogeneity-robust ATT estimation.

- **Unit:** Law enforcement agency (ORI) × year
- **Treatment:** First year an agency reports NIBRS data
- **Treated:** ~14,000 agencies across 30+ cohorts (1991–2024)
- **Control:** ~4,000 never-treated agencies still reporting SRS
- **Pre-periods:** 5–20+ years depending on cohort

### Built-in Placebo: Murder

Murder is always the most serious offense in the hierarchy. Removing the hierarchy rule has **zero mechanical effect** on murder counts — a murder incident already reports the murder. A non-zero NIBRS effect on murder would indicate confounding (e.g., coincidental policing changes).

### Mechanism Test: Multi-Offense Incidents

The hierarchy rule's bite is directly observable: NIBRS data records the number of offenses per incident. At adoption, the share of incidents with 2+ recorded offenses should jump discontinuously. This is the smoking gun — it measures the exact channel through which NIBRS inflates crime counts.

## Expected Effects

1. **Property crime rates increase 5–15%** at NIBRS adoption (property offenses most commonly co-occur with higher-hierarchy offenses)
2. **Violent crime rates increase 2–8%** (aggravated assault often subordinated to robbery)
3. **Murder rate: null effect** (placebo — always top of hierarchy)
4. **Multi-offense incident share jumps** from ~0% (by definition in SRS) to 10–20% in NIBRS
5. **Larger effects in small agencies** (fewer complex incidents = larger proportional change when hierarchy removed)

## Primary Specification

```
Y_{it} = α_i + λ_t + β × NIBRS_{it} + ε_{it}
```

Estimated via Callaway–Sant'Anna (2021) group-time ATT with:
- Agency fixed effects (α_i)
- Year fixed effects (λ_t)
- Never-treated agencies as control group
- Clustering at agency level

## Exposure Alignment

The treatment — NIBRS adoption — directly and mechanically affects the measurement of crime in all agencies within the state. Every agency that switches from SRS to NIBRS is affected: the hierarchy rule removal applies uniformly to all incident types. The treated population is the set of criminal incidents reported by agencies under the new system. There is no selection into treatment at the incident level — all incidents reported by NIBRS agencies are subject to the new counting rules. The timing of exposure is precisely the year the state achieves majority NIBRS coverage. Never-treated states either adopted NIBRS before our sample window (and thus have stable measurement throughout) or have not yet adopted (stable SRS measurement throughout).

## Data Sources

1. **FBI Crime Data Explorer API** (`api.usa.gov/crime/fbi/`): Agency-level offense counts by year, agency characteristics
2. **FBI NIBRS participation files**: Which agencies report NIBRS vs SRS by year
3. **Census Bureau population estimates**: Denominators for crime rates
4. **BJS NIBRS API** (`api.ojp.gov`): National-level NIBRS estimates (supplementary)

## Robustness

- Event study plots showing pre-trend dynamics
- HonestDiD sensitivity analysis (Rambachan–Roth 2023)
- Leave-one-state-out stability
- Small vs. large agency heterogeneity
- Callaway–Sant'Anna with varying base periods
- Wild cluster bootstrap inference

## Welfare Implication

The measurement artifact is a correction factor for the entire crime literature. Any study comparing crime rates across jurisdictions or time periods that straddle SRS/NIBRS transitions is potentially confounded. The paper provides the first causal estimate of this bias.
