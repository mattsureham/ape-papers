# Research Plan: The Safe Country Lottery

## Research Question
Do EU member states' safe country of origin (SCO) designations causally reduce asylum recognition rates, deter new applications, or merely redirect flows to non-designating neighbors?

## Identification Strategy
**Triple Difference-in-Differences (DDD)**

Treatment: Member state *j* adds origin country *c* to its safe country list at time *t*.

- **Diff 1 (time):** Recognition rate for citizenship *c* in country *j*, pre vs. post designation
- **Diff 2 (cross-destination):** Compare with citizenship *c* in country *k* that did not designate *c* as safe
- **Diff 3 (cross-citizenship):** Compare with citizenship *c'* (never designated safe) in country *j*

This triple-diff eliminates destination-specific shocks (e.g., political climate changes), origin-specific shocks (e.g., conflict escalation), and common time trends.

## Main Specification

$$RecognitionRate_{cjt} = \alpha + \beta \cdot SCO_{cjt} + \gamma_{cj} + \delta_{ct} + \theta_{jt} + \epsilon_{cjt}$$

Where:
- $SCO_{cjt}$ = 1 if destination *j* designates origin *c* as safe at time *t*
- $\gamma_{cj}$ = citizenship × destination fixed effects
- $\delta_{ct}$ = citizenship × year fixed effects
- $\theta_{jt}$ = destination × year fixed effects

**β** captures the within-cell change in recognition rate attributable to safe-country designation, after absorbing all bilateral, origin-time, and destination-time confounds.

## Expected Effects and Mechanisms
1. **Recognition rate decline** (primary): SCO designation creates a presumption of safety, shifting the burden of proof to the applicant → lower recognition rates
2. **Application deterrence**: If potential applicants learn of lower odds, applications may decline
3. **Flow diversion**: Applications may shift to neighboring non-designating states (spatial spillover)
4. **Heterogeneity**: Stronger effects for nationalities with marginal claims (Balkans) vs. those with high baseline recognition (conflict zones)

## Data Sources
1. **Eurostat migr_asydcfsta**: First-instance asylum decisions by citizenship, receiving country, and decision type (2008-2023). Construct recognition rates.
2. **Eurostat migr_asyappctza**: Asylum applications by citizenship and receiving country (2008-2023). For deterrence/diversion analysis.
3. **SCO treatment matrix**: Constructed from AIDA (Asylum Information Database), EUAA reports, and legislative records. Key events:
   - Germany: Albania, Kosovo, Montenegro, Serbia, Bosnia, Ghana, N. Macedonia, Senegal (Oct 2015)
   - France: variable list with frequent changes (Kosovo added/removed 2013-2015)
   - Austria: Balkan states added 2016-2018
   - Netherlands: 32 countries designated (long-standing)

## Robustness
- Event study (leads and lags) for parallel trends validation
- Wild cluster bootstrap (clustering at destination level)
- Leave-one-out (drop each destination)
- Placebo: citizenship × destination pairs where no designation change occurred
- Callaway-Sant'Anna for staggered treatment heterogeneity

## Primary Specification Details
- Unit of observation: citizenship × destination × year
- Dependent variable: recognition rate = (positive decisions) / (total first-instance decisions)
- Sample: 2008-2023, ~15 EU destinations, ~30 citizenships
- Clustering: destination country level (conservative; ~15 clusters → wild bootstrap)
- Minimum cell size: require ≥10 decisions per cell
