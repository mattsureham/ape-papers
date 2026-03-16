# 03_main_analysis.R — Main DiD analysis
# apep_0709: Markets Under Fire

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %s obs, %d markets, %d commodities\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$market_id),
            uniqueN(panel$commodity_clean)))

# ============================================================
# 1. Summary Statistics
# ============================================================
cat("\n--- Summary Statistics ---\n")

# Pre-treatment summary (before any market is treated)
first_treat_date <- min(panel[treated == TRUE]$first_event_ym, na.rm = TRUE)
pre <- panel[ym < first_treat_date]
post_treated <- panel[post == TRUE]

sumstats <- panel[, .(
  Mean = mean(price, na.rm = TRUE),
  SD = sd(price, na.rm = TRUE),
  Min = min(price, na.rm = TRUE),
  Max = max(price, na.rm = TRUE),
  N = .N
), by = commodity_clean][order(commodity_clean)]

cat("Summary by commodity:\n")
print(sumstats)

# Overall summary for table
overall_stats <- data.frame(
  Variable = c("Price (CFA/kg)", "Log price", "Post-conflict",
               "Events within 50km", "Fatalities within 50km"),
  Mean = c(mean(panel$price), mean(panel$log_price),
           mean(panel$post), mean(panel$total_events_50km),
           mean(panel$total_fatalities_50km)),
  SD = c(sd(panel$price), sd(panel$log_price),
         sd(panel$post), sd(panel$total_events_50km),
         sd(panel$total_fatalities_50km)),
  Min = c(min(panel$price), min(panel$log_price),
          0, min(panel$total_events_50km),
          min(panel$total_fatalities_50km)),
  Max = c(max(panel$price), max(panel$log_price),
          1, max(panel$total_events_50km),
          max(panel$total_fatalities_50km))
)

# Save SD of outcome for SDE calculation
sd_log_price <- sd(panel$log_price, na.rm = TRUE)
sd_log_price_pre <- sd(panel[ym < first_treat_date]$log_price, na.rm = TRUE)
saveRDS(list(sd_log_price = sd_log_price, sd_log_price_pre = sd_log_price_pre,
             sd_price = sd(panel$price, na.rm = TRUE)),
        file.path(data_dir, "outcome_sds.rds"))

# ============================================================
# 2. Callaway-Sant'Anna Staggered DiD
# ============================================================
cat("\n--- Callaway-Sant'Anna Estimation ---\n")

# Prepare data for did package at QUARTERLY frequency
# Monthly cohorts create too many groups (30) for 64 markets
# Quarterly aggregation gives cleaner estimation

cs_data <- copy(panel)

# Create quarterly time variable
cs_data[, yq := paste0(year, "Q", ceiling(month / 3))]
cs_data[, quarter := ceiling(month / 3)]
cs_data[, t_q := (year - 2012) * 4 + quarter]  # Numeric quarter index

# Aggregate to market-quarter level (pool commodities)
cs_market <- cs_data[, .(
  log_price = mean(log_price, na.rm = TRUE),
  price = mean(price, na.rm = TRUE),
  n_obs = .N
), by = .(market_id, t_q, treated, first_event_ym)]

# Group variable: quarter of first treatment (0 = never-treated)
cs_market[, first_treat_q := ifelse(
  treated,
  (year(first_event_ym) - 2012) * 4 + ceiling(month(first_event_ym) / 3),
  0
)]

# Use not-yet-treated as additional controls (only 4 never-treated)
cat(sprintf("  CS quarterly data: %d market-quarters, %d cohorts\n",
            nrow(cs_market), uniqueN(cs_market$first_treat_q[cs_market$first_treat_q > 0])))

# Balance the panel by filling missing quarters
full_grid <- CJ(market_id = unique(cs_market$market_id),
                t_q = unique(cs_market$t_q))
cs_market <- merge(full_grid, cs_market, by = c("market_id", "t_q"), all.x = TRUE)
cs_market[, first_treat_q := max(first_treat_q, na.rm = TRUE), by = market_id]
cs_market[is.infinite(first_treat_q), first_treat_q := 0]
cs_market[, log_price := nafill(nafill(log_price, "locf"), "nocb"), by = market_id]
cs_market <- cs_market[!is.na(log_price)]

cat(sprintf("  Balanced panel: %d obs, %d markets, %d periods\n",
            nrow(cs_market), uniqueN(cs_market$market_id), uniqueN(cs_market$t_q)))

# Run Callaway-Sant'Anna with not-yet-treated controls (larger control pool)
cs_out <- att_gt(
  yname = "log_price",
  tname = "t_q",
  idname = "market_id",
  gname = "first_treat_q",
  data = as.data.frame(cs_market),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)

# Aggregate: overall ATT
cs_att <- aggte(cs_out, type = "simple")
cat(sprintf("\n  CS ATT (simple): %.4f (SE: %.4f, p: %.4f)\n",
            cs_att$overall.att, cs_att$overall.se,
            2 * pnorm(-abs(cs_att$overall.att / cs_att$overall.se))))

# Aggregate: dynamic (event study)
cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -24, max_e = 24)
cat(sprintf("  CS dynamic computed: %d event-time cells\n",
            length(cs_dynamic$egt)))

# Save CS results
saveRDS(cs_out, file.path(data_dir, "cs_results.rds"))
saveRDS(cs_att, file.path(data_dir, "cs_att.rds"))
saveRDS(cs_dynamic, file.path(data_dir, "cs_dynamic.rds"))

# ============================================================
# 3. TWFE (for comparison, expected to be biased)
# ============================================================
cat("\n--- TWFE Estimation ---\n")

cs_market[, post := (first_treat_q > 0) & (t_q >= first_treat_q)]

twfe_fit <- feols(
  log_price ~ post | market_id + t_q,
  data = cs_market,
  cluster = ~market_id
)
cat(sprintf("  TWFE: %.4f (SE: %.4f)\n",
            coef(twfe_fit)["postTRUE"],
            se(twfe_fit)["postTRUE"]))

# ============================================================
# 4. Commodity-specific effects (mechanism test)
# ============================================================
cat("\n--- Commodity-Type Heterogeneity ---\n")

# Run CS by commodity type at quarterly frequency
cs_by_type <- list()
for (ctype in c("Local cereal", "Imported", "Protein/legume")) {
  ct_data <- cs_data[commodity_type == ctype]

  # Quarterly aggregation
  ct_market <- ct_data[, .(
    log_price = mean(log_price, na.rm = TRUE)
  ), by = .(market_id, t_q, treated, first_event_ym)]

  ct_market[, first_treat_q := ifelse(
    treated,
    (year(first_event_ym) - 2012) * 4 + ceiling(month(first_event_ym) / 3),
    0
  )]

  # Balance
  ct_grid <- CJ(market_id = unique(ct_market$market_id),
                t_q = unique(ct_market$t_q))
  ct_market <- merge(ct_grid, ct_market, by = c("market_id", "t_q"), all.x = TRUE)
  ct_market[, first_treat_q := max(first_treat_q, na.rm = TRUE), by = market_id]
  ct_market[is.infinite(first_treat_q), first_treat_q := 0]
  ct_market[, log_price := nafill(nafill(log_price, "locf"), "nocb"), by = market_id]
  ct_market <- ct_market[!is.na(log_price)]

  n_cohorts <- uniqueN(ct_market$first_treat_q[ct_market$first_treat_q > 0])

  if (n_cohorts >= 2) {
    cs_ct <- tryCatch({
      out <- att_gt(
        yname = "log_price",
        tname = "t_q",
        idname = "market_id",
        gname = "first_treat_q",
        data = as.data.frame(ct_market),
        control_group = "notyettreated",
        anticipation = 0,
        base_period = "varying"
      )
      aggte(out, type = "simple")
    }, error = function(e) {
      cat(sprintf("    CS failed for %s: %s\n", ctype, e$message))
      NULL
    })

    if (!is.null(cs_ct)) {
      cs_by_type[[ctype]] <- cs_ct
      cat(sprintf("  %s: ATT = %.4f (SE: %.4f)\n",
                  ctype, cs_ct$overall.att, cs_ct$overall.se))
    }
  } else {
    cat(sprintf("  %s: insufficient cohorts (%d)\n", ctype, n_cohorts))
  }
}
saveRDS(cs_by_type, file.path(data_dir, "cs_by_type.rds"))

# ============================================================
# 5. Sun-Abraham estimator (robustness)
# ============================================================
cat("\n--- Sun-Abraham Estimation ---\n")

cs_market[, cohort_sa := fifelse(first_treat_q == 0, 10000L, as.integer(first_treat_q))]

sa_fit <- feols(
  log_price ~ sunab(cohort_sa, t_q) | market_id + t_q,
  data = cs_market,
  cluster = ~market_id
)

# Extract ATT: average of post-treatment coefficients
sa_coefs <- coef(sa_fit)
sa_names <- names(sa_coefs)
# sunab names are like "t_q::5" where 5 is relative period
sa_rel <- as.numeric(gsub(".*::", "", sa_names))
sa_post_idx <- which(sa_rel >= 0)
sa_att_mean <- mean(sa_coefs[sa_post_idx])

cat(sprintf("  Sun-Abraham mean post-treatment: %.4f\n", sa_att_mean))
saveRDS(sa_fit, file.path(data_dir, "sa_fit.rds"))

# ============================================================
# 6. Write diagnostics.json
# ============================================================
market_treat_info <- unique(panel[, .(market_id, treated)])
diagnostics <- list(
  n_obs = nrow(panel),
  n_treated = sum(market_treat_info$treated),
  n_pre = as.integer(difftime(first_treat_date, min(panel$ym), units = "days") / 30),
  n_markets = uniqueN(panel$market_id),
  n_never_treated = sum(!market_treat_info$treated),
  n_commodities = uniqueN(panel$commodity_clean),
  n_months = uniqueN(panel$ym),
  cs_att = cs_att$overall.att,
  cs_se = cs_att$overall.se,
  sd_log_price_pre = sd_log_price_pre
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("CS ATT: %.4f (%.4f)\n", cs_att$overall.att, cs_att$overall.se))
cat(sprintf("Diagnostics saved to data/diagnostics.json\n"))
