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

## --------------------------------------------------------------------------
## V2: 5. First-stage evidence — did restriction actually reduce immigration?
## --------------------------------------------------------------------------

cat("\n=== V2: First-stage evidence ===\n")

if ("delta_restricted_share" %in% names(dt)) {
  ## County-level first stage: change in restricted-origin share ~ 1920 exposure
  county_dt <- dt[, .(
    delta_restricted_share = mean(delta_restricted_share, na.rm = TRUE),
    delta_fb_share = mean(delta_fb_share, na.rm = TRUE),
    quota_exposure = mean(quota_exposure),
    total_pop = mean(total_pop),
    n_individuals = .N
  ), by = .(statefip_1920, countyicp_1920)]

  m_fs1 <- feols(delta_restricted_share ~ quota_exposure | statefip_1920,
                  data = county_dt, weights = ~n_individuals)

  m_fs2 <- feols(delta_fb_share ~ quota_exposure | statefip_1920,
                  data = county_dt, weights = ~n_individuals)

  cat("\n--- First stage: change in restricted-origin share ---\n")
  etable(m_fs1, m_fs2)

  saveRDS(list(m_fs1 = m_fs1, m_fs2 = m_fs2, county_dt = county_dt),
          file.path(data_dir, "first_stage_models.rds"))
} else {
  cat("No 1930 FB data available — skipping first stage\n")
}

## --------------------------------------------------------------------------
## V2: 6. Homeownership mechanism decomposition
## --------------------------------------------------------------------------

cat("\n=== V2: Homeownership mechanism decomposition ===\n")

## Homeownership by initial tenure
m_owner_renters <- feols(became_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                           literate + urban + log_pop | statefip_1920 + occ1950_1920,
                         data = dt[ownershp_1920 == 2], lean = TRUE,
                         cluster = ~statefip_1920 + countyicp_1920)

## Lost homeownership among owners
m_lost_home <- feols(lost_home ~ quota_exposure + age_1920 + I(age_1920^2) +
                       literate + urban + log_pop | statefip_1920 + occ1950_1920,
                     data = dt[ownershp_1920 == 1], lean = TRUE,
                     cluster = ~statefip_1920 + countyicp_1920)

## Net homeownership transition (full sample)
m_net_owner <- feols(net_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                       literate + urban + log_pop | statefip_1920 + occ1950_1920,
                     data = dt, lean = TRUE,
                     cluster = ~statefip_1920 + countyicp_1920)

## Homeownership by age group
m_owner_young <- feols(became_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                         literate + urban + log_pop | statefip_1920 + occ1950_1920,
                       data = dt[age_cat %in% c("18-25", "26-35")], lean = TRUE,
                       cluster = ~statefip_1920 + countyicp_1920)

m_owner_old <- feols(became_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                       literate + urban + log_pop | statefip_1920 + occ1950_1920,
                     data = dt[age_cat %in% c("36-45", "46-55")], lean = TRUE,
                     cluster = ~statefip_1920 + countyicp_1920)

## Homeownership by urban/rural
m_owner_urban <- feols(became_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                         literate + log_pop | statefip_1920 + occ1950_1920,
                       data = dt[urban == 1], lean = TRUE,
                       cluster = ~statefip_1920 + countyicp_1920)

m_owner_rural <- feols(became_owner ~ quota_exposure + age_1920 + I(age_1920^2) +
                         literate + log_pop | statefip_1920 + occ1950_1920,
                       data = dt[urban == 0], lean = TRUE,
                       cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- Homeownership mechanism results ---\n")
etable(m_owner_renters, m_lost_home, m_net_owner)
etable(m_owner_young, m_owner_old, m_owner_urban, m_owner_rural)

saveRDS(list(
  m_owner_renters = m_owner_renters, m_lost_home = m_lost_home,
  m_net_owner = m_net_owner,
  m_owner_young = m_owner_young, m_owner_old = m_owner_old,
  m_owner_urban = m_owner_urban, m_owner_rural = m_owner_rural
), file.path(data_dir, "owner_mechanism_models.rds"))

## --------------------------------------------------------------------------
## V2: 7. Occupational ladder transitions
## --------------------------------------------------------------------------

cat("\n=== V2: Occupational ladder analysis ===\n")

## Ladder up (categorical)
m_ladder <- feols(ladder_up ~ quota_exposure + age_1920 + I(age_1920^2) +
                    literate + urban + log_pop | statefip_1920,
                  data = dt[occ_rank_1920 > 0], lean = TRUE,
                  cluster = ~statefip_1920 + countyicp_1920)

## Self-employment transition
m_self_emp <- feols(became_self_employed ~ quota_exposure + age_1920 + I(age_1920^2) +
                      literate + urban + log_pop | statefip_1920 + occ1950_1920,
                    data = dt, lean = TRUE,
                    cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- Ladder and self-employment ---\n")
etable(m_ladder, m_self_emp)

saveRDS(list(m_ladder = m_ladder, m_self_emp = m_self_emp),
        file.path(data_dir, "ladder_models.rds"))

## --------------------------------------------------------------------------
## V2: 8. Mobility and sorting
## --------------------------------------------------------------------------

cat("\n=== V2: Mobility and sorting ===\n")

## Did high-exposure places see more out-migration?
m_moved_interaction <- feols(moved ~ quota_exposure * i(skill_1920, ref = "Medium") +
                               age_1920 + I(age_1920^2) + literate + urban + log_pop |
                               statefip_1920,
                             data = dt, lean = TRUE,
                             cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- Mobility by skill level ---\n")
etable(m_moved_interaction)

saveRDS(m_moved_interaction, file.path(data_dir, "mobility_model.rds"))

cat("\n=== Main analysis complete ===\n")
