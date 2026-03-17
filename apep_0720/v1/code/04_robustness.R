# 04_robustness.R — Robustness checks for sports betting cannibalization
# apep_0720

source("00_packages.R")

data_dir <- "../data"

stc <- readRDS(file.path(data_dir, "stc_analysis.rds"))

# Analysis sample: states with known treatment status
df <- stc %>% filter(!is.na(g))
cat(sprintf("Analysis sample: %d state-years\n", nrow(df)))

# ===================================================================
# ROBUSTNESS 1: Levels instead of logs (T11 and T20 in millions)
# ===================================================================

cat("\n=== Robustness: Levels (millions) ===\n\n")

r1_t11_levels <- feols(T11 ~ post | state_fips + year,
                       data = df, cluster = ~state_fips)
cat("T11 in levels (millions):\n")
summary(r1_t11_levels)

r1_t20_levels <- feols(T20 ~ post | state_fips + year,
                       data = df %>% filter(!is.na(T20)),
                       cluster = ~state_fips)
cat("\nT20 in levels (millions):\n")
summary(r1_t20_levels)

# ===================================================================
# ROBUSTNESS 2: Combined T11 + T20 as total gambling revenue
# ===================================================================

cat("\n=== Robustness: Combined T11+T20 ===\n\n")

df <- df %>%
  mutate(
    total_gambling = T11 + T20,
    log_total_gambling = ifelse(total_gambling > 0, log(total_gambling), NA_real_)
  )

r2_combined_log <- feols(log_total_gambling ~ post | state_fips + year,
                         data = df %>% filter(!is.na(log_total_gambling)),
                         cluster = ~state_fips)
cat("Log(T11 + T20) combined:\n")
summary(r2_combined_log)

r2_combined_levels <- feols(total_gambling ~ post | state_fips + year,
                            data = df, cluster = ~state_fips)
cat("\nT11 + T20 combined (levels, millions):\n")
summary(r2_combined_levels)

# ===================================================================
# ROBUSTNESS 3: Leave-one-out — drop NJ (largest/first treated state)
# ===================================================================

cat("\n=== Robustness: Leave-one-out (drop NJ) ===\n\n")

df_no_nj <- df %>% filter(state_abbr != "NJ")
cat(sprintf("Sample without NJ: %d state-years\n", nrow(df_no_nj)))

r3_t11_no_nj <- feols(log_T11 ~ post | state_fips + year,
                      data = df_no_nj %>% filter(!is.na(log_T11)),
                      cluster = ~state_fips)
cat("T11 (log) without NJ:\n")
summary(r3_t11_no_nj)

r3_t20_no_nj <- feols(log_T20 ~ post | state_fips + year,
                      data = df_no_nj %>% filter(!is.na(log_T20)),
                      cluster = ~state_fips)
cat("\nT20 (log) without NJ:\n")
summary(r3_t20_no_nj)

# ===================================================================
# SAVE ROBUSTNESS RESULTS
# ===================================================================

robustness <- list(
  r1_t11_levels = r1_t11_levels,
  r1_t20_levels = r1_t20_levels,
  r2_combined_log = r2_combined_log,
  r2_combined_levels = r2_combined_levels,
  r3_t11_no_nj = r3_t11_no_nj,
  r3_t20_no_nj = r3_t20_no_nj
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
