# 04_robustness.R — Robustness checks and mechanism analysis
# apep_0660: FCC Cellular Lottery and Local Economic Development
# RSA design: state-level treatment, state-clustered SEs

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== Robustness Checks ===\n")

# Prepare balanced panel (same as main analysis)
panel_bal <- panel %>%
  filter(!is.na(log_emp) & is.finite(log_emp)) %>%
  group_by(fips) %>%
  filter(n() >= 15) %>%
  ungroup()

panel_bal$county_id <- as.integer(factor(panel_bal$fips))

# ==============================================================================
# 1. Sector Heterogeneity (Mechanism Test)
# ==============================================================================
cat("\n--- Sector Heterogeneity ---\n")

sector_file <- file.path(data_dir, "sector_panel.rds")
sector_results <- list()

if (file.exists(sector_file)) {
  sector_panel <- readRDS(sector_file)

  for (sec in unique(sector_panel$sector)) {
    cat(sprintf("  Sector: %s\n", sec))
    sec_data <- sector_panel %>%
      filter(sector == sec & !is.na(log_emp) & is.finite(log_emp)) %>%
      group_by(fips) %>%
      filter(n() >= 3) %>%
      ungroup()

    if (nrow(sec_data) < 100 || n_distinct(sec_data$treat_year) < 2) {
      cat(sprintf("    Skipping (too few obs: %d)\n", nrow(sec_data)))
      next
    }

    sec_data$county_id <- as.integer(factor(sec_data$fips))
    sec_data$state_fips <- substr(sec_data$fips, 1, 2)

    sec_fit <- tryCatch(
      feols(log_emp ~ treated | fips + year,
            data = sec_data, cluster = ~state_fips),
      error = function(e) {
        cat(sprintf("    TWFE failed: %s\n", e$message))
        NULL
      }
    )

    if (!is.null(sec_fit)) {
      sector_results[[sec]] <- list(
        coef = coef(sec_fit)["treated"],
        se = se(sec_fit)["treated"],
        n = nrow(sec_data),
        n_counties = n_distinct(sec_data$fips)
      )
      cat(sprintf("    β = %.4f (SE = %.4f), N = %d\n",
                  sector_results[[sec]]$coef,
                  sector_results[[sec]]$se,
                  sector_results[[sec]]$n))
    }
  }
}

# ==============================================================================
# 2. Cohort-specific ATTs (from CS group aggregation)
# ==============================================================================
cat("\n--- Cohort-specific ATTs ---\n")

group_emp <- results$group_emp
cohort_results <- list()
if (!is.null(group_emp)) {
  g_df <- data.frame(
    group = group_emp$egt,
    att = group_emp$att.egt,
    se = group_emp$se.egt
  )
  g_df$p <- 2 * pnorm(-abs(g_df$att / g_df$se))
  for (i in seq_len(nrow(g_df))) {
    cat(sprintf("  Cohort %d: ATT = %.4f (SE = %.4f, p = %.3f)\n",
                g_df$group[i], g_df$att[i], g_df$se[i], g_df$p[i]))
    cohort_results[[as.character(g_df$group[i])]] <- list(
      coef = g_df$att[i], se = g_df$se[i], p = g_df$p[i]
    )
  }
}

# ==============================================================================
# 3. Pre-treatment Parallel Trends Test
# ==============================================================================
cat("\n--- Pre-treatment Parallel Trends Test ---\n")

# Test: are pre-treatment event study coefficients jointly zero?
es_obj <- results$es_emp
e_seq <- es_obj$egt
pre_idx <- which(e_seq < 0)
pre_coeffs <- es_obj$att.egt[pre_idx]
pre_ses <- es_obj$se.egt[pre_idx]
pre_pvals <- 2 * pnorm(-abs(pre_coeffs / pre_ses))

cat("Pre-treatment event study coefficients:\n")
for (i in seq_along(pre_idx)) {
  cat(sprintf("  k=%d: ATT = %.4f (SE = %.4f, p = %.3f)\n",
              e_seq[pre_idx[i]], pre_coeffs[i], pre_ses[i], pre_pvals[i]))
}

# Maximum absolute pre-treatment coefficient
max_pre <- max(abs(pre_coeffs))
cat(sprintf("Max |pre-treatment ATT|: %.4f\n", max_pre))

pre_trend_result <- list(
  coefficients = pre_coeffs,
  se = pre_ses,
  p_values = pre_pvals,
  event_times = e_seq[pre_idx],
  max_abs = max_pre
)

# ==============================================================================
# 4. HonestDiD Sensitivity (Rambachan-Roth)
# ==============================================================================
cat("\n--- HonestDiD Sensitivity Analysis ---\n")

honest_result <- tryCatch({
  es_obj <- results$es_emp
  betahat <- es_obj$att.egt
  sigma <- es_obj$V_analytical

  e_seq <- es_obj$egt
  pre_idx <- which(e_seq < 0)
  post_idx <- which(e_seq >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    honest <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD bounds computed\n")
    print(honest)
    honest
  } else {
    cat("Insufficient pre/post periods for HonestDiD\n")
    NULL
  }
}, error = function(e) {
  cat(sprintf("HonestDiD failed: %s\n", e$message))
  NULL
})

# ==============================================================================
# 5. County-level clustering (less conservative alternative)
# ==============================================================================
cat("\n--- County-clustered SEs (less conservative) ---\n")

twfe_county_clust <- feols(log_emp ~ treated | fips + year,
                           data = panel_bal, cluster = ~fips)
cat(sprintf("County-clustered: β = %.4f (SE = %.4f)\n",
            coef(twfe_county_clust)["treated"],
            se(twfe_county_clust)["treated"]))

# ==============================================================================
# 6. Level specification
# ==============================================================================
cat("\n--- Level specification ---\n")

twfe_level <- feols(emp ~ treated | fips + year,
                    data = panel_bal, cluster = ~state_fips)
cat(sprintf("Level (employment): β = %.1f (SE = %.1f)\n",
            coef(twfe_level)["treated"], se(twfe_level)["treated"]))

twfe_estab_level <- feols(estab ~ treated | fips + year,
                          data = panel_bal, cluster = ~state_fips)
cat(sprintf("Level (establishments): β = %.1f (SE = %.1f)\n",
            coef(twfe_estab_level)["treated"], se(twfe_estab_level)["treated"]))

# ==============================================================================
# 7. Save robustness results
# ==============================================================================
robustness <- list(
  sector = sector_results,
  cohort = cohort_results,
  county_cluster = list(coef = coef(twfe_county_clust)["treated"],
                        se = se(twfe_county_clust)["treated"]),
  level_emp = list(coef = coef(twfe_level)["treated"],
                   se = se(twfe_level)["treated"]),
  level_estab = list(coef = coef(twfe_estab_level)["treated"],
                     se = se(twfe_estab_level)["treated"]),
  honest = honest_result,
  pre_trend = pre_trend_result,
  twfe_level_fit = twfe_level,
  twfe_estab_level_fit = twfe_estab_level,
  twfe_county_clust_fit = twfe_county_clust
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
