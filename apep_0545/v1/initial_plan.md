# Initial Research Plan: The Regulatory Ratchet

## Research Question

Does media salience of safety incidents cause increased federal rulemaking, while media salience of regulatory burden fails to generate deregulation? This paper provides the first cross-sectoral empirical test of the asymmetric regulatory ratchet hypothesis — that democratic regulatory systems are structurally biased toward accumulation because media dynamics amplify incidents but cannot sustain sustained attention to diffuse costs.

## Identification Strategy

### Empirical Design

Two-way fixed effects panel regression at the **agency-quarter** level, 1994-2020:

```
Outcome_{a,t} = α_a + δ_t + β₁·incident_{a,t-1} + β₂·burden_{a,t-1} + γ·X_{a,t} + ε_{a,t}
```

- **a** = agency (12 federal regulatory agencies)
- **t** = quarter (108 quarters, 1994Q1 to 2020Q4)
- **α_a** = agency fixed effects (absorbs time-invariant agency-level factors: size, mandate type, statutory structure)
- **δ_t** = quarter fixed effects (absorbs aggregate political cycles, election years, recessions)
- **β₁** = effect of sector-specific safety incident coverage on rulemaking (expected positive)
- **β₂** = effect of sector-specific regulatory burden coverage on rulemaking (expected near zero or negative)

**Asymmetry test:** F-test of H₀: β₁ = |β₂| (symmetric response) vs. H₁: β₁ > |β₂| (ratchet)

### Competing-News Instrument (Eisensee-Strömberg 2007)

The key threat to identification: agencies facing more incidents may face more regulatory pressure for other reasons (actual underlying risk increases). The IV solves this by exploiting variation in what else is in the news.

**Instrument construction:**
- For each agency-quarter, compute the volume of major non-agency-sector news events (natural disasters, major elections, geopolitical crises, high-profile sports) in the same quarter
- Higher competing-news volume → news space is crowded → less coverage of the agency's incidents (even holding actual incident rates constant)
- **First stage:** competing_news_{t} → incident_coverage_{a,t} (negative coefficient — news competition crowds out)
- **Second stage:** instrumented incident_coverage_{a,t} → rulemaking_{a,t}

**Exclusion restriction:** Competing news events (e.g., a hurricane making landfall in Florida, a presidential election) do not directly affect the rulemaking decisions of the EPA or OSHA except through the salience of media coverage.

### Instrument Construction from GDELT + BigQuery

GDELT `gkg_partitioned` table allows us to:
1. Construct agency-specific incident themes by quarter (using THEMES field)
2. Construct competing news as total GDELT coverage in domains orthogonal to each agency's mandate (cross-sector news volume)
3. The instrument is: log total GDELT events in non-agency domains in quarter t

### Key Heterogeneity Tests

1. **Trump EO 13771 (2017-2020):** Did the one-in/two-out executive mandate change the ratchet? If β₂ becomes significantly negative post-2017, the ratchet is conditional on political commitment. If β₂ ≈ 0 even then, the ratchet is robust to political institutions.

2. **Proposed vs. final rules:** Incident coverage may be strongest on agenda-setting (proposed rules) rather than completion (final rules) — different lags in the political process.

3. **Significant rules:** Economically significant rules (OIRA-reviewed, >$100M annual impact) should show stronger asymmetry — these are the high-stakes actions that media pressure most influences.

4. **Agency characteristics:** High-salience agencies (aviation, food safety, mining) should show stronger first-stage (incidents get more coverage per event) and stronger second-stage effects.

5. **Placebo test:** Cross-sector incident shocks (aviation incidents predicting OSHA rulemaking) should show zero effect — the mechanism requires sector-specific salience.

## Expected Effects and Mechanisms

**Main prediction (β₁ > 0):** Incident coverage increases rulemaking — availability cascade mechanism (Kuran-Sunstein 1999). Salient events create political pressure on regulators and legislators to act.

**Ratchet prediction (β₂ ≈ 0):** Burden coverage does not reduce rulemaking. Deregulation is diffuse and complex; the political costs of removing specific regulations are concentrated (industry beneficiaries of rules resist removal) while the benefits are dispersed. Media can create incident salience but cannot solve the political economy of deregulation.

**Trump counterfactual:** EO 13771 created a formal institutional mechanism to force deregulation. Testing whether this overcomes the ratchet provides a clean test of whether media dynamics are fundamental or merely correlated with political will.

**Magnitude:** Based on estimates from disaster relief (Eisensee-Strömberg) where 1 SD increase in news competition decreases aid probability by 10-20%, expect first-stage reduction in incident coverage of 15-25%. If incident coverage affects rulemaking at similar magnitude, the ratchet could account for a substantial fraction of the regulatory accumulation observed across administrations.

## Primary Specification

**Outcome 1:** log(1 + n_significant_rules_{a,t}) — significant (OIRA-reviewed) rule final actions
**Outcome 2:** log(1 + n_proposed_{a,t}) — proposed rule notices (agenda-setting)
**Outcome 3:** n_significant_{a,t} / agency_baseline (normalized by agency average)

**Preferred specification:** 2SLS with agency and quarter FE, clustering SEs at agency level

## Planned Robustness Checks

1. Alternative outcome: QuantGov regulatory restriction counts from CFR
2. Alternative instrument: Olympic Games months, major election months (non-economic events)
3. Alternative lag structure: t-2, t-3 for incident coverage (regulatory processes have lags)
4. Placebo agencies: cross-sector shocks should not predict rulemaking
5. Placebo periods: pre-information era (if data permits) should show weaker effects
6. Trump EO 13771 interaction (administration × burden coverage)
7. Wild cluster bootstrap SEs (12 clusters is borderline; need robust inference)
8. Callaway-Sant'Anna DiD for Trump-era subset (staggered adoption of EO 13771 waivers)
9. HonestDiD sensitivity analysis for any parallel trends concerns

## Power Assessment

- Panel: 12 agencies × 108 quarters = 1,296 agency-quarter observations
- Cross-sectional clusters: 12 agencies (small — use wild cluster bootstrap + Cameron-Miller)
- For main IV specification: expect first-stage F-stat > 10 if news competition explains 15%+ of incident coverage variation
- MDE for 1,296 obs, agency/quarter FE, R² ≈ 0.6 (from FEs): roughly 0.08 SD effect size
- Significant rule counts (4-121/year range) provide sufficient variation

## Planned Exhibits

**Figure 1:** Time series of rulemaking activity by agency, 1994-2020 (faceted, showing Trump-era deregulation that didn't materialize in significant rule counts)

**Figure 2:** First-stage visualization — competing news crowding out incident coverage (binned scatter with confidence intervals)

**Figure 3:** Main results event study — rulemaking response to incident coverage spikes, with/without IV

**Table 1:** Summary statistics — agency-quarter panel

**Table 2:** Main regression results — OLS and 2SLS, four specifications

**Table 3:** Asymmetry test — β₁ vs. β₂ formal test, with CIs

**Table 4:** Heterogeneity by administration (Trump EO 13771 interaction)

**Table 5:** Robustness — alternative outcomes, lags, instruments

## Data Pipeline

1. **Federal Register API** (`api.federalregister.gov`) → proposed and final rules by agency-quarter
2. **GDELT GKG via BigQuery** (`gdelt-bq.gdeltv2.gkg_partitioned`) → incident and burden coverage counts by agency-sector themes
3. **BLS fatality and injury data** → severity controls (separating media salience from actual risk)
4. **QuantGov RegData** → secondary outcome (CFR restriction counts)

## Timeline and Risk

**Main risks:**
1. First-stage weakness (competing news may not strongly predict sector-specific coverage in quarterly aggregates) → mitigate by using monthly data for first stage, aggregate to quarterly for second stage
2. Agency FE may absorb too much variation → robustness with only year FE
3. 12-cluster inference → wild cluster bootstrap mandatory; Cameron-Miller alternative SEs

**Pivot plan:** If Federal Register API data proves thin for quarterly analysis, aggregate to annual (12 agencies × 27 years = 324 obs) and use OLS with HonestDiD robustness.

## Pre-Registration Statement

This paper pre-registers the following predictions:
1. β₁ > 0: incident coverage increases significant federal rulemaking
2. β₂ ≈ 0: burden coverage does not decrease rulemaking
3. Effect of β₁ stronger for proposed rules than final rules (agenda-setting dominates)
4. Trump EO 13771 period: β₂ potentially negative but β₁ still positive (ratchet survives political commitment)
