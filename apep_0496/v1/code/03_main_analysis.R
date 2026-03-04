## =============================================================================
## 03_main_analysis.R — Main RDD analysis at REP/non-REP boundaries
## apep_0496: Education Priority Labels and Housing Markets in France
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## ---------------------------------------------------------------------------
## 1. Load analysis data
## ---------------------------------------------------------------------------

cat("=== Loading analysis data ===\n")

dt <- readRDS(file.path(data_dir, "analysis_data.rds"))
cat("Observations:", format(nrow(dt), big.mark = ","), "\n")

# Focus on transactions near boundary (within 2km of equidistant line)
dt_near <- dt[abs(dist_signed) <= 2000]
cat("Within 2km of boundary:", format(nrow(dt_near), big.mark = ","), "\n")

# Log price per m2
dt_near[, log_price_m2 := log(price_m2)]

cat("REP side:", sum(dt_near$rep_side == 1, na.rm = TRUE), "\n")
cat("Non-REP side:", sum(dt_near$rep_side == 0, na.rm = TRUE), "\n")

## ---------------------------------------------------------------------------
## 2. Summary statistics (Table 1)
## ---------------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")

stats_overall <- dt_near[, .(
  n = .N,
  mean_price_m2 = mean(price_m2, na.rm = TRUE),
  sd_price_m2 = sd(price_m2, na.rm = TRUE),
  median_price_m2 = median(price_m2, na.rm = TRUE),
  mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
  pct_apartment = mean(type_local == "Appartement", na.rm = TRUE)
)]

stats_by_rep <- dt_near[, .(
  n = .N,
  mean_price_m2 = mean(price_m2, na.rm = TRUE),
  sd_price_m2 = sd(price_m2, na.rm = TRUE),
  median_price_m2 = median(price_m2, na.rm = TRUE),
  mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
  pct_apartment = mean(type_local == "Appartement", na.rm = TRUE)
), by = rep_side]

cat("Overall:\n")
print(stats_overall)
cat("\nBy REP side:\n")
print(stats_by_rep)

tab1 <- rbind(
  data.table(Group = "All", stats_overall),
  data.table(Group = ifelse(stats_by_rep$rep_side == 1, "REP Side", "Non-REP Side"),
             stats_by_rep[, -"rep_side"]),
  fill = TRUE
)
fwrite(tab1, file.path(tables_dir, "table1_summary_stats.csv"))

## ---------------------------------------------------------------------------
## 3. Main RDD: Boundary discontinuity
## ---------------------------------------------------------------------------

cat("\n=== Main Boundary RDD ===\n")

# The running variable is signed distance to REP/non-REP boundary
# Positive = REP side, Negative = non-REP side

rdd_main <- rdrobust(
  y = dt_near$log_price_m2,
  x = dt_near$dist_signed,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  all = TRUE
)

cat("Main RDD Results:\n")
summary(rdd_main)

rdd_coef <- rdd_main$coef["Conventional", ]
rdd_se <- rdd_main$se["Conventional", ]
rdd_ci <- rdd_main$ci["Conventional", ]
rdd_bw <- rdd_main$bws["h", "left"]
rdd_n <- rdd_main$N_h

cat("\nRDD coefficient (boundary gap):", round(rdd_coef, 4), "\n")
cat("SE:", round(rdd_se, 4), "\n")
cat("95% CI: [", round(rdd_ci[1], 4), ",", round(rdd_ci[2], 4), "]\n")
cat("Bandwidth:", round(rdd_bw, 0), "meters\n")
cat("Effective N:", rdd_n, "\n")

rdd_bc <- rdd_main$coef["Bias-Corrected", ]
rdd_bc_se <- rdd_main$se["Robust", ]
cat("Bias-corrected:", round(rdd_bc, 4), "SE:", round(rdd_bc_se, 4), "\n")

## ---------------------------------------------------------------------------
## 4. Year-by-year RDD (time dynamics)
## ---------------------------------------------------------------------------

cat("\n=== Year-by-Year RDD ===\n")

years <- sort(unique(dt_near$year))
year_results <- data.table()

for (yr in years) {
  dt_yr <- dt_near[year == yr]
  if (nrow(dt_yr) < 500) next

  rdd_yr <- tryCatch({
    rdrobust(
      y = dt_yr$log_price_m2,
      x = dt_yr$dist_signed,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )
  }, error = function(e) NULL)

  if (!is.null(rdd_yr)) {
    year_results <- rbind(year_results, data.table(
      year = yr,
      coef = rdd_yr$coef["Conventional", ],
      se = rdd_yr$se["Conventional", ],
      ci_lower = rdd_yr$ci["Conventional", 1],
      ci_upper = rdd_yr$ci["Conventional", 2],
      bw = rdd_yr$bws["h", "left"],
      n_eff = rdd_yr$N_h[1] + rdd_yr$N_h[2],
      bc_coef = rdd_yr$coef["Bias-Corrected", ],
      bc_se = rdd_yr$se["Robust", ]
    ))
    cat("  Year", yr, ": coef =", round(rdd_yr$coef["Conventional", ], 4),
        "SE =", round(rdd_yr$se["Conventional", ], 4),
        "N =", rdd_yr$N_h[1] + rdd_yr$N_h[2], "\n")
  }
}

fwrite(year_results, file.path(tables_dir, "year_by_year_rdd.csv"))

## ---------------------------------------------------------------------------
## 5. Parametric estimates with controls (fixest)
## ---------------------------------------------------------------------------

cat("\n=== Parametric boundary estimates ===\n")

# Rescale distance to km for readable coefficients
dt_near[, dist_km := dist_signed / 1000]

# Baseline: no controls
m1 <- feols(log_price_m2 ~ rep_side | year,
            data = dt_near[abs(dist_signed) <= 1000],
            cluster = ~code_commune)

# + distance polynomial (in km)
m2 <- feols(log_price_m2 ~ rep_side + dist_km + I(dist_km^2) | year,
            data = dt_near[abs(dist_signed) <= 1000],
            cluster = ~code_commune)

# + property controls
m3 <- feols(log_price_m2 ~ rep_side + dist_km + I(dist_km^2) +
              surface_reelle_bati + I(type_local == "Appartement") | year,
            data = dt_near[abs(dist_signed) <= 1000],
            cluster = ~code_commune)

# + department FE
m4 <- feols(log_price_m2 ~ rep_side + dist_km + I(dist_km^2) +
              surface_reelle_bati + I(type_local == "Appartement") |
              year + code_departement,
            data = dt_near[abs(dist_signed) <= 1000],
            cluster = ~code_commune)

# + commune FE (finest geographic controls)
m5 <- feols(log_price_m2 ~ rep_side + dist_km + I(dist_km^2) +
              surface_reelle_bati + I(type_local == "Appartement") |
              year + code_commune,
            data = dt_near[abs(dist_signed) <= 1000],
            cluster = ~code_commune)

cat("Column 5 (commune FE):", round(coef(m5)["rep_side"], 4), "\n")

etable(m1, m2, m3, m4, m5,
       dict = c(rep_side = "REP Side",
                dist_km = "Distance (km)",
                surface_reelle_bati = "Surface (m\\textsuperscript{2})"),
       fitstat = ~ n + r2 + my,
       file = file.path(tables_dir, "table2_parametric_rdd.tex"))

cat("Parametric results:\n")
etable(m1, m2, m3, m4, m5,
       dict = c(rep_side = "REP Side",
                dist_signed = "Distance to Boundary"),
       fitstat = ~ n + r2)

## ---------------------------------------------------------------------------
## 6. Private school mechanism interaction
## ---------------------------------------------------------------------------

cat("\n=== Private School Mechanism ===\n")

if ("high_private" %in% names(dt_near)) {
  # Interaction: boundary gap × private school density
  m_priv <- feols(log_price_m2 ~ rep_side * high_private +
                    dist_signed + I(dist_signed^2) +
                    surface_reelle_bati + I(type_local == "Appartement") |
                    year + code_departement,
                  data = dt_near[abs(dist_signed) <= 1000],
                  cluster = ~code_commune)

  cat("Private school interaction:\n")
  summary(m_priv)

  # Continuous interaction
  m_priv_cont <- feols(log_price_m2 ~ rep_side * n_private_5km +
                    dist_signed + I(dist_signed^2) +
                    surface_reelle_bati + I(type_local == "Appartement") |
                    year + code_departement,
                  data = dt_near[abs(dist_signed) <= 1000],
                  cluster = ~code_commune)
  cat("Continuous private interaction:\n")
  summary(m_priv_cont)

  # Separate RDD for high vs low private density
  for (hp in c(0, 1)) {
    dt_hp <- dt_near[high_private == hp]
    if (nrow(dt_hp) < 500) next
    rdd_hp <- tryCatch({
      rdrobust(y = dt_hp$log_price_m2, x = dt_hp$dist_signed,
               c = 0, kernel = "triangular", bwselect = "mserd")
    }, error = function(e) NULL)
    if (!is.null(rdd_hp)) {
      label <- ifelse(hp == 1, "High private density", "Low private density")
      cat(label, ": coef =", round(rdd_hp$coef["Conventional", ], 4),
          "SE =", round(rdd_hp$se["Conventional", ], 4), "\n")
    }
  }
}

## ---------------------------------------------------------------------------
## 7. Save main results
## ---------------------------------------------------------------------------

cat("\n=== Saving results ===\n")

results <- list(
  rdd_main = list(
    coef = as.numeric(rdd_main$coef["Conventional", ]),
    se = as.numeric(rdd_main$se["Conventional", ]),
    ci = as.numeric(rdd_main$ci["Conventional", ]),
    bw = as.numeric(rdd_main$bws["h", "left"]),
    n_eff = as.numeric(rdd_main$N_h)
  ),
  year_results = year_results,
  summary_stats = tab1
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("Main results saved.\n")
