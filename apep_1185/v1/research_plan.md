# Research Plan: The Substitution Trap — Kratom Bans and Opioid Overdose Mortality

## Research Question

Do state-level kratom bans increase opioid overdose mortality by eliminating a harm-reduction substitute? When states classified kratom (mitragynine/7-hydroxymitragynine) as Schedule I, did users substitute toward deadlier opioids — particularly illicit fentanyl?

## Policy Background

Kratom is a plant-based opioid receptor partial agonist used by an estimated 10-15 million Americans, primarily for pain management and opioid withdrawal. Five states banned kratom in staggered fashion during 2014-2017:

| State | Ban Effective Date | Mechanism |
|-------|-------------------|-----------|
| Wisconsin | April 2014 | Schedule I classification |
| Indiana | July 2014 | Synthetic drug analog ban |
| Arkansas | October 2015 | Schedule I via BPC |
| Alabama | May 2016 | Schedule I classification |
| Rhode Island | June 2017 | Schedule I classification |

Meanwhile, 9+ states passed Kratom Consumer Protection Acts (2019-2023) regulating rather than banning. 45 states + DC serve as controls.

## Identification Strategy

**Staggered difference-in-differences** using Callaway and Sant'Anna (2021).

- **Treatment:** State-level kratom ban (binary, month of enactment)
- **Treated units:** 5 states (IN, WI, AR, AL, RI)
- **Control units:** 45 states + DC
- **Time:** Monthly, 2015-2024 (120 months)
- **Estimand:** ATT — effect of kratom prohibition on drug overdose deaths per 100,000

### Key identification assumptions
1. **Parallel trends:** Pre-ban mortality trends in ban states track control states (testable with event study)
2. **No anticipation:** Bans took effect quickly after legislative action; limited scope for anticipatory behavior
3. **SUTVA:** Bans are state-specific; cross-border substitution would attenuate estimates (conservative bias)

### Addressing the 5-state limitation
- Wild cluster bootstrap (Webb 2023) for inference with few treated clusters
- Randomization inference: permute treatment assignment across all 51 jurisdictions
- Explicit power discussion in paper

## Expected Effects and Mechanisms

**Primary hypothesis:** Kratom bans increase total opioid overdose mortality.

**Mechanism — drug-type decomposition:**
- Synthetic opioid deaths (fentanyl proxy) should **increase** — users who lose kratom access may turn to illicit fentanyl
- Natural/semi-synthetic opioid deaths may increase (prescription opioid relapse)
- Heroin deaths may increase (another illicit substitute)
- Psychostimulant deaths (methamphetamine/cocaine) should show **no effect** (negative control — kratom is an opioid substitute, not a stimulant substitute)

This drug-type decomposition is the structural mechanism test. If bans only affect opioid-class deaths and not stimulant deaths, the substitution mechanism is supported.

## Primary Specification

```
Y_{st} = α_s + α_t + β · KratomBan_{st} + ε_{st}
```

Where:
- Y_{st}: drug overdose deaths per 100,000 in state s, month t
- α_s: state fixed effects
- α_t: month fixed effects
- KratomBan_{st}: indicator = 1 after state s bans kratom
- Clustering: state level (51 clusters; wild cluster bootstrap for robustness)

**Callaway-Sant'Anna implementation:**
- Group-time ATTs with never-treated as comparison
- Event-study aggregation for dynamic effects
- Separate estimates by drug type

## Robustness Checks

1. **Event study:** Pre-trend test with 24+ monthly leads
2. **Wild cluster bootstrap:** Webb (2023) 6-point distribution
3. **Randomization inference:** 1000 permutations of treatment assignment
4. **Placebo outcomes:** Psychostimulant deaths, heart disease mortality
5. **Leave-one-out:** Drop each treated state sequentially
6. **Alternative control groups:** Neighboring states only; states that later passed KCPA

## Data Sources

1. **CDC VSRR Provisional Drug Overdose Deaths** (data.cdc.gov/resource/xkb8-kh2a)
   - State-month, 2015-2024
   - Drug-type indicators: opioids, synthetic opioids, natural/semi-synthetic, heroin, psychostimulants
   - No authentication required

2. **CDC WONDER** (for pre-2015 age-adjusted rates, if needed)

3. **Census population estimates** (for rate calculations if raw counts provided)

## Data Fetch Strategy

1. Query CDC VSRR API for all states, all months, all drug types
2. Validate: confirm all 5 ban states present with complete time series
3. Construct treatment indicators from known ban dates
4. Calculate per-capita rates using population denominators
