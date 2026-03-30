## 03_main_analysis.R — Main analysis: Bunching at the LISA £450K cap
## Two-design paper: (1) Bunching analysis at £450K (main)
##                   (2) LA-level staggered DiD (supporting)

source("00_packages.R")

DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "panel_hpi_la_quarter.csv"))
treatment <- fread(file.path(DATA_DIR, "treatment_timing.csv"))
ppd_cells <- fread(file.path(DATA_DIR, "ppd_cells_proptype.csv"))

LISA_CAP <- 450000
LISA_START <- as.Date("2017-04-01")

cat("=== MAIN ANALYSIS: BUNCHING AT LISA £450K CAP ===\n\n")

# ===========================================================================
# 1. Load transaction-level PPD data for bunching analysis
#    Need the actual price distribution, not pre-aggregated cells
# ===========================================================================
cat("--- Loading PPD transaction data for bunching ---\n")

ppd_dir <- file.path(DATA_DIR, "ppd")
ppd_files <- list.files(ppd_dir, pattern = "pp-20.*\\.csv$", full.names = TRUE)

# Read price and date from each year
all_txns <- list()
for (f in ppd_files) {
  yr <- as.integer(gsub(".*pp-(\\d{4})\\.csv", "\\1", f))
  dt <- fread(f, header = FALSE,
              select = c(2, 3, 5, 6, 13))  # price, date, prop_type, old_new, district
  setnames(dt, c("price", "date", "prop_type", "old_new", "district"))
  dt[, price := as.numeric(price)]
  dt[, date := as.Date(date)]
  dt[, year := year(date)]

  # Keep transactions in range £200K-£700K for bunching window
  dt <- dt[price >= 200000 & price <= 700000]
  all_txns[[as.character(yr)]] <- dt
  cat(sprintf("  %d: %d transactions in £200K-£700K range\n", yr, nrow(dt)))
}

txns <- rbindlist(all_txns)
txns[, post_lisa := fifelse(date >= LISA_START, 1L, 0L)]
txns[, period := fifelse(post_lisa == 1, "Post-LISA (2017-2024)", "Pre-LISA (2010-2016)")]

cat(sprintf("\nTotal transactions: %d (pre: %d, post: %d)\n",
            nrow(txns),
            sum(txns$post_lisa == 0),
            sum(txns$post_lisa == 1)))

# ===========================================================================
# 2. Bunching Analysis: Density around £450K
# ===========================================================================
cat("\n--- Bunching Analysis ---\n")

# Create price bins (£5K width for fine resolution)
bin_width <- 5000
txns[, price_bin := floor(price / bin_width) * bin_width]

# Count transactions per bin per period
density_pre <- txns[post_lisa == 0, .N, by = price_bin][order(price_bin)]
density_post <- txns[post_lisa == 1, .N, by = price_bin][order(price_bin)]

setnames(density_pre, "N", "n_pre")
setnames(density_post, "N", "n_post")

density <- merge(density_pre, density_post, by = "price_bin", all = TRUE)
density[is.na(n_pre), n_pre := 0]
density[is.na(n_post), n_post := 0]

# Normalize to shares (within period)
density[, share_pre := n_pre / sum(n_pre)]
density[, share_post := n_post / sum(n_post)]
density[, diff := share_post - share_pre]

# Focus on bunching window
cat("\nDensity around £450K (£5K bins):\n")
bunching_window <- density[price_bin >= 400000 & price_bin <= 500000]
bunching_window[, label := sprintf("£%dK-£%dK", price_bin / 1000, (price_bin + bin_width) / 1000)]
print(bunching_window[, .(label, n_pre, n_post, share_pre = round(share_pre, 5),
                           share_post = round(share_post, 5),
                           diff = round(diff, 5))])

# Key bins: just below (£440K-£450K) and just above (£450K-£455K)
below_cap <- density[price_bin >= 440000 & price_bin < 450000]
above_cap <- density[price_bin >= 450000 & price_bin < 460000]

cat(sprintf("\nJust below cap (£440K-£450K): pre share = %.5f, post share = %.5f, diff = %+.5f\n",
            sum(below_cap$share_pre), sum(below_cap$share_post),
            sum(below_cap$share_post) - sum(below_cap$share_pre)))
cat(sprintf("Just above cap (£450K-£460K): pre share = %.5f, post share = %.5f, diff = %+.5f\n",
            sum(above_cap$share_pre), sum(above_cap$share_post),
            sum(above_cap$share_post) - sum(above_cap$share_pre)))

# ===========================================================================
# 3. Formal bunching estimation: Excess mass below £450K
#    Following Chetty et al. (2011) / Kleven (2016) approach
# ===========================================================================
cat("\n--- Formal Bunching Estimation ---\n")

# Use finer bins (£2K) for bunching estimation
fine_bin <- 2000
txns[, fbin := floor(price / fine_bin) * fine_bin]

# Bunching window: £400K to £500K
# Excluded region: £440K to £460K (where bunching occurs)
bw_lower <- 400000
bw_upper <- 500000
excl_lower <- 440000
excl_upper <- 460000

# Estimate counterfactual density using polynomial fit on non-excluded bins
for (per in c(0, 1)) {
  per_label <- ifelse(per == 0, "Pre-LISA", "Post-LISA")
  cat(sprintf("\n  %s bunching estimation:\n", per_label))

  sub <- txns[post_lisa == per & fbin >= bw_lower & fbin <= bw_upper]
  bin_counts <- sub[, .N, by = fbin][order(fbin)]
  bin_counts[, bin_center := fbin + fine_bin / 2]
  bin_counts[, excluded := fbin >= excl_lower & fbin < excl_upper]

  # Fit 5th-order polynomial on non-excluded bins
  fit_data <- bin_counts[excluded == FALSE]
  if (nrow(fit_data) < 10) {
    cat("    Insufficient bins for polynomial fit.\n")
    next
  }

  poly_fit <- lm(N ~ poly(bin_center, 5), data = fit_data)
  bin_counts[, counterfactual := predict(poly_fit, newdata = bin_counts)]

  # Excess mass in excluded region
  excl_bins <- bin_counts[excluded == TRUE]
  excess <- sum(excl_bins$N) - sum(excl_bins$counterfactual)
  avg_cf <- mean(excl_bins$counterfactual)
  excess_normalized <- excess / avg_cf  # "b" statistic

  # Below cap specifically (£440K-£450K)
  below_bins <- bin_counts[fbin >= 440000 & fbin < 450000]
  excess_below <- sum(below_bins$N) - sum(below_bins$counterfactual)

  # Above cap specifically (£450K-£460K)
  above_bins <- bin_counts[fbin >= 450000 & fbin < 460000]
  missing_above <- sum(above_bins$counterfactual) - sum(above_bins$N)

  cat(sprintf("    Observed below cap (£440K-£450K): %d\n", sum(below_bins$N)))
  cat(sprintf("    Counterfactual below cap: %.0f\n", sum(below_bins$counterfactual)))
  cat(sprintf("    Excess mass below cap: %.0f (normalized b = %.3f)\n",
              excess_below, excess_below / mean(below_bins$counterfactual)))
  cat(sprintf("    Missing mass above cap (£450K-£460K): %.0f\n", missing_above))
  cat(sprintf("    Excess in full window: %.0f (normalized b = %.3f)\n",
              excess, excess_normalized))
}

# ===========================================================================
# 4. Diff-in-Bunching: Pre vs Post LISA
# ===========================================================================
cat("\n--- Diff-in-Bunching ---\n")

# For each year, compute the bunching statistic (share just below cap / share just above)
yearly_bunching <- txns[, .(
  n_total = .N,
  n_440_450 = sum(price >= 440000 & price < 450000),
  n_450_460 = sum(price >= 450000 & price < 460000),
  n_425_450 = sum(price >= 425000 & price < 450000),
  n_450_475 = sum(price >= 450000 & price < 475000)
), by = year]

yearly_bunching[, ratio_narrow := n_440_450 / n_450_460]
yearly_bunching[, ratio_wide := n_425_450 / n_450_475]
yearly_bunching[, post_lisa := fifelse(year >= 2017, 1L, 0L)]

cat("Yearly bunching ratios (just-below / just-above):\n")
print(yearly_bunching[, .(year, n_440_450, n_450_460, ratio_narrow = round(ratio_narrow, 3),
                           post_lisa)])

# DiD on bunching ratio: pre-post LISA
pre_mean <- mean(yearly_bunching[post_lisa == 0, ratio_narrow])
post_mean <- mean(yearly_bunching[post_lisa == 1, ratio_narrow])
cat(sprintf("\nMean bunching ratio: Pre-LISA = %.3f, Post-LISA = %.3f, Diff = %+.3f\n",
            pre_mean, post_mean, post_mean - pre_mean))

# Regression: bunching ratio on post-LISA dummy
bunch_reg <- lm(ratio_narrow ~ post_lisa, data = yearly_bunching)
cat(sprintf("Regression: coef = %.4f (SE = %.4f, p = %.4f)\n",
            coef(bunch_reg)["post_lisa"],
            summary(bunch_reg)$coefficients["post_lisa", "Std. Error"],
            summary(bunch_reg)$coefficients["post_lisa", "Pr(>|t|)"]))

# ===========================================================================
# 5. Placebo threshold: £350K (no policy relevance)
# ===========================================================================
cat("\n--- Placebo: Bunching at £350K ---\n")

placebo_bunching <- txns[, .(
  n_340_350 = sum(price >= 340000 & price < 350000),
  n_350_360 = sum(price >= 350000 & price < 360000)
), by = .(year, post_lisa)]

placebo_bunching[, ratio := n_340_350 / n_350_360]

placebo_reg <- lm(ratio ~ post_lisa, data = placebo_bunching)
cat(sprintf("Placebo (£350K) bunching ratio change: %.4f (SE = %.4f, p = %.4f)\n",
            coef(placebo_reg)["post_lisa"],
            summary(placebo_reg)$coefficients["post_lisa", "Std. Error"],
            summary(placebo_reg)$coefficients["post_lisa", "Pr(>|t|)"]))

# ===========================================================================
# 6. LA-level DiD (supporting analysis)
# ===========================================================================
cat("\n--- LA-level DiD (supporting) ---\n")

panel_a <- panel[year >= 2012 & year <= 2024]
panel_a[, la_id := as.integer(as.factor(la_code))]
panel_a[, log_volume := log(sales_volume + 1)]
panel_a[, log_price := log(avg_price)]
panel_a[, above_450k := fifelse(!is.na(first_above_450k) & yq >= first_above_450k, 1L, 0L)]

time_index <- unique(panel_a[, .(yq)])[order(yq)]
time_index[, t_int := .I]
panel_a <- merge(panel_a, time_index, by = "yq", all.x = TRUE)

# Static TWFE
twfe_vol <- feols(log_volume ~ above_450k | la_id + t_int,
                  data = panel_a, cluster = ~la_code)
twfe_price <- feols(log_price ~ above_450k | la_id + t_int,
                    data = panel_a, cluster = ~la_code)

cat(sprintf("TWFE Volume: %.4f (SE = %.4f)\n",
            coef(twfe_vol)["above_450k"], se(twfe_vol)["above_450k"]))
cat(sprintf("TWFE Price:  %.4f (SE = %.4f)\n",
            coef(twfe_price)["above_450k"], se(twfe_price)["above_450k"]))

# Event study for pre-trend visualization
panel_a[, et := fifelse(
  !is.na(first_above_450k) & treated == TRUE,
  as.integer(round((yq - first_above_450k) * 4)),
  NA_integer_
)]
panel_a[!is.na(et) & et < -8, et := -8L]
panel_a[!is.na(et) & et > 12, et := 12L]

twfe_es <- feols(log_volume ~ i(et, ref = -1) | la_id + t_int,
                 data = panel_a[!is.na(et) | treated == FALSE],
                 cluster = ~la_code)

# ===========================================================================
# 7. Save diagnostics and models
# ===========================================================================
cat("\n--- Saving ---\n")

diagnostics <- list(
  n_treated = as.integer(sum(treatment$treated)),
  n_pre = 20L,  # 5 years x 4 quarters pre-LISA
  n_obs = as.integer(nrow(panel_a)),
  n_transactions = as.integer(nrow(txns)),
  twfe_vol_coef = as.numeric(coef(twfe_vol)["above_450k"]),
  twfe_vol_se = as.numeric(se(twfe_vol)["above_450k"]),
  twfe_price_coef = as.numeric(coef(twfe_price)["above_450k"]),
  twfe_price_se = as.numeric(se(twfe_price)["above_450k"]),
  bunching_pre_ratio = pre_mean,
  bunching_post_ratio = post_mean,
  bunching_diff = post_mean - pre_mean,
  bunching_p = summary(bunch_reg)$coefficients["post_lisa", "Pr(>|t|)"],
  placebo_bunching_p = summary(placebo_reg)$coefficients["post_lisa", "Pr(>|t|)"]
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

save(twfe_vol, twfe_price, twfe_es, bunch_reg, placebo_reg, yearly_bunching,
     density,
     file = file.path(DATA_DIR, "main_models.RData"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
