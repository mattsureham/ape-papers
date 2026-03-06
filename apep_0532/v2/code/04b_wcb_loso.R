# ==============================================================================
# 04b_wcb_loso.R — Wild Cluster Bootstrap & Leave-One-State-Out
# apep_0532 v2
# ==============================================================================

source("00_packages.R")
library(boot)

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
models <- readRDS(file.path(data_dir, "all_models.rds"))

cat("=== Wild Cluster Bootstrap (manual implementation) ===\n\n")

# --- Manual WCB-t using Rademacher weights ---
# Following Cameron, Gelbach, Miller (2008) Algorithm 3.1

wcb_test <- function(data, formula_str, param, n_boot = 9999) {
  # Fit restricted and unrestricted models
  full_mod <- feols(as.formula(formula_str), data = data, cluster = ~state_id)

  # Get the t-statistic for the parameter of interest
  t_orig <- coef(full_mod)[param] / se(full_mod)[param]

  # Get cluster IDs
  clusters <- unique(data$state_id)
  G <- length(clusters)

  # Get residuals
  resid_full <- residuals(full_mod)

  # Bootstrap
  t_boot <- numeric(n_boot)
  for (b in 1:n_boot) {
    # Rademacher weights: +1 or -1 with equal probability
    w <- sample(c(-1, 1), G, replace = TRUE)
    names(w) <- clusters

    # Apply weights at cluster level
    y_star <- fitted(full_mod) + resid_full * w[as.character(data$state_id)]

    # Re-estimate
    data_star <- copy(data)
    data_star[, y_boot := y_star]

    boot_mod <- tryCatch(
      feols(as.formula(gsub("^[^ ]+", "y_boot", formula_str)),
            data = data_star, cluster = ~state_id),
      error = function(e) NULL
    )

    if (!is.null(boot_mod) && param %in% names(coef(boot_mod))) {
      t_boot[b] <- coef(boot_mod)[param] / se(boot_mod)[param]
    } else {
      t_boot[b] <- NA
    }
  }

  t_boot <- t_boot[!is.na(t_boot)]

  # Two-sided p-value
  p_wcb <- mean(abs(t_boot) >= abs(t_orig))

  return(list(
    t_orig = t_orig,
    p_wcb = p_wcb,
    n_boot_valid = length(t_boot),
    ci_lo = coef(full_mod)[param] - quantile(abs(t_boot), 0.95) * se(full_mod)[param],
    ci_hi = coef(full_mod)[param] + quantile(abs(t_boot), 0.95) * se(full_mod)[param]
  ))
}

# Main specification
cat("WCB for main specification (full sample):\n")
wcb_main <- wcb_test(panel,
  "climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id",
  "tavg_x_ag", n_boot = 4999)
cat(sprintf("  tavg_x_ag: t = %.3f, WCB p = %.4f\n", wcb_main$t_orig, wcb_main$p_wcb))

# High internet subsample
panel_hi <- panel[internet_pen_2015 >= median(internet_pen_2015, na.rm=TRUE)]
cat("\nWCB for high-internet subsample:\n")
wcb_hi <- wcb_test(panel_hi,
  "climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id",
  "tavg_x_ag", n_boot = 4999)
cat(sprintf("  tavg_x_ag: t = %.3f, WCB p = %.4f\n", wcb_hi$t_orig, wcb_hi$p_wcb))

# Monsoon subsample
panel_mon <- panel[is_monsoon == 1]
cat("\nWCB for monsoon subsample:\n")
wcb_mon <- wcb_test(panel_mon,
  "climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id",
  "tavg_x_ag", n_boot = 4999)
cat(sprintf("  tavg_x_ag: t = %.3f, WCB p = %.4f\n", wcb_mon$t_orig, wcb_mon$p_wcb))

# Save WCB results
wcb_results <- data.table(
  spec = c("Full sample", "High internet", "Monsoon"),
  coef = c(coef(models$ols_main)["tavg_x_ag"],
           coef(models$het_high_internet)["tavg_x_ag"],
           coef(models$seas_monsoon)["tavg_x_ag"]),
  se = c(se(models$ols_main)["tavg_x_ag"],
         se(models$het_high_internet)["tavg_x_ag"],
         se(models$seas_monsoon)["tavg_x_ag"]),
  crve_p = c(2*pt(-abs(coef(models$ols_main)["tavg_x_ag"]/se(models$ols_main)["tavg_x_ag"]), df=20),
             2*pt(-abs(coef(models$het_high_internet)["tavg_x_ag"]/se(models$het_high_internet)["tavg_x_ag"]),
                  df=length(unique(panel_hi$state_id))-1),
             2*pt(-abs(coef(models$seas_monsoon)["tavg_x_ag"]/se(models$seas_monsoon)["tavg_x_ag"]), df=20)),
  wcb_p = c(wcb_main$p_wcb, wcb_hi$p_wcb, wcb_mon$p_wcb)
)
fwrite(wcb_results, file.path(data_dir, "wcb_results.csv"))
cat("\nSaved wcb_results.csv\n")

# ==============================================================================
# LEAVE-ONE-STATE-OUT
# ==============================================================================
cat("\n=== Leave-One-State-Out Analysis ===\n\n")

states <- unique(panel$state)
loso <- data.table(
  state_dropped = character(),
  ag_share = numeric(),
  interaction_coef = numeric(),
  interaction_se = numeric(),
  n_obs = integer(),
  n_clusters = integer()
)

for (s in states) {
  sub <- panel[state != s]
  m <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
             data = sub, cluster = ~state_id)
  loso <- rbind(loso, data.table(
    state_dropped = s,
    ag_share = panel[state == s, ag_emp_share[1]],
    interaction_coef = coef(m)["tavg_x_ag"],
    interaction_se = se(m)["tavg_x_ag"],
    n_obs = m$nobs,
    n_clusters = length(unique(sub$state_id))
  ))
}

fwrite(loso, file.path(data_dir, "loso_results.csv"))
cat("Leave-one-state-out results:\n")
print(loso[order(interaction_coef)])
cat("\nRange of interaction coefficient: [",
    round(min(loso$interaction_coef), 3), ", ",
    round(max(loso$interaction_coef), 3), "]\n")
cat("States that flip sign when dropped:\n")
baseline_sign <- sign(coef(models$ols_main)["tavg_x_ag"])
flippers <- loso[sign(interaction_coef) != baseline_sign]
if (nrow(flippers) > 0) print(flippers) else cat("  None\n")

# ==============================================================================
# TRIPLE INTERACTION: Temp × Ag × Internet (continuous)
# ==============================================================================
cat("\n=== Triple Interaction ===\n\n")

# Standardize internet penetration
panel[, inet_std := scale(internet_pen_2015)]
panel[, tavg_x_ag_x_inet := tavg_anomaly * ag_emp_share * inet_std]
panel[, tavg_x_inet := tavg_anomaly * inet_std]

m_triple <- feols(climate_search ~ tavg_anomaly + tavg_x_ag + tavg_x_inet +
                    tavg_x_ag_x_inet | state_id + time_id,
                  data = panel, cluster = ~state_id)
cat("Triple interaction model:\n")
summary(m_triple)

# Save
saveRDS(m_triple, file.path(data_dir, "triple_interaction.rds"))

# ==============================================================================
# HORSE RACE: Ag share vs urbanization
# ==============================================================================
cat("\n=== Horse Race ===\n\n")
# Use internet penetration as proxy for urbanization
panel[, tavg_x_urban := tavg_anomaly * (1 - ag_emp_share)]  # urbanization ≈ 1 - ag share

m_horse <- feols(climate_search ~ tavg_anomaly + tavg_x_ag + tavg_x_inet |
                   state_id + time_id,
                 data = panel, cluster = ~state_id)
cat("Horse race (ag share vs internet):\n")
summary(m_horse)

cat("\n=== All supplementary analyses complete ===\n")
