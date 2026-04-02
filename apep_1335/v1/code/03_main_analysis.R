# 03_main_analysis.R — Main DiD analysis using Callaway-Sant'Anna
# apep_1335: Cannabis Lottery and Local Economic Renewal
# Packages: fixest, did, tidyverse, HonestDiD (loaded via 00_packages.R)

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "rows,", n_distinct(panel$county_fips), "counties\n")
cat("Treated:", sum(panel$first_treat > 0) / n_distinct(panel$time_period), "counties\n")
cat("Control:", sum(panel$first_treat == 0) / n_distinct(panel$time_period), "counties\n")

# ============================================================================
# PART 1: Summary Statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")

# Pre-treatment period summary (before any lottery: period < 14 = 2021Q2)
pre_panel <- panel %>% filter(time_period < 14)

summary_stats <- pre_panel %>%
  mutate(group = ifelse(first_treat > 0, "Treated", "Never-treated")) %>%
  group_by(group) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_emp_retail = mean(emp_retail, na.rm = TRUE),
    sd_emp_retail = sd(emp_retail, na.rm = TRUE),
    mean_emp_food = mean(emp_food, na.rm = TRUE),
    sd_emp_food = sd(emp_food, na.rm = TRUE),
    mean_emp_total = mean(emp_total, na.rm = TRUE),
    sd_emp_total = sd(emp_total, na.rm = TRUE),
    mean_earn_retail = mean(earn_retail, na.rm = TRUE),
    sd_earn_retail = sd(earn_retail, na.rm = TRUE),
    mean_earn_total = mean(earn_total, na.rm = TRUE),
    sd_earn_total = sd(earn_total, na.rm = TRUE),
    .groups = "drop"
  )

cat("Pre-treatment summary:\n")
print(summary_stats)

# ============================================================================
# PART 2: Callaway-Sant'Anna Estimation
# ============================================================================

cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for CS estimator
cs_data <- panel %>%
  filter(!is.na(log_emp_retail)) %>%
  mutate(
    # CS requires: gname = first treated period (0 for never-treated)
    gname = first_treat
  )

cat("CS data: N =", nrow(cs_data), ", units =", n_distinct(cs_data$county_id),
    ", periods =", n_distinct(cs_data$time_period), "\n")

# --- Main outcome: Log retail employment ---
cat("\n--- Retail Employment (NAICS 44-45) ---\n")

cs_retail <- att_gt(
  yname = "log_emp_retail",
  tname = "time_period",
  idname = "county_id",
  gname = "gname",
  data = cs_data,
  control_group = "notyettreated",
  est_method = "dr",       # Doubly robust
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("ATT(g,t) estimates computed.\n")

# Aggregate: simple ATT
att_simple_retail <- aggte(cs_retail, type = "simple")
cat("\nSimple ATT (retail employment):\n")
summary(att_simple_retail)

# Aggregate: event-study (dynamic effects)
es_retail <- aggte(cs_retail, type = "dynamic", min_e = -8, max_e = 8)
cat("\nEvent study (retail employment):\n")
summary(es_retail)

# --- Main outcome: Log food service employment ---
cat("\n--- Food Service Employment (NAICS 7225) ---\n")

cs_data_food <- cs_data %>% filter(!is.na(log_emp_food))

cs_food <- att_gt(
  yname = "log_emp_food",
  tname = "time_period",
  idname = "county_id",
  gname = "gname",
  data = cs_data_food,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

att_simple_food <- aggte(cs_food, type = "simple", na.rm = TRUE)
cat("\nSimple ATT (food service employment):\n")
summary(att_simple_food)

es_food <- aggte(cs_food, type = "dynamic", min_e = -8, max_e = 8, na.rm = TRUE)

# --- Main outcome: Log total employment ---
cat("\n--- Total Employment ---\n")

cs_data_total <- cs_data %>% filter(!is.na(log_emp_total))

cs_total <- att_gt(
  yname = "log_emp_total",
  tname = "time_period",
  idname = "county_id",
  gname = "gname",
  data = cs_data_total,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

att_simple_total <- aggte(cs_total, type = "simple", na.rm = TRUE)
cat("\nSimple ATT (total employment):\n")
summary(att_simple_total)

es_total <- aggte(cs_total, type = "dynamic", min_e = -8, max_e = 8, na.rm = TRUE)

# --- Outcome: Log retail earnings ---
cat("\n--- Retail Earnings ---\n")

cs_data_earn <- cs_data %>% filter(!is.na(log_earn_retail))

cs_earn <- att_gt(
  yname = "log_earn_retail",
  tname = "time_period",
  idname = "county_id",
  gname = "gname",
  data = cs_data_earn,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

att_simple_earn <- aggte(cs_earn, type = "simple", na.rm = TRUE)
cat("\nSimple ATT (retail earnings):\n")
summary(att_simple_earn)

es_earn <- aggte(cs_earn, type = "dynamic", min_e = -8, max_e = 8, na.rm = TRUE)

# ============================================================================
# PART 3: TWFE as Comparison
# ============================================================================

cat("\n=== TWFE Comparison ===\n")

twfe_retail <- feols(log_emp_retail ~ treated | county_id + time_period,
                      data = cs_data, cluster = ~county_id)
cat("TWFE retail:\n")
print(summary(twfe_retail))

twfe_food <- feols(log_emp_food ~ treated | county_id + time_period,
                    data = cs_data_food, cluster = ~county_id)
cat("TWFE food service:\n")
print(summary(twfe_food))

twfe_total <- feols(log_emp_total ~ treated | county_id + time_period,
                     data = cs_data_total, cluster = ~county_id)
cat("TWFE total:\n")
print(summary(twfe_total))

twfe_earn <- feols(log_earn_retail ~ treated | county_id + time_period,
                    data = cs_data_earn, cluster = ~county_id)
cat("TWFE retail earnings:\n")
print(summary(twfe_earn))

# ============================================================================
# PART 4: Save Results
# ============================================================================

results <- list(
  # CS estimates
  cs_retail = cs_retail,
  cs_food = cs_food,
  cs_total = cs_total,
  cs_earn = cs_earn,
  # Aggregated ATTs
  att_retail = att_simple_retail,
  att_food = att_simple_food,
  att_total = att_simple_total,
  att_earn = att_simple_earn,
  # Event studies
  es_retail = es_retail,
  es_food = es_food,
  es_total = es_total,
  es_earn = es_earn,
  # TWFE
  twfe_retail = twfe_retail,
  twfe_food = twfe_food,
  twfe_total = twfe_total,
  twfe_earn = twfe_earn,
  # Summary stats
  summary_stats = summary_stats
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================================
# PART 5: Diagnostics JSON
# ============================================================================

diagnostics <- list(
  n_treated = as.integer(sum(panel$first_treat > 0) / n_distinct(panel$time_period)),
  n_pre = as.integer(min(panel$first_treat[panel$first_treat > 0]) - 1),
  n_obs = nrow(cs_data),
  n_counties = n_distinct(cs_data$county_fips),
  n_periods = n_distinct(cs_data$time_period),
  n_never_treated = as.integer(sum(panel$first_treat == 0) / n_distinct(panel$time_period)),
  att_retail = att_simple_retail$overall.att,
  se_retail = att_simple_retail$overall.se,
  att_food = att_simple_food$overall.att,
  se_food = att_simple_food$overall.se,
  att_total = att_simple_total$overall.att,
  se_total = att_simple_total$overall.se,
  att_earn = att_simple_earn$overall.att,
  se_earn = att_simple_earn$overall.se
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

cat("\n=== Main Analysis Complete ===\n")
cat("ATT (retail emp):", round(att_simple_retail$overall.att, 4),
    "SE:", round(att_simple_retail$overall.se, 4), "\n")
cat("ATT (food service):", round(att_simple_food$overall.att, 4),
    "SE:", round(att_simple_food$overall.se, 4), "\n")
cat("ATT (total emp):", round(att_simple_total$overall.att, 4),
    "SE:", round(att_simple_total$overall.se, 4), "\n")
cat("ATT (retail earn):", round(att_simple_earn$overall.att, 4),
    "SE:", round(att_simple_earn$overall.se, 4), "\n")
