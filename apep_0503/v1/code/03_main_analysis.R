## ============================================================================
## 03_main_analysis.R — Multi-cutoff RDD estimation
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
RESULTS_DIR <- "../tables"
dir.create(RESULTS_DIR, showWarnings = FALSE, recursive = TRUE)

cat("=== Loading analysis data ===\n")
analysis <- arrow::read_parquet(file.path(DATA_DIR, "analysis.parquet"))

cat(sprintf("Analysis dataset: %s observations\n",
            format(nrow(analysis), big.mark = ",")))

## ============================================================================
## PART 1: Cutoff-by-cutoff RDD estimation
## ============================================================================

cat("\n=== Cutoff-by-cutoff RDD estimation ===\n")

cutoff_results <- list()

for (cut_name in names(DPE_ENERGY_CUTS)) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) {
    cat(sprintf("  Cutoff %s (%d): too few observations (%d), skipping\n",
                cut_name, cut_val, nrow(df_cut)))
    next
  }

  cat(sprintf("  Cutoff %s (%d kWh): N=%s\n",
              cut_name, cut_val, format(nrow(df_cut), big.mark = ",")))

  # RDD with rdrobust
  tryCatch({
    rdd_fit <- rdrobust(
      y = df_cut$log_price_m2,
      x = df_cut$energy_kwh_m2,
      c = cut_val,
      kernel = "triangular",
      p = 1,          # Local linear
      bwselect = "mserd"  # MSE-optimal bandwidth
    )

    # Extract results
    # NOTE: rdrobust estimates mu_+(c) - mu_-(c) = right - left.
    # We negate to report mu_-(c) - mu_+(c) = below-cutoff - above-cutoff
    # = better-label - worse-label, consistent with pooled spec's B_i coding.
    cutoff_results[[cut_name]] <- tibble(
      cutoff = cut_name,
      cutoff_value = cut_val,
      n_total = nrow(df_cut),
      n_effective = rdd_fit$N_h[1] + rdd_fit$N_h[2],
      n_left = rdd_fit$N_h[1],
      n_right = rdd_fit$N_h[2],
      bandwidth = rdd_fit$bws[1, 1],
      estimate = -rdd_fit$coef[1],       # Negated: below - above
      se = rdd_fit$se[1],
      ci_lower = -rdd_fit$ci[3, 2],      # Negated robust CI (swap bounds)
      ci_upper = -rdd_fit$ci[3, 1],
      pval = rdd_fit$pv[3],             # Robust p-value (unchanged)
      estimate_bc = -rdd_fit$coef[2],    # Negated bias-corrected
      se_bc = rdd_fit$se[3]             # Robust SE (unchanged)
    )

    cat(sprintf("    Effect: %.4f (SE: %.4f), p=%.4f, BW=%.1f\n",
                rdd_fit$coef[1], rdd_fit$se[3], rdd_fit$pv[3], rdd_fit$bws[1, 1]))

  }, error = function(e) {
    cat(sprintf("    RDD estimation failed: %s\n", e$message))
  })
}

rdd_main <- bind_rows(cutoff_results)

cat("\n=== Main RDD Results ===\n")
print(rdd_main %>%
        select(cutoff, cutoff_value, n_effective, estimate, se_bc, pval) %>%
        mutate(across(c(estimate, se_bc, pval), ~round(., 4))))

# Save main results
write_csv(rdd_main, file.path(RESULTS_DIR, "rdd_main_results.csv"))

## ============================================================================
## PART 2: Regulatory vs. information decomposition
## ============================================================================

cat("\n=== Regulatory vs. Information Decomposition ===\n")

# Compare regulatory cutoffs (G/F, F/E) vs. information-only cutoffs (D/C, C/B, B/A)
rdd_main <- rdd_main %>%
  mutate(
    cutoff_type = case_when(
      cutoff == "F" ~ "regulatory_active",
      cutoff == "E" ~ "anticipation_near",
      cutoff == "D" ~ "anticipation_distant",
      cutoff %in% c("C", "B", "A") ~ "information_only"
    )
  )

# Mean effect by type
type_summary <- rdd_main %>%
  group_by(cutoff_type) %>%
  summarise(
    n_cutoffs = n(),
    mean_effect = mean(estimate, na.rm = TRUE),
    mean_se = mean(se_bc, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nMean effect by cutoff type:\n")
print(type_summary)

## ============================================================================
## PART 3: Pre-ban vs. post-ban comparison at G/F cutoff
## ============================================================================

cat("\n=== Pre-ban vs Post-ban at G/F cutoff ===\n")

df_gf <- analysis %>% filter(nearest_cutoff == "F")

period_results <- list()

for (p in c("pre_ban", "post_ban")) {
  df_period <- df_gf %>% filter(period == p)

  if (nrow(df_period) < 200) {
    cat(sprintf("  Period %s: too few observations (%d)\n", p, nrow(df_period)))
    next
  }

  tryCatch({
    rdd_period <- rdrobust(
      y = df_period$log_price_m2,
      x = df_period$energy_kwh_m2,
      c = 420,
      kernel = "triangular",
      p = 1,
      bwselect = "mserd"
    )

    period_results[[p]] <- tibble(
      period = p,
      n_effective = rdd_period$N_h[1] + rdd_period$N_h[2],
      estimate = -rdd_period$coef[1],  # Negated: below - above
      se_bc = rdd_period$se[3],
      pval = rdd_period$pv[3],
      bandwidth = rdd_period$bws[1, 1]
    )

    cat(sprintf("  %s: effect=%.4f (SE=%.4f, p=%.4f)\n",
                p, rdd_period$coef[1], rdd_period$se[3], rdd_period$pv[3]))

  }, error = function(e) {
    cat(sprintf("  %s: estimation failed: %s\n", p, e$message))
  })
}

period_comparison <- bind_rows(period_results)
write_csv(period_comparison, file.path(RESULTS_DIR, "rdd_pre_post_ban.csv"))

## ============================================================================
## PART 4: Owner-occupied placebo (high vs. low rental communes)
## ============================================================================

cat("\n=== Owner-occupied placebo test ===\n")

if ("high_rental" %in% names(analysis) && sum(!is.na(analysis$high_rental)) > 0) {
  df_gf_rental <- analysis %>% filter(nearest_cutoff == "F", !is.na(high_rental))

  rental_results <- list()

  for (rental_type in c(TRUE, FALSE)) {
    label <- if (rental_type) "high_rental" else "low_rental"
    df_sub <- df_gf_rental %>% filter(high_rental == rental_type)

    if (nrow(df_sub) < 200) {
      cat(sprintf("  %s: too few observations (%d)\n", label, nrow(df_sub)))
      next
    }

    tryCatch({
      rdd_rental <- rdrobust(
        y = df_sub$log_price_m2,
        x = df_sub$energy_kwh_m2,
        c = 420,
        kernel = "triangular",
        p = 1,
        bwselect = "mserd"
      )

      rental_results[[label]] <- tibble(
        subsample = label,
        n_effective = rdd_rental$N_h[1] + rdd_rental$N_h[2],
        estimate = -rdd_rental$coef[1],  # Negated: below - above
        se_bc = rdd_rental$se[3],
        pval = rdd_rental$pv[3],
        bandwidth = rdd_rental$bws[1, 1]
      )

      cat(sprintf("  %s: effect=%.4f (SE=%.4f, p=%.4f)\n",
                  label, rdd_rental$coef[1], rdd_rental$se[3], rdd_rental$pv[3]))

    }, error = function(e) {
      cat(sprintf("  %s: estimation failed: %s\n", label, e$message))
    })
  }

  rental_comparison <- bind_rows(rental_results)
  write_csv(rental_comparison, file.path(RESULTS_DIR, "rdd_rental_placebo.csv"))
} else {
  cat("  Skipping: rental share data not available\n")
}

## ============================================================================
## PART 5: Energy-bound vs. GHG-bound heterogeneity
## ============================================================================

cat("\n=== Binding dimension heterogeneity ===\n")

binding_results <- list()

for (dim in c("energy", "ghg")) {
  df_dim <- analysis %>%
    filter(nearest_cutoff == "F",
           binding_dim == dim)

  if (nrow(df_dim) < 200) {
    cat(sprintf("  %s-bound: too few observations (%d)\n", dim, nrow(df_dim)))
    next
  }

  # For GHG-bound, use GHG as running variable
  rv <- if (dim == "energy") df_dim$energy_kwh_m2 else df_dim$ghg_kg_m2
  cv <- if (dim == "energy") 420 else 100  # F/G cutoff for GHG

  tryCatch({
    rdd_dim <- rdrobust(
      y = df_dim$log_price_m2,
      x = rv,
      c = cv,
      kernel = "triangular",
      p = 1,
      bwselect = "mserd"
    )

    binding_results[[dim]] <- tibble(
      binding = dim,
      n_effective = rdd_dim$N_h[1] + rdd_dim$N_h[2],
      estimate = -rdd_dim$coef[1],  # Negated: below - above
      se_bc = rdd_dim$se[3],
      pval = rdd_dim$pv[3],
      bandwidth = rdd_dim$bws[1, 1]
    )

    cat(sprintf("  %s-bound: effect=%.4f (SE=%.4f, p=%.4f)\n",
                dim, rdd_dim$coef[1], rdd_dim$se[3], rdd_dim$pv[3]))

  }, error = function(e) {
    cat(sprintf("  %s-bound: estimation failed: %s\n", dim, e$message))
  })
}

binding_comparison <- bind_rows(binding_results)
write_csv(binding_comparison, file.path(RESULTS_DIR, "rdd_binding_dim.csv"))

## ============================================================================
## PART 6: Pooled multi-cutoff estimation
## ============================================================================

cat("\n=== Pooled multi-cutoff estimation ===\n")

# Normalize running variable as distance to cutoff
pooled <- analysis %>%
  filter(abs(dist_to_cutoff) <= 40) %>%  # Keep within ±40 kWh/m² of cutoff
  mutate(
    is_regulatory = cutoff_type %in% c("regulatory_active", "anticipation_near"),
    below_cutoff = dist_to_cutoff < 0,
    cutoff_fe = as.factor(nearest_cutoff)
  )

# Pooled local linear regression with cutoff FE
# Using fixest for clustered standard errors
pooled_reg <- feols(
  log_price_m2 ~ below_cutoff * is_regulatory +
    dist_to_cutoff + I(dist_to_cutoff * below_cutoff) |
    cutoff_fe,
  data = pooled,
  cluster = ~code_commune_clean
)

cat("\nPooled regression with cutoff FE:\n")
summary(pooled_reg)

# Save pooled results
sink(file.path(RESULTS_DIR, "pooled_regression.txt"))
summary(pooled_reg)
sink()

cat("\n=== Main analysis complete ===\n")
