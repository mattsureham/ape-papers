## 04_robustness.R — Robustness checks and placebo tests
source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- fread("../data/analysis_panel.csv")
load("../data/models.RData")

## ==============================
## R1: Binary treatment DiD (high vs low manufacturing)
## ==============================
cat("\n--- R1: Binary treatment (>30% manufacturing) ---\n")

# Callaway-Sant'Anna style: binary treatment, single cohort (2015)
binary_manuf <- feols(
  manuf_share ~ high_manuf:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

binary_service <- feols(
  service_share ~ high_manuf:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

binary_log_sec <- feols(
  log_emp_secondary ~ high_manuf:post | gem_id + year,
  data = panel,
  cluster = ~gem_id
)

cat("Binary treatment results:\n")
cat("  Manuf share: beta =", round(coef(binary_manuf), 4),
    " SE =", round(se(binary_manuf), 4), "\n")
cat("  Service share: beta =", round(coef(binary_service), 4),
    " SE =", round(se(binary_service), 4), "\n")
cat("  Log secondary: beta =", round(coef(binary_log_sec), 4),
    " SE =", round(se(binary_log_sec), 4), "\n")

## ==============================
## R2: Exclude very small municipalities (<100 employees)
## ==============================
cat("\n--- R2: Exclude small municipalities (<100 employees) ---\n")

panel_large <- panel[emp_total_2014 >= 100]
cat("Municipalities after filtering:", uniqueN(panel_large$gem_id), "\n")

robust_large <- feols(
  manuf_share ~ manuf_share_2014:post | gem_id + year,
  data = panel_large,
  cluster = ~gem_id
)
cat("  Manuf share (large only): beta =", round(coef(robust_large), 4),
    " SE =", round(se(robust_large), 4), "\n")

robust_large_serv <- feols(
  service_share ~ manuf_share_2014:post | gem_id + year,
  data = panel_large,
  cluster = ~gem_id
)

## ==============================
## R3: Alternative thresholds for binary treatment
## ==============================
cat("\n--- R3: Alternative binary thresholds ---\n")

for (threshold in c(0.20, 0.25, 0.35, 0.40)) {
  panel[, treat_alt := as.integer(manuf_share_2014 > threshold)]
  mod <- feols(manuf_share ~ treat_alt:post | gem_id + year, data = panel, cluster = ~gem_id)
  cat("  Threshold", threshold, ": beta =", round(coef(mod), 4),
      " SE =", round(se(mod), 4),
      " N_treated =", sum(panel[year == 2014]$treat_alt),
      "\n")
}

## ==============================
## R4: Weighted by 2014 employment
## ==============================
cat("\n--- R4: Employment-weighted ---\n")

weighted_manuf <- feols(
  manuf_share ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  weights = ~emp_total_2014,
  cluster = ~gem_id
)

weighted_service <- feols(
  service_share ~ manuf_share_2014:post | gem_id + year,
  data = panel,
  weights = ~emp_total_2014,
  cluster = ~gem_id
)

cat("  Weighted manuf share: beta =", round(coef(weighted_manuf), 4),
    " SE =", round(se(weighted_manuf), 4), "\n")
cat("  Weighted service share: beta =", round(coef(weighted_service), 4),
    " SE =", round(se(weighted_service), 4), "\n")

## ==============================
## R5: Placebo test — pre-period only (2011-2014, fake shock at 2013)
## ==============================
cat("\n--- R5: Placebo test (fake shock at 2013) ---\n")

panel_pre <- panel[year <= 2014]
panel_pre[, placebo_post := as.integer(year >= 2013)]

placebo_manuf <- feols(
  manuf_share ~ manuf_share_2014:placebo_post | gem_id + year,
  data = panel_pre,
  cluster = ~gem_id
)
cat("  Placebo manuf share: beta =", round(coef(placebo_manuf), 4),
    " SE =", round(se(placebo_manuf), 4),
    " p =", round(pvalue(placebo_manuf), 4), "\n")

## ==============================
## R6: Municipality-specific linear time trends
## ==============================
cat("\n--- R6: Municipality-specific linear trends ---\n")

panel[, gem_id_num := as.integer(as.factor(gem_id))]
panel[, year_num := year - 2014]

# Control for municipality-specific linear trend
trend_manuf <- feols(
  manuf_share ~ manuf_share_2014:post + gem_id_num:year_num | gem_id + year,
  data = panel[!is.na(manuf_share)],
  cluster = ~gem_id
)

# Alternative: separate pre/post slopes — test for break in trend
panel[, pre_trend := as.integer(year < 2015) * (year - 2014)]
panel[, post_trend := as.integer(year >= 2015) * (year - 2014)]

break_manuf <- feols(
  manuf_share ~ manuf_share_2014:pre_trend + manuf_share_2014:post_trend | gem_id + year,
  data = panel[!is.na(manuf_share)],
  cluster = ~gem_id
)

cat("Trend-adjusted manuf share: beta =", round(coef(trend_manuf)["manuf_share_2014:post"], 4),
    " SE =", round(se(trend_manuf)["manuf_share_2014:post"], 4), "\n")
cat("Break-in-trend pre: beta =", round(coef(break_manuf)[1], 4),
    " post: beta =", round(coef(break_manuf)[2], 4), "\n")

## ==============================
## Save robustness objects
## ==============================
save(
  binary_manuf, binary_service, binary_log_sec,
  robust_large, robust_large_serv,
  weighted_manuf, weighted_service,
  placebo_manuf,
  trend_manuf, break_manuf,
  file = "../data/robustness_models.RData"
)

cat("\n=== Robustness checks complete ===\n")
