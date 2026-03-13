# Research Plan: The Symmetric Tax Shock

## Research Question
Does housing capitalization of tax subsidies exhibit symmetric reversibility? Specifically, did the 2018 TCJA SALT deduction cap ($10K limit) reduce house prices in high-SALT zip codes, and did the 2025 OBBB reversal ($40K cap) restore them — or do capitalization effects exhibit hysteresis?

## Identification Strategy
**Continuous-treatment DiD** at the zip-code × month level. Treatment intensity = pre-reform (2017) average SALT deduction per itemizing return from IRS SOI data.

**Specification:**
Y_{z,t} = α_z + γ_t + β × Post_t × SALTExposure_z + X'δ + ε_{z,t}

where Y is log(ZHVI), α_z is zip FE, γ_t is month FE. Standard errors clustered at state level.

**Two shocks:**
1. TCJA cap (Jan 2018): High-SALT zips lose subsidy → prices should fall relative to low-SALT zips
2. OBBB reversal (Jul 2025, retroactive to Jan 2025): High-SALT zips regain subsidy → prices should recover

**Symmetry test:** H0: |β_cap| = |β_uncap|. Rejection implies asymmetric capitalization (hysteresis from household sorting lock-in).

## Expected Effects and Mechanisms
- **Tax capitalization**: Standard prediction is β < 0 for TCJA (higher user cost → lower prices) and β > 0 for OBBB
- **Migration channel**: SALT cap may induce out-migration from high-tax states, amplifying price effects. Test with IRS SOI migration data.
- **Asymmetry**: If households sorted permanently during the cap period, the reversal may produce smaller effects (hysteresis)
- **Within-metro variation**: Key for identification — metro × time FE isolate within-metro SALT variation from metro-level trends

## Primary Specification
1. Full panel: zip × month, 2014-2026, zip FE + month FE, clustered at state
2. Within-metro: add CBSA × month FE (strongest spec)
3. Binary treatment: above/below $10K SALT threshold
4. Dose-response: quintile indicators × Post

## Data Sources
1. **Zillow ZHVI** (zip-code monthly, 2000-2026): ~26,300 zips, CSV download
2. **IRS SOI** (zip-code income, 2017): SALT deduction amounts (A18500, N18500), ~27,660 zips
3. **FHFA HPI** (zip-code annual, 1984-2024): Repeat-sales index for robustness
4. **IRS SOI Migration** (county-to-county flows, 2011-2022): For migration mechanism

## Table Plan (V1: ≤5 tables, zero figures)
1. **Table 1**: Summary statistics by SALT exposure quintile
2. **Table 2**: Main DiD results — TCJA cap effect on log(ZHVI)
3. **Table 3**: OBBB reversal + symmetry test
4. **Table 4**: Mechanism tests (within-metro, migration, housing quantity)
5. **Table 5**: Robustness (alternative treatment, FHFA outcomes, placebo)

## Risks and Mitigation
- **Parallel trends**: High-SALT zips are high-cost metros with possibly different trends → use CBSA × month FE
- **COVID contamination**: COVID shock (2020-2021) affects all housing markets → include COVID controls, test with pre-COVID subsample
- **Anticipation**: TCJA debated throughout 2017 → test with announcement date (Nov 2017) vs effective date
- **OBBB short post-period**: Only ~8 months post-reversal → preliminary result, interpret cautiously
