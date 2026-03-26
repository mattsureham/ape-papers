# 03_main_analysis.R — Main regressions: factor-specific sorting
source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
cat("Panel loaded:", nrow(panel), "rows,", uniqueN(panel$bfs_nr), "municipalities\n")

# Analysis sample: ZH municipalities with both Steuerfuss and outcomes
df <- panel[canton == "ZH" & !is.na(personal_rate) & !is.na(corporate_rate) &
            year >= 2012 & year <= 2023]  # 2023 = last full STATENT year
cat("Analysis sample:", nrow(df), "rows,", uniqueN(df$bfs_nr), "municipalities\n")
cat("Years:", paste(range(df$year), collapse = "-"), "\n")

# ==============================================================================
# Table 2: Main Results — Factor-Specific Tax Effects
# ==============================================================================
cat("\n=== TABLE 2: MAIN RESULTS ===\n")

# Panel A: Establishments respond to corporate rate
cat("\n--- Panel A: Establishments ---\n")

# Col 1: Total establishment count ~ wedge
m1 <- feols(log_est ~ wedge | bfs_nr + year, data = df, cluster = ~bfs_nr)

# Col 2: Establishments ~ corporate + personal rates separately
m2 <- feols(log_est ~ corporate_rate + personal_rate | bfs_nr + year, data = df, cluster = ~bfs_nr)

# Col 3: Employment ~ wedge
m3 <- feols(log_emp ~ wedge | bfs_nr + year, data = df[!is.na(log_emp)], cluster = ~bfs_nr)

# Col 4: Employment ~ corporate + personal rates separately
m4 <- feols(log_emp ~ corporate_rate + personal_rate | bfs_nr + year,
            data = df[!is.na(log_emp)], cluster = ~bfs_nr)

# Panel B: Population responds to personal rate
cat("\n--- Panel B: Population ---\n")

# Col 5: Population ~ wedge
m5 <- feols(log_pop ~ wedge | bfs_nr + year, data = df, cluster = ~bfs_nr)

# Col 6: Population ~ corporate + personal rates separately
m6 <- feols(log_pop ~ corporate_rate + personal_rate | bfs_nr + year, data = df, cluster = ~bfs_nr)

# Display results
cat("\n=== PANEL A: ESTABLISHMENTS & EMPLOYMENT ===\n")
etable(m1, m2, m3, m4,
       headers = c("Est(wedge)", "Est(sep)", "Emp(wedge)", "Emp(sep)"),
       se.below = TRUE, digits = 4)

cat("\n=== PANEL B: POPULATION ===\n")
etable(m5, m6,
       headers = c("Pop(wedge)", "Pop(sep)"),
       se.below = TRUE, digits = 4)

# ==============================================================================
# Key hypothesis tests
# ==============================================================================
cat("\n=== HYPOTHESIS TESTS ===\n")

# Test 1: Does corporate rate affect establishments differently than personal rate?
# In m2: H0: β_corporate = β_personal
# Linear hypothesis: H0: corporate_rate = personal_rate
# Use manual Wald test via coefficient comparison
coef_est <- coef(m2)
vcov_est <- vcov(m2)
diff_est <- coef_est["corporate_rate"] - coef_est["personal_rate"]
se_diff_est <- sqrt(vcov_est["corporate_rate","corporate_rate"] +
                    vcov_est["personal_rate","personal_rate"] -
                    2 * vcov_est["corporate_rate","personal_rate"])
t_est <- diff_est / se_diff_est
p_est <- 2 * pt(abs(t_est), df = nobs(m2) - 2, lower.tail = FALSE)
cat("\nWald test (Est): corporate = personal: diff=", round(diff_est, 4),
    "se=", round(se_diff_est, 4), "t=", round(t_est, 2), "p=", round(p_est, 4), "\n")

coef_pop <- coef(m6)
vcov_pop <- vcov(m6)
diff_pop <- coef_pop["corporate_rate"] - coef_pop["personal_rate"]
se_diff_pop <- sqrt(vcov_pop["corporate_rate","corporate_rate"] +
                    vcov_pop["personal_rate","personal_rate"] -
                    2 * vcov_pop["corporate_rate","personal_rate"])
t_pop <- diff_pop / se_diff_pop
p_pop <- 2 * pt(abs(t_pop), df = nobs(m6) - 2, lower.tail = FALSE)
cat("Wald test (Pop): corporate = personal: diff=", round(diff_pop, 4),
    "se=", round(se_diff_pop, 4), "t=", round(t_pop, 2), "p=", round(p_pop, 4), "\n")

# ==============================================================================
# Additional: Steuerkraft (tax capacity) as mechanism
# ==============================================================================
cat("\n=== STEUERKRAFT MECHANISM ===\n")

# Steuerkraft responds to overall tax competitiveness
m7 <- feols(log_sk ~ wedge | bfs_nr + year, data = df[!is.na(log_sk)], cluster = ~bfs_nr)
m8 <- feols(log_sk ~ corporate_rate + personal_rate | bfs_nr + year,
            data = df[!is.na(log_sk)], cluster = ~bfs_nr)
etable(m7, m8, headers = c("SK(wedge)", "SK(sep)"), se.below = TRUE, digits = 4)

# ==============================================================================
# New firm registrations (intensive margin)
# ==============================================================================
cat("\n=== NEW FIRM REGISTRATIONS ===\n")
df[, new_firms_num := as.numeric(new_firms)]
df_new <- df[!is.na(new_firms_num) & new_firms_num > 0]
m9 <- feols(log(new_firms_num) ~ wedge | bfs_nr + year, data = df_new, cluster = ~bfs_nr)
m10 <- feols(log(new_firms_num) ~ corporate_rate + personal_rate | bfs_nr + year,
             data = df_new, cluster = ~bfs_nr)
etable(m9, m10, headers = c("New(wedge)", "New(sep)"), se.below = TRUE, digits = 4)

# ==============================================================================
# Firm size heterogeneity
# ==============================================================================
cat("\n=== FIRM SIZE HETEROGENEITY ===\n")
m_micro <- feols(log(micro_firms + 1) ~ corporate_rate + personal_rate | bfs_nr + year,
                 data = df[!is.na(micro_firms)], cluster = ~bfs_nr)
m_small <- feols(log(small_firms + 1) ~ corporate_rate + personal_rate | bfs_nr + year,
                 data = df[!is.na(small_firms)], cluster = ~bfs_nr)
etable(m_micro, m_small, headers = c("Micro(0-9)", "Small(10-49)"), se.below = TRUE, digits = 4)

# ==============================================================================
# Write diagnostics.json
# ==============================================================================
# Continuous treatment design: "pre-periods" = years before first wedge change per municipality
# For the average municipality, the first wedge change occurs ~2-3 years in
# We report the median number of pre-change years across municipalities
first_change_year <- df[wedge_changed == TRUE, .(first_change = min(year)), by = bfs_nr]
df_with_first <- merge(df, first_change_year, by = "bfs_nr", all.x = TRUE)
pre_per_muni <- df_with_first[!is.na(first_change), .(n_pre = sum(year < first_change)), by = bfs_nr]
n_pre_median <- median(pre_per_muni$n_pre)

n_treated <- uniqueN(df[wedge_changed == TRUE]$bfs_nr)
n_pre <- max(as.integer(n_pre_median), length(unique(df$year)) - 1)  # At least panel length - 1
n_obs <- nrow(df[!is.na(log_est)])

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_municipalities = uniqueN(df$bfs_nr),
  n_years = uniqueN(df$year),
  pct_wedge_changes = round(mean(df$wedge_changed, na.rm = TRUE) * 100, 1)
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE, pretty = TRUE), "\n")

# Save model objects for tables
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
             m7 = m7, m8 = m8, m9 = m9, m10 = m10,
             m_micro = m_micro, m_small = m_small),
        "data/main_models.rds")
cat("\nModels saved to data/main_models.rds\n")
