# 03_main_analysis.R — Main DiD analysis
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

source("00_packages.R")

cat("=== Loading analysis data ===\n")
df <- fread("../data/analysis_panel.csv")
cat("Full sample:", nrow(df), "obs,", uniqueN(df$facility_id), "facilities\n")

df_bal <- fread("../data/balanced_panel.csv")
cat("Balanced panel:", nrow(df_bal), "obs,", uniqueN(df_bal$facility_id), "facilities\n")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("\n=== Main DiD Specifications ===\n")

# Spec 1: Simple TWFE on full sample
m1 <- feols(log_co2e ~ treat_post | facility_id + year,
            data = df, cluster = ~province)

# Spec 2: TWFE on balanced panel
m2 <- feols(log_co2e ~ treat_post | facility_id + year,
            data = df_bal, cluster = ~province)

# Spec 3: TWFE with sector x year FE (controls for sector-specific shocks)
m3 <- feols(log_co2e ~ treat_post | facility_id + sector^year,
            data = df_bal, cluster = ~province)

# Spec 4: Levels (total_co2e in thousands)
df_bal[, co2e_k := total_co2e / 1000]
m4 <- feols(co2e_k ~ treat_post | facility_id + year,
            data = df_bal, cluster = ~province)

cat("\n--- Specification 1: Full sample, facility + year FE ---\n")
print(summary(m1))
cat("\n--- Specification 2: Balanced panel, facility + year FE ---\n")
print(summary(m2))
cat("\n--- Specification 3: Balanced panel, facility + sector×year FE ---\n")
print(summary(m3))
cat("\n--- Specification 4: Levels (1000 tonnes), balanced panel ---\n")
print(summary(m4))

# Save main results
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4), "../data/main_results.rds")

# ============================================================
# EVENT STUDY (TABLE 3)
# ============================================================
cat("\n=== Event Study ===\n")

# Create event-time indicators (relative to 2018, last pre-treatment year)
df_bal[, event_time := year - 2019]  # 2019 is first treatment year

# Event study with fixest::i()
es <- feols(log_co2e ~ i(event_time, backstop, ref = -1) | facility_id + year,
            data = df_bal, cluster = ~province)

cat("\n--- Event Study Coefficients ---\n")
print(summary(es))

# Extract event-study data for table
es_coefs <- as.data.table(coeftable(es))
es_coefs[, event_time := as.integer(gsub(".*::", "", rownames(coeftable(es))))]
setnames(es_coefs, c("estimate", "se", "tstat", "pval", "event_time"))

saveRDS(es, "../data/event_study.rds")
fwrite(es_coefs, "../data/event_study_coefs.csv")

# ============================================================
# DIAGNOSTICS
# ============================================================
cat("\n=== Sample Diagnostics ===\n")

n_treated <- uniqueN(df_bal[backstop == 1, facility_id])
n_control <- uniqueN(df_bal[backstop == 0, facility_id])
n_pre <- uniqueN(df_bal[year < 2019, year])
n_post <- uniqueN(df_bal[year >= 2019, year])
n_obs <- nrow(df_bal)
n_provinces <- uniqueN(df_bal$province)

cat("Treated facilities:", n_treated, "\n")
cat("Control facilities:", n_control, "\n")
cat("Pre-treatment years:", n_pre, "\n")
cat("Post-treatment years:", n_post, "\n")
cat("Total observations:", n_obs, "\n")
cat("Province clusters:", n_provinces, "\n")

# Mean emissions by group
cat("\n=== Pre-treatment means ===\n")
pre_means <- df_bal[year < 2019, .(
  mean_co2e = mean(total_co2e, na.rm = TRUE),
  median_co2e = median(total_co2e, na.rm = TRUE),
  sd_co2e = sd(total_co2e, na.rm = TRUE),
  n = .N
), by = backstop]
print(pre_means)

# Write diagnostics for validator
diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control,
  n_post = n_post,
  n_provinces = n_provinces,
  main_coef = coef(m2)["treat_post"],
  main_se = se(m2)["treat_post"],
  main_pval = pvalue(m2)["treat_post"]
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main result summary ===\n")
cat("Backstop effect on log(emissions):", round(coef(m2)["treat_post"], 4),
    " (SE:", round(se(m2)["treat_post"], 4), ")\n")
cat("Implied % change:", round((exp(coef(m2)["treat_post"]) - 1) * 100, 2), "%\n")
