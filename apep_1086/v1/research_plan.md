# Research Plan: The Deregulation Rebound

## Research Question

When counties transition from Clean Air Act nonattainment to attainment status, does the removal of regulatory stringency lead to a rebound in manufacturing activity and toxic emissions? Does the distributional incidence of deregulation differ across communities?

## Identification Strategy

**Staggered difference-in-differences** exploiting the timing of EPA redesignation decisions. Under the CAA, counties designated as nonattainment for criteria pollutants (PM2.5, O3, SO2, NO2, CO, Pb) face elevated regulatory burdens: New Source Review for new/modified facilities, Reasonably Available Control Technology (RACT) requirements, and emission offset mandates. When ambient concentrations improve sufficiently, EPA redesignates counties to attainment/maintenance status, relaxing these burdens.

The EPA Green Book documents 1,561 county-pollutant redesignation events from 1993 to 2025, with major waves in 1995-97, 2005-07, and 2011-16. Treatment is the redesignation date for each county-pollutant pair. Control counties are those that remain in nonattainment or were never designated nonattainment during the same period.

**Estimator:** Callaway and Sant'Anna (2021) with not-yet-treated and never-treated counties as controls. Event-study specification with 5 pre-periods and 5 post-periods (annual).

**Key threats:**
- Selection: counties that achieve attainment may be on different trajectories. Pre-trends test addresses this.
- Simultaneous shocks: redesignation often occurs during economic cycles. Year FEs and never-treated controls absorb this.
- Heterogeneous treatment effects: different pollutants and time periods may have different effects. CS estimator handles this.

## Expected Effects and Mechanisms

**Primary hypothesis:** Redesignation to attainment leads to:
1. **Manufacturing employment increase** (3-5 years post): relaxed NSR allows new facility construction and expansion
2. **Toxic releases increase** (1-3 years post): relaxed RACT requirements and reduced monitoring pressure

**Mechanism:** The regulatory "shadow" of nonattainment deters investment. Removal of this shadow should attract manufacturing, but the environmental consequences depend on whether firms internalize pollution control or only comply under regulatory threat.

**Null hypothesis:** If pollution control technology has been permanently adopted, redesignation may have no environmental rebound even as economic activity increases — a "ratchet effect."

## Primary Specification

```
Y_{c,t} = α_c + γ_t + β × 1[Redesignated]_{c,t} + ε_{c,t}
```

Where Y is: (1) log manufacturing employment from QWI, (2) ambient PM2.5 concentration from AQS. County and year fixed effects. Standard errors clustered at county level.

## Exposure Alignment

Treatment operates at the county level: when a county exits nonattainment, New Source Review requirements, RACT mandates, and emission offset obligations are relaxed for **all manufacturing facilities** in the county. The affected population is the full manufacturing sector (NAICS 31-33) in the county. Outcome measurement matches: QWI manufacturing employment is measured at the county-industry-quarter level, and AQS monitors capture ambient air quality at the county level. Treatment timing is sharp (EPA redesignation date), though counties enter a 20-year maintenance period with less stringent but continued obligations.

## Data Sources

1. **EPA Green Book** (treatment): County-pollutant designations and redesignation dates. XLS file from EPA website (~1.1 MB).
2. **TRI** (environmental outcome): Facility-level toxic releases aggregated to county-year. Annual CSV from EPA (~62 MB for national data).
3. **QWI** (economic outcome): County-quarter manufacturing employment (NAICS 31-33) by demographics. Census API, no key required.
4. **Census ACS** (controls): County-level demographics, income, population. Census API.

## Fetch Strategy

1. Download EPA Green Book XLS directly
2. Download TRI basic data files (national, 2000-2023)
3. Query QWI API for manufacturing employment (NAICS 31-33) at county level, 2000-2023
4. Query Census ACS for county demographics

All sources are public, no credentials needed beyond configured Census API key.
