# 03_main_analysis.R — Main DiD estimation
# apep_0734: Wales 20mph Speed Limit and Road Casualties

source("00_packages.R")

cat("=== Loading panel ===\n")
panel <- fread("../data/panel.csv")

# Verify panel structure
n_welsh <- uniqueN(panel[wales == 1]$la_code)
n_english <- uniqueN(panel[wales == 0]$la_code)
n_quarters <- uniqueN(panel$year_q)
cat("Welsh LAs:", n_welsh, "\n")
cat("English LAs:", n_english, "\n")
cat("Quarters:", n_quarters, "\n")

# ============================================================
# 1. MAIN SPECIFICATION: DiD on restricted-road casualties
# ============================================================
cat("\n=== Main DiD: Total casualties on restricted roads ===\n")

# Specification: Y_lt = alpha_l + gamma_t + beta * (Wales_l x Post_t) + epsilon_lt
# Clustered at LA level

# Use log(casualties + 1) as primary outcome
m1 <- feols(log_casualties ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
summary(m1)

# Level specification
m1_level <- feols(casualties ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
summary(m1_level)

# Per capita (if available)
if ("casualties_pc" %in% names(panel) && sum(!is.na(panel$casualties_pc)) > nrow(panel) * 0.5) {
  m1_pc <- feols(casualties_pc ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
  summary(m1_pc)
} else {
  m1_pc <- NULL
}

# ============================================================
# 2. EVENT STUDY for pre-trend validation
# ============================================================
cat("\n=== Event Study ===\n")

# Create event-time indicators
# Treatment date: 2023-Q4 (year_q = 2023.75)
panel[, event_time := year_q - 2023.75]
# Round to nearest quarter for clean indicators
panel[, event_q := round(event_time * 4) / 4]

# Interact with Wales indicator
panel[, event_wales := wales * event_q]

# Drop one pre-period as reference (Q3 2023 = event_q = -0.25)
# Create event time factor
panel[, event_factor := factor(event_q)]

# Event study regression
m_es <- feols(log_casualties ~ i(event_q, wales, ref = -0.25) | la_code + quarter,
              data = panel, cluster = ~la_code)
summary(m_es)

# ============================================================
# 3. BY SEVERITY
# ============================================================
cat("\n=== By severity ===\n")

panel[, log_fatal_serious := log(fatal + serious + 1)]
panel[, log_slight := log(slight + 1)]

m_fs <- feols(log_fatal_serious ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
m_sl <- feols(log_slight ~ treat | la_code + quarter, data = panel, cluster = ~la_code)

cat("Fatal+Serious:\n")
summary(m_fs)
cat("Slight:\n")
summary(m_sl)

# ============================================================
# 4. BY ROAD TYPE (20mph vs 30mph)
# ============================================================
cat("\n=== By road type ===\n")

panel[, log_cas_20 := log(casualties_20 + 1)]
panel[, log_cas_30 := log(casualties_30 + 1)]
panel[, log_cas_high := log(casualties_high + 1)]

m_20 <- feols(log_cas_20 ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
m_30 <- feols(log_cas_30 ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
m_high <- feols(log_cas_high ~ treat | la_code + quarter, data = panel, cluster = ~la_code)

cat("20mph roads:\n")
summary(m_20)
cat("30mph roads:\n")
summary(m_30)
cat("High-speed roads (placebo):\n")
summary(m_high)

# ============================================================
# 5. WILD CLUSTER BOOTSTRAP (few treated clusters)
# ============================================================
cat("\n=== Wild cluster bootstrap ===\n")

# Manual wild cluster bootstrap (Rademacher weights) for few-cluster inference
wild_cluster_boot <- function(model, data, cluster_var, param, B = 9999) {
  clusters <- unique(data[[cluster_var]])
  G <- length(clusters)
  orig_coef <- coef(model)[param]

  boot_coefs <- numeric(B)
  for (b in 1:B) {
    # Rademacher weights: +1 or -1 per cluster
    weights <- sample(c(-1, 1), G, replace = TRUE)
    names(weights) <- clusters
    data$boot_weight <- weights[as.character(data[[cluster_var]])]
    data$boot_y <- fitted(model) + residuals(model) * data$boot_weight

    boot_mod <- tryCatch(
      feols(boot_y ~ treat | la_code + quarter, data = data, cluster = as.formula(paste0("~", cluster_var))),
      error = function(e) NULL
    )
    if (!is.null(boot_mod)) {
      boot_coefs[b] <- coef(boot_mod)[param]
    } else {
      boot_coefs[b] <- NA
    }
  }
  boot_coefs <- boot_coefs[!is.na(boot_coefs)]
  # Two-sided p-value
  p_val <- mean(abs(boot_coefs - mean(boot_coefs)) >= abs(orig_coef - mean(boot_coefs)))
  ci <- quantile(boot_coefs, c(0.025, 0.975))
  list(p_val = p_val, conf_int = ci, boot_coefs = boot_coefs)
}

boot_m1 <- tryCatch({
  wild_cluster_boot(m1, panel, "la_code", "treat", B = 999)
}, error = function(e) {
  cat("Wild cluster bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_m1)) {
  cat("WCB p-value:", boot_m1$p_val, "\n")
  cat("WCB 95% CI: [", boot_m1$conf_int[1], ",", boot_m1$conf_int[2], "]\n")
}

# ============================================================
# 6. SAVE RESULTS
# ============================================================
cat("\n=== Saving results ===\n")

# Diagnostics for validator
n_pre <- sum(sort(unique(panel$year_q)) < 2023.75)
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_welsh,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_english,
  n_quarters = n_quarters,
  main_coef = coef(m1)["treat"],
  main_se = se(m1)["treat"],
  main_pval = pvalue(m1)["treat"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved\n")

# Save model objects for tables
save(m1, m1_level, m1_pc, m_es, m_fs, m_sl, m_20, m_30, m_high, boot_m1, panel,
     file = "../data/models.RData")
cat("Models saved\n")

cat("\n=== Main analysis complete ===\n")
