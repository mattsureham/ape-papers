# 03_main_analysis.R — Main triple-difference estimation
# EU Late Payment Directive & Small Firm Survival (apep_0938)

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# ================================================================
# A. Summary statistics
# ================================================================

cat("=== Summary Statistics ===\n")

# Pre/post means by small vs large
summ <- panel |>
  filter(!is.na(death_rate)) |>
  group_by(small, post) |>
  summarise(
    mean_death = mean(death_rate, na.rm = TRUE),
    sd_death = sd(death_rate, na.rm = TRUE),
    mean_birth = mean(birth_rate, na.rm = TRUE),
    mean_surv = mean(surv_rate_3yr, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

print(summ)

# Pre/post means by high-delay vs low-delay
summ2 <- panel |>
  filter(!is.na(death_rate)) |>
  group_by(high_delay, post) |>
  summarise(
    mean_death = mean(death_rate, na.rm = TRUE),
    mean_birth = mean(birth_rate, na.rm = TRUE),
    mean_surv = mean(surv_rate_3yr, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

cat("\nBy high/low delay:\n")
print(summ2)

# ================================================================
# B. Main triple-diff: Death Rate
# ================================================================

cat("\n=== Main Results: Firm Death Rate ===\n")

# Primary specification: triple-diff with saturated FE
# Y = death_rate
# FE: country×size, country×year, size×year
# Key coefficient: post × pay_delay_z × small

m1_death <- feols(
  death_rate ~ post:pay_delay_z:small +
    post:pay_delay_z + post:small + pay_delay_z:small |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel,
  cluster = ~geo
)

cat("\nModel 1: Triple-diff on death rate\n")
summary(m1_death)

# Binary intensity version
m2_death <- feols(
  death_rate ~ post:high_delay:small +
    post:high_delay + post:small + high_delay:small |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel,
  cluster = ~geo
)

cat("\nModel 2: Binary intensity triple-diff on death rate\n")
summary(m2_death)

# ================================================================
# C. Main triple-diff: Birth Rate
# ================================================================

cat("\n=== Main Results: Firm Birth Rate ===\n")

# Birth rate (V97130) has sparse coverage — wrap in tryCatch
m1_birth <- tryCatch({
  panel_birth <- panel |> filter(!is.na(birth_rate), birth_rate > 0)
  if (nrow(panel_birth) < 100) stop("Insufficient birth rate data")
  feols(
    birth_rate ~ post:pay_delay_z:small +
      post:pay_delay_z + post:small + pay_delay_z:small |
      geo^sizeclas + geo^year + sizeclas^year,
    data = panel_birth,
    cluster = ~geo
  )
}, error = function(e) {
  cat("Birth rate model failed (sparse data):", conditionMessage(e), "\n")
  NULL
})

if (!is.null(m1_birth)) {
  cat("\nModel 1: Triple-diff on birth rate\n")
  summary(m1_birth)
} else {
  cat("Skipping birth rate — insufficient data.\n")
}

# ================================================================
# D. Main triple-diff: 3-Year Survival Rate
# ================================================================

cat("\n=== Main Results: 3-Year Survival Rate ===\n")

m1_surv <- feols(
  surv_rate_3yr ~ post:pay_delay_z:small +
    post:pay_delay_z + post:small + pay_delay_z:small |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel,
  cluster = ~geo
)

cat("\nModel 1: Triple-diff on 3-year survival rate\n")
summary(m1_surv)

m2_surv <- feols(
  surv_rate_3yr ~ post:high_delay:small +
    post:high_delay + post:small + high_delay:small |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel,
  cluster = ~geo
)

cat("\nModel 2: Binary intensity triple-diff on survival rate\n")
summary(m2_surv)

# ================================================================
# E. Event Study (year-by-year triple interaction)
# ================================================================

cat("\n=== Event Study ===\n")

# Exclude 2013 as the omitted year (last pre-treatment year)
panel_es <- panel |>
  filter(!is.na(death_rate)) |>
  mutate(
    rel_year_f = factor(rel_year),
    # Omit year 0 (2013) as reference
    rel_year_f = relevel(rel_year_f, ref = "0")
  )

es_death <- feols(
  death_rate ~ i(rel_year, I(pay_delay_z * small), ref = 0) +
    i(rel_year, pay_delay_z, ref = 0) +
    i(rel_year, small, ref = 0) |
    geo^sizeclas + sizeclas^year,
  data = panel_es,
  cluster = ~geo
)

cat("\nEvent study on death rate:\n")
summary(es_death)

# Save event study coefficients for the paper
es_coefs <- coeftable(es_death) |>
  as.data.frame() |>
  tibble::rownames_to_column("term") |>
  filter(grepl("pay_delay_z.*small", term)) |>
  mutate(
    rel_year = as.numeric(str_extract(term, "-?\\d+"))
  ) |>
  select(rel_year, estimate = Estimate, se = `Std. Error`,
         pval = `Pr(>|t|)`) |>
  mutate(
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  )

cat("\nEvent study triple-interaction coefficients:\n")
print(es_coefs)

saveRDS(es_coefs, "../data/es_coefs_death.rds")

# ================================================================
# F. Wild cluster bootstrap for main specification
# ================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

# Bootstrap the main triple-diff coefficient
tryCatch({
  boot_res <- boottest(
    m1_death,
    param = "post:pay_delay_z:small",
    clustid = ~geo,
    B = 999,
    type = "webb"
  )
  cat("Bootstrap p-value:", boot_res$p_val, "\n")
  cat("Bootstrap 95% CI: [", boot_res$conf_int[1], ",", boot_res$conf_int[2], "]\n")

  saveRDS(boot_res, "../data/boot_death.rds")
}, error = function(e) {
  cat("Bootstrap failed:", conditionMessage(e), "\n")
  cat("Proceeding with cluster-robust SEs only.\n")
})

# ================================================================
# G. Store pre-treatment SDs for SDE calculation
# ================================================================

pre_stats <- panel |>
  filter(year < 2014) |>
  summarise(
    sd_death = sd(death_rate, na.rm = TRUE),
    sd_birth = sd(birth_rate, na.rm = TRUE),
    sd_surv = sd(surv_rate_3yr, na.rm = TRUE),
    mean_death = mean(death_rate, na.rm = TRUE),
    mean_birth = mean(birth_rate, na.rm = TRUE),
    mean_surv = mean(surv_rate_3yr, na.rm = TRUE)
  )

cat("\nPre-treatment outcome statistics:\n")
print(pre_stats)

saveRDS(pre_stats, "../data/pre_stats.rds")

# ================================================================
# H. Save all models
# ================================================================

models <- list(
  death_continuous = m1_death,
  death_binary = m2_death,
  birth_continuous = m1_birth,
  surv_continuous = m1_surv,
  surv_binary = m2_surv,
  es_death = es_death
)

saveRDS(models, "../data/models.rds")

# ================================================================
# I. Diagnostics JSON
# ================================================================

n_treated_small <- panel |>
  filter(small == 1, post == 1, !is.na(death_rate)) |>
  distinct(geo) |>
  nrow()

n_pre <- panel |>
  filter(post == 0) |>
  distinct(year) |>
  nrow()

n_obs <- panel |>
  filter(!is.na(death_rate)) |>
  nrow()

diagnostics <- list(
  n_treated = n_treated_small,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = n_distinct(panel$geo),
  n_years = n_distinct(panel$year),
  n_size_classes = n_distinct(panel$sizeclas)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:\n")
print(diagnostics)

cat("\n=== Main analysis complete ===\n")
