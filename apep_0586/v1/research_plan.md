# Initial Research Plan: Winning the Peace

## Research Question
Did WWII military service cause occupational upgrading for American men, or do veterans' better post-war outcomes reflect pre-existing selection? What was the role of the GI Bill in facilitating educational and occupational mobility?

## Key Contribution
First individual-level evidence on WWII military service returns using the universe of 9.1 million draft-age men tracked across three census decades (1930–1940–1950). The 1930 pre-baseline enables genuine pre-trend testing impossible with two-decade designs, and allows us to control for pre-existing individual trajectories.

## Identification Strategy

### Design: State × Cohort IV (Reduced Form)

**Treatment intensity:** State-level WWII mobilization exposure, proxied by the inverse of the state's agricultural employment share among men 18–44 in 1940. Agricultural workers received systematic deferments under the Tydings Amendment, creating cross-state variation in military service rates that is plausibly exogenous to post-war occupational upgrading conditional on state and cohort fixed effects.

**Main specification:**

ΔY_{isc} = α + β₁(MobExposure_s × DraftEligible_c) + δ_s + θ_c + X_{i,pre}γ + ε_{isc}

Where:
- i = individual, s = state of residence (1940), c = birth cohort
- ΔY = change in outcome (occscore, educ, log incwage) from 1940 to 1950
- MobExposure_s = 1 − (agricultural share of male workers 18–44 in state s, 1940), standardized
- DraftEligible_c = indicator for birth cohorts 1915–1922 (age 18–25 in 1940, highest service rates)
- δ_s = state fixed effects, θ_c = birth-year fixed effects
- X_{i,pre} = pre-war individual controls (1940 educ, occscore, marital status, race, nativity)

β₁ is the key parameter: the differential occupational gain for draft-eligible cohorts in high-mobilization (low-agriculture) states.

### Pre-Trend Test (1930 Pre-Baseline — Key Novelty)

Run the identical specification on 1930–1940 outcomes:

ΔY_{isc}^{pre} = α + β₁^{pre}(MobExposure_s × DraftEligible_c) + δ_s + θ_c + X_{i,1930}γ + ε_{isc}

β₁^{pre} should be zero: future mobilization exposure should not predict pre-war occupational changes for the same cohorts.

### Built-In Placebo Groups

1. **Age placebo:** Men born 1895–1904 (age 36–45 in 1940). Low draft probability. Should show no differential effect of mobilization exposure.
2. **Pre-trend placebo:** Identical specification on 1930–1940 outcomes for draft-eligible cohorts. No war yet → β = 0.

### Exclusion Restriction

Agricultural share affects 1940–1950 occupational upgrading for draft-eligible cohorts ONLY through differential military service exposure. Potential threats:
- Agricultural states had different economic structures → state FE absorb time-invariant state differences
- War production was concentrated in manufacturing states → control for 1940 manufacturing share × cohort
- Agricultural mechanization accelerated during WWII → control for farm status in 1940

## Expected Effects and Mechanisms

1. **Occupational upgrading:** Draft-eligible men in high-mobilization states should show larger occscore gains (1940→1950). Military training + GI Bill education enabled transition from low-skill to skilled occupations.
2. **Education channel:** Draft-eligible men in high-mobilization states should show higher education attainment in 1950 (GI Bill college access).
3. **Wage gains:** Higher wages in 1950 reflecting occupational upgrading.
4. **Heterogeneity by pre-war occupation:** Men in low-occscore occupations in 1940 should show the largest gains (most room to upgrade). Men already in high-occscore occupations had less to gain.

## Primary Specification

OLS with state and cohort FE, clustering at the state level (48 clusters). State-level mobilization is the treatment variation → state-clustered SEs are appropriate. Report: wild cluster bootstrap (48 clusters), randomization inference, leave-one-out.

## Planned Robustness Checks

1. **Leave-one-out states:** Drop each state to ensure no single state drives results
2. **Randomization inference:** Permute mobilization exposure across states
3. **Alternative cohort definitions:** Vary the "draft-eligible" window (1910–1922, 1912–1920)
4. **War production controls:** Add state-level war contract spending × cohort
5. **Migration controls:** Control for inter-state migration (mover_40_50)
6. **Race subsamples:** Separate estimates for white and non-white men (MLP linking quality differs by race)
7. **Alternative outcomes:** SEI (socioeconomic index), industry upgrading, homeownership

## Data

- **Individual panel:** `az://derived/mlp_panel/linked_1930_1940_1950.parquet` (41.5M records, 9.1M draft-age men)
- **State-level instrument:** Constructed from 1940 census (agricultural employment share among men 18–44)
- **Outcomes:** occscore_1950, educ_1950, incwage_1950 (all in panel)
- **Pre-treatment baseline:** occscore_1930, occscore_1940 (for pre-trend test)

## Key Literature

- Angrist (1990 AER): Vietnam draft lottery IV for military service returns
- Bound & Turner (2002): GI Bill and college attendance (aggregate)
- Turner & Bound (2003): GI Bill college effects by state (aggregate)
- Collins & Zimran (2025 EEH): WWII service and GI Bill with 1940–1950 linked census (selection on observables, no 1930 pre-baseline)
- Acemoglu, Autor & Lyle (2004 JPE): WWII mobilization rates and female labor supply (source for mobilization instrument)
- Angrist & Krueger (1994): The economic returns to schooling (IV methods)

## Power Assessment

- Draft-eligible cohorts: ~4.5M men (born 1915–1922)
- Control cohorts: ~4.6M men (born 1905–1914)
- State clusters: 48
- Pre-treatment periods: 1 (1930–1940 change)
- Treatment variation: mobilization exposure ranges 0.41–0.54 across states
- Given N > 9M with 48 clusters, even small effects should be detectable
