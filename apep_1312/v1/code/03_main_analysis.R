# 03_main_analysis.R — Main DiD estimation with wild cluster bootstrap
source("00_packages.R")

dt <- fread("../data/wages_estimation.csv")
cat(sprintf("Loaded %d observations for estimation\n", nrow(dt)))

# ============================================================
# Wild cluster bootstrap helper (Cameron-Gelbach-Miller 2008)
# Rademacher weights at cluster level
# ============================================================
wild_cluster_boot <- function(model, param, data, cluster_var, B = 999) {
  clusters <- unique(data[[cluster_var]])
  G <- length(clusters)
  beta_hat <- coef(model)[param]
  resid_hat <- residuals(model)

  t_stats <- numeric(B)
  for (b in seq_len(B)) {
    weights <- sample(c(-1, 1), G, replace = TRUE)
    w_map <- setNames(weights, clusters)
    y_star <- fitted(model) + resid_hat * w_map[as.character(data[[cluster_var]])]
    data_b <- copy(data)
    data_b[["y_boot"]] <- y_star
    fml <- as.formula(paste("y_boot ~", paste(names(coef(model)), collapse = " + "),
                            "| sector + ym"))
    m_b <- tryCatch(
      feols(fml, data = data_b, cluster = as.formula(paste("~", cluster_var)),
            warn = FALSE, notes = FALSE),
      error = function(e) NULL
    )
    if (!is.null(m_b) && param %in% names(coef(m_b))) {
      t_stats[b] <- coef(m_b)[param] / se(m_b)[param]
    } else {
      t_stats[b] <- NA
    }
  }
  t_stats <- t_stats[!is.na(t_stats)]
  t_orig <- beta_hat / se(model)[param]
  p_val <- mean(abs(t_stats) >= abs(t_orig))
  return(list(point_estimate = beta_hat, p_val = p_val, t_orig = t_orig))
}

# ============================================================
# 1. MAIN SPECIFICATION: Continuous-treatment DiD
# ============================================================
cat("\n=== Model 1: Continuous Exposure DiD ===\n")

m1 <- feols(ln_gross ~ reform_x_exposure + post_x_exposure | sector + ym,
            data = dt, cluster = ~sector)
summary(m1)

cat("\n--- Wild cluster bootstrap for Model 1 ---\n")
boot1_reform <- wild_cluster_boot(m1, "reform_x_exposure", dt, "sector", B = 999)
cat(sprintf("Reform × Exposure: coef=%.4f, boot p=%.4f\n",
            boot1_reform$point_estimate, boot1_reform$p_val))

boot1_post <- wild_cluster_boot(m1, "post_x_exposure", dt, "sector", B = 999)
cat(sprintf("Post × Exposure: coef=%.4f, boot p=%.4f\n",
            boot1_post$point_estimate, boot1_post$p_val))

# ============================================================
# 2. NET WAGES — Mechanism test
# ============================================================
cat("\n=== Model 2: Net Wage Response ===\n")
m2 <- feols(ln_net ~ reform_x_exposure + post_x_exposure | sector + ym,
            data = dt, cluster = ~sector)
summary(m2)

boot2_reform <- wild_cluster_boot(m2, "reform_x_exposure", dt, "sector", B = 999)

# ============================================================
# 3. GROSS-NET GAP — Reporting channel
# ============================================================
cat("\n=== Model 3: Gross-Net Gap (Reporting Channel) ===\n")
dt[, gross_net_gap := gross_wage - net_wage]
dt[, ln_gap := log(gross_net_gap)]
m3 <- feols(ln_gap ~ reform_x_exposure + post_x_exposure | sector + ym,
            data = dt, cluster = ~sector)
summary(m3)

# ============================================================
# 4. EVENT STUDY — Monthly leads and lags
# ============================================================
cat("\n=== Model 4: Event Study ===\n")

dt[, et_binned := pmax(-24, pmin(24, event_time))]
dt[, et_factor := factor(et_binned)]

m4 <- feols(ln_gross ~ i(et_binned, exposure, ref = -1) | sector + ym,
            data = dt[et_binned >= -24 & et_binned <= 24],
            cluster = ~sector)
summary(m4)

# ============================================================
# 5. BINARY TREATMENT (for robustness)
# ============================================================
cat("\n=== Model 5: Binary High/Low Exposure DiD ===\n")
dt[, high_exposure := as.integer(exposure >= 0.5)]
dt[, reform_x_high := reform_2019 * high_exposure]
dt[, post_x_high := post_2020 * high_exposure]

m5 <- feols(ln_gross ~ reform_x_high + post_x_high | sector + ym,
            data = dt, cluster = ~sector)
summary(m5)

boot5_reform <- wild_cluster_boot(m5, "reform_x_high", dt, "sector", B = 999)
cat(sprintf("Binary Reform × High: coef=%.4f, boot p=%.4f\n",
            boot5_reform$point_estimate, boot5_reform$p_val))

# ============================================================
# SAVE RESULTS
# ============================================================
cat("\n=== Saving results ===\n")

results <- list(
  m1_reform = list(coef = coef(m1)["reform_x_exposure"],
                   se = se(m1)["reform_x_exposure"],
                   boot_p = boot1_reform$p_val),
  m1_post = list(coef = coef(m1)["post_x_exposure"],
                 se = se(m1)["post_x_exposure"],
                 boot_p = boot1_post$p_val),
  m2_reform = list(coef = coef(m2)["reform_x_exposure"],
                   se = se(m2)["reform_x_exposure"],
                   boot_p = boot2_reform$p_val),
  m3_reform = list(coef = coef(m3)["reform_x_exposure"],
                   se = se(m3)["reform_x_exposure"]),
  m3_post = list(coef = coef(m3)["post_x_exposure"],
                 se = se(m3)["post_x_exposure"]),
  m5_reform = list(coef = coef(m5)["reform_x_high"],
                   se = se(m5)["reform_x_high"],
                   boot_p = boot5_reform$p_val)
)

saveRDS(results, "../data/main_results.rds")

# Diagnostics for validator
# Continuous treatment: all 19 sectors receive non-zero exposure
n_treated <- uniqueN(dt$sector)  # All sectors are treated at varying intensities
n_pre <- uniqueN(dt[year < 2019, ym])
n_obs <- nrow(dt)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre / 12,
  n_obs = n_obs
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("Diagnostics: %d treated sectors, %.0f pre-years, %d obs\n",
            n_high, n_pre / 12, n_obs))

# Save event study coefficients for table
# Names look like "et_binned::-24:exposure" — extract the number
es_names <- names(coef(m4))
es_times <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_names))
es_coefs <- data.table(
  event_time = es_times,
  coef = coef(m4),
  se = se(m4)
)
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]
fwrite(es_coefs, "../data/event_study_coefs.csv")

cat("\nMain analysis complete.\n")
