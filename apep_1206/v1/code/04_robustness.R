# 04_robustness.R — Robustness checks
source("code/00_packages.R")

df <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Placebo: Natural-person Steuerfuss (should not affect firms)
# ============================================================
cat("\n--- 1. Placebo: Natural-Person Tax ---\n")

# Load ZH data with natural-person Steuerfuss
zh_stf <- fread("data/zh_steuerfuss.csv")
if ("STF_O_KIRCHE1" %in% names(zh_stf)) {
  # STF_O_KIRCHE1 is natural-person Steuerfuss without church tax
  nat_stf <- zh_stf[, .(bfsnr = BFSNR, year = YEAR, stf_nat = STF_O_KIRCHE1)]
  nat_stf <- nat_stf[!is.na(stf_nat) & year >= 2011 & year <= 2023]

  nat_stf <- nat_stf[order(bfsnr, year)]
  nat_stf[, stf_nat_lag := shift(stf_nat, 1), by = bfsnr]
  nat_stf[, stf_nat_change := stf_nat - stf_nat_lag]
  nat_stf[, nat_cut := as.integer(!is.na(stf_nat_change) & stf_nat_change <= -5)]

  first_nat_cuts <- nat_stf[nat_cut == 1, .(first_nat_cut_year = min(year)), by = bfsnr]
  nat_stf <- merge(nat_stf, first_nat_cuts, by = "bfsnr", all.x = TRUE)
  nat_stf[, post_nat_cut := as.integer(!is.na(first_nat_cut_year) & year >= first_nat_cut_year)]

  df_placebo <- merge(df, nat_stf[, .(bfsnr, year, post_nat_cut)],
                       by = c("bfsnr", "year"), all.x = TRUE)
  df_placebo[is.na(post_nat_cut), post_nat_cut := 0]

  cat(sprintf("  Municipalities with nat-person cut: %d\n",
              uniqueN(nat_stf[!is.na(first_nat_cut_year)]$bfsnr)))

  placebo_m <- feols(log_emp_per_estab ~ post_nat_cut | bfsnr + year,
                     data = df_placebo, cluster = ~canton)
  cat("  Placebo effect on log(emp/estab):\n")
  print(summary(placebo_m))
} else {
  cat("  Natural-person Steuerfuss column not found, skipping placebo\n")
}

# ============================================================
# 2. Alternative clustering: municipality level
# ============================================================
cat("\n--- 2. Municipality-Level Clustering ---\n")
df[, post_cut := as.integer(!is.na(first_cut_year) & year >= first_cut_year)]

m_mun <- feols(log_emp_per_estab ~ post_cut | bfsnr + year,
               data = df, cluster = ~bfsnr)
m_mun_ter <- feols(log_emp_per_estab_ter ~ post_cut | bfsnr + year,
                   data = df[!is.na(log_emp_per_estab_ter)], cluster = ~bfsnr)

etable(m_mun, m_mun_ter,
       headers = c("Log(Emp/Est) [Mun]", "Log(Emp/Est Ter) [Mun]"))

# ============================================================
# 3. Leave-one-out by treated municipality
# ============================================================
cat("\n--- 3. Leave-One-Out by Treated Municipality ---\n")
treated_munis <- df[ever_cut == 1, unique(bfsnr)]
loo_betas <- numeric(length(treated_munis))

for (j in seq_along(treated_munis)) {
  m_loo <- feols(log_emp_per_estab ~ post_cut | bfsnr + year,
                 data = df[bfsnr != treated_munis[j]], cluster = ~bfsnr)
  loo_betas[j] <- coef(m_loo)["post_cut"]
}

cat(sprintf("  LOO range: [%.4f, %.4f], mean: %.4f\n",
            min(loo_betas), max(loo_betas), mean(loo_betas)))
cat(sprintf("  Main estimate: %.4f\n", coef(results$m1)["post_cut"]))

# ============================================================
# 4. Different cut thresholds
# ============================================================
cat("\n--- 4. Alternative Cut Thresholds ---\n")

for (thresh in c(3, 5, 10)) {
  df_t <- copy(df)
  stf_temp <- fread("data/analysis_panel.csv")
  # Recompute stf_change from the raw Steuerfuss
  stf_temp <- stf_temp[order(bfsnr, year)]
  stf_temp[, stf_change_r := steuerfuss - shift(steuerfuss, 1), by = bfsnr]
  stf_temp[, cut_t := as.integer(!is.na(stf_change_r) & stf_change_r <= -thresh)]
  fc <- stf_temp[cut_t == 1, .(fc_year = min(year)), by = bfsnr]
  stf_temp <- merge(stf_temp, fc, by = "bfsnr", all.x = TRUE)
  stf_temp[, post_t := as.integer(!is.na(fc_year) & year >= fc_year)]

  m_t <- feols(log_emp_per_estab ~ post_t | bfsnr + year,
               data = stf_temp, cluster = ~bfsnr)
  n_treat <- uniqueN(stf_temp[!is.na(fc_year)]$bfsnr)
  cat(sprintf("  Threshold >= %dpp: beta = %.4f (SE %.4f), treated = %d\n",
              thresh, coef(m_t)["post_t"], se(m_t)["post_t"], n_treat))
}

# ============================================================
# 5. Secondary sector placebo (should show null — no letterbox)
# ============================================================
cat("\n--- 5. Secondary Sector Placebo ---\n")
df[, log_emp_per_estab_sec := log(emp_sec / estab_sec)]

m_sec <- feols(log_emp_per_estab_sec ~ post_cut | bfsnr + year,
               data = df[!is.na(log_emp_per_estab_sec)], cluster = ~canton)
cat("  Secondary sector effect:\n")
etable(m_sec)

# ============================================================
# 6. Population control
# ============================================================
cat("\n--- 6. Population Control ---\n")
df[, log_pop := log(population)]
m_pop <- feols(log_emp_per_estab ~ post_cut + log_pop | bfsnr + year,
               data = df[!is.na(log_pop)], cluster = ~canton)
m_pop_ter <- feols(log_emp_per_estab_ter ~ post_cut + log_pop | bfsnr + year,
                   data = df[!is.na(log_pop) & !is.na(log_emp_per_estab_ter)],
                   cluster = ~canton)
etable(m_pop, m_pop_ter,
       headers = c("Log(Emp/Est) + Pop", "Log(Emp/Est Ter) + Pop"))

# Save robustness results
rob_results <- list(
  placebo = if (exists("placebo_m")) placebo_m else NULL,
  m_mun = m_mun, m_mun_ter = m_mun_ter,
  m_sec = m_sec,
  m_pop = m_pop, m_pop_ter = m_pop_ter
)
saveRDS(rob_results, "data/robustness_results.rds")
cat("\nRobustness results saved.\n")
