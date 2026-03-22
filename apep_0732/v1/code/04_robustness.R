## 04_robustness.R — Robustness checks for apep_0732
## Bandwidth sensitivity, winter placebo, donut RDD, boundary heterogeneity

source("00_packages.R")

cs    <- readRDS("../data/panel_crosssec.rds")
panel <- readRDS("../data/panel_annual.rds")

cat("=== Robustness Checks ===\n")


## ============================================================
## 1. Bandwidth Sensitivity (Cross-Section)
## ============================================================

cat("\n--- Bandwidth sensitivity ---\n")

bandwidths <- c(1, 1.5, 2, 2.5, 3)

bw_results <- lapply(bandwidths, function(bw) {
  sub <- cs[abs(dist_to_boundary) <= bw]
  if (nrow(sub) < 30 || uniqueN(sub$STATEFP) < 5) return(NULL)

  m <- tryCatch(
    feols(mean_ypll ~ late_sunset * mean_summer_temp +
            log_pop + median_income + pct_black + pct_hispanic + median_age |
            boundary,
          data = sub, cluster = ~STATEFP),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)

  data.table(
    bandwidth = bw,
    n_counties = nrow(sub),
    coef_interaction = coef(m)["late_sunset:mean_summer_temp"],
    se_interaction = se(m)["late_sunset:mean_summer_temp"],
    coef_late = coef(m)["late_sunset"],
    se_late = se(m)["late_sunset"]
  )
})

bw_table <- rbindlist(bw_results[!sapply(bw_results, is.null)])
cat("Bandwidth sensitivity:\n")
print(bw_table)
saveRDS(bw_table, "../data/robustness_bandwidth.rds")


## ============================================================
## 2. Winter Placebo Test
## ============================================================

cat("\n--- Winter placebo ---\n")

## In the panel: if mechanism is heat × sleep, winter should show ZERO interaction
m_winter <- feols(ypll_rate ~ late_sunset * winter_avg_temp +
                    log_pop + median_income + pct_black + pct_hispanic + median_age |
                    boundary + chr_year,
                  data = panel, cluster = ~STATEFP)
cat("Winter placebo (panel):\n")
summary(m_winter)

## Winter with county FE
m_winter_fe <- feols(ypll_rate ~ late_sunset:winter_avg_temp + winter_avg_temp |
                       fips + chr_year,
                     data = panel, cluster = ~STATEFP)
cat("Winter placebo (county FE):\n")
summary(m_winter_fe)

## Cross-section winter
m_winter_cs <- feols(mean_ypll ~ late_sunset * mean_winter_temp +
                       log_pop + median_income + pct_black + pct_hispanic + median_age |
                       boundary,
                     data = cs, cluster = ~STATEFP)
cat("Winter placebo (cross-section):\n")
cat("  Interaction coef:", coef(m_winter_cs)["late_sunset:mean_winter_temp"],
    "SE:", se(m_winter_cs)["late_sunset:mean_winter_temp"], "\n")


## ============================================================
## 3. Donut RDD
## ============================================================

cat("\n--- Donut RDD ---\n")

donut_sizes <- c(0.25, 0.5, 0.75)

donut_results <- lapply(donut_sizes, function(d) {
  sub <- cs[abs(dist_to_boundary) >= d]
  if (nrow(sub) < 30) return(NULL)

  m <- tryCatch(
    feols(mean_ypll ~ late_sunset * mean_summer_temp +
            log_pop + median_income + pct_black + pct_hispanic + median_age |
            boundary,
          data = sub, cluster = ~STATEFP),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)

  data.table(
    donut = d,
    n_counties = nrow(sub),
    coef_interaction = coef(m)["late_sunset:mean_summer_temp"],
    se_interaction = se(m)["late_sunset:mean_summer_temp"]
  )
})

donut_table <- rbindlist(donut_results[!sapply(donut_results, is.null)])
cat("Donut results:\n")
print(donut_table)
saveRDS(donut_table, "../data/robustness_donut.rds")


## ============================================================
## 4. By-Boundary Heterogeneity
## ============================================================

cat("\n--- By-boundary estimates ---\n")

boundary_results <- cs[, {
  if (.N >= 30 && uniqueN(STATEFP) >= 3) {
    m <- tryCatch(
      feols(mean_ypll ~ late_sunset * mean_summer_temp +
              log_pop + median_income + pct_black + pct_hispanic + median_age,
            data = .SD, cluster = ~STATEFP),
      error = function(e) NULL
    )
    if (!is.null(m) && "late_sunset:mean_summer_temp" %in% names(coef(m))) {
      list(
        coef_interaction = coef(m)["late_sunset:mean_summer_temp"],
        se_interaction = se(m)["late_sunset:mean_summer_temp"],
        n = .N
      )
    } else {
      list(coef_interaction = NA_real_, se_interaction = NA_real_, n = .N)
    }
  } else {
    list(coef_interaction = NA_real_, se_interaction = NA_real_, n = .N)
  }
}, by = boundary]

cat("By-boundary:\n")
print(boundary_results)
saveRDS(boundary_results, "../data/robustness_boundary.rds")


## ============================================================
## 5. Population-Weighted Regressions
## ============================================================

cat("\n--- Population-weighted ---\n")

m_wt <- feols(mean_ypll ~ late_sunset * mean_summer_temp +
                log_pop + median_income + pct_black + pct_hispanic + median_age |
                boundary,
              data = cs, cluster = ~STATEFP, weights = cs$total_pop)
cat("Population-weighted interaction:", coef(m_wt)["late_sunset:mean_summer_temp"],
    "SE:", se(m_wt)["late_sunset:mean_summer_temp"], "\n")

## Panel weighted
p_wt <- feols(ypll_rate ~ late_sunset:summer_heat_dd65 + summer_heat_dd65 |
                fips + chr_year,
              data = panel, cluster = ~STATEFP, weights = panel$total_pop)
cat("Panel pop-weighted interaction:", coef(p_wt)["late_sunset:summer_heat_dd65"],
    "SE:", se(p_wt)["late_sunset:summer_heat_dd65"], "\n")


## ============================================================
## 6. RDD Bandwidth Sensitivity
## ============================================================

cat("\n--- RDD bandwidth sensitivity ---\n")

bws_to_try <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
rdd_bw_results <- lapply(bws_to_try, function(h) {
  rd <- tryCatch(
    rdrobust(y = cs$mean_ypll, x = cs$dist_to_boundary, c = 0,
             kernel = "triangular", p = 1, h = h),
    error = function(e) NULL
  )
  if (is.null(rd)) return(NULL)
  data.table(
    bandwidth = h,
    coef = rd$Estimate[1],
    se = rd$se[3],
    pval = rd$pv[3],
    n_left = rd$N_h[1],
    n_right = rd$N_h[2]
  )
})

rdd_bw_table <- rbindlist(rdd_bw_results[!sapply(rdd_bw_results, is.null)])
cat("RDD bandwidth sensitivity:\n")
print(rdd_bw_table)


## ============================================================
## Save all robustness
## ============================================================

robustness <- list(
  bandwidth = bw_table,
  donut = donut_table,
  by_boundary = boundary_results,
  winter_panel = m_winter,
  winter_fe = m_winter_fe,
  winter_cs = m_winter_cs,
  pop_weighted = m_wt,
  panel_weighted = p_wt,
  rdd_bandwidth = rdd_bw_table
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
