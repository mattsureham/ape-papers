# Research Plan: The Enforcement Lottery — Federal vs State Inspector Stringency and Pollution Outcomes

## Research Question

Does federal (EPA) enforcement produce different environmental outcomes than state-delegated enforcement? Under cooperative federalism, states conduct ~85% of environmental inspections, but EPA retains concurrent authority. If federal inspectors are systematically stricter, the delegation of enforcement to states may create an "enforcement discount" — a welfare-relevant gap between the pollution outcomes achievable under federal oversight and those realized under state implementation.

## Identification Strategy

### Core Design: State Review Framework (SRF) as Instrument

EPA's State Review Framework reviews each state's enforcement programs on a 4-5 year rotating cycle. When EPA finds a state program "deficient" in an SRF review, it triggers increased federal inspection activity (including "overfiling" — federal enforcement in areas nominally delegated to the state). The SRF review schedule is driven by EPA's administrative rotation across states, not by individual facility pollution behavior.

**Instrument:** State-year indicators for SRF deficiency findings. A state's SRF review year is determined by the administrative cycle, creating quasi-random temporal variation in federal inspection intensity.

**First stage:** SRF deficiency finding → increased federal inspection share in the state (measured as the proportion of inspections conducted by EPA/federal vs state inspectors).

**Reduced form:** SRF deficiency finding → subsequent facility TRI emissions and compliance outcomes.

**Exclusion restriction:** The SRF review timing affects facility emissions only through changes in enforcement behavior (inspector identity, inspection frequency, penalty stringency), not directly.

### Alternative/complementary approach

Within-facility event study comparing compliance and emission trajectories after federal vs state inspections, with facility fixed effects absorbing time-invariant characteristics and year fixed effects absorbing national trends. This is descriptive but informative about the first stage.

## Expected Effects and Mechanisms

1. **First stage:** Federal inspections should have higher violation finding rates and penalty amounts than state inspections (federal inspectors face different incentives — no revolving door with regulated industry, less political pressure from local firms).

2. **Main effect:** More stringent enforcement (instrumented by federal inspection share) should reduce facility-level TRI releases and improve compliance status.

3. **Mechanism — "regulatory capture channel":** States with more industry lobbying pressure may have weaker enforcement. The federal-state gap should be larger in states with higher industry campaign contributions or weaker environmental agencies.

4. **Heterogeneity:** The enforcement gap may vary by industry (manufacturing vs mining), facility size (large facilities face more scrutiny regardless), and program area (CAA vs CWA vs RCRA).

## Primary Specification

**Unit:** Facility × year panel

**Outcome variables:**
- log(TRI total releases in pounds + 1) — primary
- Significant Noncompliance (SNC) status indicator — secondary
- Number of violations found per inspection — mechanism

**Endogenous variable:** Federal inspection share (proportion of inspections by EPA/federal inspectors in state-year)

**Instrument:** SRF deficiency finding indicator × post-review period

**Fixed effects:** Facility FE + Year FE

**Clustering:** State level (50 clusters)

**Sample:** TRI-reporting facilities (2008-2023), covering SRF Rounds 3-4

## Data Sources and Fetch Strategy

### Primary: EPA ECHO Bulk Downloads
1. **ECHO Exporter** — facility-level summary data (1.5M+ facilities, inspection counts, violations, TRI linkages)
   - URL: https://echo.epa.gov/files/echodownloads/echo_exporter.zip
   - Fields: facility ID, state, NAICS, inspection counts by agency, TRI releases, SNC status

2. **ICIS-FE&C** — detailed inspection records with agency type
   - URL: https://echo.epa.gov/tools/data-downloads/icis-fec-download-summary
   - Key field: COMP_MONITOR_AGENCY_TYPES (State / U.S. EPA / Regional)
   - Individual inspection records with dates

3. **TRI Basic Data Files** — facility-year emissions
   - URL: https://www.epa.gov/toxics-release-inventory-tri-program/tri-basic-data-files-calendar-years-1987-present
   - Annual facility-level chemical releases (air, water, land)

### Secondary: SRF Review Data
4. **SRF Results** — state-program-year review outcomes
   - URL: https://www.epa.gov/compliance/state-review-framework-results-table
   - Manual coding from EPA state reports for deficiency findings by program area and round

## Key Risks

1. **SRF instrument strength:** If SRF deficiency findings don't meaningfully change federal inspection behavior, the first stage will be weak. Mitigation: test F-statistics, report effective F.
2. **Exclusion restriction:** SRF reviews might directly affect state enforcement behavior (state "shapes up" independently). This would bias results toward zero — finding effects despite this bias strengthens the case.
3. **Sample selection:** TRI-reporting facilities are larger and already more regulated. Results may not generalize to smaller facilities.
4. **Data size:** ECHO Exporter is 392MB compressed. Manageable with 16GB RAM using data.table.
