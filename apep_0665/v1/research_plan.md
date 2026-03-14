# Research Plan: Locked In and Levered Up — Italy's Fornero Pension Reform and Regional Capital Deepening

## Research Question

Did Italy's sudden December 2011 Fornero pension reform — which raised retirement ages by up to 5 years overnight — trigger compensatory capital investment in regions where more older workers were forced to stay? We test whether forced labor retention causes capital-labor complementarity or substitution.

## Identification Strategy

**Continuous-treatment DiD at NUTS2 × year level.** Treatment intensity = "Fornero bite" (change in 55-64 employment rate from 2010 to 2014), which varies from +0.2pp (Sicilia) to +15.4pp (Umbria). Reform was sudden (3 weeks from government appointment to law), unexpected, and nationally uniform but differentially binding due to pre-existing regional age structure.

Y_{r,t} = α_r + γ_t + β(FBite_r × Post_t) + ε_{r,t}

## Data Sources (Eurostat REST API, no auth)

1. `lfst_r_lfe2emprt` — Employment rate by age (55-64) by NUTS2 region, by sex
2. `nama_10r_2gfcf` — GFCF by NUTS2 region and NACE sector
3. `rd_e_gerdreg` — R&D expenditure by NUTS2

## Expected Effects

Ambiguous: capital-labor complementarity → more investment; capital-labor substitution → less investment; crowding out of youth → ambiguous.
