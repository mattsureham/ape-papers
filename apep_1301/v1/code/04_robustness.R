## ============================================================
## 04_robustness.R — Robustness Checks (State Level)
## APEP Paper apep_1301: SNAP Retailer Exits and Birth Outcomes
## ============================================================

source("code/00_packages.R")

data_dir <- "data"
df <- fread(file.path(data_dir, "analysis_panel.csv"))

# Reconstruct key variables
df[, first_exit_year := fifelse(
  any(super_exits > 0), min(year[super_exits > 0]), NA_integer_),
  by = state_fips]
df[, ever_treated := as.integer(!is.na(first_exit_year))]
df[, rel_time := year - first_exit_year]
median_medicaid <- median(df$medicaid_share, na.rm = TRUE)
df[, high_medicaid := as.integer(medicaid_share >= median_medicaid)]

## ---- 1. Cumulative Exits (Intensive Margin) ----
cat("=== Robustness 1: Cumulative Exits ===\n")

m_cum_lbw <- feols(lbw_rate_100 ~ cum_exits | state_fips + year,
                   data = df, cluster = ~state_fips)
m_cum_preterm <- feols(preterm_rate_100 ~ cum_exits | state_fips + year,
                       data = df, cluster = ~state_fips)
summary(m_cum_lbw)


## ---- 2. Log Active Supermarkets ----
cat("\n=== Robustness 2: Log Active Supermarkets ===\n")

df[, log_supers := log(n_supermarkets + 1)]
m_log_lbw <- feols(lbw_rate_100 ~ log_supers | state_fips + year,
                   data = df, cluster = ~state_fips)
m_log_preterm <- feols(preterm_rate_100 ~ log_supers | state_fips + year,
                       data = df, cluster = ~state_fips)
summary(m_log_lbw)


## ---- 3. Exclude COVID Years ----
cat("\n=== Robustness 3: Exclude COVID ===\n")

df_nc <- df[!year %in% c(2020, 2021)]
m_nc_lbw <- feols(lbw_rate_100 ~ exit_rate | state_fips + year,
                  data = df_nc, cluster = ~state_fips)
m_nc_preterm <- feols(preterm_rate_100 ~ exit_rate | state_fips + year,
                      data = df_nc, cluster = ~state_fips)
summary(m_nc_lbw)


## ---- 4. Population-Weighted ----
cat("\n=== Robustness 4: Birth-Weighted ===\n")

m_wt_lbw <- feols(lbw_rate_100 ~ exit_rate | state_fips + year,
                  data = df, cluster = ~state_fips, weights = ~births)
m_wt_preterm <- feols(preterm_rate_100 ~ exit_rate | state_fips + year,
                      data = df, cluster = ~state_fips, weights = ~births)
summary(m_wt_lbw)


## ---- 5. Wild Cluster Bootstrap (few clusters) ----
cat("\n=== Robustness 5: Wild Cluster Bootstrap ===\n")

# With ~50 state clusters, WCB is important
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  m_base <- feols(lbw_rate_100 ~ exit_rate | state_fips + year, data = df)
  boot_result <- tryCatch({
    boottest(m_base, param = "exit_rate",
             clustid = ~state_fips,
             B = 9999, type = "rademacher")
  }, error = function(e) {
    cat("  WCB failed:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_result)) {
    cat(sprintf("  WCB p-value: %.4f, 95%% CI: [%.4f, %.4f]\n",
                boot_result$p_val,
                boot_result$conf_int[1], boot_result$conf_int[2]))
  }
} else {
  cat("  fwildclusterboot not available, installing...\n")
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  library(fwildclusterboot)
  m_base <- feols(lbw_rate_100 ~ exit_rate | state_fips + year, data = df)
  boot_result <- tryCatch({
    boottest(m_base, param = "exit_rate",
             clustid = ~state_fips,
             B = 9999, type = "rademacher")
  }, error = function(e) {
    cat("  WCB failed:", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(boot_result)) {
    cat(sprintf("  WCB p-value: %.4f\n", boot_result$p_val))
  }
}


## ---- 6. Leave-One-Chain-Out IV ----
cat("\n=== Robustness 6: Leave-One-Chain-Out ===\n")

iv_int_cols <- names(df)[grepl("^iv_intensity_", names(df))]
for (drop_col in iv_int_cols) {
  chain_name <- gsub("^iv_intensity_", "", drop_col)
  keep_cols <- setdiff(iv_int_cols, drop_col)
  df[, iv_loo := rowSums(.SD), .SDcols = keep_cols]

  m_loo <- tryCatch({
    feols(lbw_rate_100 ~ 1 | state_fips + year | exit_rate ~ iv_loo,
          data = df, cluster = ~state_fips)
  }, error = function(e) NULL)

  if (!is.null(m_loo)) {
    cf <- coef(m_loo)
    se_val <- se(m_loo)
    f_val <- tryCatch(fitstat(m_loo, "ivf")$ivf$stat, error = function(e) NA)
    cat(sprintf("  Drop %s: coef=%.4f, se=%.4f, F=%.1f\n",
                chain_name, cf[1], se_val[1], f_val))
  }
  df[, iv_loo := NULL]
}


## ---- 7. Placebo: Pre-Chain-Bankruptcy Period ----
cat("\n=== Robustness 7: Pre-Chain Bankruptcy Placebo ===\n")

# Use chain bankruptcy timing: assign placebo 2 years before chain closure
df[, first_chain_year := fifelse(
  any(chain_closures > 0), min(year[chain_closures > 0]), NA_integer_),
  by = state_fips]

df[, placebo_chain := as.integer(
  !is.na(first_chain_year) & year >= (first_chain_year - 2) & year < first_chain_year)]

pre_chain_data <- df[is.na(first_chain_year) | year < first_chain_year]
if (nrow(pre_chain_data) > 10) {
  m_placebo <- feols(lbw_rate_100 ~ placebo_chain | state_fips + year,
                     data = pre_chain_data, cluster = ~state_fips)
  summary(m_placebo)
} else {
  cat("  Insufficient pre-chain-bankruptcy observations for placebo test.\n")
  m_placebo <- NULL
}


## ---- Save ----
rob_results <- list(
  cum_lbw = m_cum_lbw, cum_preterm = m_cum_preterm,
  log_lbw = m_log_lbw, log_preterm = m_log_preterm,
  nocovid_lbw = m_nc_lbw, nocovid_preterm = m_nc_preterm,
  weighted_lbw = m_wt_lbw, weighted_preterm = m_wt_preterm,
  placebo = m_placebo
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
