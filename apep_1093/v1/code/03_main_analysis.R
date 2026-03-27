# 03_main_analysis.R — Main regressions for pay transparency and racial earnings gap
# Triple-difference: state x post x high-dispersion industry

source("00_packages.R")

# ---- Load data ----
df <- readRDS("../data/qwi_clean.rds")
df_gap <- readRDS("../data/qwi_gap.rds")

cat("=== MAIN ANALYSIS ===\n\n")

# ====================================================================
# Analysis 1: Race-specific earnings regressions (DDD on ln_earn_hire)
# ====================================================================

cat("--- Analysis 1: DDD on ln(new-hire earnings) by race ---\n")

# For Black workers only
df_black <- df %>% filter(race == "Black")
df_white <- df %>% filter(race == "White")

# DDD: Treated x Post x HighDisp
# Model 1: Black workers — DiD (no triple diff)
m1_black_did <- feols(
  ln_earn_hire ~ treated_state:post |
    panel_id + time_index,
  data = df_black,
  cluster = ~state_fips
)

# Model 2: White workers — DiD
m1_white_did <- feols(
  ln_earn_hire ~ treated_state:post |
    panel_id + time_index,
  data = df_white,
  cluster = ~state_fips
)

# Model 3: Black workers — DDD
m2_black_ddd <- feols(
  ln_earn_hire ~ treated_state:post:high_dispersion +
    treated_state:post + treated_state:high_dispersion +
    post:high_dispersion |
    panel_id + time_index,
  data = df_black,
  cluster = ~state_fips
)

# Model 4: White workers — DDD
m2_white_ddd <- feols(
  ln_earn_hire ~ treated_state:post:high_dispersion +
    treated_state:post + treated_state:high_dispersion +
    post:high_dispersion |
    panel_id + time_index,
  data = df_white,
  cluster = ~state_fips
)

cat("\nBlack DiD:\n")
print(summary(m1_black_did))
cat("\nWhite DiD:\n")
print(summary(m1_white_did))
cat("\nBlack DDD:\n")
print(summary(m2_black_ddd))
cat("\nWhite DDD:\n")
print(summary(m2_white_ddd))

# ====================================================================
# Analysis 2: B-W earnings gap as outcome (gap regression)
# ====================================================================

cat("\n--- Analysis 2: B-W earnings gap regressions ---\n")

# Model 5: DiD on gap
m3_gap_did <- feols(
  bw_gap ~ treated_state:post |
    panel_id + time_index,
  data = df_gap,
  cluster = ~state_fips
)

# Model 6: DDD on gap
m4_gap_ddd <- feols(
  bw_gap ~ treated_state:post:high_dispersion +
    treated_state:post + treated_state:high_dispersion +
    post:high_dispersion |
    panel_id + time_index,
  data = df_gap,
  cluster = ~state_fips
)

cat("\nGap DiD:\n")
print(summary(m3_gap_did))
cat("\nGap DDD:\n")
print(summary(m4_gap_ddd))

# ====================================================================
# Analysis 3: Extensive margin — hiring counts by race
# ====================================================================

cat("\n--- Analysis 3: Hiring counts by race ---\n")

m5_hire_black <- feols(
  ln_hires ~ treated_state:post |
    panel_id + time_index,
  data = df_black,
  cluster = ~state_fips
)

m5_hire_white <- feols(
  ln_hires ~ treated_state:post |
    panel_id + time_index,
  data = df_white,
  cluster = ~state_fips
)

cat("\nBlack hiring DiD:\n")
print(summary(m5_hire_black))
cat("\nWhite hiring DiD:\n")
print(summary(m5_hire_white))

# ====================================================================
# Store results for tables
# ====================================================================

results <- list(
  m1_black_did = m1_black_did,
  m1_white_did = m1_white_did,
  m2_black_ddd = m2_black_ddd,
  m2_white_ddd = m2_white_ddd,
  m3_gap_did = m3_gap_did,
  m4_gap_ddd = m4_gap_ddd,
  m5_hire_black = m5_hire_black,
  m5_hire_white = m5_hire_white
)

saveRDS(results, "../data/main_results.rds")

# ---- Diagnostics for validator ----
# Treated units = county-industry panels in treated states (unit of analysis)
n_treated_panels <- n_distinct(df_gap$panel_id[df_gap$treated_state == 1])
n_treated_states <- n_distinct(df_gap$state_fips[df_gap$treated_state == 1])
n_pre <- length(unique(df_gap$time_index[df_gap$time_index < min(
  df_gap$time_index[df_gap$post == 1], na.rm = TRUE)]))
n_obs <- nrow(df_gap)

jsonlite::write_json(list(
  n_treated = n_treated_panels,
  n_treated_states = n_treated_states,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%s\n",
    n_treated_states, n_pre, format(n_obs, big.mark = ",")))

cat("\nMain analysis complete.\n")
