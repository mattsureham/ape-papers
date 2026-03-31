# 03_main_analysis.R — Main empirical analysis
# apep_1229: GIPP and Insurance Market Competition

source("00_packages.R")

data_dir <- "../data/"
cpih <- readRDS(paste0(data_dir, "cpih_panel.rds"))
fca  <- readRDS(paste0(data_dir, "fca_panel.rds"))

# ============================================================================
# 1. CPIH Insurance Price Event Study
# ============================================================================
# Monthly insurance price index event study around GIPP (Jan 2022)
# Estimate: log(Insurance_t) = α + Σ_k β_k * 1[event_time = k] + γ * log(CPIH_t) + ε_t

cat("=== 1. CPIH Insurance Event Study ===\n")

# Focus on 2015-2026 window (avoid too-distant pre-period)
cpih_est <- cpih %>%
  filter(year >= 2015, year <= 2025) %>%
  mutate(
    log_transport_ins = log(transport_ins),
    log_house_ins = log(house_ins),
    log_health_ins = log(health_ins),
    log_insurance = log(insurance),
    log_cpih = log(cpih_all),
    # Bin event time into 6-month bins
    event_bin = case_when(
      event_time < -36 ~ -36L,
      event_time >= 48 ~ 48L,
      TRUE ~ as.integer(floor(event_time / 6) * 6)
    ),
    event_bin_f = factor(event_bin)
  )

# Reference period: -12 to -7 (6 months before treatment)
cpih_est$event_bin_f <- relevel(cpih_est$event_bin_f, ref = "-12")

# Model 1: Transport insurance relative to overall CPIH
# Simple OLS event study
m1_transport <- feols(log_transport_ins ~ event_bin_f + log_cpih,
                      data = cpih_est, vcov = "hetero")

cat("\nModel 1: Transport Insurance Event Study\n")
cat("Key post-GIPP coefficients:\n")
coefs <- coef(m1_transport)
ses   <- se(m1_transport)
for (nm in names(coefs)) {
  if (grepl("event_bin_f(0|6|12|18|24|30|36|42)", nm)) {
    cat(sprintf("  %s: %.4f (%.4f)\n", nm, coefs[nm], ses[nm]))
  }
}

# Model 2: House contents insurance (also treated by GIPP)
m2_house <- feols(log_house_ins ~ event_bin_f + log_cpih,
                  data = cpih_est, vcov = "hetero")

# Model 3: Health insurance (also under GIPP but different market structure)
m3_health <- feols(log_health_ins ~ event_bin_f + log_cpih,
                   data = cpih_est, vcov = "hetero")

# ============================================================================
# 2. Difference-in-Differences: Transport vs Health Insurance
# ============================================================================
# Treat transport insurance as "heavily treated" (motor = core GIPP target)
# Use health insurance as "lightly treated" control (GIPP applies but less
# relevant since health insurance switching is rare)

cat("\n=== 2. DiD: Transport vs Health Insurance ===\n")

cpih_long <- cpih_est %>%
  select(date, year, month, event_time, post_gipp, log_cpih,
         log_transport_ins, log_health_ins) %>%
  pivot_longer(
    cols = c(log_transport_ins, log_health_ins),
    names_to = "series",
    values_to = "log_index"
  ) %>%
  mutate(
    is_transport = as.integer(series == "log_transport_ins"),
    treat_post = is_transport * post_gipp,
    # For stacked interactions with time
    event_bin = case_when(
      event_time < -36 ~ -36L,
      event_time >= 48 ~ 48L,
      TRUE ~ as.integer(floor(event_time / 6) * 6)
    ),
    event_bin_f = factor(event_bin)
  )

# Simple DiD
m4_did <- feols(log_index ~ treat_post + is_transport + post_gipp + log_cpih,
                data = cpih_long, vcov = "hetero")
cat("DiD estimate (Transport × Post):", round(coef(m4_did)["treat_post"], 4),
    "(", round(se(m4_did)["treat_post"], 4), ")\n")

# Dynamic DiD
cpih_long$event_bin_f <- relevel(cpih_long$event_bin_f, ref = "-12")
m5_dynamic_did <- feols(log_index ~ i(event_bin_f, is_transport, ref = "-12") +
                          is_transport + log_cpih,
                        data = cpih_long, vcov = "hetero")

cat("\nDynamic DiD coefficients (Transport × Time):\n")
coefs5 <- coef(m5_dynamic_did)
ses5 <- se(m5_dynamic_did)
for (nm in names(coefs5)) {
  if (grepl("event_bin_f", nm) && grepl("is_transport", nm)) {
    cat(sprintf("  %s: %.4f (%.4f)\n", nm, coefs5[nm], ses5[nm]))
  }
}

# ============================================================================
# 3. FCA Loss Ratio Analysis (Mechanism)
# ============================================================================

cat("\n=== 3. FCA Loss Ratio Mechanism Test ===\n")

# Cross-product comparison: treated (Motor+Home) vs control products
fca_summary <- fca %>%
  group_by(product_group, year) %>%
  summarise(
    n_products = n(),
    mean_lr = mean(loss_ratio, na.rm = TRUE),
    median_lr = median(loss_ratio, na.rm = TRUE),
    total_premiums = sum(premiums, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nLoss ratios by product group and year:\n")
print(fca_summary, n = 20)

# Regression: loss ratio on treated indicator
m6_lr <- lm(loss_ratio ~ treated * factor(year), data = fca)
cat("\nLoss ratio regression:\n")
summary(m6_lr)

# Premium-weighted analysis
m7_lr_weighted <- lm(loss_ratio ~ treated * factor(year), data = fca,
                     weights = premiums)
cat("\nPremium-weighted loss ratio regression:\n")
summary(m7_lr_weighted)

# ============================================================================
# 4. Magnitude decomposition: price increase vs claims increase
# ============================================================================

cat("\n=== 4. Price Decomposition ===\n")

# Calculate cumulative price increases from Dec 2021
dec2021 <- cpih %>% filter(date == as.Date("2021-12-01"))
dec2023 <- cpih %>% filter(date == as.Date("2023-12-01"))
feb2026 <- cpih %>% filter(date == max(cpih$date))

cat("Cumulative % changes from Dec 2021:\n")
for (var in c("cpih_all", "insurance", "transport_ins", "house_ins", "health_ins")) {
  pct_23 <- (dec2023[[var]] / dec2021[[var]] - 1) * 100
  pct_latest <- (feb2026[[var]] / dec2021[[var]] - 1) * 100
  cat(sprintf("  %-15s: +%.1f%% by Dec 2023, +%.1f%% by %s\n",
              var, pct_23, pct_latest, as.character(max(cpih$date))))
}

# Compare transport insurance price increase with FCA motor loss ratio
# If prices rose 83% but loss ratio only changed modestly, firms captured surplus
motor_lr_2023 <- fca %>% filter(product == "Motor (All)", year == 2023) %>% pull(loss_ratio)
motor_lr_2024 <- fca %>% filter(product == "Motor (All)", year == 2024) %>% pull(loss_ratio)

cat("\nMotor insurance decomposition:\n")
cat("  Transport ins price: +",
    round((dec2023$transport_ins / dec2021$transport_ins - 1) * 100, 1), "% (Dec 2021 to Dec 2023)\n")
if (length(motor_lr_2023) > 0) {
  cat("  Motor loss ratio 2023:", round(motor_lr_2023, 3),
      "(firms retain", round((1 - motor_lr_2023) * 100, 1), "% of premiums)\n")
}
if (length(motor_lr_2024) > 0) {
  cat("  Motor loss ratio 2024:", round(motor_lr_2024, 3),
      "(firms retain", round((1 - motor_lr_2024) * 100, 1), "% of premiums)\n")
}

# ============================================================================
# 5. Write diagnostics.json
# ============================================================================

# For the CPIH time series analysis
n_pre <- sum(cpih_est$event_time < 0, na.rm = TRUE)
n_post <- sum(cpih_est$event_time >= 0, na.rm = TRUE)
n_series <- 2  # transport and health in DiD

diagnostics <- list(
  n_treated = n_series,  # 2 insurance types compared
  n_pre = n_pre,        # months before GIPP
  n_obs = nrow(cpih_long),
  n_products_fca = nrow(fca),
  n_firms_fca = n_distinct(fca$product),
  treatment_date = "2022-01-01",
  pre_months = n_pre,
  post_months = n_post
)

jsonlite::write_json(diagnostics, paste0(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

# Save model objects for table generation
save(m1_transport, m2_house, m3_health, m4_did, m5_dynamic_did,
     m6_lr, m7_lr_weighted, cpih_est, cpih_long, fca,
     file = paste0(data_dir, "models.RData"))

cat("\n=== Analysis complete. Models saved to data/models.RData ===\n")
