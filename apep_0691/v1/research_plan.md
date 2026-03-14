# Research Plan: Sugar Tax Without Sticker Shock

## Research Question

Did the UK Soft Drinks Industry Levy (SDIL) improve childhood health outcomes, and did the pre-implementation reformulation channel (2016-2018) account for most of the gains? We exploit cross-Local Authority variation in deprivation — a strong predictor of sugary drink consumption — to estimate the differential health impact on more- vs. less-deprived areas, decomposing announcement (reformulation) from implementation (price) effects.

## Policy Background

- **March 2016:** SDIL announced in Budget. Two-tier structure: 18p/L for >5g sugar per 100ml; 24p/L for >8g per 100ml.
- **April 2018:** SDIL takes effect. By this point, 50% of previously liable products had reformulated below the 5g threshold. Aggregate sugar content in soft drinks fell 46%.
- The tax raised less revenue than projected precisely because reformulation was so effective.

## Identification Strategy

**Continuous treatment intensity DiD.** All English LAs face the same national policy, but the dose varies with baseline deprivation:
- Most-deprived quintile consumes 2.3x more sugary drinks than least-deprived (PHE 2019)
- Treatment intensity = IMD 2019 deprivation score (or rank) for each LA

**Primary specification:**

Y_it = α_i + γ_t + β₁(Post2016_t × Deprivation_i) + β₂(Post2018_t × Deprivation_i) + X_it'δ + ε_it

Where:
- α_i = LA fixed effects
- γ_t = year (wave) fixed effects
- Post2016 = 1 for waves after March 2016 (announcement)
- Post2018 = 1 for waves after April 2018 (implementation)
- β₁ captures the announcement/reformulation effect
- β₂ - β₁ captures the additional implementation/price effect

**Key identification assumption:** Absent the SDIL, health outcomes would have evolved in parallel across deprivation levels (conditional on fixed effects). Testable with pre-trends.

## Expected Effects and Mechanisms

1. **Reformulation channel (β₁):** Expect negative coefficient on dental decay × deprivation interaction post-2016. Reformulation reduced sugar content uniformly, but more-deprived areas had higher baseline consumption, so the absolute sugar reduction was larger.

2. **Price channel (β₂ - β₁):** Potentially smaller if reformulation was the dominant mechanism. The tax applies to products that did NOT reformulate, which are a shrinking share.

3. **Heterogeneity:** Urban vs. rural, North vs. South, quintile-level event study.

## Primary Outcomes

1. **Dental decay prevalence in 5-year-olds** (Fingertips Indicator 93563): Survey-based, LA-level, ~7 waves 2007-2024. The headline outcome — dental caries is the most direct health consequence of sugar consumption in children.

2. **Childhood overweight/obesity, Reception year** (Fingertips Indicator 20601): Annual, LA-level, 2006-2025. The NCMP measure. More observations but less mechanistically direct than dental decay.

## Placebo Outcome

3. **COPD emergency admissions** (Fingertips Indicator 92302): Should NOT respond to sugar tax. Validates that deprivation trends aren't driving results through other channels.

## Data Sources

All from PHE/OHID Fingertips API (https://fingertips.phe.org.uk/api/):
- Dental decay: Indicator 93563, ~300 LAs, survey waves
- Childhood obesity: Indicator 20601 (Reception overweight+obese), ~330 districts, annual
- IMD deprivation: Indicator 93553, district-level IMD 2019 scores
- COPD admissions: Indicator 92302, district-level, annual

## Feasibility

- ~300 English LAs provide sufficient cross-sectional variation
- Pre-announcement period: 3-4 waves (dental), 10 years (obesity)
- Treatment timing is sharp and national (no staggered adoption)
- Deprivation variation is large (IMD scores range 5-45)
- All data freely accessible via Fingertips API

## Design Parameters

- Treated units: ~300 LAs (continuous intensity)
- Pre-periods: ~4 dental waves (2007-2016), ~10 obesity years (2006-2016)
- Treatment timing: Announcement March 2016, Implementation April 2018
- Expected dental observations: ~300 × 7 waves ≈ 2,100
- Expected obesity observations: ~330 × 18 years ≈ 5,940
