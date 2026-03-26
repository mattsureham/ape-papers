## 03_main_analysis.R — IV estimation of SNAP retailer loss on participation
## apep_1023: Redemption Deserts

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
cat(sprintf("Analysis panel: %d rows, %d tracts\n", nrow(df), n_distinct(df$GEOID)))

# === Table 1: Summary Statistics ===
cat("\n=== Summary Statistics ===\n")

summ_vars <- c("snap_rate", "n_retailers", "net_exits", "n_exits", "n_new",
               "poverty_rate", "no_vehicle_rate", "log_pop", "log_med_inc",
               "pct_black", "pct_hispanic", "pre_small_share")

summ_df <- df %>%
  select(all_of(summ_vars)) %>%
  pivot_longer(everything()) %>%
  group_by(name) %>%
  summarise(
    N = sum(!is.na(value)),
    Mean = mean(value, na.rm = TRUE),
    SD = sd(value, na.rm = TRUE),
    Min = min(value, na.rm = TRUE),
    Max = max(value, na.rm = TRUE),
    .groups = "drop"
  )

print(summ_df, n = 20)
saveRDS(summ_df, "../data/summary_stats.rds")

# === OLS Baseline (Table 2) ===
cat("\n=== OLS Estimates ===\n")

# Specification 1: No controls, county + year FE
ols1 <- feols(snap_rate ~ net_exits | county_fips + year,
              data = df, cluster = ~county_fips)

# Specification 2: With controls
ols2 <- feols(snap_rate ~ net_exits + poverty_rate + log_pop + log_med_inc +
                pct_black + pct_hispanic | county_fips + year,
              data = df, cluster = ~county_fips)

# Specification 3: Tract FE + year FE
ols3 <- feols(snap_rate ~ net_exits | GEOID + year,
              data = df, cluster = ~county_fips)

# Specification 4: Tract FE + controls
ols4 <- feols(snap_rate ~ net_exits + poverty_rate + log_pop + log_med_inc |
                GEOID + year,
              data = df, cluster = ~county_fips)

cat("OLS Results:\n")
etable(ols1, ols2, ols3, ols4,
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10))

# === First Stage (Table 3) ===
cat("\n=== First Stage Regressions ===\n")

# First stage 1: Corporate shocks only
fs1 <- feols(net_exits ~ iv_fd + iv_wm + iv_ap | county_fips + year,
             data = df, cluster = ~county_fips)

# First stage 2: Stocking rule only
fs2 <- feols(net_exits ~ iv_stock_rule | county_fips + year,
             data = df, cluster = ~county_fips)

# First stage 3: All instruments
fs3 <- feols(net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule | county_fips + year,
             data = df, cluster = ~county_fips)

# First stage 4: All instruments + tract FE
fs4 <- feols(net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule | GEOID + year,
             data = df, cluster = ~county_fips)

cat("First Stage Results:\n")
etable(fs1, fs2, fs3, fs4,
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10))

# Report F-statistics for instrument relevance
f_stat_1 <- fitstat(fs1, type = "ivwald")
f_stat_2 <- fitstat(fs2, type = "ivwald")
f_stat_3 <- fitstat(fs3, type = "ivwald")
cat(sprintf("\nFirst-stage F-statistics:\n"))
cat(sprintf("  Corporate shocks only: F = %.1f\n", summary(fs1)$fstatistic[[1]]))
cat(sprintf("  Stocking rule only: F = %.1f\n", summary(fs2)$fstatistic[[1]]))
cat(sprintf("  All instruments: F = %.1f\n", summary(fs3)$fstatistic[[1]]))

# === IV/2SLS Estimation (Table 4) ===
cat("\n=== IV Estimates ===\n")

# IV Specification 1: Corporate shocks as IVs, county FE
iv1 <- feols(snap_rate ~ 1 | county_fips + year | net_exits ~ iv_fd + iv_wm + iv_ap,
             data = df, cluster = ~county_fips)

# IV Specification 2: Stocking rule as IV, county FE
iv2 <- feols(snap_rate ~ 1 | county_fips + year | net_exits ~ iv_stock_rule,
             data = df, cluster = ~county_fips)

# IV Specification 3: All instruments, county FE
iv3 <- feols(snap_rate ~ 1 | county_fips + year | net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
             data = df, cluster = ~county_fips)

# IV Specification 4: All instruments + controls, county FE
iv4 <- feols(snap_rate ~ poverty_rate + log_pop + log_med_inc | county_fips + year |
               net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
             data = df, cluster = ~county_fips)

# IV Specification 5: All instruments, tract FE
iv5 <- feols(snap_rate ~ 1 | GEOID + year | net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
             data = df, cluster = ~county_fips)

cat("IV Results:\n")
etable(iv1, iv2, iv3, iv4, iv5,
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = c("n", "r2", "ivf", "sargan"))

# Store IV results for SDE computation
iv_main <- iv3  # Primary specification
coef_main <- coef(iv_main)["fit_net_exits"]
se_main <- se(iv_main)["fit_net_exits"]
cat(sprintf("\nMain IV estimate: β = %.6f (SE = %.6f)\n", coef_main, se_main))

# === Reduced Form (Table 4 Panel B) ===
cat("\n=== Reduced Form Estimates ===\n")

rf1 <- feols(snap_rate ~ iv_fd + iv_wm + iv_ap | county_fips + year,
             data = df, cluster = ~county_fips)

rf2 <- feols(snap_rate ~ iv_stock_rule | county_fips + year,
             data = df, cluster = ~county_fips)

rf3 <- feols(snap_rate ~ iv_fd + iv_wm + iv_ap + iv_stock_rule | county_fips + year,
             data = df, cluster = ~county_fips)

cat("Reduced Form Results:\n")
etable(rf1, rf2, rf3,
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10))

# === Mechanism Tests ===
cat("\n=== Mechanism: Vehicle Access ===\n")

# Split by vehicle access (above/below median no-vehicle rate)
med_veh <- median(df$no_vehicle_rate, na.rm = TRUE)
df$high_noveh <- as.integer(df$no_vehicle_rate > med_veh)

iv_low_veh <- feols(snap_rate ~ 1 | county_fips + year |
                      net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                    data = df[df$high_noveh == 0, ], cluster = ~county_fips)

iv_high_veh <- feols(snap_rate ~ 1 | county_fips + year |
                       net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                     data = df[df$high_noveh == 1, ], cluster = ~county_fips)

cat("Low no-vehicle tracts:\n")
cat(sprintf("  β = %.6f (SE = %.6f)\n",
            coef(iv_low_veh)["fit_net_exits"], se(iv_low_veh)["fit_net_exits"]))
cat("High no-vehicle tracts:\n")
cat(sprintf("  β = %.6f (SE = %.6f)\n",
            coef(iv_high_veh)["fit_net_exits"], se(iv_high_veh)["fit_net_exits"]))

# === Last-retailer mechanism ===
cat("\n=== Mechanism: Last Retailer ===\n")

# Flag tracts where exiting retailer was the last one
df$had_one_retailer <- as.integer(df$n_retailers <= 1 & df$n_exits > 0)

iv_not_last <- feols(snap_rate ~ 1 | county_fips + year |
                       net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                     data = df[df$n_retailers > 1 | df$n_exits == 0, ],
                     cluster = ~county_fips)

cat(sprintf("Tracts with >1 retailer: β = %.6f (SE = %.6f)\n",
            coef(iv_not_last)["fit_net_exits"], se(iv_not_last)["fit_net_exits"]))

# === Diagnostics ===
cat("\n=== Writing diagnostics.json ===\n")

n_treated <- n_distinct(df$GEOID[df$net_exits > 0])
n_pre <- length(unique(df$year[df$year < 2018]))
n_obs <- nrow(df)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_tracts = n_distinct(df$GEOID),
  n_counties = n_distinct(df$county_fips),
  n_years = length(unique(df$year)),
  iv_fstat_corporate = summary(fs1)$fstatistic[[1]],
  iv_fstat_all = summary(fs3)$fstatistic[[1]],
  iv_coef = as.numeric(coef_main),
  iv_se = as.numeric(se_main)
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Saved diagnostics.json\n")

# Save all model objects for table generation
save(ols1, ols2, ols3, ols4,
     fs1, fs2, fs3, fs4,
     iv1, iv2, iv3, iv4, iv5,
     rf1, rf2, rf3,
     iv_low_veh, iv_high_veh, iv_not_last,
     summ_df, df,
     file = "../data/all_models.RData")

cat("\n=== Main analysis complete ===\n")
