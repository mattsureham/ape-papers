# 03_main_analysis.R — Main DiD estimation for apep_1215
# Treatment-intensity DiD: Deutschlandticket effective subsidy × post-2023
# Annual NUTS2 panel

source("00_packages.R")

cat("=== Running main analysis ===\n")

# --- Load data ---
unemp_panel <- readRDS("../data/unemp_panel.rds")
emp_panel <- readRDS("../data/emp_panel.rds")
vv_prices <- readRDS("../data/vv_prices.rds")

# ===================================================================
# MAIN SPECIFICATION: Unemployment rate
# Y_kt = α_k + α_t + β(Subsidy_k/10 × Post_t) + ε_kt
# Clustered at NUTS1 level (16 states)
# ===================================================================

# Specification 1: Subsidy level × Post
cat("--- Specification 1: Unemployment ~ Subsidy(EUR) × Post ---\n")
m1 <- feols(unemp_rate ~ treat_dt | geo + year, data = unemp_panel,
            cluster = ~nuts1)
cat(sprintf("  Coef: %.4f, SE: %.4f, p: %.4f\n",
            coef(m1), se(m1), pvalue(m1)))

# Specification 2: Per EUR 10 subsidy × Post (primary)
cat("\n--- Specification 2: Unemployment ~ Subsidy/10 × Post (PRIMARY) ---\n")
m2 <- feols(unemp_rate ~ treat_dt_10 | geo + year, data = unemp_panel,
            cluster = ~nuts1)
summary(m2)

# Specification 3: Binary high/low subsidy
cat("\n--- Specification 3: Binary high vs low subsidy ---\n")
unemp_panel <- unemp_panel %>%
  mutate(treat_binary = high_subsidy * post_dt)
m3_binary <- feols(unemp_rate ~ treat_binary | geo + year, data = unemp_panel,
                   cluster = ~nuts1)
summary(m3_binary)

# ===================================================================
# EMPLOYMENT RATE
# ===================================================================
cat("\n--- Specification 4: Employment rate ~ Subsidy/10 × Post ---\n")
m4 <- feols(emp_rate ~ treat_dt_10 | geo + year, data = emp_panel,
            cluster = ~nuts1)
summary(m4)

# ===================================================================
# EVENT STUDY (annual)
# ===================================================================
cat("\n--- Event study (annual, ref = 2022) ---\n")

# Event time relative to 2023 (treatment year)
# Reference period: event_year = -1 (2022)
m_event <- feols(unemp_rate ~ i(event_year, subsidy, ref = -1) | geo + year,
                 data = unemp_panel, cluster = ~nuts1)
summary(m_event)

# Employment event study
m_event_emp <- feols(emp_rate ~ i(event_year, subsidy, ref = -1) | geo + year,
                     data = emp_panel, cluster = ~nuts1)

# ===================================================================
# NUTS2-LEVEL CLUSTERING (alternative)
# ===================================================================
cat("\n--- Alternative clustering: NUTS2 ---\n")
m_nuts2 <- feols(unemp_rate ~ treat_dt_10 | geo + year, data = unemp_panel,
                 cluster = ~geo)
summary(m_nuts2)

# ===================================================================
# SUMMARY STATISTICS
# ===================================================================
cat("\n=== Summary Statistics ===\n")

pre_data <- filter(unemp_panel, post_dt == 0)
post_data <- filter(unemp_panel, post_dt == 1)

cat("Unemployment rate (full panel):\n")
cat(sprintf("  Mean: %.2f%%\n", mean(unemp_panel$unemp_rate, na.rm = TRUE)))
cat(sprintf("  SD: %.2f\n", sd(unemp_panel$unemp_rate, na.rm = TRUE)))
cat(sprintf("  Min: %.1f\n", min(unemp_panel$unemp_rate, na.rm = TRUE)))
cat(sprintf("  Max: %.1f\n", max(unemp_panel$unemp_rate, na.rm = TRUE)))

cat("\nPre-treatment (2010-2022):\n")
cat(sprintf("  Mean: %.2f%%\n", mean(pre_data$unemp_rate, na.rm = TRUE)))
cat(sprintf("  N: %d\n", sum(!is.na(pre_data$unemp_rate))))

cat("\nPost-treatment (2023-2024):\n")
cat(sprintf("  Mean: %.2f%%\n", mean(post_data$unemp_rate, na.rm = TRUE)))
cat(sprintf("  N: %d\n", sum(!is.na(post_data$unemp_rate))))

cat("\nEmployment rate:\n")
cat(sprintf("  Mean: %.2f%%\n", mean(emp_panel$emp_rate, na.rm = TRUE)))
cat(sprintf("  SD: %.2f\n", sd(emp_panel$emp_rate, na.rm = TRUE)))

cat("\nSubsidy (EUR/month):\n")
cat(sprintf("  Mean: %.1f\n", mean(vv_prices$subsidy)))
cat(sprintf("  SD: %.1f\n", sd(vv_prices$subsidy)))

# --- MAIN RESULT: Interpretation ---
b <- as.numeric(coef(m2)["treat_dt_10"])
cat(sprintf("\n=== MAIN RESULT ===\n"))
cat(sprintf("A EUR 10 increase in effective subsidy is associated with a %.3f pp change in unemployment rate.\n", b))
cat(sprintf("At the mean subsidy of EUR %.1f, this implies a total effect of %.3f pp.\n",
            mean(vv_prices$subsidy), b * mean(vv_prices$subsidy) / 10))

# ===================================================================
# DIAGNOSTICS
# ===================================================================
diagnostics <- list(
  n_treated = n_distinct(unemp_panel$geo),
  n_pre = n_distinct(pre_data$year),
  n_obs = nrow(unemp_panel),
  n_regions = n_distinct(unemp_panel$geo),
  n_clusters = n_distinct(unemp_panel$nuts1),
  outcome_mean = mean(unemp_panel$unemp_rate, na.rm = TRUE),
  outcome_sd = sd(unemp_panel$unemp_rate, na.rm = TRUE),
  subsidy_mean = mean(vv_prices$subsidy),
  subsidy_sd = sd(vv_prices$subsidy),
  main_coef = as.numeric(coef(m2)["treat_dt_10"]),
  main_se = as.numeric(se(m2)["treat_dt_10"]),
  main_pval = as.numeric(pvalue(m2)["treat_dt_10"]),
  emp_coef = as.numeric(coef(m4)["treat_dt_10"]),
  emp_se = as.numeric(se(m4)["treat_dt_10"])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

# --- Save model objects ---
saveRDS(m1, "../data/m1_level.rds")
saveRDS(m2, "../data/m2_per10eur.rds")
saveRDS(m3_binary, "../data/m3_binary.rds")
saveRDS(m4, "../data/m4_employment.rds")
saveRDS(m_event, "../data/m_event.rds")
saveRDS(m_event_emp, "../data/m_event_emp.rds")
saveRDS(m_nuts2, "../data/m_nuts2_cluster.rds")

cat("\n=== Main analysis complete ===\n")
