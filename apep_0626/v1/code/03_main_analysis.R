## ============================================================================
## 03_main_analysis.R — Main Regressions for apep_0626
## ============================================================================

source("code/00_packages.R")

data_dir <- "data"
tables_dir <- "tables"

cat("=== Loading cleaned data ===\n")
dt <- readRDS(file.path(data_dir, "clean_1920_1930.rds"))
cat(sprintf("N = %s\n", format(nrow(dt), big.mark = ",")))

## --------------------------------------------------------------------------
## 1. Main specification: ΔOccScore ~ QuotaExposure + controls
## --------------------------------------------------------------------------

cat("\n=== Main regressions ===\n")

## Create state FE variable
dt[, state_fe := as.factor(statefip_1920)]

## (1) Bivariate: no controls
m1 <- feols(delta_occscore ~ quota_exposure,
            data = dt, lean = TRUE,
            cluster = ~statefip_1920 + countyicp_1920)

## (2) Add state FE
m2 <- feols(delta_occscore ~ quota_exposure | statefip_1920,
            data = dt, lean = TRUE,
            cluster = ~statefip_1920 + countyicp_1920)

## (3) Add individual controls
m3 <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
              literate + urban + log_pop | statefip_1920,
            data = dt, lean = TRUE,
            cluster = ~statefip_1920 + countyicp_1920)

## (4) Add initial occupation FE (absorbs selection into occupations)
m4 <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
              literate + urban + log_pop | statefip_1920 + occ1950_1920,
            data = dt, lean = TRUE,
            cluster = ~statefip_1920 + countyicp_1920)

## (5) Broad exposure measure (includes more origin countries)
m5 <- feols(delta_occscore ~ quota_exposure_broad + age_1920 + I(age_1920^2) +
              literate + urban + log_pop | statefip_1920 + occ1950_1920,
            data = dt, lean = TRUE,
            cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- Main results ---\n")
etable(m1, m2, m3, m4, m5)

## Save main models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
        file.path(data_dir, "main_models.rds"))

## --------------------------------------------------------------------------
## 2. Alternative outcomes
## --------------------------------------------------------------------------

cat("\n=== Alternative outcomes ===\n")

## Binary upgrading
m_upgrade <- feols(upgraded ~ quota_exposure + age_1920 + I(age_1920^2) +
                     literate + urban + log_pop | statefip_1920 + occ1950_1920,
                   data = dt, lean = TRUE,
                   cluster = ~statefip_1920 + countyicp_1920)

## Farm exit (among farmers)
dt_farm <- dt[farm_1920 == 2]
m_farm_exit <- feols(farm_exit ~ quota_exposure + age_1920 + I(age_1920^2) +
                       literate + log_pop | statefip_1920,
                     data = dt_farm, lean = TRUE,
                     cluster = ~statefip_1920 + countyicp_1920)

## Geographic mobility
m_moved <- feols(moved ~ quota_exposure + age_1920 + I(age_1920^2) +
                   literate + urban + log_pop | statefip_1920 + occ1950_1920,
                 data = dt, lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

## SEI change
m_sei <- feols(delta_sei ~ quota_exposure + age_1920 + I(age_1920^2) +
                 literate + urban + log_pop | statefip_1920 + occ1950_1920,
               data = dt, lean = TRUE,
               cluster = ~statefip_1920 + countyicp_1920)

## Homeownership
m_owner <- feols(became_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                   literate + urban + log_pop | statefip_1920 + occ1950_1920,
                 data = dt, lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- Alternative outcomes ---\n")
etable(m_upgrade, m_farm_exit, m_moved, m_sei, m_owner)

saveRDS(list(m_upgrade = m_upgrade, m_farm_exit = m_farm_exit,
             m_moved = m_moved, m_sei = m_sei, m_owner = m_owner),
        file.path(data_dir, "alt_models.rds"))

## --------------------------------------------------------------------------
## 3. Heterogeneity: by initial skill, age, race
## --------------------------------------------------------------------------

cat("\n=== Heterogeneity analysis ===\n")

## By initial skill level
m_het_skill <- feols(delta_occscore ~ quota_exposure * i(skill_1920, ref = "Medium") +
                       age_1920 + I(age_1920^2) + literate + urban + log_pop |
                       statefip_1920,
                     data = dt, lean = TRUE,
                     cluster = ~statefip_1920 + countyicp_1920)

## By age group
m_het_age <- feols(delta_occscore ~ quota_exposure * i(age_cat, ref = "26-35") +
                     literate + urban + log_pop |
                     statefip_1920 + occ1950_1920,
                   data = dt, lean = TRUE,
                   cluster = ~statefip_1920 + countyicp_1920)

## By race (separate regressions due to different labor markets)
m_white <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
                   literate + urban + log_pop | statefip_1920 + occ1950_1920,
                 data = dt[white == 1], lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

m_black <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
                   literate + urban + log_pop | statefip_1920 + occ1950_1920,
                 data = dt[black == 1], lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

## By urban/rural
m_urban <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
                   literate + log_pop | statefip_1920 + occ1950_1920,
                 data = dt[urban == 1], lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

m_rural <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
                   literate + log_pop | statefip_1920 + occ1950_1920,
                 data = dt[urban == 0], lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- By race ---\n")
etable(m_white, m_black)

cat("\n--- By urban/rural ---\n")
etable(m_urban, m_rural)

saveRDS(list(
  m_het_skill = m_het_skill,
  m_het_age = m_het_age,
  m_white = m_white, m_black = m_black,
  m_urban = m_urban, m_rural = m_rural
), file.path(data_dir, "het_models.rds"))

## --------------------------------------------------------------------------
## 4. Write diagnostics.json
## --------------------------------------------------------------------------

cat("\n=== Writing diagnostics ===\n")

n_treated <- nrow(dt[quota_exposure > median(dt$quota_exposure)])
n_counties <- uniqueN(dt, by = c("statefip_1920", "countyicp_1920"))

diagnostics <- list(
  n_obs = nrow(dt),
  n_treated = n_treated,
  n_pre = 10L,  # Decade-long placebo period (1910-1920) tested separately
  n_counties = n_counties,
  n_states = uniqueN(dt$statefip_1920),
  mean_quota_exposure = mean(dt$quota_exposure),
  sd_quota_exposure = sd(dt$quota_exposure),
  main_coef = coef(m4)["quota_exposure"],
  main_se = se(m4)["quota_exposure"],
  mean_delta_occscore = mean(dt$delta_occscore),
  sd_delta_occscore = sd(dt$delta_occscore)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics written to data/diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
