## ============================================================
## 03_main_analysis.R — RDD estimation
## ERDF Treatment Withdrawal RDD
## ============================================================

source("00_packages.R")

data_dir <- "../data/"
analysis <- fread(paste0(data_dir, "analysis.csv"))
annual   <- fread(paste0(data_dir, "annual_panel.csv"))

cat("=== MAIN ANALYSIS ===\n\n")

## ---------------------------------------------------------
## 1. First Stage: ERDF intensity discontinuity at 75%
## ---------------------------------------------------------
cat("1. First stage: ERDF intensity at threshold\n")

# Find the best ERDF per capita columns
erdf_cols <- grep("erdf_total.*_pc$", names(analysis), value = TRUE)
cat("  Available ERDF per capita columns:", paste(erdf_cols, collapse = ", "), "\n")

# Identify the 2007-2013 and 2014-2020 period columns
erdf_0713_col <- grep("2007|07.13", erdf_cols, value = TRUE)
erdf_1420_col <- grep("2014|14.20", erdf_cols, value = TRUE)

# If standard naming doesn't work, compute from raw
if (length(erdf_0713_col) == 0 | length(erdf_1420_col) == 0) {
  cat("  Computing ERDF per capita from raw data...\n")
  erdf_raw <- fread(paste0(data_dir, "erdf_payments.csv"))
  pop_avg <- fread(paste0(data_dir, "population.csv"))
  pop_avg <- pop_avg[time %in% 2010:2013, .(pop = mean(values, na.rm = TRUE)), by = .(geo)]

  # Aggregate by NUTS2 and period
  erdf_by_period <- erdf_raw[!is.na(nuts2_id) & nuts2_id != "", .(
    erdf_0713 = sum(eu_payment_annual[grepl("2007|07", programming_period)], na.rm = TRUE),
    erdf_1420 = sum(eu_payment_annual[grepl("2014|14", programming_period)], na.rm = TRUE)
  ), by = .(nuts2_id)]

  erdf_by_period <- merge(erdf_by_period, pop_avg, by.x = "nuts2_id", by.y = "geo")
  erdf_by_period[, `:=`(
    erdf_0713_pc = erdf_0713 / pop * 1e6,
    erdf_1420_pc = erdf_1420 / pop * 1e6
  )]

  analysis <- merge(analysis,
    erdf_by_period[, .(nuts2_id, erdf_0713_pc, erdf_1420_pc)],
    by.x = "geo", by.y = "nuts2_id", all.x = TRUE)

  erdf_0713_col <- "erdf_0713_pc"
  erdf_1420_col <- "erdf_1420_pc"
} else {
  erdf_0713_col <- erdf_0713_col[1]
  erdf_1420_col <- erdf_1420_col[1]
}

# Change in ERDF per capita
if (erdf_0713_col %in% names(analysis) & erdf_1420_col %in% names(analysis)) {
  analysis[, delta_erdf_pc := get(erdf_1420_col) - get(erdf_0713_col)]
} else {
  # Fallback: use the graduated dummy as first stage
  cat("  Warning: ERDF per capita columns not found; using graduated dummy\n")
  analysis[, delta_erdf_pc := NA_real_]
}

# First stage RDD
fs_data <- analysis[!is.na(rv_centered) & !is.na(delta_erdf_pc) &
                     abs(rv_centered) <= 30]

if (sum(!is.na(fs_data$delta_erdf_pc) & fs_data$delta_erdf_pc != 0) >= 20) {
  fs_rdd <- rdrobust(y = fs_data$delta_erdf_pc, x = fs_data$rv_centered, c = 0)
  cat("\n  First Stage RDD:\n")
  summary(fs_rdd)

  # Save first stage results
  fs_results <- data.table(
    spec = "First Stage",
    coef = fs_rdd$coef[1],
    se = fs_rdd$se[3],  # robust SE
    ci_lower = fs_rdd$ci[3, 1],
    ci_upper = fs_rdd$ci[3, 2],
    bw = fs_rdd$bws[1, 1],
    n_left = fs_rdd$N[1],
    n_right = fs_rdd$N[2],
    p_value = fs_rdd$pv[3]
  )
  fwrite(fs_results, paste0(data_dir, "first_stage_results.csv"))
} else {
  cat("  Insufficient ERDF variation for RDD first stage; proceeding with reduced form.\n")
  fs_results <- data.table(spec = "First Stage", coef = NA, se = NA)
  fwrite(fs_results, paste0(data_dir, "first_stage_results.csv"))
}

## ---------------------------------------------------------
## 2. Reduced-Form RDD: GDP growth at 75% threshold
## ---------------------------------------------------------
cat("\n2. Reduced-form RDD: GDP at threshold\n")

# Primary outcome: change in GDP per capita (% EU27)
rdd_data <- analysis[!is.na(rv_centered) & !is.na(delta_gdp) & abs(rv_centered) <= 30]
cat("  Observations within ±30pp:", nrow(rdd_data), "\n")

# CCT optimal bandwidth
rdd_gdp <- rdrobust(y = rdd_data$delta_gdp, x = rdd_data$rv_centered, c = 0)
cat("\n  Main RDD (GDP growth):\n")
summary(rdd_gdp)

# Store main result
main_results <- data.table(
  outcome = "GDP_pct_EU27",
  spec = "CCT_optimal",
  coef = rdd_gdp$coef[1],
  se_robust = rdd_gdp$se[3],
  ci_lower = rdd_gdp$ci[3, 1],
  ci_upper = rdd_gdp$ci[3, 2],
  bw_left = rdd_gdp$bws[1, 1],
  bw_right = rdd_gdp$bws[1, 2],
  n_left = rdd_gdp$N[1],
  n_right = rdd_gdp$N[2],
  p_value = rdd_gdp$pv[3],
  h_opt = rdd_gdp$bws[1, 1]
)

## ---------------------------------------------------------
## 3. Alternative bandwidths
## ---------------------------------------------------------
cat("\n3. Bandwidth sensitivity\n")

bws <- c(5, 7.5, 10, 12.5, 15, 20, 25)
bw_results <- list()

for (h in bws) {
  sub <- rdd_data[abs(rv_centered) <= h]
  if (nrow(sub) < 20) next

  tryCatch({
    rdd_h <- rdrobust(y = sub$delta_gdp, x = sub$rv_centered, c = 0, h = h)
    bw_results[[as.character(h)]] <- data.table(
      outcome = "GDP_pct_EU27",
      spec = paste0("bw_", h),
      coef = rdd_h$coef[1],
      se_robust = rdd_h$se[3],
      ci_lower = rdd_h$ci[3, 1],
      ci_upper = rdd_h$ci[3, 2],
      bw_left = h,
      bw_right = h,
      n_left = rdd_h$N[1],
      n_right = rdd_h$N[2],
      p_value = rdd_h$pv[3],
      h_opt = h
    )
    cat("  bw=", h, ": coef=", round(rdd_h$coef[1], 3),
        " (SE=", round(rdd_h$se[3], 3), ")\n")
  }, error = function(e) cat("  bw=", h, ": failed\n"))
}

## ---------------------------------------------------------
## 4. Employment rate RDD
## ---------------------------------------------------------
cat("\n4. Employment rate RDD\n")

rdd_data_emp <- analysis[!is.na(rv_centered) & !is.na(delta_emp) & abs(rv_centered) <= 30]

if (nrow(rdd_data_emp) >= 30) {
  rdd_emp <- rdrobust(y = rdd_data_emp$delta_emp, x = rdd_data_emp$rv_centered, c = 0)
  cat("  Employment RDD:\n")
  summary(rdd_emp)

  emp_result <- data.table(
    outcome = "Employment_rate",
    spec = "CCT_optimal",
    coef = rdd_emp$coef[1],
    se_robust = rdd_emp$se[3],
    ci_lower = rdd_emp$ci[3, 1],
    ci_upper = rdd_emp$ci[3, 2],
    bw_left = rdd_emp$bws[1, 1],
    bw_right = rdd_emp$bws[1, 2],
    n_left = rdd_emp$N[1],
    n_right = rdd_emp$N[2],
    p_value = rdd_emp$pv[3],
    h_opt = rdd_emp$bws[1, 1]
  )
} else {
  cat("  Insufficient data for employment RDD\n")
  emp_result <- data.table(outcome = "Employment_rate", spec = "CCT_optimal",
    coef = NA, se_robust = NA, ci_lower = NA, ci_upper = NA,
    bw_left = NA, bw_right = NA, n_left = NA, n_right = NA,
    p_value = NA, h_opt = NA)
}

## ---------------------------------------------------------
## 5. Manufacturing share RDD (mechanism)
## ---------------------------------------------------------
cat("\n5. Manufacturing share RDD (mechanism)\n")

rdd_data_mfg <- analysis[!is.na(rv_centered) & !is.na(delta_mfg_share) & abs(rv_centered) <= 30]

if (nrow(rdd_data_mfg) >= 30) {
  rdd_mfg <- rdrobust(y = rdd_data_mfg$delta_mfg_share,
                       x = rdd_data_mfg$rv_centered, c = 0)
  cat("  Manufacturing share RDD:\n")
  summary(rdd_mfg)

  mfg_result <- data.table(
    outcome = "Mfg_GVA_share",
    spec = "CCT_optimal",
    coef = rdd_mfg$coef[1],
    se_robust = rdd_mfg$se[3],
    ci_lower = rdd_mfg$ci[3, 1],
    ci_upper = rdd_mfg$ci[3, 2],
    bw_left = rdd_mfg$bws[1, 1],
    bw_right = rdd_mfg$bws[1, 2],
    n_left = rdd_mfg$N[1],
    n_right = rdd_mfg$N[2],
    p_value = rdd_mfg$pv[3],
    h_opt = rdd_mfg$bws[1, 1]
  )
} else {
  cat("  Insufficient data for manufacturing share RDD\n")
  mfg_result <- data.table(outcome = "Mfg_GVA_share", spec = "CCT_optimal",
    coef = NA, se_robust = NA, ci_lower = NA, ci_upper = NA,
    bw_left = NA, bw_right = NA, n_left = NA, n_right = NA,
    p_value = NA, h_opt = NA)
}

## ---------------------------------------------------------
## 6. Parametric RDD (for comparison)
## ---------------------------------------------------------
cat("\n6. Parametric RDD specifications\n")

# Linear, with country FE
param_data <- analysis[!is.na(rv_centered) & !is.na(delta_gdp)]

param1 <- feols(delta_gdp ~ graduated * rv_centered | country,
  data = param_data[abs(rv_centered) <= 15])
cat("  Linear (bw=15):", coef(param1)["graduated"], "\n")

param2 <- feols(delta_gdp ~ graduated * rv_centered + graduated * I(rv_centered^2) | country,
  data = param_data[abs(rv_centered) <= 20])
cat("  Quadratic (bw=20):", coef(param2)["graduated"], "\n")

# Save parametric results
param_results <- data.table(
  outcome = "GDP_pct_EU27",
  spec = c("param_linear_15", "param_quad_20"),
  coef = c(coef(param1)["graduated"], coef(param2)["graduated"]),
  se_robust = c(se(param1)["graduated"], se(param2)["graduated"]),
  n_obs = c(nobs(param1), nobs(param2))
)

## ---------------------------------------------------------
## 7. Event study: annual GDP trajectory
## ---------------------------------------------------------
cat("\n7. Event study\n")

# For regions near the threshold (±15pp)
es_data <- annual[!is.na(rv_centered) & abs(rv_centered) <= 15 & year >= 2003]

# Create relative time to treatment (2014)
es_data[, rel_year := year - 2014]

# Event study regression
es_data[, graduated_f := factor(graduated)]
es_data[, rel_year_f := factor(rel_year)]

# Interaction of graduated × year (omitting year -1 as reference)
es_reg <- feols(gdp_pct ~ i(rel_year, graduated, ref = -1) | geo + year,
  data = es_data, cluster = ~geo)

cat("  Event study estimated.\n")
summary(es_reg)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_reg), keep.rownames = "term")
es_coefs <- es_coefs[grepl("rel_year::", term)]
es_coefs[, rel_year := as.integer(gsub("rel_year::(-?\\d+):graduated", "\\1", term))]

fwrite(es_coefs, paste0(data_dir, "event_study_coefs.csv"))

## ---------------------------------------------------------
## 8. Compile all results
## ---------------------------------------------------------
all_results <- rbindlist(list(
  main_results,
  rbindlist(bw_results, fill = TRUE),
  emp_result,
  mfg_result
), fill = TRUE)

fwrite(all_results, paste0(data_dir, "main_results.csv"))
fwrite(param_results, paste0(data_dir, "parametric_results.csv"))

# Summary statistics for Table 1
sumstat_data <- analysis[abs(rv_centered) <= 20 & !is.na(delta_gdp)]
sumstats <- data.table(
  variable = c("GDP/cap (% EU27), 2008-2010 avg",
               "GDP/cap (% EU27), 2007-2013 avg",
               "GDP/cap (% EU27), 2014-2020 avg",
               "Change in GDP/cap (pp)",
               "Employment rate (%), 2007-2013",
               "Employment rate (%), 2014-2020",
               "Change in employment (pp)",
               "Manufacturing GVA share, pre",
               "Manufacturing GVA share, post",
               "N regions"),
  below_75 = c(
    round(mean(sumstat_data[graduated == 0]$running_var, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 0]$gdp_pct_pre, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 0]$gdp_pct_post, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 0]$delta_gdp, na.rm = TRUE), 2),
    round(mean(sumstat_data[graduated == 0]$emp_pre, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 0]$emp_post, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 0]$delta_emp, na.rm = TRUE), 2),
    round(mean(sumstat_data[graduated == 0]$mfg_share_pre, na.rm = TRUE), 3),
    round(mean(sumstat_data[graduated == 0]$mfg_share_post, na.rm = TRUE), 3),
    sumstat_data[graduated == 0, .N]
  ),
  above_75 = c(
    round(mean(sumstat_data[graduated == 1]$running_var, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 1]$gdp_pct_pre, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 1]$gdp_pct_post, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 1]$delta_gdp, na.rm = TRUE), 2),
    round(mean(sumstat_data[graduated == 1]$emp_pre, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 1]$emp_post, na.rm = TRUE), 1),
    round(mean(sumstat_data[graduated == 1]$delta_emp, na.rm = TRUE), 2),
    round(mean(sumstat_data[graduated == 1]$mfg_share_pre, na.rm = TRUE), 3),
    round(mean(sumstat_data[graduated == 1]$mfg_share_post, na.rm = TRUE), 3),
    sumstat_data[graduated == 1, .N]
  )
)

fwrite(sumstats, paste0(data_dir, "summary_statistics.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Results saved to:", data_dir, "\n")
