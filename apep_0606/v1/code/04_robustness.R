## 04_robustness.R — Robustness checks
## APEP-0606: Cross-Substance Spillovers of Cigarette Excise Taxes

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
panel[, treated := as.integer(first_treat_year > 0 & year >= first_treat_year)]
cat("Loaded panel:", nrow(panel), "state-year obs\n")

results <- list()

# =============================================================================
# 1. Alternative treatment thresholds
# =============================================================================
cat("\n=== ALTERNATIVE THRESHOLDS ===\n")
cdc <- readRDS("../data/cdc_tax_raw.rds")
cdc[, year := as.integer(year)]
cdc[, tax_per_pack := as.numeric(data_value)]
cdc[, state_name := locationdesc]
cdc <- cdc[state_name != "United States"]
cdc <- cdc[order(state_name, year)]
cdc[, tax_change := tax_per_pack - shift(tax_per_pack, 1), by = state_name]

for (thresh in c(0.10, 0.50, 1.00)) {
  fi <- cdc[!is.na(tax_change) & tax_change >= thresh & year >= 2001,
            .(first_treat_alt = min(year)), by = state_name]
  panel_alt <- merge(panel[, .(state_name, state_id, year, total)],
                     fi, by = "state_name", all.x = TRUE)
  panel_alt[is.na(first_treat_alt), first_treat_alt := 0L]

  n_treat_alt <- length(unique(panel_alt[first_treat_alt > 0]$state_name))
  cat(sprintf("  Threshold $%.2f: %d treated states\n", thresh, n_treat_alt))

  if (n_treat_alt >= 5) {
    cs_alt <- tryCatch(
      att_gt(yname = "total", tname = "year", idname = "state_id",
             gname = "first_treat_alt", data = as.data.frame(panel_alt),
             control_group = "notyettreated", anticipation = 0,
             base_period = "varying"),
      error = function(e) { cat("  Error:", e$message, "\n"); NULL }
    )
    if (!is.null(cs_alt)) {
      att_alt <- aggte(cs_alt, type = "simple")
      results[[paste0("thresh_", thresh)]] <- att_alt
      cat(sprintf("  ATT = %.4f (SE = %.4f)\n",
                  att_alt$overall.att, att_alt$overall.se))
    }
  }
}

# =============================================================================
# 2. Bacon decomposition (TWFE diagnostics)
# =============================================================================
cat("\n=== BACON DECOMPOSITION ===\n")
# Need binary treatment timing — use first_treat_year
panel_bacon <- panel[, .(state_id, year, total, first_treat_year, treated)]
# Only works with balanced panel and binary treatment
bacon_out <- tryCatch({
  bacon(total ~ treated,
        data = as.data.frame(panel_bacon),
        id_var = "state_id",
        time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition failed:", e$message, "\n")
  NULL
})

if (!is.null(bacon_out)) {
  cat("Bacon decomposition results:\n")
  bacon_summary <- aggregate(cbind(estimate, weight) ~ type,
                              data = bacon_out, FUN = mean)
  print(bacon_summary)
  results$bacon <- bacon_out
  saveRDS(bacon_out, "../data/bacon_decomp.rds")
}

# =============================================================================
# 3. HonestDiD sensitivity analysis
# =============================================================================
cat("\n=== HONESTDID SENSITIVITY ===\n")
es_total <- readRDS("../data/es_total.rds")

# Extract event study coefficients for HonestDiD
es_coefs <- data.table(
  event_time = es_total$egt,
  estimate = es_total$att.egt,
  se = es_total$se.egt
)

# HonestDiD requires pre-period estimates
pre_coefs <- es_coefs[event_time < 0]
post_coefs <- es_coefs[event_time >= 0]

if (nrow(pre_coefs) > 0 && nrow(post_coefs) > 0) {
  # Construct inputs for HonestDiD
  # Need the full variance-covariance matrix from CS
  # Use the event study coefficients directly
  beta_hat <- es_coefs$estimate
  sigma_hat <- diag(es_coefs$se^2)  # Approximation: diagonal covariance

  n_pre <- sum(es_coefs$event_time < 0)
  n_post <- sum(es_coefs$event_time >= 0)

  # Run sensitivity analysis
  honest_result <- tryCatch({
    HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = n_pre,
      numPostPeriods = n_post,
      Mvec = seq(0, 0.05, by = 0.01)
    )
  }, error = function(e) {
    cat("HonestDiD failed:", e$message, "\n")
    NULL
  })

  if (!is.null(honest_result)) {
    cat("HonestDiD sensitivity bounds:\n")
    print(honest_result)
    results$honest <- honest_result
    saveRDS(honest_result, "../data/honest_did.rds")
  }
}

# =============================================================================
# 4. Exclude states with simultaneous alcohol tax changes
# =============================================================================
cat("\n=== EXCLUDING POTENTIAL CONFOUNDERS ===\n")

# States that also raised alcohol taxes around the same time could confound
# We don't have alcohol tax data, but we can check sensitivity to dropping
# the largest states (CA, NY, IL) which may have had coordinated tax reforms
big_states <- c("California", "New York", "Illinois")
panel_excl <- panel[!(state_name %in% big_states)]

cs_excl <- tryCatch(
  att_gt(yname = "total", tname = "year", idname = "state_id",
         gname = "first_treat_year", data = as.data.frame(panel_excl),
         control_group = "notyettreated", anticipation = 0,
         base_period = "varying"),
  error = function(e) { cat("Error:", e$message, "\n"); NULL }
)
if (!is.null(cs_excl)) {
  att_excl <- aggte(cs_excl, type = "simple")
  results$excl_big <- att_excl
  cat(sprintf("Excl. CA/NY/IL: ATT = %.4f (SE = %.4f)\n",
              att_excl$overall.att, att_excl$overall.se))
}

# =============================================================================
# 5. Different sample windows
# =============================================================================
cat("\n=== ALTERNATIVE SAMPLE WINDOWS ===\n")

# Restrict to 2001-2019 only (no pre-2001 data)
panel_short <- panel[year >= 2001]
cs_short <- tryCatch(
  att_gt(yname = "total", tname = "year", idname = "state_id",
         gname = "first_treat_year", data = as.data.frame(panel_short),
         control_group = "notyettreated", anticipation = 0,
         base_period = "varying"),
  error = function(e) { cat("Error:", e$message, "\n"); NULL }
)
if (!is.null(cs_short)) {
  att_short <- aggte(cs_short, type = "simple")
  results$short_window <- att_short
  cat(sprintf("2001-2019 only: ATT = %.4f (SE = %.4f)\n",
              att_short$overall.att, att_short$overall.se))
}

saveRDS(results, "../data/robustness_results.rds")
cat("\n=== ALL ROBUSTNESS CHECKS COMPLETE ===\n")
