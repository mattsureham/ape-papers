# Research Plan: Is Tax Capitalization Reversible? Evidence from the SALT Cap and Its Reversal

## Research Question
Does the capitalization of tax subsidies into housing prices exhibit symmetric reversibility, or do sorting, search frictions, and anchoring create a one-way ratchet? We exploit the 2018 TCJA cap on the SALT deduction ($10K limit) and the 2025 OBBB reversal ($40K limit) as symmetric shocks to the same zip codes, testing whether housing values recover as quickly as they decline.

## Identification Strategy
**Continuous-treatment DiD.** Treatment intensity = pre-reform (2017) average SALT deduction per itemizing return at the zip-code level. Zip codes where itemizers claimed $30K+ in SALT faced far greater loss of tax benefit than zips where average SALT was $5K.

**Main specification:**
log(ZHVI)_{z,t} = α_z + γ_t + β₁ × (PostTCJA_t × SALTExposure_z) + Controls + ε_{z,t}

**Reversal specification:**
log(ZHVI)_{z,t} = α_z + γ_t + β₂ × (PostOBBB_t × SALTExposure_z) + Controls + ε_{z,t}

**Symmetry test:** H₀: β₁ = -β₂ (full reversibility). Rejection indicates asymmetric capitalization.

**Key identifying assumption:** Parallel trends in housing prices across zip codes with different SALT exposure, conditional on controls and metro × year FE. Testable with 6+ pre-TCJA years (2012-2017).

## Expected Effects and Mechanisms
- **TCJA cap (2018):** Negative effect on high-SALT zip house prices. Magnitude: 2-5% relative decline for top-quartile exposure.
- **OBBB reversal (2025):** Positive effect, but potentially smaller due to sorting lock-in (high-income residents already left) and anchoring effects.
- **Mechanism channels:**
  1. After-tax cost of housing: Direct user cost channel (Poterba 1984)
  2. Sorting/migration: High-income households leave high-tax areas (IRS SOI flows)
  3. Supply response: Potential construction slowdown in affected markets

## Primary Specification
- **Unit:** Zip code × month
- **Outcome:** log(Zillow ZHVI)
- **Treatment:** Continuous: avg SALT deduction per itemizer (2017 IRS SOI)
- **Fixed effects:** Zip code + month (baseline); metro × month (preferred)
- **Clustering:** State level (treatment assignment correlated within states)
- **Sample:** ~26,300 zips, Jan 2012 - Jan 2026

## Data Sources
1. **Zillow ZHVI** (zip, monthly, 2000-2026) — primary outcome
2. **IRS SOI zip-code income data** (2017) — treatment intensity (A18500/N18500)
3. **FHFA zip-code HPI** (annual, 1984-2024) — robustness outcome
4. **ACS 5-year zip-level** — demographic controls (median income, education, homeownership rate)

## Tables (5 max)
1. **Summary statistics** — zip-code characteristics by SALT exposure quartile
2. **Main results** — continuous-treatment DiD for TCJA cap effect
3. **Event study** — dynamic treatment effects (pre-trend validation)
4. **OBBB reversal and symmetry test** — short-run reversal effects
5. **Robustness** — metro×month FE, placebo on low-SALT zips, dose-response bins
