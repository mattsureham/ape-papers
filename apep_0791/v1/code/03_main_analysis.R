# ==============================================================================
# 03_main_analysis.R — Primary Regressions
# Paper: The Credential Equity Trap (apep_0791)
# ==============================================================================

source("00_packages.R")

panel <- readRDS(file.path("..", "data", "analysis_panel.rds"))
race_panel <- readRDS(file.path("..", "data", "race_panel.rds"))

# ---- 1. DD: Total completions ----
cat("=== DD: Total Completions ===\n")
m1_total <- feols(log_total ~ forprofit:ge_active + forprofit:post_repeal |
                    unitid + year,
                  data = panel, cluster = ~unitid)
print(summary(m1_total))

# ---- 2. DD: Minority completion share ----
cat("\n=== DD: Minority Share ===\n")
m2_share <- feols(minority_share ~ forprofit:ge_active + forprofit:post_repeal |
                    unitid + year,
                  data = panel, cluster = ~unitid)
print(summary(m2_share))

# ---- 3. DD: Log minority completions ----
cat("\n=== DD: Log Minority Completions ===\n")
m3_minority <- feols(log_minority ~ forprofit:ge_active + forprofit:post_repeal |
                       unitid + year,
                     data = panel, cluster = ~unitid)
print(summary(m3_minority))

# ---- 4. DD: Log white completions (placebo) ----
cat("\n=== DD: Log White Completions (placebo) ===\n")
m4_white <- feols(log_white ~ forprofit:ge_active + forprofit:post_repeal |
                    unitid + year,
                  data = panel, cluster = ~unitid)
print(summary(m4_white))

# ---- 5. DDD: Race-stacked panel ----
cat("\n=== DDD: Minority × ForProfit × Period ===\n")
# Create triple interaction variables directly
race_panel[, fp_min := forprofit * minority]
race_panel[, fp_ge := forprofit * ge_active]
race_panel[, min_ge := minority * ge_active]
race_panel[, fp_min_ge := forprofit * minority * ge_active]
race_panel[, fp_rep := forprofit * post_repeal]
race_panel[, min_rep := minority * post_repeal]
race_panel[, fp_min_rep := forprofit * minority * post_repeal]

# Full DDD with all two-way interactions
m5_ddd <- feols(log_comp ~ fp_min_ge + fp_min_rep |
                  unitid_race + race_year + unitid_year,
                data = race_panel, cluster = ~unitid)
print(summary(m5_ddd))

# ---- 6. Event study (annual) for pre-trend check ----
cat("\n=== Event Study: Minority Share ===\n")
m6_event <- feols(minority_share ~ i(year, forprofit, ref = 2014) |
                    unitid + year,
                  data = panel, cluster = ~unitid)
print(summary(m6_event))

# ---- 7. Save model objects ----
models <- list(
  total = m1_total,
  share = m2_share,
  minority = m3_minority,
  white = m4_white,
  ddd = m5_ddd,
  event = m6_event
)
saveRDS(models, file.path("..", "data", "main_models.rds"))

# ---- 8. Write diagnostics.json ----
diag <- list(
  n_treated = uniqueN(panel[forprofit == 1, unitid]),
  n_control = uniqueN(panel[forprofit == 0, unitid]),
  n_pre = length(unique(panel[year < 2015, year])),
  n_post = length(unique(panel[year >= 2015, year])),
  n_obs = nrow(panel),
  n_obs_race = nrow(race_panel),
  year_range = paste(range(panel$year), collapse = "-"),
  mean_total_comp_fp = round(mean(panel[forprofit == 1, total_comp], na.rm = TRUE), 1),
  mean_total_comp_pub = round(mean(panel[forprofit == 0, total_comp], na.rm = TRUE), 1),
  mean_minority_share_fp = round(mean(panel[forprofit == 1, minority_share], na.rm = TRUE), 3),
  mean_minority_share_pub = round(mean(panel[forprofit == 0, minority_share], na.rm = TRUE), 3)
)
jsonlite::write_json(diag, file.path("..", "data", "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics:\n")
print(data.frame(unlist(diag)))
cat("\nMain analysis complete.\n")
