# Research Plan: When the Window Closes — Post Office Hours Reductions and Rural Business Formation

## Research Question
Did the 2012-2015 USPS POStPlan — which cut operating hours at 13,387 rural post offices from 8 hours to 2, 4, or 6 hours based on workload scores — reduce business formation in affected rural counties?

## Identification Strategy
**Continuous treatment DiD with dose-response.** Treatment intensity = share of county post offices receiving POStPlan hour reductions, weighted by severity (hours lost per PO). The AWEL (Adjusted Workload Earned Load) score determined assignment to 2, 4, or 6-hour schedules — creating quasi-random dose variation conditional on observable post office characteristics.

**Key design features:**
1. **Dose-response monotonicity:** If the mechanism is real, 2-hour POs (6 hours lost) should show larger effects than 6-hour POs (2 hours lost). This is built-in internal replication.
2. **Pre-trend validation:** 7 years of pre-treatment BFS data (2005-2011) to test parallel trends.
3. **Callaway-Sant'Anna estimator** for staggered timing (Sep 2012 - Feb 2015 rollout).
4. **Placebo outcomes:** Urban counties (no treated POs), manufacturing employment (not postal-dependent).

## Expected Effects and Mechanisms
**Primary mechanism:** Rural post offices serve as critical business infrastructure — PO boxes for business registration, money order services for unbanked entrepreneurs, identity verification, certified mail for legal/regulatory compliance. When hours are cut from 8 to 2, businesses face higher transaction costs.

**Expected direction:** Negative effect on business applications, larger for high-dose (2-hour) reductions. Heterogeneity by: broadband penetration (digital substitution), bank branch density (financial alternatives), rural isolation.

**Magnitude prior:** A 6-hour reduction (75% cut) in a county with high PO concentration might reduce business applications by 3-8%. This is a moderate effect given the severity of the access reduction.

## Primary Specification
```
BA_ct = α + β × POStPlan_Dose_ct + γ_c + δ_t + X_ct'θ + ε_ct
```
- BA_ct: business applications in county c, year t (Census BFS)
- POStPlan_Dose_ct: county-level treatment intensity (avg hours lost per PO × share treated)
- γ_c: county fixed effects
- δ_t: year fixed effects
- X_ct: time-varying controls (population, broadband, bank branches)
- Cluster SEs at state level (~50 clusters)

## Data Sources
1. **POStPlan treatment data:** Google Sheet with 35,941 POs, treatment assignment, hours. Need to download and merge with county FIPS.
2. **Census Business Formation Statistics (BFS):** County-level annual business applications, 2005-2024. From Census API.
3. **FDIC Summary of Deposits:** Bank branch counts at ZIP/county level (mechanism).
4. **ACS:** County broadband subscriptions, population (controls).
5. **NOAA/weather:** Not needed for this paper.

## Risks and Mitigations
- **Selection into treatment:** AWEL scores correlate with PO size/activity. Mitigation: control for pre-treatment PO volume, show balance on county characteristics.
- **Rural decline trend:** Treated counties may already be declining. Mitigation: 7 pre-periods + event study showing flat pre-trends.
- **Spillovers:** Businesses might shift to nearby non-treated POs. Mitigation: test for geographic spillover patterns; this would attenuate estimates (conservative bias).
- **COVID:** Treatment is 2012-2015; main post-period is 2013-2019 (pre-COVID). Robustness: restrict to 2005-2019.
