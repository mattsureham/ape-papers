# Research Plan: Fiber to the Home, Polarization, and the Demand for Unreliable Information

## Research Question

Does the expansion of high-speed broadband infrastructure (FTTH) cause changes in political polarization and the demand for unreliable information? The ex ante sign is ambiguous: better connectivity can reduce misinformation (improved access to quality sources) or increase it (expanded exposure to low-quality content). Either direction is informative.

## Identification Strategy

**Primary design:** Staggered difference-in-differences (Callaway-Sant'Anna) exploiting within-department variation in FTTH coverage over time. France's Plan France Tres Haut Debit created deployment zones (zones tres denses, AMII, RIP) with institutionally determined rollout timing. Within comparable zones, the timing of fiber deployment is driven by operator capacity and infrastructure readiness, not local political demand.

**Unit of analysis:** 96 metropolitan departments x quarters (2013 Q1 - 2024 Q4), yielding ~4,608 department-quarter observations.

**Treatment definitions:**
- (a) Continuous: FTTH coverage rate (share of premises eligible)
- (b) Binary threshold crossings: departments crossing 25%, 50%, 75% coverage
- (c) Complementary: entry into copper-closure lot (lot-level timing from ARCEP)

**Key identification assumptions:**
1. Parallel trends in political outcomes across departments with different FTTH rollout timing, conditional on deployment zone type
2. No anticipation effects (political outcomes don't respond before FTTH becomes available)
3. Rollout timing within comparable zones is uncorrelated with time-varying political shocks

**Plausibility tests:**
- Event-study with flexible pre-trend diagnostics (unconditional and conditional on zone type)
- Balance test: baseline political variables do not predict rollout timing within zone
- HonestDiD sensitivity analysis for parallel trends violations

## Expected Effects and Mechanisms

**Ambiguous ex ante.** Two channels:
1. **Information access channel (-):** FTTH enables access to high-quality news, fact-checking, institutional sources → reduces support for anti-system parties
2. **Information pollution channel (+):** FTTH enables exposure to social media, conspiracy content, attention-grabbing narratives → increases support for anti-system parties

**Heterogeneity predictions (mechanism tests):**
- Effects should be larger in rural departments (where online media substitutes for sparse offline sources)
- Effects should be larger where baseline far-right/far-left vote share is higher (pre-existing demand for polarized content)
- Effects should be larger in departments with fewer newsstand/press outlets (information desert hypothesis)

## Primary Specification

$$Y_{dt} = \alpha_d + \gamma_t + \beta \cdot FTTH_{dt} + X_{dt}'\delta + \varepsilon_{dt}$$

Where:
- $Y_{dt}$: anti-system party vote share (RN + LFI, as % of registered voters) in department $d$, election round closest to quarter $t$
- $\alpha_d$: department fixed effects
- $\gamma_t$: quarter fixed effects
- $FTTH_{dt}$: FTTH coverage rate in department $d$, quarter $t$
- $X_{dt}$: time-varying controls (population, unemployment rate, zone-type × time trends)

**Primary estimator:** Callaway-Sant'Anna (2021) with not-yet-treated as comparison group.

**Primary outcome:** Anti-system party vote share (RN + LFI combined, % of registered).

**Secondary outcomes:** Turnout, blank/null votes, effective number of parties (Laakso-Taagepera index), GDELT misinformation-theme article counts (exploratory).

## Planned Robustness Checks

1. Alternative treatment definitions (continuous, thresholds, copper-closure timing)
2. Zone-type × time fixed effects (absorb zone-level trends)
3. Sun-Abraham estimator as alternative to Callaway-Sant'Anna
4. TWFE comparison (show potential bias)
5. Randomization inference (permute treatment timing within zones)
6. HonestDiD bounds for parallel trends sensitivity
7. Leave-one-department-out jackknife
8. Pensioner vote share placebo (low internet adoption → should not respond)
9. Pre-FTTH DSL rollout period as historical placebo
10. Bonferroni/BH corrections for secondary outcome family

## Exposure Alignment (DiD Required)

- **Who is treated:** Residents of departments receiving FTTH infrastructure
- **Primary estimand population:** Voters in metropolitan France departments
- **Placebo population:** Pensioners (lower broadband adoption), pre-FTTH DSL period
- **Design:** Staggered DiD with continuous treatment intensity

## Power Assessment

- 96 metropolitan departments
- ~48 quarters (2013 Q1 - 2024 Q4)
- Treatment varies continuously across departments and time
- Elections: ~6 election rounds (Presidential 2017, 2022; European 2014, 2019, 2024; Legislative 2017, 2022)
- Department-level clustering → 96 clusters (well above 30 threshold for CRSE)
- Anti-system vote share has substantial cross-department variation (~15-45% range)
- Expected MDE with 96 clusters: ~2-3 percentage points (adequate for policy relevance)

## Data Sources

| Source | Access | Granularity | Period |
|--------|--------|-------------|--------|
| ARCEP FTTH deployment | data.gouv.fr (open) | Department × quarter | 2013-2024 |
| Election results | data.gouv.fr (open) | Commune → department | 2012-2024 |
| GDELT GKG | BigQuery/bulk (open) | Lat/lon → department | 2015-2024 |
| Copper closure lots | ARCEP (open) | Commune → department | 2022-2026 |
| INSEE population | BDM/SDMX (open) | Department × year | 2012-2024 |
| INSEE unemployment | BDM/SDMX (open) | Department × quarter | 2012-2024 |
