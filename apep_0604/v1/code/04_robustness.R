# 04_robustness.R — Robustness checks
# APEP-0604: Colombia FARC Peace and Education

source("code/00_packages.R")

load("data/models.RData")

cat("=== Robustness checks ===\n")

# ---------------------------------------------------------------
# 1. Alternative treatment measures
# ---------------------------------------------------------------
cat("\n--- Log intensity ---\n")

r1_log <- feols(
  net_secondary ~ log_farc_intensity:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)
summary(r1_log)

# Deaths-based intensity
cat("\n--- Deaths-based intensity ---\n")
r1_deaths <- feols(
  net_secondary ~ farc_deaths_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)
summary(r1_deaths)

# High-intensity binary (≥3 events)
cat("\n--- High-intensity binary ---\n")
r1_high <- feols(
  net_secondary ~ high_farc:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)
summary(r1_high)

# ---------------------------------------------------------------
# 2. Excluding department capitals
# ---------------------------------------------------------------
cat("\n--- Excluding department capitals ---\n")

# Department capitals typically end in 001
panel <- panel %>%
  mutate(is_capital = (mun_code %% 1000 == 1))

r2_no_capitals <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel %>% filter(!is_capital),
  cluster = ~dept_code
)
summary(r2_no_capitals)

# ---------------------------------------------------------------
# 3. Alternative clustering (municipality level)
# ---------------------------------------------------------------
cat("\n--- Municipality-clustered SEs ---\n")
r3_mun_cluster <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~mun_code
)
summary(r3_mun_cluster)

# ---------------------------------------------------------------
# 4. Excluding COVID year (2020)
# ---------------------------------------------------------------
cat("\n--- Excluding 2020 (COVID) ---\n")
r4_no_covid <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel %>% filter(year != 2020),
  cluster = ~dept_code
)
summary(r4_no_covid)

# ---------------------------------------------------------------
# 5. Pre-trend test: formal F-test on pre-period coefficients
# ---------------------------------------------------------------
cat("\n--- Pre-trend F-test ---\n")
# Test that all pre-period event study coefficients are jointly zero
pre_coefs <- grep("^event_factor::-[2-4]", names(coef(m4_es)), value = TRUE)
if (length(pre_coefs) > 0) {
  wald_test <- wald(m4_es, pre_coefs)
  cat("Joint pre-trend test (H0: all pre-period coefficients = 0):\n")
  print(wald_test)
}

# ---------------------------------------------------------------
# 6. Placebo treatment year (2013 instead of 2015)
# ---------------------------------------------------------------
cat("\n--- Placebo treatment year (2013) ---\n")
panel_placebo <- panel %>%
  filter(year <= 2015) %>%
  mutate(post_placebo = as.integer(year >= 2014))

r6_placebo <- feols(
  net_secondary ~ farc_events_pre:post_placebo |
    mun_code + year,
  data = panel_placebo,
  cluster = ~dept_code
)
summary(r6_placebo)

# ---------------------------------------------------------------
# 7. Wild cluster bootstrap (few clusters concern: 34 departments)
# ---------------------------------------------------------------
cat("\n--- Wild cluster bootstrap p-values ---\n")

# Using fixest's built-in bootstrap
r7_boot <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)

boot_pval <- tryCatch({
  boot_res <- boot(r7_boot, cluster = ~dept_code, R = 999, type = "mammen")
  boot_res
}, error = function(e) {
  cat("  Bootstrap failed:", e$message, "\n")
  NULL
})

if (!is.null(boot_pval)) {
  cat("Wild cluster bootstrap result:\n")
  print(boot_pval)
}

# ---------------------------------------------------------------
# 8. Sensitivity analysis: PDET only municipalities
# ---------------------------------------------------------------
cat("\n--- PDET municipalities only ---\n")
r8_pdet_only <- feols(
  net_secondary ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel %>% filter(pdet == 1),
  cluster = ~dept_code
)
summary(r8_pdet_only)

# ---------------------------------------------------------------
# 9. Violence reduction as first stage
# ---------------------------------------------------------------
cat("\n--- Violence reduction (first stage evidence) ---\n")

# Show that FARC events actually declined in high-intensity areas
r9_violence <- feols(
  farc_events_yr ~ farc_events_pre:post_ceasefire |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)
summary(r9_violence)

cat("\n--- Violence by period ---\n")
r9_violence_2 <- feols(
  farc_events_yr ~ farc_events_pre:post1_ceasefire_only +
    farc_events_pre:post2_pdet |
    mun_code + year,
  data = panel,
  cluster = ~dept_code
)
summary(r9_violence_2)

# ---------------------------------------------------------------
# Save robustness models
# ---------------------------------------------------------------
save(
  r1_log, r1_deaths, r1_high,
  r2_no_capitals,
  r3_mun_cluster,
  r4_no_covid,
  r6_placebo,
  r8_pdet_only,
  r9_violence, r9_violence_2,
  file = "data/robustness_models.RData"
)

cat("\n=== Robustness checks complete ===\n")
