# ==============================================================================
# 04_robustness.R — Robustness Checks
# Paper: When the Campus Goes Dark (apep_0771)
# ==============================================================================

source("00_packages.R")

qwi_panel  <- readRDS("../data/qwi_panel.rds")
results    <- readRDS("../data/main_results.rds")

# Build annual panel (same as 03)
annual_panel <- qwi_panel %>%
  group_by(county_fips, year, industry, n_closures, first_closure_year,
           total_peak_enrollment, has_chain, chain_closures) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    hir_a = sum(hir_a, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_emp = log(pmax(emp, 1)),
    log_hir = log(pmax(hir_a, 1)),
    log_sep = log(pmax(sep, 1)),
    log_earn = log(pmax(earn_s, 1)),
    post = as.integer(year >= first_closure_year & first_closure_year > 0),
    treat_intensity = n_closures * post
  )

robustness <- list()

# ---- 1. Enrollment-weighted intensity ----
cat("--- Enrollment-Weighted Intensity ---\n")

df_edu <- annual_panel %>%
  filter(industry == "61") %>%
  mutate(enrl_intensity = total_peak_enrollment * post / 1000) %>%
  filter(!is.na(log_emp), is.finite(log_emp))

robustness$enrl_weighted <- feols(log_emp ~ enrl_intensity | county_fips + year,
                                   data = df_edu, cluster = ~county_fips)
cat(sprintf("  Enrollment-weighted: %.6f (%.6f)\n",
            coef(robustness$enrl_weighted)[1],
            sqrt(vcov(robustness$enrl_weighted)[1,1])))

# ---- 2. High-Intensity Only (>=3 closures) ----
cat("--- High-Intensity Counties (>=3 closures) ---\n")

df_high <- annual_panel %>%
  filter(industry == "61", n_closures >= 3 | n_closures == 0) %>%
  filter(!is.na(log_emp), is.finite(log_emp))

robustness$high_intensity <- feols(log_emp ~ treat_intensity | county_fips + year,
                                    data = df_high, cluster = ~county_fips)
cat(sprintf("  High-intensity: %.5f (%.5f)\n",
            coef(robustness$high_intensity)[1],
            sqrt(vcov(robustness$high_intensity)[1,1])))

# ---- 3. Placebo: Manufacturing (NAICS 31-33) ----
# Manufacturing should NOT be affected by for-profit college closures
cat("--- Placebo: Total Private Employment ---\n")

df_total <- annual_panel %>%
  filter(industry == "00") %>%
  filter(!is.na(log_emp), is.finite(log_emp))

robustness$placebo_total <- feols(log_emp ~ treat_intensity | county_fips + year,
                                   data = df_total, cluster = ~county_fips)
cat(sprintf("  Total Private: %.5f (%.5f)\n",
            coef(robustness$placebo_total)[1],
            sqrt(vcov(robustness$placebo_total)[1,1])))

# ---- 4. Drop Top-5 Closure Counties (Outlier Check) ----
cat("--- Dropping Top-5 Closure Counties ---\n")

top5 <- annual_panel %>%
  filter(n_closures > 0) %>%
  distinct(county_fips, n_closures) %>%
  arrange(desc(n_closures)) %>%
  head(5) %>%
  pull(county_fips)

df_no_top5 <- annual_panel %>%
  filter(industry == "61", !(county_fips %in% top5)) %>%
  filter(!is.na(log_emp), is.finite(log_emp))

robustness$no_top5 <- feols(log_emp ~ treat_intensity | county_fips + year,
                             data = df_no_top5, cluster = ~county_fips)
cat(sprintf("  No Top-5: %.5f (%.5f)\n",
            coef(robustness$no_top5)[1],
            sqrt(vcov(robustness$no_top5)[1,1])))

# ---- 5. Pre-Trend Test (Event Study Coefficients) ----
cat("--- Pre-Trend Test ---\n")

df_es <- annual_panel %>%
  filter(industry == "61") %>%
  mutate(
    event_time = ifelse(first_closure_year > 0, year - first_closure_year, NA_integer_)
  ) %>%
  filter(!is.na(log_emp), is.finite(log_emp))

# Only for treated units: check pre-trend coefficients
df_treated_es <- df_es %>%
  filter(!is.na(event_time), event_time >= -5, event_time <= 5) %>%
  mutate(event_time_f = relevel(factor(event_time), ref = "-1"))

robustness$event_study <- feols(log_emp ~ event_time_f | county_fips + year,
                                 data = df_treated_es, cluster = ~county_fips)

# Check pre-trend coefficients
pre_coefs <- coef(robustness$event_study)
pre_names <- grep("^event_time_f-[2-5]$", names(pre_coefs), value = TRUE)
if (length(pre_names) > 0) {
  pre_vals <- pre_coefs[pre_names]
  pre_ses  <- sqrt(diag(vcov(robustness$event_study))[pre_names])
  cat("  Pre-trend coefficients:\n")
  for (j in seq_along(pre_names)) {
    cat(sprintf("    %s: %.5f (%.5f), p=%.4f\n",
                pre_names[j], pre_vals[j], pre_ses[j],
                2 * pnorm(-abs(pre_vals[j] / pre_ses[j]))))
  }
}

# ---- 6. Heterogeneity: Urban vs Rural ----
cat("--- Urban vs Rural Heterogeneity ---\n")

# Proxy: counties with emp > median are "urban"
median_emp <- annual_panel %>%
  filter(industry == "00", year == 2012) %>%
  pull(emp) %>%
  median(na.rm = TRUE)

df_het <- annual_panel %>%
  filter(industry == "61") %>%
  mutate(urban = as.integer(emp > median_emp)) %>%
  filter(!is.na(log_emp), is.finite(log_emp))

robustness$urban <- feols(log_emp ~ treat_intensity:i(urban) | county_fips + year,
                           data = df_het, cluster = ~county_fips)

# ---- 7. Save all robustness results ----
saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
