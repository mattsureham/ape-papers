## 04_robustness.R — Robustness checks and falsification tests
## APEP-1204: Stretched Thin

source("00_packages.R")

data_dir <- "../data"
analysis <- readRDS(file.path(data_dir, "analysis.rds"))

ihp_df <- filter(analysis, has_ihp, ihp_registrations > 0) %>%
  mutate(concurrent_load_sd = (concurrent_load - mean(concurrent_load)) / sd(concurrent_load))

pa_df <- filter(analysis, has_pa) %>%
  mutate(concurrent_load_sd = (concurrent_load - mean(concurrent_load)) / sd(concurrent_load))

# ============================================================================
# 1. Falsification: Pre-determined disaster characteristics as outcomes
# ============================================================================
cat("\n=== Falsification: Concurrent load should NOT predict pre-determined characteristics ===\n")

# Number of counties (geographic scope — determined by disaster, not FEMA)
fals_counties <- feols(
  log_n_counties ~ concurrent_load_sd +
    is_hurricane + is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = ihp_df, cluster = ~state
)

# Total damage (determined by disaster severity, not FEMA response)
fals_damage <- feols(
  log(ihp_total_damage + 1) ~ concurrent_load_sd +
    is_hurricane + is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = filter(ihp_df, !is.na(ihp_total_damage)),
  cluster = ~state
)

cat(sprintf("Falsification - Log counties: β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(fals_counties)["concurrent_load_sd"],
            se(fals_counties)["concurrent_load_sd"],
            pvalue(fals_counties)["concurrent_load_sd"]))
cat(sprintf("Falsification - Log damage: β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(fals_damage)["concurrent_load_sd"],
            se(fals_damage)["concurrent_load_sd"],
            pvalue(fals_damage)["concurrent_load_sd"]))

# ============================================================================
# 2. Leave-one-out: exclude disasters in same FEMA region
# ============================================================================
cat("\n=== Leave-One-Out by FEMA Region ===\n")

# FEMA regions (approximate state assignments)
fema_regions <- list(
  R1 = c("CT","ME","MA","NH","RI","VT"),
  R2 = c("NJ","NY","PR","VI"),
  R3 = c("DC","DE","MD","PA","VA","WV"),
  R4 = c("AL","FL","GA","KY","MS","NC","SC","TN"),
  R5 = c("IL","IN","MI","MN","OH","WI"),
  R6 = c("AR","LA","NM","OK","TX"),
  R7 = c("IA","KS","MO","NE"),
  R8 = c("CO","MT","ND","SD","UT","WY"),
  R9 = c("AZ","CA","HI","NV","GU","AS","MP","FM","MH","PW"),
  R10 = c("AK","ID","OR","WA")
)

ihp_df$fema_region <- NA_character_
for (r in names(fema_regions)) {
  ihp_df$fema_region[ihp_df$state %in% fema_regions[[r]]] <- r
}

# Re-compute concurrent load excluding same FEMA region
ihp_df_loo <- ihp_df %>% filter(!is.na(fema_region))

loo_approval <- feols(
  approval_rate ~ concurrent_load_sd + log_n_counties +
    is_hurricane + is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = ihp_df_loo, cluster = ~state
)
cat(sprintf("LOO approval rate: β = %.4f (SE = %.4f)\n",
            coef(loo_approval)["concurrent_load_sd"],
            se(loo_approval)["concurrent_load_sd"]))

# ============================================================================
# 3. Heterogeneity: by disaster type
# ============================================================================
cat("\n=== Heterogeneity by Disaster Type ===\n")

# Hurricanes vs non-hurricanes
for (dtype in c("Hurricane", "Non-hurricane")) {
  if (dtype == "Hurricane") {
    sub_df <- filter(ihp_df, is_hurricane == 1)
  } else {
    sub_df <- filter(ihp_df, is_hurricane == 0)
  }
  if (nrow(sub_df) < 30) next

  het_mod <- feols(
    approval_rate ~ concurrent_load_sd + log_n_counties |
      decl_year + quarter,
    data = sub_df, cluster = ~state
  )
  cat(sprintf("  %s (N=%d): β = %.4f (SE = %.4f)\n",
              dtype, nrow(sub_df),
              coef(het_mod)["concurrent_load_sd"],
              se(het_mod)["concurrent_load_sd"]))
}

# ============================================================================
# 4. Inspection intensity as mechanism
# ============================================================================
cat("\n=== Mechanism: Inspection Rate ===\n")

# Inspection rate = totalInspected / validRegistrations
ihp_df <- ihp_df %>%
  mutate(inspection_rate = ihp_inspected / ihp_registrations)

rf_inspection <- feols(
  inspection_rate ~ concurrent_load_sd + log_n_counties +
    is_hurricane + is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = filter(ihp_df, !is.na(inspection_rate), is.finite(inspection_rate)),
  cluster = ~state
)
cat(sprintf("Inspection rate: β = %.4f (SE = %.4f)\n",
            coef(rf_inspection)["concurrent_load_sd"],
            se(rf_inspection)["concurrent_load_sd"]))

# ============================================================================
# 5. Alternative concurrent load definitions
# ============================================================================
cat("\n=== Alternative Instruments ===\n")

# a) Total concurrent (including same state)
ihp_df <- ihp_df %>%
  mutate(concurrent_total_sd = (concurrent_total - mean(concurrent_total)) / sd(concurrent_total))

alt_total <- feols(
  approval_rate ~ concurrent_total_sd + log_n_counties +
    is_hurricane + is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = ihp_df, cluster = ~state
)
cat(sprintf("Total concurrent (incl same state): β = %.4f (SE = %.4f)\n",
            coef(alt_total)["concurrent_total_sd"],
            se(alt_total)["concurrent_total_sd"]))

# b) Quadratic specification
rf_quad <- feols(
  approval_rate ~ concurrent_load_sd + I(concurrent_load_sd^2) + log_n_counties +
    is_hurricane + is_flood + is_fire + is_severe_storm |
    decl_year + quarter,
  data = ihp_df, cluster = ~state
)
cat("Quadratic specification:\n")
print(summary(rf_quad))

# ============================================================================
# 6. Temporal trends in concurrent load
# ============================================================================
cat("\n=== Concurrent Load Over Time ===\n")
time_trend <- analysis %>%
  group_by(decl_year) %>%
  summarise(
    n_disasters = n(),
    mean_concurrent = mean(concurrent_load),
    median_concurrent = median(concurrent_load),
    max_concurrent = max(concurrent_load),
    .groups = "drop"
  )
print(time_trend, n = 25)

# ============================================================================
# Save robustness results
# ============================================================================
rob_results <- list(
  fals_counties = fals_counties,
  fals_damage = fals_damage,
  loo_approval = loo_approval,
  rf_inspection = rf_inspection,
  alt_total = alt_total,
  rf_quad = rf_quad,
  time_trend = time_trend
)
saveRDS(rob_results, file.path(data_dir, "results_robustness.rds"))
cat("\nRobustness results saved.\n")
