## 03_main_analysis.R — Main DiD regressions and event study
## APEP paper apep_0631

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Loaded panel:", nrow(panel), "obs,", uniqueN(panel$zip), "zips\n")

# Ensure proper types
panel[, `:=`(
  date = as.Date(date),
  zip = as.character(zip)
)]

## ── 1. Summary Statistics by SALT Exposure Quartile ──
cat("\n=== Summary Statistics ===\n")

# Zip-level summary (cross-section)
zip_summary <- panel[year == 2017, .(
  mean_zhvi = mean(zhvi, na.rm = TRUE),
  mean_salt = mean(avg_salt, na.rm = TRUE),
  mean_bite = mean(salt_bite, na.rm = TRUE),
  n_zips = uniqueN(zip),
  mean_n_returns = mean(n_returns, na.rm = TRUE)
), by = salt_group]

print(zip_summary)

# Overall summary stats for the panel
panel_stats <- panel[, .(
  mean_zhvi = mean(zhvi, na.rm = TRUE),
  sd_zhvi = sd(zhvi, na.rm = TRUE),
  mean_log_zhvi = mean(log_zhvi, na.rm = TRUE),
  sd_log_zhvi = sd(log_zhvi, na.rm = TRUE),
  mean_salt = mean(avg_salt, na.rm = TRUE),
  sd_salt = sd(avg_salt, na.rm = TRUE),
  mean_bite = mean(salt_bite, na.rm = TRUE),
  sd_bite = sd(salt_bite, na.rm = TRUE),
  n_obs = .N,
  n_zips = uniqueN(zip),
  n_months = uniqueN(date)
)]
cat("\nOverall panel statistics:\n")
print(panel_stats)

## ── 2. Main DiD: TCJA Cap Effect ──
cat("\n=== Main DiD Regressions ===\n")

# Specification 1: Zip + month FE, no controls
fit1 <- feols(log_zhvi ~ post_tcja:salt_bite | zip_id + time_id,
              data = panel, cluster = ~state_fips)
cat("\nSpec 1 (Zip + Month FE):\n")
summary(fit1)

# Specification 2: Zip + month FE, separate OBBB period
fit2 <- feols(log_zhvi ~ post_tcja:salt_bite + post_obbb:salt_bite | zip_id + time_id,
              data = panel, cluster = ~state_fips)
cat("\nSpec 2 (Separate TCJA and OBBB):\n")
summary(fit2)

# Specification 3: Metro × month FE (preferred — absorbs metro-level trends)
# Only for zips with non-missing metro
panel_metro <- panel[!is.na(Metro) & Metro != ""]
cat("\nPanel with metro:", nrow(panel_metro), "obs,", uniqueN(panel_metro$zip), "zips\n")

fit3 <- feols(log_zhvi ~ post_tcja:salt_bite | zip_id + metro_id^time_id,
              data = panel_metro, cluster = ~state_fips)
cat("\nSpec 3 (Zip + Metro×Month FE):\n")
summary(fit3)

# Specification 4: Metro × month FE with separate OBBB
fit4 <- feols(log_zhvi ~ post_tcja:salt_bite + post_obbb:salt_bite | zip_id + metro_id^time_id,
              data = panel_metro, cluster = ~state_fips)
cat("\nSpec 4 (Metro×Month FE, separate shocks):\n")
summary(fit4)

# Store key coefficients
tcja_coef <- coef(fit3)["post_tcja:salt_bite"]
tcja_se <- se(fit3)["post_tcja:salt_bite"]
cat("\n=== KEY RESULT ===\n")
cat(sprintf("TCJA cap effect (metro×month FE): %.4f (SE: %.4f)\n", tcja_coef, tcja_se))
cat(sprintf("Interpretation: A $10K increase in SALT bite → %.1f%% decline in house prices\n",
            tcja_coef * 100))

## ── 3. Event Study ──
cat("\n=== Event Study ===\n")

# Create annual dummies relative to TCJA (2018 = 0, reference = 2017 = -1)
panel[, year_rel := year - 2018]

# Bin endpoints
panel[, year_rel_bin := pmin(pmax(year_rel, -5), 7)]
panel[, year_rel_factor := relevel(factor(year_rel_bin), ref = "-1")]

# Event study with zip + month FE
fit_es <- feols(log_zhvi ~ i(year_rel_bin, salt_bite, ref = -1) | zip_id + time_id,
                data = panel[year_rel_bin >= -5 & year_rel_bin <= 7],
                cluster = ~state_fips)
cat("\nEvent study coefficients:\n")
summary(fit_es)

# Update panel_metro with year_rel_bin
panel_metro <- panel[!is.na(Metro) & Metro != ""]

# Event study with metro × month FE
fit_es_metro <- feols(log_zhvi ~ i(year_rel_bin, salt_bite, ref = -1) | zip_id + metro_id^time_id,
                      data = panel_metro[year_rel_bin >= -5 & year_rel_bin <= 7],
                      cluster = ~state_fips)
cat("\nEvent study (metro×month FE):\n")
summary(fit_es_metro)

## ── 4. Save regression objects ──
saveRDS(list(
  fit1 = fit1, fit2 = fit2, fit3 = fit3, fit4 = fit4,
  fit_es = fit_es, fit_es_metro = fit_es_metro,
  panel_stats = panel_stats, zip_summary = zip_summary
), file.path(data_dir, "main_results.rds"))

## ── 5. Write diagnostics.json ──
# Count treated units (zips with salt_bite > 0)
n_treated <- uniqueN(panel$zip[panel$salt_bite > 0])
n_pre <- length(unique(panel$year[panel$year < 2018]))
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_zips = uniqueN(panel$zip),
  n_months = uniqueN(panel$date),
  tcja_coef = round(tcja_coef, 6),
  tcja_se = round(tcja_se, 6),
  salt_bite_sd = round(sd(panel$avg_salt[!duplicated(panel$zip)], na.rm = TRUE), 2)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\ndiagnostics.json written.\n")
cat(sprintf("n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated, n_pre, n_obs))
