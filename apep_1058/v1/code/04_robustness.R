# ==============================================================================
# 04_robustness.R — Robustness and mechanism tests
# apep_1058: The Networked Bank Run
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

analysis <- readRDS(file.path(data_dir, "analysis.rds"))
sod_all <- readRDS(file.path(data_dir, "sod_all.rds"))
sci_raw <- readRDS(file.path(data_dir, "sci_raw.rds"))

# ==============================================================================
# 1. Non-failing bank placebo
# ==============================================================================
cat("=== Non-failing bank placebo ===\n")

# Construct placebo exposure using JPMorgan Chase (CERT 628) footprint
sod_2022 <- sod_all %>% filter(YEAR == 2022)

# JPMorgan Chase CERT = 628
jpm_branches <- sod_2022 %>%
  filter(CERT == "628" | CERT == 628) %>%
  mutate(
    fips = sprintf("%05d", as.integer(STCNTYBR)),
    deposits = as.numeric(DEPSUMBR)
  ) %>%
  filter(!is.na(deposits))

cat(sprintf("JPMorgan branches: %d\n", nrow(jpm_branches)))

# County-level JPM deposit totals
county_deps <- sod_2022 %>%
  mutate(
    fips = sprintf("%05d", as.integer(STCNTYBR)),
    deposits = as.numeric(DEPSUMBR)
  ) %>%
  filter(!is.na(deposits) & nchar(fips) == 5) %>%
  group_by(fips) %>%
  summarise(total_dep = sum(deposits, na.rm=TRUE), .groups="drop")

jpm_county <- jpm_branches %>%
  group_by(fips) %>%
  summarise(jpm_dep = sum(deposits, na.rm=TRUE), .groups="drop")

jpm_share <- county_deps %>%
  left_join(jpm_county, by = "fips") %>%
  mutate(jpm_share = ifelse(is.na(jpm_dep), 0, jpm_dep / total_dep)) %>%
  filter(jpm_share > 0) %>%
  select(fips, jpm_share)

# Compute JPM network exposure
sci <- sci_raw %>%
  mutate(
    user_fips = sprintf("%05d", as.integer(user_region)),
    fr_fips = sprintf("%05d", as.integer(friend_region))
  )

sci_jpm <- sci %>%
  inner_join(jpm_share, by = c("fr_fips" = "fips"))

jpm_exposure <- sci_jpm %>%
  group_by(user_fips) %>%
  summarise(
    jpm_exposure = sum(as.numeric(scaled_sci) * jpm_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(fips = user_fips) %>%
  mutate(jpm_exposure_std = (jpm_exposure - mean(jpm_exposure)) / sd(jpm_exposure))

# Merge with analysis
analysis_placebo <- analysis %>%
  left_join(jpm_exposure %>% select(fips, jpm_exposure_std), by = "fips") %>%
  filter(!is.na(jpm_exposure_std))

# Placebo regression: JPM exposure should not predict deposit flight
placebo_jpm <- feols(dlog_dep_2223 ~ jpm_exposure_std + log_dist_to_sc +
                       log_pop + log_income + tech_share + pre_trend | state_fips,
                     data = analysis_placebo, cluster = ~state_fips)

# Horse race: SVB vs JPM
horse_race <- feols(dlog_dep_2223 ~ network_exposure_std + jpm_exposure_std +
                      log_dist_to_sc + log_pop + log_income + tech_share + pre_trend | state_fips,
                    data = analysis_placebo, cluster = ~state_fips)

cat(sprintf("JPM placebo: %.5f (SE: %.5f)\n",
            coef(placebo_jpm)["jpm_exposure_std"], se(placebo_jpm)["jpm_exposure_std"]))
cat(sprintf("Horse race - SVB: %.5f (SE: %.5f)\n",
            coef(horse_race)["network_exposure_std"], se(horse_race)["network_exposure_std"]))
cat(sprintf("Horse race - JPM: %.5f (SE: %.5f)\n",
            coef(horse_race)["jpm_exposure_std"], se(horse_race)["jpm_exposure_std"]))

# ==============================================================================
# 2. Distance-trimmed sample (drop California / nearby)
# ==============================================================================
cat("\n=== Distance robustness ===\n")

# Drop California
r_no_ca <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                   log_pop + log_income + tech_share + pre_trend | state_fips,
                 data = filter(analysis, same_state_ca == 0), cluster = ~state_fips)

# Drop counties within 500km
r_far <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                 log_pop + log_income + tech_share + pre_trend | state_fips,
               data = filter(analysis, dist_to_sc_km > 500), cluster = ~state_fips)

# Drop counties within 1000km
r_vfar <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                  log_pop + log_income + tech_share + pre_trend | state_fips,
                data = filter(analysis, dist_to_sc_km > 1000), cluster = ~state_fips)

cat(sprintf("Baseline:  %.5f (SE: %.5f), N=%d\n",
            coef(feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                         log_pop + log_income + tech_share + pre_trend | state_fips,
                       data = analysis, cluster = ~state_fips))["network_exposure_std"],
            se(feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                       log_pop + log_income + tech_share + pre_trend | state_fips,
                     data = analysis, cluster = ~state_fips))["network_exposure_std"],
            nrow(analysis)))
cat(sprintf("Drop CA:   %.5f (SE: %.5f), N=%d\n",
            coef(r_no_ca)["network_exposure_std"], se(r_no_ca)["network_exposure_std"], nobs(r_no_ca)))
cat(sprintf(">500km:    %.5f (SE: %.5f), N=%d\n",
            coef(r_far)["network_exposure_std"], se(r_far)["network_exposure_std"], nobs(r_far)))
cat(sprintf(">1000km:   %.5f (SE: %.5f), N=%d\n",
            coef(r_vfar)["network_exposure_std"], se(r_vfar)["network_exposure_std"], nobs(r_vfar)))

# ==============================================================================
# 3. Alternative clustering
# ==============================================================================
cat("\n=== Alternative clustering ===\n")

# HC1 robust (no clustering)
r_robust <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                    log_pop + log_income + tech_share + pre_trend | state_fips,
                  data = analysis, vcov = "HC1")

cat(sprintf("State-clustered SE: %.5f\n",
            se(feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                       log_pop + log_income + tech_share + pre_trend | state_fips,
                     data = analysis, cluster = ~state_fips))["network_exposure_std"]))
cat(sprintf("HC1 robust SE:      %.5f\n",
            se(r_robust)["network_exposure_std"]))

# ==============================================================================
# 4. Generate Table 4: Robustness
# ==============================================================================
cat("\n=== Generating robustness table ===\n")

# Reload baseline
m5 <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
              log_pop + log_income + tech_share + pre_trend | state_fips,
            data = analysis, cluster = ~state_fips)

tab4_tex <- etable(m5, placebo_jpm, horse_race, r_no_ca, r_far,
                   se.below = TRUE,
                   keep = c("%network_exposure_std", "%jpm_exposure_std"),
                   dict = c(
                     network_exposure_std = "SVB Network Exposure (std.)",
                     jpm_exposure_std = "JPM Placebo Exposure (std.)"
                   ),
                   headers = c("Baseline", "JPM Only",
                               "Horse Race", "Drop CA", ">500km"),
                   fitstat = ~ n + r2,
                   style.tex = style.tex("aer"),
                   tex = TRUE,
                   title = "Robustness: Placebo Epicenter and Distance Restrictions",
                   label = "tab:robust",
                   notes = paste0(
                     "Column (1) reproduces the baseline from Table 1. Column (2) replaces SVB exposure with ",
                     "JPMorgan Chase exposure as a non-failing bank placebo. Column (3) includes both. ",
                     "Columns (4)--(5) restrict the sample by distance from Silicon Valley. ",
                     "All specifications include state FE and state-clustered SEs."
                   ))

writeLines(tab4_tex, file.path(tables_dir, "tab4_robust.tex"))

cat("\n=== Robustness analysis complete ===\n")
