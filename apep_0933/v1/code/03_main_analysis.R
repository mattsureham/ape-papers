## 03_main_analysis.R — Main DiD analysis of BNG effects on housing development
## APEP paper apep_0933: BNG and Housing Development in England

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Main Analysis: BNG and Housing Development ===\n")
cat("Panel:", nrow(panel), "obs,", length(unique(panel$la_code)), "LAs,",
    length(unique(panel$quarter)), "quarters\n\n")

# ====================================================================
# 1. Summary statistics by exposure group (pre-BNG)
# ====================================================================
cat("=== Pre-BNG summary by exposure group ===\n")
pre <- panel[post_bng == 0]
pre_summary <- pre[, .(
  total_granted_mean = mean(total_granted, na.rm = TRUE),
  major_grant_mean   = mean(major_dwell_grant, na.rm = TRUE),
  apps_received_mean = mean(apps_received, na.rm = TRUE),
  approval_rate_mean = mean(approval_rate, na.rm = TRUE),
  bf_sites_mean      = mean(bf_sites, na.rm = TRUE),
  n_la_qtrs          = .N
), by = high_exposure]

cat("\nPre-BNG means by exposure group (1=high exposure/few brownfield):\n")
print(pre_summary)

# ====================================================================
# 2. Main DiD: continuous intensity
# ====================================================================
cat("\n=== Estimation: Heterogeneous-intensity DiD ===\n")

# Model 1: Total applications granted (log)
m1 <- feols(log_total_granted ~ did_term | la_code + quarter,
            data = panel, cluster = ~la_code)

# Model 2: Applications received (log)
m2 <- feols(log_apps_received ~ did_term | la_code + quarter,
            data = panel, cluster = ~la_code)

# Model 3: Major dwelling applications granted (log)
m3 <- feols(log_major_grant ~ did_term | la_code + quarter,
            data = panel, cluster = ~la_code)

# Model 4: Approval rate (levels)
m4 <- feols(approval_rate ~ did_term | la_code + quarter,
            data = panel, cluster = ~la_code)

# Model 5: Major dwelling approval rate
m5 <- feols(major_approval_rate ~ did_term | la_code + quarter,
            data = panel, cluster = ~la_code)

cat("Model results (continuous intensity DiD):\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Log(Granted)", "Log(Received)", "Log(Major)", "Approval", "Major Appr"),
       se.below = TRUE)

# ====================================================================
# 3. Binary DiD (high vs low exposure)
# ====================================================================
cat("\n=== Binary DiD (high vs low brownfield exposure) ===\n")

m6 <- feols(log_total_granted ~ post_bng:high_exposure | la_code + quarter,
            data = panel, cluster = ~la_code)

m7 <- feols(log_apps_received ~ post_bng:high_exposure | la_code + quarter,
            data = panel, cluster = ~la_code)

m8 <- feols(log_major_grant ~ post_bng:high_exposure | la_code + quarter,
            data = panel, cluster = ~la_code)

cat("Binary DiD results:\n")
etable(m6, m7, m8,
       headers = c("Log(Granted)", "Log(Received)", "Log(Major)"),
       se.below = TRUE)

# ====================================================================
# 4. Event study (continuous intensity × quarter dummies)
# ====================================================================
cat("\n=== Event Study ===\n")

# Restrict to 2019 Q1 - 2025 Q4 for cleaner event study
panel_es <- panel[year >= 2019]
panel_es[, event_time_f := factor(event_time)]

# Drop reference period: event_time = -1 (2023 Q4)
m_es <- feols(log_total_granted ~ i(event_time, bng_intensity, ref = -1) | la_code + quarter,
              data = panel_es, cluster = ~la_code)

cat("Event study coefficients:\n")
print(coeftable(m_es))

# Also for major dwellings
m_es_major <- feols(log_major_grant ~ i(event_time, bng_intensity, ref = -1) | la_code + quarter,
                    data = panel_es, cluster = ~la_code)

# ====================================================================
# 5. Save results for tables
# ====================================================================
results <- list(
  continuous_did = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
  binary_did = list(m6 = m6, m7 = m7, m8 = m8),
  event_study = list(total = m_es, major = m_es_major)
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ====================================================================
# 6. Key numbers for paper text
# ====================================================================
cat("\n=== Key Numbers for Paper ===\n")
cat("DiD coefficient (log total granted):", round(coef(m1)["did_term"], 4),
    "SE:", round(se(m1)["did_term"], 4), "\n")
cat("DiD coefficient (log received):", round(coef(m2)["did_term"], 4),
    "SE:", round(se(m2)["did_term"], 4), "\n")
cat("DiD coefficient (log major):", round(coef(m3)["did_term"], 4),
    "SE:", round(se(m3)["did_term"], 4), "\n")
cat("DiD coefficient (approval rate):", round(coef(m4)["did_term"], 4),
    "SE:", round(se(m4)["did_term"], 4), "\n")

# Pre-BNG SDs for SDE computation
pre_data <- panel[post_bng == 0]
cat("\nPre-treatment SDs:\n")
cat("SD(log_total_granted):", round(sd(pre_data$log_total_granted, na.rm = TRUE), 4), "\n")
cat("SD(log_apps_received):", round(sd(pre_data$log_apps_received, na.rm = TRUE), 4), "\n")
cat("SD(log_major_grant):", round(sd(pre_data$log_major_grant, na.rm = TRUE), 4), "\n")
cat("SD(approval_rate):", round(sd(pre_data$approval_rate, na.rm = TRUE), 4), "\n")
cat("SD(bng_intensity):", round(sd(pre_data$bng_intensity, na.rm = TRUE), 4), "\n")

# ====================================================================
# 7. Write diagnostics.json
# ====================================================================
n_treated <- length(unique(panel[high_exposure == 1]$la_code))
n_pre <- length(unique(panel[post_bng == 0]$quarter))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_las = length(unique(panel$la_code)),
  n_quarters = length(unique(panel$quarter)),
  pre_mean_granted = round(mean(pre_data$total_granted, na.rm = TRUE), 1),
  pre_mean_major_granted = round(mean(pre_data$major_dwell_grant, na.rm = TRUE), 2)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved. n_treated:", n_treated, "n_pre:", n_pre, "n_obs:", n_obs, "\n")
