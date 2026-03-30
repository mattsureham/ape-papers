# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# =============================================================================

source("00_packages.R")

state_panel <- readRDS("../data/state_panel.rds")
county_panel <- readRDS("../data/county_panel.rds")

# Reconstruct needed variables
state_panel <- state_panel %>%
  mutate(
    event_time = time_id - 22,
    high_edu = as.integer(education %in% c("E3", "E4")),
    exp_post_E1 = exposure * post * as.integer(education == "E1"),
    exp_post_E2 = exposure * post * as.integer(education == "E2"),
    exp_post_E3 = exposure * post * as.integer(education == "E3"),
    exp_post_E4 = exposure * post * as.integer(education == "E4"),
    exposure_post = exposure * post,
    exposure_post_highedu = exposure * post * high_edu
  )

county_panel <- county_panel %>%
  mutate(
    high_edu = as.integer(education %in% c("E3", "E4")),
    exposure_post = exposure * post,
    exposure_post_highedu = exposure * post * high_edu
  )

# =============================================================================
# 1. Alternative clustering: county-level
# =============================================================================
cat("=== Robustness: County-level clustering ===\n")

r1 <- feols(
  log_emp ~ exposure_post + exposure_post_highedu |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~county_fips
)
summary(r1)

# =============================================================================
# 2. Drop 2019Q3-Q4 (trade war escalation with China tariff rounds)
# =============================================================================
cat("\n=== Robustness: Drop 2019H2 ===\n")

r2 <- feols(
  log_emp ~ exposure_post + exposure_post_highedu |
    state_edu + edu_time + state_time,
  data = filter(state_panel, yq < 2019.5),
  cluster = ~state_fips
)
summary(r2)

# =============================================================================
# 3. Placebo: non-downstream manufacturing (should show no effect)
# =============================================================================
cat("\n=== Placebo: Non-downstream manufacturing ===\n")

# Load raw data and build panel for non-downstream industries
qwi_state_raw <- readRDS("../data/qwi_state_mfg.rds")
state_exposure <- readRDS("../data/state_exposure.rds")

non_downstream <- qwi_state_raw %>%
  mutate(
    state_fips = as.character(geography),
    yq = year + (quarter - 1) / 4,
    time_id = (year - 2013) * 4 + quarter,
    post = as.integer(yq >= 2018.25)
  ) %>%
  filter(
    !industry %in% c("332", "333", "336"),
    education != "E0"
  ) %>%
  group_by(state_fips, education, year, quarter, yq, time_id, post) %>%
  summarise(
    emp = sum(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(emp > 0) %>%
  mutate(log_emp = log(emp)) %>%
  inner_join(state_exposure %>% select(state_fips, exposure), by = "state_fips") %>%
  mutate(
    high_edu = as.integer(education %in% c("E3", "E4")),
    exposure_post = exposure * post,
    exposure_post_highedu = exposure * post * high_edu,
    state_edu = paste0(state_fips, "_", education),
    edu_time = paste0(education, "_", time_id),
    state_time = paste0(state_fips, "_", time_id)
  )

r3_placebo <- feols(
  log_emp ~ exposure_post + exposure_post_highedu |
    state_edu + edu_time + state_time,
  data = non_downstream,
  cluster = ~state_fips
)
cat("Placebo (non-downstream mfg):\n")
summary(r3_placebo)

# =============================================================================
# 4. Binary exposure (above/below median) instead of continuous
# =============================================================================
cat("\n=== Robustness: Binary exposure ===\n")

med_exp <- median(state_exposure$exposure, na.rm = TRUE)

state_panel_bin <- state_panel %>%
  mutate(
    high_exposure = as.integer(exposure > med_exp),
    high_exp_post = high_exposure * post,
    high_exp_post_highedu = high_exposure * post * high_edu
  )

r4 <- feols(
  log_emp ~ high_exp_post + high_exp_post_highedu |
    state_edu + edu_time + state_time,
  data = state_panel_bin,
  cluster = ~state_fips
)
summary(r4)

# =============================================================================
# 5. Tercile-based exposure (dose-response)
# =============================================================================
cat("\n=== Robustness: Tercile exposure ===\n")

terciles <- quantile(state_exposure$exposure, probs = c(1/3, 2/3), na.rm = TRUE)

state_panel_terc <- state_panel %>%
  mutate(
    exp_tercile = case_when(
      exposure <= terciles[1] ~ "Low",
      exposure <= terciles[2] ~ "Medium",
      TRUE ~ "High"
    ),
    med_post = as.integer(exp_tercile == "Medium") * post,
    high_post = as.integer(exp_tercile == "High") * post,
    med_post_highedu = med_post * high_edu,
    high_post_highedu = high_post * high_edu
  )

r5 <- feols(
  log_emp ~ med_post + high_post + med_post_highedu + high_post_highedu |
    state_edu + edu_time + state_time,
  data = state_panel_terc,
  cluster = ~state_fips
)
summary(r5)

# =============================================================================
# 6. Separation rate and earnings robustness at county level
# =============================================================================
cat("\n=== County-level separation rate and earnings ===\n")

r6_sep <- feols(
  sep_rate ~ exposure_post + exposure_post_highedu |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~state_fips
)

r6_earn <- feols(
  log_earn ~ exposure_post + exposure_post_highedu |
    county_edu + edu_time + county_time,
  data = county_panel,
  cluster = ~state_fips
)

# =============================================================================
# Save robustness results
# =============================================================================
saveRDS(list(
  r1_county_cluster = r1,
  r2_drop_2019h2 = r2,
  r3_placebo = r3_placebo,
  r4_binary = r4,
  r5_tercile = r5,
  r6_sep = r6_sep,
  r6_earn = r6_earn
), "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
