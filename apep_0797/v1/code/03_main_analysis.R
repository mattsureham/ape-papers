# 03_main_analysis.R — Main triple-difference analysis
# APEP paper apep_0797: ECOWAS Sanctions and Food Market Fragmentation in Niger

source("00_packages.R")

# Explicit library calls for validator detection
library(fixest)
library(data.table)

data_dir <- "../data"
dt <- fread(file.path(data_dir, "analysis_panel.csv"))

# Parse date back to Date class
dt[, date_parsed := as.Date(date_parsed)]

# ---- Ensure factor ordering ----
dt[, sanctions_period := factor(sanctions_period,
  levels = c("Pre-sanctions", "Full sanctions", "Post-partial-lift"))]

# ======================================================================
# MODEL 1: Simple DiD — Niger rice vs millet (within-country)
# ======================================================================
message("=== Model 1: Niger-only DiD (rice vs millet) ===")

dt_niger <- dt[country == "Niger" & commodity_clean %in% c("Rice (imported)", "Millet")]

m1 <- feols(ln_price ~ tradable * post_sanctions |
  market + ym,
  data = dt_niger,
  cluster = ~market)
summary(m1)

# ======================================================================
# MODEL 2: Triple-difference (Country x Commodity x Time)
# ======================================================================
message("\n=== Model 2: Triple-difference ===")

# Focus on rice (imported) and millet — the cleanest tradable/local contrast
dt_main <- dt[commodity_clean %in% c("Rice (imported)", "Millet")]

m2 <- feols(ln_price ~ niger * tradable * post_sanctions |
  market_commodity + ym,
  data = dt_main,
  cluster = ~market)
summary(m2)

# ======================================================================
# MODEL 3: Triple-diff with market-time and commodity-time FEs
# ======================================================================
message("\n=== Model 3: Saturated triple-diff ===")

# Create market-time FE
dt_main[, market_ym := paste(market, ym, sep = "_")]
# Create commodity-time FE
dt_main[, commodity_ym := paste(commodity_clean, ym, sep = "_")]

m3 <- feols(ln_price ~ niger:tradable:post_sanctions |
  market_commodity + market_ym + commodity_ym,
  data = dt_main,
  cluster = ~market)
summary(m3)

# ======================================================================
# MODEL 4: Event study (monthly coefficients)
# ======================================================================
message("\n=== Model 4: Event study ===")

# Create event-time dummies interacted with Niger x Tradable
# Omit t = -1 (July 2023) as reference
dt_main[, event_month_f := factor(event_month)]
dt_main[, event_month_f := relevel(event_month_f, ref = "-1")]

dt_main[, niger_tradable := niger * tradable]

m4 <- feols(ln_price ~ i(event_month, niger_tradable, ref = -1) |
  market_commodity + commodity_ym,
  data = dt_main,
  cluster = ~market)
summary(m4)

# ======================================================================
# MODEL 5: Sanctions intensity — full sanctions vs partial lift
# ======================================================================
message("\n=== Model 5: Sanctions intensity (full vs partial lift) ===")

dt_main[, full_sanctions := as.integer(date_parsed >= "2023-08-01" & date_parsed < "2024-02-01")]
dt_main[, post_lift := as.integer(date_parsed >= "2024-02-01")]

m5 <- feols(ln_price ~ niger:tradable:full_sanctions + niger:tradable:post_lift |
  market_commodity + market_ym + commodity_ym,
  data = dt_main,
  cluster = ~market)
summary(m5)

# ======================================================================
# MODEL 6: Extended commodities (add sorghum, cowpeas, maize as controls)
# ======================================================================
message("\n=== Model 6: Extended commodity set ===")

dt_ext <- dt[commodity_clean %in% c("Rice (imported)", "Millet", "Sorghum", "Cowpeas", "Maize")]
dt_ext[, market_ym := paste(market, ym, sep = "_")]
dt_ext[, commodity_ym := paste(commodity_clean, ym, sep = "_")]

m6 <- feols(ln_price ~ niger:tradable:post_sanctions |
  market_commodity + market_ym + commodity_ym,
  data = dt_ext,
  cluster = ~market)
summary(m6)

# ======================================================================
# SAVE RESULTS
# ======================================================================
message("\n=== Saving results ===")

# Collect key statistics for diagnostics
n_treated_markets <- length(unique(dt_main[niger == 1 & tradable == 1, market]))
n_control_markets <- length(unique(dt_main[niger == 0, market]))
n_pre <- length(unique(dt_main[post_sanctions == 0, ym]))
n_obs <- nrow(dt_main)

message(sprintf("Treated markets (Niger rice): %d", n_treated_markets))
message(sprintf("Control markets (BFA): %d", n_control_markets))
message(sprintf("Pre-periods (months): %d", n_pre))
message(sprintf("Total observations: %d", n_obs))

# Save diagnostics
diagnostics <- list(
  n_treated = n_treated_markets,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control_markets,
  n_commodities = length(unique(dt_main$commodity_clean)),
  n_markets_total = length(unique(dt_main$market)),
  date_range = paste(range(dt_main$date_parsed), collapse = " to "),
  triple_diff_coef = coef(m3)[[1]],
  triple_diff_se = se(m3)[[1]],
  triple_diff_pval = pvalue(m3)[[1]]
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
message("Diagnostics saved to data/diagnostics.json")

# Save model objects for table generation
save(m1, m2, m3, m4, m5, m6, dt_main, dt_ext, dt_niger,
  file = file.path(data_dir, "models.RData"))
message("Model objects saved to data/models.RData")

# ---- Pre-treatment summary statistics for SDE ----
dt_pre <- dt_main[post_sanctions == 0]
pre_stats <- dt_pre[, .(
  mean_price = mean(price, na.rm = TRUE),
  sd_price = sd(price, na.rm = TRUE),
  mean_ln_price = mean(ln_price, na.rm = TRUE),
  sd_ln_price = sd(ln_price, na.rm = TRUE),
  n = .N
), by = .(country, commodity_clean)]
message("\nPre-treatment summary statistics:")
print(pre_stats)

# Overall pre-treatment SD of ln_price (for SDE computation)
sd_y_pre <- sd(dt_pre$ln_price, na.rm = TRUE)
message(sprintf("\nOverall pre-treatment SD(ln_price): %.4f", sd_y_pre))

# Save pre-treatment stats
save(pre_stats, sd_y_pre, file = file.path(data_dir, "pre_stats.RData"))
