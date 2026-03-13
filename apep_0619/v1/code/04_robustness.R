## 04_robustness.R — Robustness checks
## APEP Paper apep_0619: H-1B Visa Lottery and Firm R&D Investment

source("00_packages.R")

data_dir <- "../data"
est_sample <- readRDS(file.path(data_dir, "est_sample.rds"))

cat("=== Robustness Checks ===\n")

post_h0 <- est_sample |> filter(horizon == 0)

# ---- 1. Dose-Response: High vs Low H-1B Dependence ----
cat("\n--- Dose-Response by H-1B Dependence ---\n")

if (sum(!is.na(post_h0$log_rd)) > 20) {
  # Interaction with H-1B intensity
  m_dose <- feols(log_rd ~ win_rate * high_h1b_dependence + log(n_registered) | fiscal_year,
                   data = post_h0, vcov = ~cik)
  cat("Interaction with high H-1B dependence:\n")
  print(summary(m_dose))
}

# ---- 2. Registration Threshold Sensitivity ----
cat("\n--- Registration Threshold Sensitivity ---\n")

for (thresh in c(3, 5, 10, 20, 50)) {
  sub <- est_sample |>
    filter(horizon == 0, n_registered >= thresh)
  if (sum(!is.na(sub$log_rd)) > 10) {
    m <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
               data = sub, vcov = ~cik)
    cat(sprintf("  Threshold >= %d: beta=%.4f (se=%.4f), N=%d, firms=%d\n",
                thresh, coef(m)["win_rate"], se(m)["win_rate"],
                m$nobs, length(unique(sub$cik))))
  }
}

# ---- 3. Placebo: Pre-Lottery Outcomes ----
cat("\n--- Placebo: Pre-Lottery Outcomes ---\n")

pre_data <- est_sample |>
  filter(horizon < 0) |>
  group_by(cik, fiscal_year) |>
  summarize(
    win_rate = first(win_rate),
    n_registered = first(n_registered),
    log_rd = mean(log_rd, na.rm = TRUE),
    log_rev = mean(log_rev, na.rm = TRUE),
    .groups = "drop"
  )

if (nrow(pre_data) > 10 && sum(is.finite(pre_data$log_rd)) > 5) {
  m_placebo <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                      data = pre_data[is.finite(pre_data$log_rd), ],
                      vcov = ~cik)
  cat("Placebo (pre-lottery R&D):\n")
  print(summary(m_placebo))
}

if (nrow(pre_data) > 10 && sum(is.finite(pre_data$log_rev)) > 5) {
  m_placebo_rev <- feols(log_rev ~ win_rate + log(n_registered) | fiscal_year,
                          data = pre_data[is.finite(pre_data$log_rev), ],
                          vcov = ~cik)
  cat("\nPlacebo (pre-lottery Revenue):\n")
  print(summary(m_placebo_rev))
}

# ---- 4. Alternative Outcome Measures ----
cat("\n--- Alternative Outcomes ---\n")

# Level R&D (millions, winsorized)
if (sum(!is.na(post_h0$rd_millions_w)) > 10) {
  m_level <- feols(rd_millions_w ~ win_rate + log(n_registered) | fiscal_year,
                    data = post_h0, vcov = ~cik)
  cat("R&D level (millions, winsorized):\n")
  print(summary(m_level))
}

# Operating income
if (sum(!is.na(post_h0$opinc_millions)) > 10) {
  m_opinc <- feols(opinc_millions ~ win_rate + log(n_registered) | fiscal_year,
                    data = post_h0, vcov = ~cik)
  cat("\nOperating income (millions):\n")
  print(summary(m_opinc))
}

# PP&E (capital investment proxy)
if (sum(!is.na(post_h0$ppe_millions)) > 10) {
  m_ppe <- feols(ppe_millions ~ win_rate + log(n_registered) | fiscal_year,
                  data = post_h0, vcov = ~cik)
  cat("\nPP&E (millions):\n")
  print(summary(m_ppe))
}

# ---- 5. Alternative Clustering ----
cat("\n--- Alternative Clustering ---\n")

if (sum(!is.na(post_h0$log_rd)) > 10) {
  # State clustering
  m_state <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                    data = post_h0, vcov = "hetero")
  cat("Heteroskedasticity-robust SE:\n")
  cat(sprintf("  beta=%.4f (se=%.4f)\n",
              coef(m_state)["win_rate"], se(m_state)["win_rate"]))

  # Industry clustering
  m_ind <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                  data = post_h0, vcov = ~sic_2d)
  cat("Industry-clustered SE:\n")
  cat(sprintf("  beta=%.4f (se=%.4f)\n",
              coef(m_ind)["win_rate"], se(m_ind)["win_rate"]))
}

# ---- 6. Weighted Regression (by registration count) ----
cat("\n--- Weighted Regression (inverse binomial variance) ---\n")

if (sum(!is.na(post_h0$log_rd)) > 20) {
  # Weight by number of registrations (proportional to precision of win rate)
  m_weighted <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                       data = post_h0, vcov = ~cik,
                       weights = ~n_registered)
  cat("Registration-weighted:\n")
  cat(sprintf("  beta=%.4f (se=%.4f), N=%d\n",
              coef(m_weighted)["win_rate"], se(m_weighted)["win_rate"],
              m_weighted$nobs))
}

# ---- 7. Stratified Estimation by Registration Bins ----
cat("\n--- Stratified by Registration Count ---\n")

bins <- list(
  "5-9"   = c(5, 9),
  "10-24" = c(10, 24),
  "25+"   = c(25, Inf)
)

strat_results <- list()
for (b in names(bins)) {
  sub <- post_h0 |>
    filter(n_registered >= bins[[b]][1], n_registered <= bins[[b]][2])
  if (sum(!is.na(sub$log_rd)) > 10) {
    m_b <- feols(log_rd ~ win_rate + log(n_registered) | fiscal_year,
                  data = sub, vcov = ~cik)
    strat_results[[b]] <- m_b
    cat(sprintf("  Bin %s: beta=%.4f (se=%.4f), N=%d, firms=%d\n",
                b, coef(m_b)["win_rate"], se(m_b)["win_rate"],
                m_b$nobs, length(unique(sub$cik))))
  } else {
    cat(sprintf("  Bin %s: insufficient R&D observations\n", b))
  }
}

# ---- 8. Save robustness results ----
rob_results <- list()
if (exists("m_dose")) rob_results$dose <- m_dose
if (exists("m_placebo")) rob_results$placebo_rd <- m_placebo
if (exists("m_placebo_rev")) rob_results$placebo_rev <- m_placebo_rev
if (exists("m_level")) rob_results$rd_level <- m_level
if (exists("m_opinc")) rob_results$opinc <- m_opinc
if (exists("m_ppe")) rob_results$ppe <- m_ppe
if (exists("m_weighted")) rob_results$weighted <- m_weighted
rob_results$stratified <- strat_results

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
