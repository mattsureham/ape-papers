## 04_robustness.R — Robustness checks and placebo tests
## APEP paper apep_0786: HMDA Reporting Exemption and Minority Lending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

bw <- as.data.table(arrow::read_parquet(file.path(data_dir, "panel_bw.parquet")))
bw[, county_year := paste0(county_code, "_", year)]
bw[, log_volume := log(total_volume + 1)]

panel_all <- as.data.table(arrow::read_parquet(file.path(data_dir, "panel_all_races.parquet")))

# ---------------------------------------------------------------
# 1. Placebo: Asian-White denial gap (should not respond to exemption
#    if the effect is specific to Black discrimination)
# ---------------------------------------------------------------
cat("=== Placebo: Asian-White Gap ===\n")

# Construct Asian-White gap
aw <- dcast(panel_all[race %in% c("White", "Asian") & total_apps >= 5],
            year + lei + state_code + county_code + exempt ~
              race, value.var = c("denial_rate", "total_apps", "mean_income"),
            fun.aggregate = mean)

if (all(c("denial_rate_Asian", "denial_rate_White") %in% names(aw))) {
  setnames(aw, c("denial_rate_Asian", "denial_rate_White",
                 "total_apps_Asian", "total_apps_White"),
           c("deny_asian", "deny_white", "apps_asian", "apps_white"),
           skip_absent = TRUE)
  aw[, deny_gap_aw := deny_asian - deny_white]
  aw[, county_year := paste0(county_code, "_", year)]
  aw[, log_volume := log(apps_asian + apps_white + 1)]

  # Require both exempt and non-exempt in county
  cty_both <- aw[, .(has_e = any(exempt == 1), has_ne = any(exempt == 0)),
                 by = .(county_code, year)]
  aw <- aw[cty_both[has_e & has_ne], on = .(county_code, year), nomatch = NULL]

  if (nrow(aw) > 100) {
    m_placebo_aw <- feols(deny_gap_aw ~ exempt + log_volume | county_year,
                          data = aw, cluster = ~county_code)
    cat(sprintf("  Asian-White gap: β = %.4f (SE = %.4f) N = %d\n",
                coef(m_placebo_aw)["exempt"], se(m_placebo_aw)["exempt"], nobs(m_placebo_aw)))
  } else {
    cat("  Insufficient observations for Asian-White placebo\n")
    m_placebo_aw <- NULL
  }
} else {
  cat("  Asian-White columns not available\n")
  m_placebo_aw <- NULL
}

# ---------------------------------------------------------------
# 2. Heterogeneity by lender size
# ---------------------------------------------------------------
cat("\n=== Heterogeneity: Lender Size ===\n")

# Compute lender-year total volume (across all counties)
lender_size <- bw[, .(lender_volume = sum(total_volume)), by = .(lei, year)]
bw <- merge(bw, lender_size, by = c("lei", "year"), all.x = TRUE)

# Quartiles of lender size
bw[, size_q := cut(lender_volume, quantile(lender_volume, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                   include.lowest = TRUE, labels = c("Q1", "Q2", "Q3", "Q4"))]

# Check if both groups have exempt variation
small_data <- bw[size_q %in% c("Q1", "Q2")]
large_data <- bw[size_q %in% c("Q3", "Q4")]

cat(sprintf("  Small subsample: %d obs, %d exempt\n", nrow(small_data), sum(small_data$exempt == 1)))
cat(sprintf("  Large subsample: %d obs, %d exempt\n", nrow(large_data), sum(large_data$exempt == 1)))

m_small <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
                 data = small_data, cluster = ~county_code)

# Large lenders may have no exempt lenders — split at median within exempt subsample
if (sum(large_data$exempt == 1) < 10) {
  cat("  NOTE: Too few exempt lenders in Q3-Q4 (all exempt lenders are small)\n")
  # Instead: split exempt lenders at their own median
  exempt_med <- median(bw[exempt == 1]$lender_volume, na.rm = TRUE)
  m_small_exempt <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
                          data = bw[lender_volume <= exempt_med], cluster = ~county_code)
  m_large_exempt <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
                          data = bw[lender_volume > exempt_med], cluster = ~county_code)
  m_large <- m_large_exempt
  cat(sprintf("  Below-median volume: β = %.4f (SE = %.4f) N = %d\n",
              coef(m_small_exempt)["exempt"], se(m_small_exempt)["exempt"], nobs(m_small_exempt)))
  cat(sprintf("  Above-median volume: β = %.4f (SE = %.4f) N = %d\n",
              coef(m_large_exempt)["exempt"], se(m_large_exempt)["exempt"], nobs(m_large_exempt)))
} else {
  m_large <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
                   data = large_data, cluster = ~county_code)
}

cat(sprintf("  Small lenders (Q1-Q2): β = %.4f (SE = %.4f) N = %d\n",
            coef(m_small)["exempt"], se(m_small)["exempt"], nobs(m_small)))

# ---------------------------------------------------------------
# 3. Alternative clustering: state-level
# ---------------------------------------------------------------
cat("\n=== Alternative Clustering ===\n")

m_state_cl <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
                    data = bw, cluster = ~state_code)
cat(sprintf("  State clustering: β = %.4f (SE = %.4f)\n",
            coef(m_state_cl)["exempt"], se(m_state_cl)["exempt"]))

# Two-way clustering: county + year
m_twoway <- feols(deny_gap ~ exempt + income_ratio + log_volume | county_year,
                  data = bw, cluster = ~county_code + year)
cat(sprintf("  Two-way (county+year): β = %.4f (SE = %.4f)\n",
            coef(m_twoway)["exempt"], se(m_twoway)["exempt"]))

# ---------------------------------------------------------------
# 4. Extensive margin: Minority application share
# ---------------------------------------------------------------
cat("\n=== Extensive Margin: Minority Application Share ===\n")

# At lender-county-year level, compute Black share of applications
lender_shares <- bw[, .(
  black_share = apps_black / (apps_black + apps_white),
  total = apps_black + apps_white
), by = .(year, lei, county_code, exempt)]
lender_shares[, county_year := paste0(county_code, "_", year)]
lender_shares[, log_total := log(total + 1)]

m_share <- feols(black_share ~ exempt + log_total | county_year,
                 data = lender_shares, cluster = ~county_code)
cat(sprintf("  Black application share: β = %.4f (SE = %.4f) N = %d\n",
            coef(m_share)["exempt"], se(m_share)["exempt"], nobs(m_share)))

# ---------------------------------------------------------------
# 5. Winsorized outcomes (handle outliers)
# ---------------------------------------------------------------
cat("\n=== Winsorized Denial Gap ===\n")

winsorize <- function(x, p = 0.01) {
  q <- quantile(x, c(p, 1 - p), na.rm = TRUE)
  pmax(pmin(x, q[2]), q[1])
}

bw[, deny_gap_w := winsorize(deny_gap)]
m_wins <- feols(deny_gap_w ~ exempt + income_ratio + log_volume | county_year,
                data = bw, cluster = ~county_code)
cat(sprintf("  Winsorized (1%%): β = %.4f (SE = %.4f)\n",
            coef(m_wins)["exempt"], se(m_wins)["exempt"]))

# ---------------------------------------------------------------
# Save all robustness models
# ---------------------------------------------------------------
save(m_placebo_aw, m_small, m_large, m_state_cl, m_twoway,
     m_share, m_wins,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
