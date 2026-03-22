## 03_main_analysis.R — Main continuous-treatment DiD analysis
source("00_packages.R")
data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# Drop City of London (extreme outlier: density 61 vs next highest 4.2)
panel <- panel %>% filter(force != "London, City of")
cat("Panel after dropping City of London:", nrow(panel), "obs,",
    length(unique(panel$force)), "PFAs\n")

# ============================================================================
# 1. Summary statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

pre <- panel %>% filter(post == 0)
post_df <- panel %>% filter(post == 1)

summ <- panel %>%
  summarise(
    n_obs = n(),
    n_pfa = n_distinct(force),
    n_pre_q = n_distinct(time_id[post == 0]),
    n_post_q = n_distinct(time_id[post == 1]),
    mean_total_rate = mean(total_rate, na.rm = TRUE),
    sd_total_rate = sd(total_rate, na.rm = TRUE),
    mean_theft_rate = mean(theft_rate, na.rm = TRUE),
    mean_violence_rate = mean(violence_rate, na.rm = TRUE),
    mean_robbery_rate = mean(robbery_rate, na.rm = TRUE),
    mean_damage_rate = mean(damage_rate, na.rm = TRUE),
    mean_shoplifting_rate = mean(shoplifting_rate, na.rm = TRUE),
    mean_betting_density = mean(betting_density),
    sd_betting_density = sd(betting_density),
    min_betting_density = min(betting_density),
    max_betting_density = max(betting_density)
  )
print(summ)

# Save summary stats
saveRDS(summ, file.path(data_dir, "summary_stats.rds"))

# ============================================================================
# 2. Main specification: continuous-treatment DiD
# ============================================================================
cat("\n=== Main DiD Results ===\n")

# Crime_it = alpha_i + gamma_t + beta * (BettingDensity_i * Post_t) + epsilon_it
# Clustered at PFA level

outcomes <- c("total_rate", "theft_rate", "violence_rate", "robbery_rate",
              "damage_rate", "public_order_rate", "drugs_rate",
              "shoplifting_rate", "burglary_res_rate")
outcome_labels <- c("Total Crime", "Theft", "Violence", "Robbery",
                     "Criminal Damage", "Public Order", "Drug Offences",
                     "Shoplifting", "Residential Burglary")

results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_x_post | force_id + time_id"))
  est <- feols(fml, data = panel, cluster = ~force_id)
  results[[y]] <- est
  cat(sprintf("%-22s  beta = %8.3f  SE = %6.3f  p = %.4f\n",
              outcome_labels[i], coef(est)[1], se(est)[1], pvalue(est)[1]))
}

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================================
# 3. Event study: leads and lags with betting density interaction
# ============================================================================
cat("\n=== Event Study ===\n")

# Create relative time dummies interacted with betting density
# Normalize to quarter before treatment (rel_time = -1)
panel <- panel %>%
  mutate(
    # Bin endpoints
    rel_time_bin = case_when(
      rel_time <= -8 ~ -8L,
      rel_time >= 12 ~ 12L,
      TRUE ~ as.integer(rel_time)
    )
  )

# Event study for total crime
es_total <- feols(total_rate ~ i(rel_time_bin, betting_density, ref = -1) |
                    force_id + time_id,
                  data = panel, cluster = ~force_id)

# Event study for theft
es_theft <- feols(theft_rate ~ i(rel_time_bin, betting_density, ref = -1) |
                    force_id + time_id,
                  data = panel, cluster = ~force_id)

# Event study for violence
es_violence <- feols(violence_rate ~ i(rel_time_bin, betting_density, ref = -1) |
                       force_id + time_id,
                     data = panel, cluster = ~force_id)

saveRDS(list(total = es_total, theft = es_theft, violence = es_violence),
        file.path(data_dir, "event_study_results.rds"))

cat("\nEvent study pre-trend coefficients (total crime):\n")
es_coefs <- coef(es_total)
es_se <- se(es_total)
pre_coefs <- es_coefs[grepl("rel_time_bin::-[2-8]", names(es_coefs))]
cat("Pre-treatment coefficients:\n")
print(round(pre_coefs, 3))

# ============================================================================
# 4. Pre-COVID only specification (Apr 2019 - Feb 2020 = 3 quarters)
# ============================================================================
cat("\n=== Pre-COVID Window ===\n")

panel_precovid <- panel %>%
  filter(yearq < 2020.25)  # Up to Q1 2020 (Jan-Mar)

for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_x_post | force_id + time_id"))
  est <- feols(fml, data = panel_precovid, cluster = ~force_id)
  if (i <= 4) {
    cat(sprintf("Pre-COVID %-18s  beta = %8.3f  SE = %6.3f  p = %.4f\n",
                outcome_labels[i], coef(est)[1], se(est)[1], pvalue(est)[1]))
  }
}

# ============================================================================
# 5. Diagnostics for validation
# ============================================================================
cat("\n=== Writing diagnostics ===\n")

# Continuous treatment: all PFAs receive treatment intensity > 0
n_treated <- length(unique(panel$force))  # all 38 PFAs in continuous-treatment design
n_pre <- sum(panel$post == 0 & !duplicated(panel$time_id))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_pfa = length(unique(panel$force)),
  n_quarters = length(unique(panel$time_id))
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

# Also save panel for robustness
saveRDS(panel, file.path(data_dir, "analysis_panel_final.rds"))

cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
cat("=== MAIN ANALYSIS COMPLETE ===\n")
