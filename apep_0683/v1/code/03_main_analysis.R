## 03_main_analysis.R — Main DiD analysis for APEP-0683
## Council Tax Empty Homes Premium and Long-Term Vacancy

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Panel summary ===\n")
cat("  Obs:", nrow(panel), "\n")
cat("  LAs:", n_distinct(panel$ons_code), "\n")
cat("  Treated:", n_distinct(panel$ons_code[panel$ever_treated]), "\n")
cat("  Never-treated:", n_distinct(panel$ons_code[!panel$ever_treated]), "\n")
cat("  Years:", min(panel$year), "-", max(panel$year), "\n")

## ============================================================
## A. Treatment rollout visualization (descriptive)
## ============================================================
cat("\n=== Cohort analysis ===\n")

# Aggregate means by treatment group
group_means <- panel %>%
  group_by(ever_treated, year) %>%
  summarise(
    mean_ltv = mean(long_term_vacant, na.rm = TRUE),
    mean_log_ltv = mean(log_ltv, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

cat("  Pre-treatment (2004-2012) means:\n")
pre_means <- panel %>%
  filter(year >= 2004, year <= 2012) %>%
  group_by(ever_treated) %>%
  summarise(
    mean_ltv = mean(long_term_vacant, na.rm = TRUE),
    sd_ltv = sd(long_term_vacant, na.rm = TRUE),
    mean_log_ltv = mean(log_ltv, na.rm = TRUE),
    .groups = "drop"
  )
print(pre_means)

## ============================================================
## B. Main TWFE DiD specification
## ============================================================
cat("\n=== Main DiD results ===\n")

# Specification 1: Simple TWFE DiD
# Y_it = alpha_i + gamma_t + beta * (Treated_i x Post_t) + e_it
# Note: With ~270 treated and 5 controls, cluster at LA level

m1 <- feols(log_ltv ~ treated_post | la_id + year,
            data = panel, cluster = ~ons_code)
cat("\n--- Model 1: TWFE on log(LTV) ---\n")
summary(m1)

# Specification 2: Levels
m2 <- feols(long_term_vacant ~ treated_post | la_id + year,
            data = panel, cluster = ~ons_code)
cat("\n--- Model 2: TWFE on LTV levels ---\n")
summary(m2)

# Specification 3: LTV share (long-term vacants / all vacants)
m3 <- feols(ltv_share ~ treated_post | la_id + year,
            data = panel, cluster = ~ons_code)
cat("\n--- Model 3: TWFE on LTV share ---\n")
summary(m3)

# Specification 4: Per capita rate
m4 <- feols(ltv_per_1000 ~ treated_post | la_id + year,
            data = panel %>% filter(!is.na(ltv_per_1000)),
            cluster = ~ons_code)
cat("\n--- Model 4: TWFE on LTV per 1000 population ---\n")
summary(m4)

## ============================================================
## C. Event study (Sun-Abraham interaction-weighted)
## ============================================================
cat("\n=== Event study ===\n")

# Create event time variable
panel_es <- panel %>%
  mutate(
    event_time = ifelse(ever_treated, year - 2013, NA_integer_),
    # For never-treated, event_time stays NA (excluded from sunab)
    cohort = ifelse(ever_treated, 2013L, 10000L)  # Large number for never-treated
  )

# Sun-Abraham event study
es1 <- feols(log_ltv ~ sunab(cohort, year) | la_id + year,
             data = panel_es, cluster = ~ons_code)
cat("\n--- Event study: Sun-Abraham on log(LTV) ---\n")
summary(es1)

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es1))
es_coefs$event_time <- as.integer(str_extract(rownames(es_coefs), "-?\\d+$"))
es_coefs <- es_coefs %>%
  rename(estimate = Estimate, se = `Std. Error`, pval = `Pr(>|t|)`) %>%
  mutate(
    ci_lower = estimate - 1.96 * se,
    ci_upper = estimate + 1.96 * se
  ) %>%
  arrange(event_time)

cat("\n  Event study coefficients:\n")
print(es_coefs %>% select(event_time, estimate, se, pval))

# Save event study results
saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

## ============================================================
## D. Callaway-Sant'Anna (for comparison)
## ============================================================
cat("\n=== Callaway-Sant'Anna ===\n")

# Prepare data for did package
cs_data <- panel %>%
  mutate(
    # did package needs: first_treat = 0 for never-treated
    g = first_treat  # Already 0 for never-treated, 2013 for treated
  ) %>%
  filter(!is.na(log_ltv))

cs_out <- tryCatch({
  att_gt(
    yname = "log_ltv",
    tname = "year",
    idname = "la_id",
    gname = "g",
    data = cs_data,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("  CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\n--- CS-DiD group-time ATTs ---\n")
  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("  Overall ATT:", cs_agg$overall.att, "\n")
  cat("  SE:", cs_agg$overall.se, "\n")

  # Dynamic aggregation
  cs_dyn <- aggte(cs_out, type = "dynamic")
  cat("\n  Dynamic effects:\n")
  print(data.frame(
    event_time = cs_dyn$egt,
    att = round(cs_dyn$att.egt, 4),
    se = round(cs_dyn$se.egt, 4)
  ))

  saveRDS(cs_out, file.path(data_dir, "cs_results.rds"))
  saveRDS(cs_dyn, file.path(data_dir, "cs_dynamic.rds"))
}

## ============================================================
## E. Save main results and diagnostics
## ============================================================
cat("\n=== Saving results ===\n")

# Save model objects
saveRDS(m1, file.path(data_dir, "model_twfe_log.rds"))
saveRDS(m2, file.path(data_dir, "model_twfe_level.rds"))
saveRDS(m3, file.path(data_dir, "model_twfe_share.rds"))
saveRDS(m4, file.path(data_dir, "model_twfe_percap.rds"))
saveRDS(es1, file.path(data_dir, "model_es_sunab.rds"))

# Diagnostics for validator
n_treated_units <- n_distinct(panel$ons_code[panel$ever_treated])
n_pre <- length(unique(panel$year[panel$year < 2013]))
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated_units,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_distinct(panel$ons_code[!panel$ever_treated]),
  years = paste(min(panel$year), max(panel$year), sep = "-"),
  main_coef = coef(m1)["treated_postTRUE"],
  main_se = sqrt(diag(vcov(m1)))["treated_postTRUE"]
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("  Saved diagnostics.json\n")

cat("\nMain analysis complete.\n")
