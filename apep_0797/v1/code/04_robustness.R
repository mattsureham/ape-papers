# 04_robustness.R — Robustness checks
# APEP paper apep_0797: ECOWAS Sanctions and Food Market Fragmentation in Niger

source("00_packages.R")

data_dir <- "../data"
dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt[, date_parsed := as.Date(date_parsed)]
dt[, tradable := as.integer(commodity_clean %in% c("Rice (imported)", "Rice (local)"))]
dt[, niger := as.integer(country == "Niger")]
dt[, ln_price := log(price)]

# ======================================================================
# ROBUSTNESS 1: Placebo test — false treatment Aug 2022
# Use the less saturated model (Model 2 style) to avoid singleton issues
# ======================================================================
message("=== Robustness 1: Placebo (Aug 2022) ===")

dt_placebo <- dt[commodity_clean %in% c("Rice (imported)", "Millet") &
  date_parsed >= "2022-01-01" & date_parsed < "2023-08-01"]
dt_placebo[, post_placebo := as.integer(date_parsed >= "2022-08-01")]
dt_placebo[, market_commodity := paste(country, market, commodity_clean, sep = "_")]
dt_placebo[, ym := format(date_parsed, "%Y-%m")]

r1 <- feols(ln_price ~ niger:tradable:post_placebo |
  market_commodity + ym,
  data = dt_placebo,
  cluster = ~market)
summary(r1)

# ======================================================================
# ROBUSTNESS 2: Alternative local controls
# ======================================================================
message("\n=== Robustness 2a: Rice vs Sorghum ===")
dt_sorg <- dt[commodity_clean %in% c("Rice (imported)", "Sorghum")]
dt_sorg[, market_commodity := paste(country, market, commodity_clean, sep = "_")]
dt_sorg[, ym := format(date_parsed, "%Y-%m")]
dt_sorg[, post_sanctions := as.integer(date_parsed >= "2023-08-01")]

r2a <- feols(ln_price ~ niger:tradable:post_sanctions |
  market_commodity + ym,
  data = dt_sorg,
  cluster = ~market)
summary(r2a)

message("\n=== Robustness 2b: Rice vs Maize ===")
dt_maize <- dt[commodity_clean %in% c("Rice (imported)", "Maize")]
dt_maize[, market_commodity := paste(country, market, commodity_clean, sep = "_")]
dt_maize[, ym := format(date_parsed, "%Y-%m")]
dt_maize[, post_sanctions := as.integer(date_parsed >= "2023-08-01")]

r2b <- feols(ln_price ~ niger:tradable:post_sanctions |
  market_commodity + ym,
  data = dt_maize,
  cluster = ~market)
summary(r2b)

# ======================================================================
# ROBUSTNESS 3: Price dispersion (market integration measure)
# ======================================================================
message("\n=== Robustness 3: Price dispersion ===")

dispersion <- dt[commodity_clean %in% c("Rice (imported)", "Millet"),
  .(cv_price = sd(price, na.rm = TRUE) / mean(price, na.rm = TRUE),
    n_markets = .N),
  by = .(country, commodity_clean, ym = format(date_parsed, "%Y-%m"))]
dispersion[, `:=`(
  niger = as.integer(country == "Niger"),
  tradable = as.integer(commodity_clean == "Rice (imported)"),
  post_sanctions = as.integer(ym >= "2023-08"),
  country_commodity = paste(country, commodity_clean, sep = "_")
)]

r3 <- feols(cv_price ~ niger:tradable:post_sanctions |
  country_commodity + ym,
  data = dispersion[n_markets >= 3],
  cluster = ~country_commodity)
summary(r3)

# ======================================================================
# ROBUSTNESS 4: Permutation inference (randomize country assignment)
# ======================================================================
message("\n=== Robustness 4: Permutation inference ===")

load(file.path(data_dir, "models.RData"))

set.seed(42)
n_perms <- 500
perm_coefs <- numeric(n_perms)

dt_perm_base <- dt_main[, .(ln_price, market, commodity_clean, ym,
  tradable, post_sanctions, market_commodity)]

markets_list <- unique(dt_perm_base$market)
niger_markets <- unique(dt_main[niger == 1, market])
n_niger <- length(niger_markets)

for (i in seq_len(n_perms)) {
  perm_niger <- sample(markets_list, n_niger)
  dt_p <- copy(dt_perm_base)
  dt_p[, niger_perm := as.integer(market %in% perm_niger)]

  m_perm <- tryCatch(
    feols(ln_price ~ niger_perm:tradable:post_sanctions |
      market_commodity + ym,
      data = dt_p,
      cluster = ~market,
      notes = FALSE, warn = FALSE),
    error = function(e) NULL
  )
  if (!is.null(m_perm) && length(coef(m_perm)) > 0) {
    perm_coefs[i] <- coef(m_perm)[[1]]
  } else {
    perm_coefs[i] <- NA
  }
  if (i %% 100 == 0) message(sprintf("  Permutation %d/%d done", i, n_perms))
}

actual_coef <- coef(m2)[["niger:tradable:post_sanctions"]]
perm_pval <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
message(sprintf("Actual triple-diff coefficient: %.4f", actual_coef))
message(sprintf("Permutation p-value (2-sided): %.4f (based on %d valid permutations)",
  perm_pval, sum(!is.na(perm_coefs))))
message(sprintf("Permutation distribution: mean=%.4f, sd=%.4f",
  mean(perm_coefs, na.rm = TRUE), sd(perm_coefs, na.rm = TRUE)))

# ======================================================================
# ROBUSTNESS 5: Exclude Niamey (capital, may have different supply chains)
# ======================================================================
message("\n=== Robustness 5: Exclude Niamey ===")

dt_no_niamey <- dt_main[!grepl("Niamey", market, ignore.case = TRUE)]
dt_no_niamey[, market_commodity := paste(country, market, commodity_clean, sep = "_")]
dt_no_niamey[, ym := format(date_parsed, "%Y-%m")]

r5 <- feols(ln_price ~ niger:tradable:post_sanctions |
  market_commodity + ym,
  data = dt_no_niamey,
  cluster = ~market)
summary(r5)

# ======================================================================
# SAVE
# ======================================================================
save(r1, r2a, r2b, r3, r5, perm_coefs, perm_pval, actual_coef, dispersion,
  file = file.path(data_dir, "robustness.RData"))
message("\nAll robustness results saved.")
