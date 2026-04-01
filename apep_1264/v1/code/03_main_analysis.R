# 03_main_analysis.R — Main empirical analysis
# Paper: The Growth Ceiling (apep_1264)
source("code/00_packages.R")

data_dir <- "data"

# Load analysis datasets
panel <- fread(file.path(data_dir, "panel_canton_size_year.csv"))
canton_year <- fread(file.path(data_dir, "panel_canton_year.csv"))
national <- fread(file.path(data_dir, "national_size_year.csv"))

# ===========================================================================
# DESCRIPTIVE: National firm-size distribution over time
# ===========================================================================
cat("=== Descriptive: National firm-size distribution ===\n")

key_years <- c(2011, 2015, 2019, 2020, 2021, 2022, 2023)
for (y in key_years) {
  row_med <- national[year == y & size_label == "50-249"]
  row_sm <- national[year == y & size_label == "10-49"]
  cat(sprintf("  %d: medium=%5.0f (avg=%.1f), small=%5.0f (avg=%.1f), ratio=%.2f\n",
              y, row_med$n_workplaces, row_med$avg_emp,
              row_sm$n_workplaces, row_sm$avg_emp,
              row_sm$n_workplaces / row_med$n_workplaces))
}

# ===========================================================================
# MODEL 1: DiD — Average firm size, 50-249 vs 10-49, pre/post 2020
# ===========================================================================
cat("\n=== Model 1: DiD on average employment per workplace ===\n")

panel[, post_2020 := as.integer(year >= 2020)]
panel[, medium_bin := as.integer(size_class == 3)]

# Compare medium (50-249) and small (10-49) bins
panel_did <- panel[size_class %in% c(2, 3)]

m1 <- feols(avg_emp ~ medium_bin:post_2020 | canton_id + year + size_class,
            data = panel_did, cluster = ~canton_id)
cat("DiD coefficient (medium × post):", round(coef(m1), 3), "\n")
cat("SE:", round(sqrt(diag(vcov(m1))), 3), "\n")
print(summary(m1))

# ===========================================================================
# MODEL 2: Event study — year × medium interactions
# ===========================================================================
cat("\n=== Model 2: Event study ===\n")

panel_did[, year_f := factor(year)]
panel_did[, year_f := relevel(year_f, ref = "2019")]

m2 <- feols(avg_emp ~ i(year_f, medium_bin, ref = "2019") |
              canton_id + year + size_class,
            data = panel_did, cluster = ~canton_id)
print(summary(m2))

# Extract and store event study coefficients
es_coefs <- coef(m2)
es_se <- sqrt(diag(vcov(m2)))
es_years <- as.numeric(gsub(".*::(\\d{4}):.*", "\\1", names(es_coefs)))
es_df <- data.table(
  year = es_years,
  coef = es_coefs,
  se = es_se,
  ci_lo = es_coefs - 1.96 * es_se,
  ci_hi = es_coefs + 1.96 * es_se
)[order(year)]
cat("\nEvent study coefficients (ref = 2019):\n")
print(es_df)

# Pre-trend test: F-test on pre-2020 coefficients
pre_coefs <- names(es_coefs)[es_years < 2019]
if (length(pre_coefs) > 0) {
  pre_test <- tryCatch(
    wald(m2, keep = pre_coefs),
    error = function(e) NULL
  )
  if (!is.null(pre_test)) {
    cat("\nJoint pre-trend F-test:\n")
    print(pre_test)
  }
}

# ===========================================================================
# MODEL 3: Cross-threshold comparison
# ===========================================================================
cat("\n=== Model 3: Cross-threshold comparison ===\n")

panel[, size_f := factor(size_class)]
panel[, log_n := log(n_workplaces)]

# Compare growth of medium vs other bins using canton-year variation
# Use log ratio of medium to small firms as outcome
m3a <- feols(log(n_workplaces) ~ medium_bin:post_2020 |
               canton_id^size_class + year,
             data = panel[size_class %in% c(2, 3)], cluster = ~canton_id)
cat("Model 3a: Log(firms), medium vs small, post-2020:\n")
print(summary(m3a))

# Also compare medium to large
m3b <- feols(log(n_workplaces) ~ i(size_class == 3):post_2020 |
               canton_id^size_class + year,
             data = panel[size_class %in% c(3, 4)], cluster = ~canton_id)
cat("\nModel 3b: Log(firms), medium vs large, post-2020:\n")
print(summary(m3b))

# ===========================================================================
# MODEL 4: Continuous treatment — pre-period medium-firm intensity
# ===========================================================================
cat("\n=== Model 4: Exposure-based DiD ===\n")

# Canton-level exposure: share of medium firms in total firms (pre-period avg)
canton_exposure <- canton_year[post_gea == 0,
                               .(med_share_pre = mean(share_medium, na.rm = TRUE)),
                               by = canton_id]
canton_year <- merge(canton_year, canton_exposure, by = "canton_id", all.x = TRUE)
canton_year[, post_gea := as.integer(year >= 2020)]
canton_year[, exposure_post := med_share_pre * post_gea]

# Average firm size in medium bin — cantons with more medium firms more exposed
m4 <- feols(avg_medium ~ exposure_post | canton_id + year,
            data = canton_year, cluster = ~canton_id)
cat("Exposure DiD (pre-period medium share × post):\n")
print(summary(m4))

# ===========================================================================
# MODEL 5: Female share — GEA mechanism test
# ===========================================================================
cat("\n=== Model 5: Female employment share ===\n")

# If GEA drives behavioral change, female share should change in medium bin
panel_fem <- panel[size_class %in% c(2, 3)]

m5 <- feols(female_share ~ medium_bin:post_2020 | canton_id + year + size_class,
            data = panel_fem, cluster = ~canton_id)
cat("DiD on female share (medium × post):\n")
print(summary(m5))

# Event study for female share
panel_fem[, year_f := factor(year)]
panel_fem[, year_f := relevel(year_f, ref = "2019")]

m5_es <- feols(female_share ~ i(year_f, medium_bin, ref = "2019") |
                 canton_id + year + size_class,
               data = panel_fem, cluster = ~canton_id)

fem_coefs <- coef(m5_es)
fem_se <- sqrt(diag(vcov(m5_es)))
fem_years <- as.numeric(gsub(".*::(\\d{4}):.*", "\\1", names(fem_coefs)))
fem_df <- data.table(
  year = fem_years,
  coef = fem_coefs,
  se = fem_se
)[order(year)]
cat("\nFemale share event study:\n")
print(fem_df)

# ===========================================================================
# MODEL 6: Growth rate analysis — did medium-bin growth slow?
# ===========================================================================
cat("\n=== Model 6: Growth rate ===\n")

# Annual growth rate of firm count by size class
panel <- panel[order(canton_id, size_class, year)]
panel[, lag_n := shift(n_workplaces, 1), by = .(canton_id, size_class)]
panel[, growth := (n_workplaces - lag_n) / lag_n]

# Remove NAs from growth (first year)
m6 <- feols(growth ~ i(size_f, post_2020, ref = "1") |
              canton_id^size_class + year,
            data = panel[!is.na(growth)], cluster = ~canton_id)
cat("Size-specific growth rate post-2020:\n")
print(summary(m6))

# ===========================================================================
# Save diagnostics and results
# ===========================================================================
n_treated <- length(unique(panel[size_class == 3, canton_id]))
n_pre <- sum(unique(panel$year) < 2020)
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

# Save results for table generation
results <- list(
  m1_coef = as.numeric(coef(m1)),
  m1_se = as.numeric(sqrt(diag(vcov(m1)))),
  m1_n = m1$nobs,
  es_df = es_df,
  fem_df = fem_df,
  national = national,
  sd_avg_medium_pre = sd(canton_year[post_gea == 0, avg_medium], na.rm = TRUE),
  m3a_coef = as.numeric(coef(m3a)),
  m3a_se = as.numeric(sqrt(diag(vcov(m3a)))),
  m5_coef = as.numeric(coef(m5)),
  m5_se = as.numeric(sqrt(diag(vcov(m5))))
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

cat("\n=== Main analysis complete ===\n")
cat("Key finding: DiD on avg firm size (50-249 vs 10-49):",
    round(results$m1_coef, 3), "±", round(results$m1_se, 3), "\n")
cat("Interpretation: Positive coefficient = avg size INCREASED in medium bin\n")
cat("This is OPPOSITE of the bunching prediction → GEA null\n")
