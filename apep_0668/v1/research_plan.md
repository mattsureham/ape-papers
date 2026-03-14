# Research Plan: The Pollinator Penalty

## Research Question
Does the EU's 2018 outdoor neonicotinoid ban reduce crop yields, and does the yield cost vary systematically by pollinator dependence? Do emergency derogations reveal whether the dominant channel is pest protection loss or pollinator recovery?

## Identification Strategy
**Triple-difference (DDD):** Country × Crop × Time panel with three sources of variation:

1. **Time:** Pre-ban (2000-2018) vs. post-ban (2019-2023)
2. **Pollinator dependence:** Continuous PDR from Klein et al. (2007). Wheat/barley/maize (PDR=0) vs. rapeseed (0.25) vs. sunflower/cucumber/apple (0.65)
3. **Emergency derogations:** 11 countries (AT, BE, HR, DK, ES, FI, FR, LT, PL, RO, SK) granted Article 53 derogations for sugar beet 2019-2022 vs. 14-16 countries that did not

**Main specification:**
```
log(Yield_{ckt}) = β₁ Post_t × PDR_k × Derog_c
                 + αck + αkt + αct + ε_{ckt}
```
- Fixed effects: country×crop (αck), crop×year (αkt), country×year (αct)
- These absorb all two-way interactions; only the triple interaction β₁ remains
- SEs clustered at country level

**Interpretation:**
- β₁ captures: the differential yield change for pollinator-dependent crops in derogation vs non-derogation countries after the ban
- If neonicotinoids primarily work through pest protection: β₁ ambiguous (derogations maintain pest protection across all crops, not differentially for high-PDR)
- If neonicotinoids primarily harm pollinators: β₁ < 0 (derogation countries continued to harm pollinators, so high-PDR crops didn't recover)

**Alternative spec (main DD):**
```
log(Yield_{ckt}) = γ₁ Post_t × PDR_k + αck + αct + ε_{ckt}
```
This tests whether the ban differentially affected high-PDR crops across ALL countries (pollinator recovery channel).

## Expected Effects and Mechanisms
1. **Pest protection channel:** Ban removes insecticide protection → yield decline for all crops (especially sugar beet, rapeseed where neonicotinoids were widely used as seed treatments)
2. **Pollinator recovery channel:** Ban restores pollinator populations → yield INCREASE for high-PDR crops (rapeseed, sunflower, fruits)
3. **Net effect ambiguous for high-PDR crops:** The two channels work in opposite directions
4. **Clear negative for zero-PDR crops:** Only pest protection loss, no pollinator offset

## Primary Specification
- **Unit:** Country × crop × year (c,k,t)
- **Outcome:** log(yield in tonnes/ha)
- **Treatment:** Post2018 × PDR × Derogation (DDD); Post2018 × PDR (DD)
- **FE:** Country×crop, crop×year, country×year
- **Clustering:** Country level
- **Estimator:** OLS with three-way FE (fixest::feols)

## Data Source and Fetch Strategy
1. **Crop yields:** Eurostat `apro_cpsh1` (crop production in EU standard humidity). Country × crop × year. ~25 countries, ~20 crops, 2000-2023.
2. **Pollinator dependence:** Klein et al. (2007) classification. Hard-coded from published scientific paper (Nature Reviews).
3. **Derogation status:** Hand-coded from EFSA emergency authorization database and EC records. 11 countries identified in the idea manifest.
4. **Substitution outcome:** Eurostat `aei_fm_salpest09` (pesticide sales). Tests whether pyrethroid substitution occurred.

## Built-in Placebos
1. **Pre-ban event study:** Leads of the DDD interaction should be zero for 2010-2018
2. **Wind-pollinated crops:** No PDR gradient should appear when restricting to PDR=0 crops
3. **Post-ECJ reversal (2023+):** After derogations end, the derogation advantage should disappear
4. **Sugar beet subsample:** Derogation countries should show distinctly different trends for sugar beet specifically
