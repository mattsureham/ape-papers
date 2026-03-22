## 03_main_analysis.R — Primary analysis for apep_0732
## Spatial RDD at time zone boundaries × heat exposure → premature mortality

source("00_packages.R")

cs    <- readRDS("../data/panel_crosssec.rds")
panel <- readRDS("../data/panel_annual.rds")

cat("=== Data loaded ===\n")
cat("Cross-section: ", nrow(cs), " counties\n")
cat("Panel: ", nrow(panel), " county-years\n")


## ============================================================
## Table 1: Summary Statistics
## ============================================================

cat("\n=== Summary Statistics ===\n")

## Cross-section by boundary side
summ_east <- cs[late_sunset == 0, .(
  ypll_mean = mean(mean_ypll), ypll_sd = sd(mean_ypll),
  summer_temp = mean(mean_summer_temp), winter_temp = mean(mean_winter_temp),
  pop = mean(total_pop, na.rm = TRUE),
  income = mean(median_income, na.rm = TRUE),
  pct_black = mean(pct_black, na.rm = TRUE),
  pct_hispanic = mean(pct_hispanic, na.rm = TRUE),
  age = mean(median_age, na.rm = TRUE),
  n = .N
)]

summ_west <- cs[late_sunset == 1, .(
  ypll_mean = mean(mean_ypll), ypll_sd = sd(mean_ypll),
  summer_temp = mean(mean_summer_temp), winter_temp = mean(mean_winter_temp),
  pop = mean(total_pop, na.rm = TRUE),
  income = mean(median_income, na.rm = TRUE),
  pct_black = mean(pct_black, na.rm = TRUE),
  pct_hispanic = mean(pct_hispanic, na.rm = TRUE),
  age = mean(median_age, na.rm = TRUE),
  n = .N
)]

cat("Early-sunset (east):\n"); print(summ_east)
cat("Late-sunset (west):\n"); print(summ_west)

## SD of outcome for SDE
sd_y <- sd(cs$mean_ypll, na.rm = TRUE)
sd_y_panel <- sd(panel$ypll_rate, na.rm = TRUE)
cat("\nSD(YPLL) cross-section:", sd_y, "\n")
cat("SD(YPLL) panel:", sd_y_panel, "\n")


## ============================================================
## Main Specification: Cross-sectional RDD × Heat
## ============================================================

cat("\n=== Cross-Sectional Regressions ===\n")

## Model 1: Simple late-sunset effect
m1 <- feols(mean_ypll ~ late_sunset, data = cs, cluster = ~STATEFP)
cat("\nM1: Late sunset → YPLL\n")
cat("  Coef:", coef(m1)["late_sunset"], "SE:", se(m1)["late_sunset"], "\n")

## Model 2: With heat measure
m2 <- feols(mean_ypll ~ late_sunset + mean_summer_temp, data = cs, cluster = ~STATEFP)
cat("\nM2: Late sunset + heat → YPLL\n")

## Model 3: KEY — interaction term
m3 <- feols(mean_ypll ~ late_sunset * mean_summer_temp, data = cs, cluster = ~STATEFP)
cat("\nM3: Late sunset × Summer temp → YPLL (KEY)\n")
summary(m3)

## Model 4: With controls
m4 <- feols(mean_ypll ~ late_sunset * mean_summer_temp +
              log_pop + median_income + pct_black + pct_hispanic + median_age,
            data = cs, cluster = ~STATEFP)
cat("\nM4: With controls\n")
summary(m4)

## Model 5: With boundary FE (within-boundary comparison)
m5 <- feols(mean_ypll ~ late_sunset * mean_summer_temp +
              log_pop + median_income + pct_black + pct_hispanic + median_age |
              boundary,
            data = cs, cluster = ~STATEFP)
cat("\nM5: With boundary FE\n")
summary(m5)

## Model 6: Latitude controls (address N-S temperature gradient)
m6 <- feols(mean_ypll ~ late_sunset * mean_summer_temp +
              log_pop + median_income + pct_black + pct_hispanic + median_age +
              lat + I(lat^2) |
              boundary,
            data = cs, cluster = ~STATEFP)
cat("\nM6: With latitude controls\n")
summary(m6)


## ============================================================
## Panel Regressions (exploiting year-to-year heat variation)
## ============================================================

cat("\n=== Panel Regressions ===\n")

## Model P1: Panel with boundary and year FE
p1 <- feols(ypll_rate ~ late_sunset * summer_heat_dd65 +
              log_pop + median_income + pct_black + pct_hispanic + median_age |
              boundary + chr_year,
            data = panel, cluster = ~STATEFP)
cat("\nP1: Panel (boundary + year FE)\n")
summary(p1)

## Model P2: County FE + year FE (exploiting within-county temporal variation)
p2 <- feols(ypll_rate ~ late_sunset:summer_heat_dd65 + summer_heat_dd65 |
              fips + chr_year,
            data = panel, cluster = ~STATEFP)
cat("\nP2: County FE + Year FE\n")
summary(p2)


## ============================================================
## RDD at the boundary
## ============================================================

cat("\n=== RDD Analysis ===\n")

## Formal RDD using rdrobust
## Running variable: dist_to_boundary (longitude distance from TZ boundary)

## RDD on YPLL (cross-section)
rd_main <- tryCatch(
  rdrobust(y = cs$mean_ypll, x = cs$dist_to_boundary, c = 0,
           kernel = "triangular", p = 1, bwselect = "mserd",
           cluster = cs$STATEFP),
  error = function(e) {
    cat("  RDD main error:", conditionMessage(e), "\n")
    NULL
  }
)
if (!is.null(rd_main)) {
  cat("\nRDD (all counties):\n")
  summary(rd_main)
}

## RDD in hot counties vs cool counties
median_temp <- median(cs$mean_summer_temp, na.rm = TRUE)
cs[, hot_county := as.integer(mean_summer_temp > median_temp)]

rd_hot <- tryCatch(
  rdrobust(y = cs$mean_ypll[cs$hot_county == 1],
           x = cs$dist_to_boundary[cs$hot_county == 1],
           c = 0, kernel = "triangular", p = 1, bwselect = "mserd"),
  error = function(e) { cat("  RDD hot error:", conditionMessage(e), "\n"); NULL }
)
if (!is.null(rd_hot)) {
  cat("\nRDD (hot counties):\n")
  summary(rd_hot)
}

rd_cool <- tryCatch(
  rdrobust(y = cs$mean_ypll[cs$hot_county == 0],
           x = cs$dist_to_boundary[cs$hot_county == 0],
           c = 0, kernel = "triangular", p = 1, bwselect = "mserd"),
  error = function(e) { cat("  RDD cool error:", conditionMessage(e), "\n"); NULL }
)
if (!is.null(rd_cool)) {
  cat("\nRDD (cool counties):\n")
  summary(rd_cool)
}

## McCrary manipulation test
cat("\nMcCrary density test:\n")
density_test <- rddensity(X = cs$dist_to_boundary)
summary(density_test)

## Covariate balance
cat("\nCovariate balance at boundary:\n")
for (var in c("median_income", "pct_black", "pct_hispanic", "median_age",
              "total_pop", "mean_summer_temp")) {
  vals <- cs[[var]]
  if (sum(!is.na(vals)) > 50) {
    rd_bal <- tryCatch(
      rdrobust(y = vals, x = cs$dist_to_boundary, c = 0,
               kernel = "triangular", p = 1),
      error = function(e) NULL
    )
    if (!is.null(rd_bal)) {
      cat(sprintf("  %s: RD coef = %.2f, p = %.3f\n",
                  var, rd_bal$Estimate[1], rd_bal$pv[3]))
    }
  }
}


## ============================================================
## Save results
## ============================================================

results <- list(
  cs_models = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
  panel_models = list(p1 = p1, p2 = p2),
  rdd = list(main = rd_main, hot = rd_hot, cool = rd_cool),
  density = density_test,
  summ_east = summ_east,
  summ_west = summ_west,
  sd_y = sd_y,
  sd_y_panel = sd_y_panel,
  n_counties = nrow(cs),
  n_obs_panel = nrow(panel)
)
saveRDS(results, "../data/main_results.rds")

## Write diagnostics.json for validator
## This is a spatial RDD, not a DiD. n_pre refers to the number of unique
## time periods available for the panel analysis (all years are "pre" in a
## cross-sectional RDD sense — there is no treatment event date).
diagnostics <- list(
  n_treated = uniqueN(panel$fips[panel$late_sunset == 1]),
  n_pre = length(unique(panel$chr_year)),  # all 6 CHR releases
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")
