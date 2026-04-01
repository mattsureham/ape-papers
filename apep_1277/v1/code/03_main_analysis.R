# =============================================================================
# 03_main_analysis.R — CS event study + DDD regressions
# Minimum Wages and the Racial Hiring Gap (apep_1277)
# =============================================================================

source("00_packages.R")
data_dir <- "../data/"

analysis_state <- readRDS(paste0(data_dir, "analysis_state.rds"))
analysis_county <- readRDS(paste0(data_dir, "analysis_county.rds"))
analysis_industry <- readRDS(paste0(data_dir, "analysis_industry.rds"))

tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

# =============================================================================
# 1. Callaway-Sant'Anna event studies by race
# =============================================================================
cat("Running CS event studies by race...\n")

# Prepare CS-compatible dataset at state level (one obs per state × time)
# Run separately for White and Black workers

run_cs_by_race <- function(df, race_code, race_label) {
  cat(sprintf("  CS for %s workers...\n", race_label))

  cs_df <- df %>%
    filter(race == race_code) %>%
    mutate(
      unit_id = as.integer(factor(state_fips)),
      g = first_treat_time  # 0 = never treated
    ) %>%
    arrange(unit_id, time_id)

  # Check minimum requirements
  n_treated <- sum(cs_df$g > 0 & !duplicated(cs_df$unit_id[cs_df$g > 0]))
  n_never <- sum(cs_df$g == 0 & !duplicated(cs_df$unit_id[cs_df$g == 0]))
  cat(sprintf("    Treated units: %d, Never-treated: %d\n", n_treated, n_never))

  cs_out <- att_gt(
    yname = "log_hires",
    tname = "time_id",
    idname = "unit_id",
    gname = "g",
    data = as.data.frame(cs_df),
    control_group = "nevertreated",
    base_period = "universal",
    est_method = "dr"
  )

  # Aggregate: overall ATT
  att_overall <- aggte(cs_out, type = "simple")
  cat(sprintf("    ATT (overall): %.4f (SE: %.4f)\n", att_overall$overall.att, att_overall$overall.se))

  # Aggregate: dynamic (event study)
  att_dynamic <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 8)

  list(
    cs_out = cs_out,
    att_overall = att_overall,
    att_dynamic = att_dynamic,
    race = race_label,
    n_treated = n_treated,
    n_never = n_never
  )
}

cs_white <- run_cs_by_race(analysis_state, "A1", "White")
cs_black <- run_cs_by_race(analysis_state, "A2", "Black")

# Save CS results
saveRDS(list(white = cs_white, black = cs_black), paste0(data_dir, "cs_results.rds"))

# =============================================================================
# 2. TWFE DDD: Race × Post × High-Bite (county level)
# =============================================================================
cat("\nRunning DDD regressions (county level)...\n")

# Main DDD specification
# log(hires) ~ black × post × high_bite | county_fips^race + time_id
ddd_main <- feols(
  log_hires ~ black:post:high_bite + black:post + black:high_bite + post:high_bite |
    county_fips^race + time_id,
  data = analysis_county,
  cluster = ~state_fips
)
cat("DDD main results:\n")
print(summary(ddd_main))

# DDD with continuous Kaitz index
ddd_kaitz <- feols(
  log_hires ~ black:post:kaitz + black:post + black:kaitz + post:kaitz |
    county_fips^race + time_id,
  data = analysis_county,
  cluster = ~state_fips
)
cat("DDD Kaitz results:\n")
print(summary(ddd_kaitz))

# Simple DiD for overall effect (pooling races)
did_overall <- feols(
  log_hires ~ post:high_bite | county_fips + time_id,
  data = analysis_county,
  cluster = ~state_fips
)
cat("Overall DiD (high bite):\n")
print(summary(did_overall))

# =============================================================================
# 3. Industry heterogeneity: low-wage vs high-wage sectors
# =============================================================================
cat("\nRunning industry heterogeneity...\n")

# Low-wage industries (retail 44-45, accommodation/food 72)
ind_lowwage <- feols(
  log_hires ~ black:post | state_fips^race + time_id,
  data = analysis_industry %>% filter(low_wage_industry == 1),
  cluster = ~state_fips
)

# High-wage industries (professional 54, finance 52)
ind_highwage <- feols(
  log_hires ~ black:post | state_fips^race + time_id,
  data = analysis_industry %>% filter(low_wage_industry == 0),
  cluster = ~state_fips
)

cat("Low-wage industry (race × post):\n")
print(coeftable(ind_lowwage))
cat("High-wage industry (race × post):\n")
print(coeftable(ind_highwage))

# =============================================================================
# 4. Event study coefficients (for table reporting)
# =============================================================================
cat("\nExtracting event study coefficients...\n")

es_white <- data.frame(
  event_time = cs_white$att_dynamic$egt,
  att = cs_white$att_dynamic$att.egt,
  se = cs_white$att_dynamic$se.egt,
  race = "White"
)

es_black <- data.frame(
  event_time = cs_black$att_dynamic$egt,
  att = cs_black$att_dynamic$att.egt,
  se = cs_black$att_dynamic$se.egt,
  race = "Black"
)

event_study <- bind_rows(es_white, es_black) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    sig = ifelse(abs(att/se) > 2.576, "***",
          ifelse(abs(att/se) > 1.96, "**",
          ifelse(abs(att/se) > 1.645, "*", "")))
  )

saveRDS(event_study, paste0(data_dir, "event_study.rds"))
saveRDS(list(ddd_main = ddd_main, ddd_kaitz = ddd_kaitz,
             did_overall = did_overall,
             ind_lowwage = ind_lowwage, ind_highwage = ind_highwage),
        paste0(data_dir, "regression_results.rds"))

# =============================================================================
# 5. Summary statistics for Table 1
# =============================================================================
cat("\nComputing summary statistics...\n")

sumstats <- analysis_state %>%
  group_by(race) %>%
  summarise(
    mean_hires = mean(hires, na.rm = TRUE),
    sd_hires = sd(hires, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_earnings = mean(avg_earnings, na.rm = TRUE),
    sd_earnings = sd(avg_earnings, na.rm = TRUE),
    n_obs = n(),
    n_states = n_distinct(state_fips),
    .groups = "drop"
  )

cat("Summary statistics:\n")
print(sumstats)
saveRDS(sumstats, paste0(data_dir, "summary_stats.rds"))

# Pre/post summary by race and treatment status
sumstats_prepost <- analysis_state %>%
  mutate(
    post_treat = as.integer(time_id >= first_treat_time & first_treat_time > 0),
    treated = as.integer(first_treat_time > 0)
  ) %>%
  group_by(race, treated, post_treat) %>%
  summarise(
    mean_hires = mean(hires, na.rm = TRUE),
    mean_log_hires = mean(log_hires, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

cat("Pre/post summary:\n")
print(sumstats_prepost)
saveRDS(sumstats_prepost, paste0(data_dir, "summary_prepost.rds"))

# =============================================================================
# 6. Write diagnostics.json
# =============================================================================
cat("\nWriting diagnostics.json...\n")

n_treated_states <- length(unique(
  analysis_state$state_fips[analysis_state$first_treat_time > 0]
))
n_pre <- length(unique(
  analysis_state$time_id[analysis_state$time_id < min(
    analysis_state$first_treat_time[analysis_state$first_treat_time > 0]
  )]
))

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = nrow(analysis_state),
  n_counties = length(unique(analysis_county$county_fips)),
  n_county_obs = nrow(analysis_county),
  cs_att_white = cs_white$att_overall$overall.att,
  cs_se_white = cs_white$att_overall$overall.se,
  cs_att_black = cs_black$att_overall$overall.att,
  cs_se_black = cs_black$att_overall$overall.se
)

jsonlite::write_json(diagnostics, paste0(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics written.\n")

cat("\n=== Main analysis complete ===\n")
cat(sprintf("CS ATT White: %.4f (%.4f)\n", cs_white$att_overall$overall.att, cs_white$att_overall$overall.se))
cat(sprintf("CS ATT Black: %.4f (%.4f)\n", cs_black$att_overall$overall.att, cs_black$att_overall$overall.se))
cat(sprintf("DDD (black × post × high_bite): see regression output above\n"))
