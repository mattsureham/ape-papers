## 03_main_analysis.R — Main regressions: H-1B lottery → firm R&D
## APEP Paper apep_0619: H-1B Visa Lottery and Firm R&D Investment

source("00_packages.R")
library(fixest)
library(data.table)
library(dplyr)

data_dir <- "../data"
est_sample <- readRDS(file.path(data_dir, "est_sample.rds"))

cat("=== Main Analysis: Lottery Win Rate → Financial Outcomes ===\n")
cat(sprintf("Panel: %d obs, %d firms\n", nrow(est_sample), length(unique(est_sample$cik))))

# ---- 1. Balance Test: Pre-lottery characteristics ----
cat("\n--- Balance Test: Pre-period outcomes vs win rate ---\n")

pre_data <- est_sample |>
  filter(horizon < 0) |>
  group_by(cik, fiscal_year) |>
  summarize(
    win_rate = first(win_rate),
    n_registered = first(n_registered),
    mean_rd = mean(rd_millions, na.rm = TRUE),
    mean_rev = mean(rev_millions, na.rm = TRUE),
    mean_assets = mean(assets_millions, na.rm = TRUE),
    is_tech = first(is_tech),
    .groups = "drop"
  )

if (nrow(pre_data) > 10) {
  bal_rd <- feols(mean_rd ~ win_rate | fiscal_year, data = pre_data, vcov = "hetero")
  bal_rev <- feols(mean_rev ~ win_rate | fiscal_year, data = pre_data, vcov = "hetero")
  bal_assets <- feols(mean_assets ~ win_rate | fiscal_year, data = pre_data, vcov = "hetero")

  cat("Balance on pre-period R&D:\n")
  print(summary(bal_rd))
  cat("\nBalance on pre-period Revenue:\n")
  print(summary(bal_rev))
}

# ---- 2. Reduced-Form: Win Rate → Outcomes ----
cat("\n--- Reduced-Form Regressions ---\n")

# Concurrent year (horizon = 0)
post_h0 <- est_sample |> filter(horizon == 0)
# One year later (horizon = 1)
post_h1 <- est_sample |> filter(horizon == 1)
# Two years later (horizon = 2)
post_h2 <- est_sample |> filter(horizon == 2)

## Main specification: log R&D = f(win_rate) + firm FE + year FE
# Since we have at most 2 lottery years per firm, firm FE is absorptive.
# Use pooled OLS with year FE as baseline; add industry FE for robustness.

# --- Specification 1: Pooled OLS with year FE ---
if (nrow(post_h0) > 20 && sum(!is.na(post_h0$log_rd)) > 10) {
  m1_rd <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                  data = post_h0, vcov = ~cik)
  cat("\n[1] log(R&D) ~ win_rate + log(registrations) | year FE:\n")
  print(summary(m1_rd))
} else {
  cat("WARNING: Insufficient R&D observations for horizon 0.\n")
  # Fall back to revenue
  m1_rd <- NULL
}

# --- Revenue ---
if (sum(!is.na(post_h0$log_rev)) > 10) {
  m1_rev <- feols(log_rev ~ win_rate + log(n_registered) | fiscal_year,
                   data = post_h0, vcov = ~cik)
  cat("\n[2] log(Revenue) ~ win_rate + log(registrations) | year FE:\n")
  print(summary(m1_rev))
}

# --- Assets ---
if (sum(!is.na(post_h0$log_assets)) > 10) {
  m1_assets <- feols(log_assets ~ win_rate + log(n_registered) | fiscal_year,
                      data = post_h0, vcov = ~cik)
  cat("\n[3] log(Assets) ~ win_rate + log(registrations) | year FE:\n")
  print(summary(m1_assets))
}

# --- R&D intensity ---
if (sum(!is.na(post_h0$rd_intensity)) > 10) {
  m1_rdi <- feols(rd_intensity ~ win_rate + log(n_registered) | fiscal_year,
                   data = post_h0, vcov = ~cik)
  cat("\n[4] R&D/Revenue ~ win_rate + log(registrations) | year FE:\n")
  print(summary(m1_rdi))
}

# --- Specification 2: With industry × year FE ---
if (sum(!is.na(post_h0$log_rd)) > 20) {
  m2_rd <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year + sic_2d,
                  data = post_h0, vcov = ~cik)
  cat("\n[5] log(R&D) ~ win_rate | year + industry FE:\n")
  print(summary(m2_rd))
}

# --- Specification 3: Firm FE (if >1 lottery year per firm) ---
multi_year_firms <- post_h0 |>
  group_by(cik) |>
  filter(n() > 1) |>
  ungroup()

if (nrow(multi_year_firms) > 20 && sum(!is.na(multi_year_firms$log_rd)) > 10) {
  m3_rd <- feols(log_rd ~ win_rate + log(n_registered) | cik + fiscal_year,
                  data = multi_year_firms, vcov = ~cik)
  cat("\n[6] log(R&D) ~ win_rate | firm FE + year FE (within-firm):\n")
  print(summary(m3_rd))
} else {
  cat("\nInsufficient multi-year firms for firm FE specification.\n")
  m3_rd <- NULL
}

# ---- 3. Dynamic Effects: Horizons 0, 1, 2 ----
cat("\n--- Dynamic Effects Across Horizons ---\n")

for (h in 0:2) {
  h_data <- est_sample |> filter(horizon == h)
  if (nrow(h_data) > 20 && sum(!is.na(h_data$log_rd)) > 5) {
    mh <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                data = h_data, vcov = ~cik)
    cat(sprintf("\n  Horizon h=%d: beta=%.4f (se=%.4f), N=%d\n",
                h, coef(mh)["win_rate"], se(mh)["win_rate"],
                mh$nobs))
  } else {
    cat(sprintf("\n  Horizon h=%d: insufficient data\n", h))
  }
}

# ---- 4. Heterogeneity: Tech vs Non-Tech ----
cat("\n--- Heterogeneity: Tech vs Non-Tech ---\n")

if (sum(!is.na(post_h0$log_rd) & post_h0$is_tech) > 10) {
  m_tech <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                   data = post_h0 |> filter(is_tech), vcov = ~cik)
  cat("\nTech firms only:\n")
  print(summary(m_tech))
}

if (sum(!is.na(post_h0$log_rd) & !post_h0$is_tech) > 10) {
  m_nontech <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                      data = post_h0 |> filter(!is_tech), vcov = ~cik)
  cat("\nNon-tech firms only:\n")
  print(summary(m_nontech))
}

# ---- 5. Save regression objects ----
results <- list()
if (exists("m1_rd") && !is.null(m1_rd)) results$m1_rd <- m1_rd
if (exists("m1_rev")) results$m1_rev <- m1_rev
if (exists("m1_assets")) results$m1_assets <- m1_assets
if (exists("m1_rdi")) results$m1_rdi <- m1_rdi
if (exists("m2_rd")) results$m2_rd <- m2_rd
if (exists("m3_rd") && !is.null(m3_rd)) results$m3_rd <- m3_rd
if (exists("m_tech")) results$m_tech <- m_tech
if (exists("m_nontech")) results$m_nontech <- m_nontech
if (exists("bal_rd")) results$bal_rd <- bal_rd

saveRDS(results, file.path(data_dir, "regression_results.rds"))

# ---- 6. Write diagnostics ----
n_treated <- length(unique(post_h0$cik[post_h0$win_rate > 0.5]))
n_control <- length(unique(post_h0$cik[post_h0$win_rate <= 0.5]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = 3L,  # 3 pre-lottery years
  n_obs = nrow(post_h0),
  n_firms = length(unique(post_h0$cik)),
  n_lottery_years = length(unique(post_h0$fiscal_year)),
  design = "IV/reduced-form: H-1B lottery win rate"
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Analysis complete. Results saved. ===\n")
