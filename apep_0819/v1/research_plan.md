# Research Plan: apep_0819/v1

## Research Question

Does media attention to natural disasters affect post-disaster economic recovery in India? When competing global news crowds out coverage of Indian floods, do affected districts recover more slowly — revealing that even rights-based safety nets like MGNREGA are operationally mediated by political salience?

## The Economic Object: The Salience Gap

MGNREGA guarantees 100 days of paid employment to every rural household. In theory, this automatic stabilizer should respond identically to all floods regardless of media attention. In practice, program delivery requires bureaucratic effort — works must be sanctioned, funds released, materials procured. If media coverage creates political pressure that accelerates these processes, then floods occurring during low-salience periods (when competing news dominates the cycle) should see slower recovery. We call this divergence the **salience gap** in automatic stabilizers.

## Identification Strategy: Eisensee-Strömberg IV

Following Eisensee and Strömberg (2007 QJE), we instrument media coverage of Indian floods with the volume of competing global news. The identifying assumption: global events (Olympics, major elections, international crises) shift total news volume and crowd out Indian flood coverage, but do not directly affect Indian district-level economic recovery conditional on flood severity.

### Estimating Equations

**First stage (state-month):**
log(FloodArticles_{s,m}) = α + β × log(CompetingNews_m) + γ × FloodSeverity_{s,m} + δ_s + θ_m + ε

**Second stage (district-year):**
NightlightsGrowth_{d,t+1} = α + β × log(FloodArticles_{s(d),t})_hat + γ × FloodSeverity_{s(d),t} + δ_d + θ_t + ε

**Reduced form (district-year):**
NightlightsGrowth_{d,t+1} = α + β × CompetingNews_{s(d),t} × FloodExposed_{s(d),t} + controls + δ_d + θ_t + ε

## Expected Effects

- First stage: Competing news should negatively predict India flood coverage (β < 0)
- Second stage: Higher media coverage should improve recovery (β > 0 in 2SLS)
- Reduced form: High competing news during flood years → worse recovery in flood districts
- Mechanism: Political alignment should moderate the effect (opposition-ruled states more responsive to media pressure)

## Data Sources

1. **GDELT GKG (BigQuery):** India flood articles and global competing news, state-month, 2015-2021
2. **SHRUG VIIRS nightlights:** District-year, 2012-2021 (local: data/india_shrug/viirs_annual_pc11dist.csv)
3. **SHRUG crosswalk:** District-to-state mapping (local: data/india_shrug/pc11_td_clean_pc11dist.csv)
4. **EM-DAT:** Indian flood events with dates, severity, affected population (emdat.be)
5. **Indian state election data:** From TCPD/ECI for political alignment mechanism test

## Primary Specification

2SLS at district-year level. Cluster SEs at state level (~30 clusters). Include district FE and year FE. Flood exposure defined by state-year flood occurrence (from EM-DAT or GDELT threshold).

## Robustness

1. Placebo: Non-flood years should show no effect of competing news
2. Dose-response: Continuous flood severity interaction
3. Alternative IV: Pre-scheduled events only (Olympics, elections) as instruments
4. Balanced panel sensitivity: Drop districts with missing nightlights
5. Wild cluster bootstrap (small number of state clusters)
