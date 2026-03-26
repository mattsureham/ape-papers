## 04_robustness.R — Robustness checks with TRACT FE as preferred spec
## apep_1023: Redemption Deserts

source("00_packages.R")

load("../data/all_models.RData")

cat("=== Robustness Checks (Tract FE preferred) ===\n")

# Preferred spec: tract FE + year FE, all instruments
# From main analysis: iv5 gives β = -0.059 (tract FE)

# === 1. Leave-one-instrument-out (tract FE) ===
cat("\n--- Leave-One-Instrument-Out (Tract FE) ---\n")

iv_tfe_no_fd <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_wm + iv_ap + iv_stock_rule,
                      data = df, cluster = ~county_fips)

iv_tfe_no_wm <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_ap + iv_stock_rule,
                      data = df, cluster = ~county_fips)

iv_tfe_no_ap <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_stock_rule,
                      data = df, cluster = ~county_fips)

iv_tfe_no_sr <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_ap,
                      data = df, cluster = ~county_fips)

cat("Leave-one-out (tract FE):\n")
etable(iv_tfe_no_fd, iv_tfe_no_wm, iv_tfe_no_ap, iv_tfe_no_sr,
       se.below = TRUE)

# === 2. Placebo: Poverty rate (tract FE) ===
cat("\n--- Placebo: Poverty Rate (Tract FE) ---\n")

placebo_pov_tfe <- feols(poverty_rate ~ 1 | GEOID + year |
                           net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                         data = df, cluster = ~county_fips)

cat(sprintf("Placebo poverty: β = %.6f (SE = %.6f, p = %.4f)\n",
            coef(placebo_pov_tfe)["fit_net_exits"],
            se(placebo_pov_tfe)["fit_net_exits"],
            pvalue(placebo_pov_tfe)["fit_net_exits"]))

# === 3. Vehicle access mechanism (tract FE) ===
cat("\n--- Vehicle Access Split (Tract FE) ---\n")

# Use baseline (first-year) no-vehicle rate to avoid bad controls
baseline <- df %>%
  group_by(GEOID) %>%
  summarise(base_noveh = first(no_vehicle_rate[!is.na(no_vehicle_rate)]),
            .groups = "drop")
df <- df %>% left_join(baseline, by = "GEOID")

med_veh <- median(df$base_noveh, na.rm = TRUE)
df$high_noveh <- as.integer(df$base_noveh > med_veh)

iv_tfe_low_veh <- feols(snap_rate ~ 1 | GEOID + year |
                          net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                        data = df[df$high_noveh == 0, ], cluster = ~county_fips)

iv_tfe_high_veh <- feols(snap_rate ~ 1 | GEOID + year |
                           net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                         data = df[df$high_noveh == 1, ], cluster = ~county_fips)

cat(sprintf("Low no-vehicle: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_low_veh)["fit_net_exits"], se(iv_tfe_low_veh)["fit_net_exits"]))
cat(sprintf("High no-vehicle: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_high_veh)["fit_net_exits"], se(iv_tfe_high_veh)["fit_net_exits"]))

# === 4. Poverty split (tract FE) ===
cat("\n--- Poverty Split (Tract FE) ---\n")

baseline_pov <- df %>%
  group_by(GEOID) %>%
  summarise(base_pov = first(poverty_rate[!is.na(poverty_rate)]),
            .groups = "drop")
df <- df %>% left_join(baseline_pov, by = "GEOID")

med_pov <- median(df$base_pov, na.rm = TRUE)
df$high_poverty <- as.integer(df$base_pov > med_pov)

iv_tfe_hipov <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                      data = df[df$high_poverty == 1, ], cluster = ~county_fips)

iv_tfe_lopov <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                      data = df[df$high_poverty == 0, ], cluster = ~county_fips)

cat(sprintf("High-poverty: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_hipov)["fit_net_exits"], se(iv_tfe_hipov)["fit_net_exits"]))
cat(sprintf("Low-poverty: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_lopov)["fit_net_exits"], se(iv_tfe_lopov)["fit_net_exits"]))

# === 5. Urban/rural split (tract FE) ===
cat("\n--- Urban/Rural Split (Tract FE) ---\n")

baseline_pop <- df %>%
  group_by(GEOID) %>%
  summarise(base_pop = first(pop_total[!is.na(pop_total)]),
            .groups = "drop")
df <- df %>% left_join(baseline_pop, by = "GEOID")

med_pop <- median(df$base_pop, na.rm = TRUE)
df$urban <- as.integer(df$base_pop > med_pop)

iv_tfe_urban <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                      data = df[df$urban == 1, ], cluster = ~county_fips)

iv_tfe_rural <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                      data = df[df$urban == 0, ], cluster = ~county_fips)

cat(sprintf("Urban: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_urban)["fit_net_exits"], se(iv_tfe_urban)["fit_net_exits"]))
cat(sprintf("Rural: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_rural)["fit_net_exits"], se(iv_tfe_rural)["fit_net_exits"]))

# === 6. State-level clustering ===
cat("\n--- State Clustering ---\n")

iv_tfe_state <- feols(snap_rate ~ 1 | GEOID + year |
                        net_exits ~ iv_fd + iv_wm + iv_ap + iv_stock_rule,
                      data = df, cluster = ~state_fips)

cat(sprintf("State clustering: β = %.6f (SE = %.6f)\n",
            coef(iv_tfe_state)["fit_net_exits"], se(iv_tfe_state)["fit_net_exits"]))

# Save all robustness objects
save(iv_tfe_no_fd, iv_tfe_no_wm, iv_tfe_no_ap, iv_tfe_no_sr,
     placebo_pov_tfe,
     iv_tfe_low_veh, iv_tfe_high_veh,
     iv_tfe_hipov, iv_tfe_lopov,
     iv_tfe_urban, iv_tfe_rural,
     iv_tfe_state,
     df,
     file = "../data/robustness_models.RData")

cat("\n=== Robustness checks complete ===\n")
